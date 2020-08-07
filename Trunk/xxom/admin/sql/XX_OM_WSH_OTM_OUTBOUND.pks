SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_WSH_OTM_OUTBOUND_PKG AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_OM_WSH_OTM_OUTBOUND_PKG                                                     |
-- | RICE ID: E0271_EBSOTMDataMap                                                            |
-- | Description      : Package Body containing procedure for Delivery Information extraction|
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   30-Jan-2007       Shashi Kumar     Initial Draft Version                      |
-- |                                                                                         |
-- |1.0        22-Jun-07         Shashi Kumar     Based lined after testing                  |
-- +=========================================================================================+

--===================
-- CONSTANTS
--===================
G_PKG_NAME CONSTANT VARCHAR2(30) := 'XX_OM_WSH_OTM_OUTBOUND_PKG';

-- +==================================================================================================+
-- |  Procedure : GET_DELIVERY_OBJECTS                                                                |
-- |  Description:                                                                                    |
-- |     Procedure to get the delivery,delivery details and Lpn info                                  |
-- |     in the form of objects (WSH_OTM_DLV_TAB)                                                     |
-- |                                                                                                  |
-- |  Inputs/Outputs:                                                                                 |
-- |           p_dlv_id_tab  - id table (list of delivery Ids)                                        |
-- |           p_user_id     - User Id to set the context                                             |
-- |           p_resp_id     - Resp Id to set the context                                             |
-- |           p_resp_appl_id    - Resp Appl Id to set the context                                    |
-- |           p_caller      - When passed from GET_TRIP_OBJECTS this will have a                     |
-- |             value of 'A' else default 'D'                                                        |
-- |  Output:                                                                                         |
-- |           x_domain_name     - domain name                                                        |
-- |           x_otm_user_name   - otm User Name                                                      |
-- |       x_otm_pwd     - otm Password                                                               |
-- |       x_otm_pwd     - otm Password                                                               |
-- |       x_dlv_tab     - Nested Table which contains the delivery info                              |
-- |       x_error_dlv_id_tab - List of ids for which the data could not be retrieved                 |
-- |           x_return_status                                                                        |
-- +==================================================================================================+

PROCEDURE GET_DELIVERY_OBJECTS(p_dlv_id_tab       IN OUT NOCOPY   WSH_OTM_ID_TAB,
                               p_user_id          IN        NUMBER,
                               p_resp_id          IN        NUMBER,
                               p_resp_appl_id     IN        NUMBER,
                               p_caller           IN        VARCHAR2 DEFAULT 'D',
                               x_domain_name      OUT NOCOPY    VARCHAR2,
                               x_otm_user_name    OUT NOCOPY    VARCHAR2,
                               x_otm_pwd          OUT NOCOPY    VARCHAR2,
                               x_server_tz_code   OUT NOCOPY    VARCHAR2,
                               x_dlv_tab          OUT NOCOPY    XX_OM_WSH_OTM_DLV_TAB,
                               x_error_dlv_id_tab OUT NOCOPY  WSH_OTM_ID_TAB  ,
                               x_return_status    OUT NOCOPY  VARCHAR2);




-- +===================================================================+
-- | Name       :  GET_TRIP_OBJECTS                                    |
-- | Description:  This Procedure will be used get the Trip, Trip Stop,|
-- | delivery,delivery details and Lpn info                            |
-- |                                                                   |
-- | Parameters : Inputs/Outputs:                                      |
-- |            p_trip_id_tab - id table (list of Trip Ids)            |
-- |            p_user_id     - User Id to set the context             |
-- |            p_resp_id     - Resp Id to set the context             |
-- |            p_resp_appl_id    - Resp Appl Id to set the context    |
-- |           Output:                                                 |
-- |            x_domain_name         - domain name                    |
-- |            x_otm_user_name       - otm User Name                  |
-- |            x_otm_pwd             - otm Password                   |
-- |            x_otm_pwd             - otm Password                   |
-- |            x_trip_tab            - Nested Table which contains    |
-- |                                    the trip info                  |
-- |            x_error_trip_id_tab   - List of ids for which the      |
-- |                                    data could not be retrieved    |
-- +===================================================================+

PROCEDURE GET_TRIP_OBJECTS(p_trip_id_tab        IN OUT NOCOPY   WSH_OTM_ID_TAB,
                   p_user_id        IN      NUMBER,
                   p_resp_id        IN      NUMBER,
                   p_resp_appl_id       IN      NUMBER,
                   x_domain_name        OUT NOCOPY  VARCHAR2,
                   x_otm_user_name      OUT NOCOPY  VARCHAR2,
                   x_otm_pwd        OUT NOCOPY  VARCHAR2,
                   x_server_tz_code     OUT NOCOPY  VARCHAR2,
                   x_trip_tab       OUT NOCOPY  WSH_OTM_TRIP_TAB,
                   x_dlv_tab        OUT NOCOPY  XX_OM_WSH_OTM_DLV_TAB,
                   x_error_trip_id_tab  OUT NOCOPY  WSH_OTM_ID_TAB,
                   x_return_status      OUT NOCOPY  VARCHAR2);


-- +====================================================================================================+
-- |  Procedure : UPDATE_ENTITY_INTF_STATUS                                                             |
-- |  Description:                                                                                      |
-- |     This procedure will be used to upate the interface flag status on the delivery or trip stop.   |
-- |                                                                                                    |
-- |  Inputs/Outputs:                                                                                   |
-- |           p_entity_type - Valid values are "DELIVERY",  "TRIP"                                     |
-- |           p_entity_id_tab  - id table  (IN / OUT) -- List of Delivery id or Trip id                |
-- |           p_new_intf_status - Delivery or Trip Stop Status                                         |
-- |            Valid values of this parameter are "IN_PROCESS", "COMPLETE"                             |
-- |                                                                                                    |
-- |                      Trip Stop Interface Flag values (internal):                                   |
-- |                      ASR - ACTUAL_SHIP_REQUIRED                                                    |
-- |                      ASP - ACTUAL_IN_PROCESS                                                       |
-- |                      CMP - COMPLETE                                                                |
-- |                                                                                                    |
-- |                      Delivery Interface Flag values (internal):                                    |
-- |                      NS - NOT TO BE SENT                                                           |
-- |                      CR - CREATE_REQUIRED                                                          |
-- |                      UR - UPDATE_REQUIRED                                                          |
-- |                      DR - DELETE_REQUIRED                                                          |
-- |                      CP - CREATE_IN_PROCESS                                                        |
-- |                      UP- UPDATE_IN_PROCESS                                                         |
-- |                      DP - DELETE_IN_PROCESS                                                        |
-- |                      AW - AWAITING_ANSWER                                                          |
-- |                      AR - ANSWER_RECEIVED                                                          |
-- |                      CMP - COMPLETE                                                                |
-- |           p_user_Id  - user id ( application user id )                                             |
-- |           p_resp_Id - responsibility id                                                            |
-- |           p_resp_appl_Id - resp application id ( Application Responsibility Id)                    |
-- |  Output:                                                                                           |
-- |           p_error_id_tab - erred entity id table  -- list of ERRORed delivery id or tripd id       |
-- |           p_entity_id_tab  - id table  (IN / OUT) - list of SUCCESS delivery id or trip id         |
-- |           x_return_status - "S"-Success, "E"-Error, "U"-Unexpected Error                           |
-- |  API is called from the following phases / API                                                     |
-- +====================================================================================================+
/*
1.Concurrent Request --TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = X_IN_PROCESS.
2.WSH_GLOG_OUTBOUND.GET_TRIP_OBJECTS - TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = AWAITING_ANSWER.
3.WSH_GLOG_OUTBOUND.GET_DELIVERY_OBJECTS - TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = AWAITING_ANSWER.
*/
-- +======================================================================+
PROCEDURE UPDATE_ENTITY_INTF_STATUS(
           x_return_status   OUT NOCOPY   VARCHAR2,
           p_entity_type     IN VARCHAR2,
           p_new_intf_status IN VARCHAR2,
           p_userId          IN    NUMBER DEFAULT NULL,
           p_respId          IN    NUMBER DEFAULT NULL,
           p_resp_appl_Id    IN    NUMBER DEFAULT NULL,
           p_entity_id_tab   IN OUT NOCOPY WSH_OTM_ID_TAB,
           p_error_id_tab    IN OUT NOCOPY WSH_OTM_ID_TAB
      );



END XX_OM_WSH_OTM_OUTBOUND_PKG;
/
SHOW ERRORS;
EXIT;