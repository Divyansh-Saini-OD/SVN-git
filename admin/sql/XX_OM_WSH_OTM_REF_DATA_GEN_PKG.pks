SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_OM_WSH_OTM_REF_DATA_GEN_PKG AS
--
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_OM_WSH_OTM_REF_DATA_GEN_PKG                                                 |
-- | RICE ID: E0271_EBSOTMDataMap                                                            |
-- | Description      : Package Body containing procedures for Location Information          |
-- |                    which will be consumed by OTM                                        |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   30-Jan-2007       Shashi Kumar     Initial Draft version                      |
-- |1.0        33-Jun-07         Shashi Kumar     Based lined after testing                  |
-- +=========================================================================================+


-- +=========================================================================== +
-- |PROCEDURE : Send_Locations          This procedure is called only from      |
-- |                                    the Inbound Reconciliation UI           |
-- |                                    when the user performs the revert       |
-- |                                    matching of a matched or                |
-- |                                    partially matched receipt.              |
-- |                                                                            |
-- | PARAMETERS: p_entity_in_rec                                                |
-- |            p_transaction_type      transaction type (ASN or RECEIPT)       |
-- |            x_return_status         return status of the API                |
--==============================================================================+

PROCEDURE SEND_LOCATIONS
            (
              p_entity_in_rec    IN WSH_OTM_ENTITY_REC_TYPE,
              x_loc_xmission_rec OUT NOCOPY XX_OM_WSH_OTM_LOC_XMN_REC_TYPE,
              x_transmission_id  OUT NOCOPY NUMBER,
              x_return_status    OUT NOCOPY VARCHAR2,
              x_msg_data        OUT NOCOPY VARCHAR2
            );
            
-- +================================================================================= +
-- |PROCEDURE : GET_STOP_LOCATION_XID This procedure extracts the stop location id    |
-- |                                                                                  |
-- | PARAMETERS: p_stop_id          Stop id                                           |
-- |   returns : Location id                                                          |
--====================================================================================+          
            
FUNCTION GET_STOP_LOCATION_XID
            (
              p_stop_id          IN  NUMBER
            ) RETURN VARCHAR2;
            
-- +================================================================================= +
-- |PROCEDURE : VALIDATE_TKT   This procedure validates the tickets                   |
-- |                                                                                  |
-- | PARAMETERS: p_operation   :     Operation                                        |
-- |             p_argument          Argument                                         |
-- |             p_ticket            Ticket                                           |
-- |             x_tkt_valid         validity ofticket                                |
-- |             x_return_status     return status                                    |
-- |             x_msg_data          message data                                     |
--====================================================================================+

PROCEDURE VALIDATE_TKT
            (
              p_operation          IN  VARCHAR2,
              p_argument           IN  VARCHAR2,
              p_ticket             IN  VARCHAR2,
              x_tkt_valid          OUT NOCOPY VARCHAR2,
              x_return_status      OUT NOCOPY VARCHAR2,
              x_msg_data           OUT NOCOPY VARCHAR2
            );
            
-- +================================================================================= +
-- |PROCEDURE : GET_INT_LOCATION_XID   This procedure extract the internal location id|
-- |                                                                                  |
-- | PARAMETERS: p_location_id   :   Location id                                      |
-- |             x_location_xid  :   interanl location ID                             |
-- |             x_return_status     return status                                    |
--====================================================================================+            

PROCEDURE GET_INT_LOCATION_XID
            (
              p_location_id          IN  NUMBER,
              x_location_xid         OUT NOCOPY VARCHAR2,
              x_return_status        OUT NOCOPY VARCHAR2
            );

END XX_OM_WSH_OTM_REF_DATA_GEN_PKG;

/
SHOW ERRORS;
EXIT;