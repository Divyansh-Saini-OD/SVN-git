create or replace
PACKAGE xx_cs_mps_avf_feed_pkg AS
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
-- |1.1        01-APR-2013   Bapuji Nanapaneni  Added new procedure MISC_FEED for misc supplies   |
-- |                                                                                              |
-- +==============================================================================================+
  gc_ind VARCHAR2(5) := ',';
  -- +=====================================================================+
  -- | Name  : send_feed                                                   |
  -- | Description      : This Procedure will create feed to send to MPS   |
  -- |                    analyst                                          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   Service ID       |
  -- |                    p_party_id          IN NUMBER   customer id      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+

  PROCEDURE send_feed( p_request_id      IN  NUMBER
                     , p_party_id        IN  NUMBER
                     , x_return_status  OUT VARCHAR2
                     , x_return_mesg    OUT VARCHAR2
                     );

  -- +=====================================================================+
  -- | Name  : receive_feed                                                |
  -- | Description      : This Procedure will receive feed to update tbale |
  -- |                    after MPS analyst modify the data                |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   SR ID            |
  -- |                    p_party_id          IN NUMBER   customer ID      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE receive_feed( p_request_id      IN  NUMBER
                        , p_party_id        IN  NUMBER
                        , x_return_status  OUT VARCHAR2
                        , x_return_mesg    OUT VARCHAR2
                        );

  -- +=====================================================================+
  -- | Name  : fleet_feed                                                  |
  -- | Description      : This Procedure will read fleet feed and send data|
  -- |                    to xx_cs_mps_fleet_pkg.device_feed               |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:       p_file_name       IN VARCHAR2 file_name           |
  -- |                   x_return_status   OUT VARCHAR2 Return status      |
  -- |                   x_return_msg      OUT VARCHAR2 Return Message     |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE fleet_feed( p_file_name       IN  VARCHAR2
                      , x_return_status  OUT  VARCHAR2
                      , x_return_msg     OUT  VARCHAR2
                      );

  -- +=====================================================================+
  -- | Name  : get_ship_to                                                 |
  -- | Description      : This Procedure will create feed to send to AOPS  |
  -- |                    team to create SHIP TO                           |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_party_id          IN NUMBER   customer id      |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE get_ship_to( p_party_id        IN   NUMBER
                       , x_return_status  OUT VARCHAR2
                       , x_return_mesg    OUT VARCHAR2
                       );
  -- +=====================================================================+
  -- | Name  : get_clob_file                                               |
  -- | Description      : This Procedure will identify the file and write  |
  -- |                    file to specfied directory                       |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   request id       |
  -- |                    x_file_name        OUT VARCHAR2 file name        |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE get_clob_file( p_request_id     IN  NUMBER
                         , x_file_name     OUT  VARCHAR2
                         , x_return_status OUT  VARCHAR2
                         , x_return_msg    OUT  VARCHAR2
                         );
  -- +=====================================================================+
  -- | Name  : LOAD_FLEET_FEED                                             |
  -- | Description      : This Procedure will be called from a business    |
  -- |                    Event to process the attached file data          |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_request_id        IN NUMBER   request id       |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
  PROCEDURE LOAD_FLEET_FEED(	p_request_id      IN  NUMBER
                           , x_return_status   OUT  VARCHAR2
                           , x_return_msg      OUT  VARCHAR2
                           );
  -- +=====================================================================+
  -- | Name  : MISC_FEED                                                   |
  -- | Description      : This Procedure will read feed and insert into    |
  -- |                    XX_CS_MPS_DEVICE_SUPPLIES                        |
  -- |                                                                     |
  -- |                                                                     |
  -- | Parameters:        p_file_name        IN VARCHAR2 file_name         |
  -- |                    x_return_status    OUT VARCHAR2 Return status    |
  -- |                    x_return_msg       OUT VARCHAR2 Return Message   |
  -- |                                                                     |
  -- +=====================================================================+
PROCEDURE MISC_FEED( p_request_id IN  VARCHAR2
                   , x_return_status  OUT  VARCHAR2
                   , x_return_msg     OUT  VARCHAR2
                   );
END xx_cs_mps_avf_feed_pkg;
/
SHOW ERRORS PACKAGE XX_CS_MPS_AVF_FEED_PKG;
EXIT;