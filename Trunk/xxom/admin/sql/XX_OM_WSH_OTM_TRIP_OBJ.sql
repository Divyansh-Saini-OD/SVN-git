-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_WSH_OTM_TRIP_OBJ                                      |
-- | Rice ID     : E0280_CarrierSelection                                      |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 13-Apr-2007  Faiz                   Initial draft version         |
-- |1.0      20-Jun-2007  Pankaj Kapse           Made changes as per new       |
-- |                                             standard                      |
-- |                                                                           |
-- +===========================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Object Type......
PROMPT

WHENEVER SQLERROR CONTINUE;

PPROMPT
PROMPT Dropping object type XX_OM_WSH_OTM_TRIP_OBJ
PROMPT

DROP TYPE XX_OM_WSH_OTM_TRIP_OBJ ;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Object Type ......
PROMPT

PROMPT
PROMPT Creating the Object Types .....
PROMPT

CREATE OR REPLACE TYPE XX_OM_WSH_OTM_TRIP_OBJ AS OBJECT( 
                                                        SHIPMENT_XID                VARCHAR2(200) 
                                                       ,SHIPMENT_NAME               VARCHAR2(2000) 
                                                       ,SHIPMENT_REFNUM             VARCHAR2(200) 
                                                       ,TRANSACTION_CODE            VARCHAR2(10) 
                                                       ,SERVICE_PROVIDER_XID        VARCHAR2(200) 
                                                       ,CONTACT_XID                 VARCHAR2(200) 
                                                       ,TRANSPORT_MODE_XID          VARCHAR2(200) 
                                                       ,RATE_SERVICE_XID            VARCHAR2(200) 
                                                       ,WEIGHT_UOM_XID              VARCHAR2(200) 
                                                       ,VOLUME                      NUMBER 
                                                       ,VOLUME_UOM_XID              VARCHAR2(200) 
                                                       ,SHIPUNIT_COUNT              NUMBER 
                                                       ,PAYMENT_CODE_XID            VARCHAR2(200) 
                                                       ,STOP_COUNT                  NUMBER 
                                                       ,RELEASE_COUNT               NUMBER 
                                                       ,VOYAGE_XID                  VARCHAR2(200) 
                                                       ,VESSEL_XID                  VARCHAR2(200) 
                                                       ,EQUIPMENT_XID               VARCHAR2(200) 
                                                       ,EQUIPMENT_INITIAL           VARCHAR2(200) 
                                                       ,EQUIPMENT_NUMBER            VARCHAR2(200) 
                                                       ,EQUIPMENT_TYPE_XID          VARCHAR2(200) 
                                                       ,EQUIPMENT_GROUP_XID         VARCHAR2(200) 
                                                       ,TP_PLAN_NAME                VARCHAR2(200) 
                                                       ,EQUIPMENT_SEAL              VARCHAR2(30) 
                                                       ,MASTER_BOL_NUMBER           VARCHAR2(50) 
                                                       ,PLANNED_FLAG                VARCHAR2(1) 
                                                       ,ROUTING_INSTRUCTIONS        VARCHAR2(2000) 
                                                       ,GROSS_WEIGHT                NUMBER 
                                                       ,NET_WEIGHT                  NUMBER 
                                                       ,BOOKING_NUMBER              VARCHAR2(30) 
                                                       ,ESTIMATED_COST              VARCHAR2(200) 
                                                       ,TRIP_ID                     NUMBER 
                                                       ,IGNORE_FOR_PLANNING         VARCHAR2(1) 
                                                       ,OPERATOR                    VARCHAR2(150) 
                                                       ,MANUAL_FREIGHT_COSTS        NUMBER 
                                                       ,CURRENCY_CODE               VARCHAR2(15) 
                                                       ,PACKED_ITEM_COUNT           NUMBER 
                                                       ,TRIP_ID_QLFR                VARCHAR2(20) 
                                                       ,MBOL_NUMBER_QLFR            VARCHAR2(30) 
                                                       ,PLANNED_TRIP_QLFR           VARCHAR2(30) 
                                                       ,MANUAL_FREIGHT_COSTS_QLFR   VARCHAR2(30) 
                                                       ,MAN_FREIGHT_COST_CUR_QLFR   VARCHAR2(30) 
                                                       ,OPERATOR_QLFR               VARCHAR2(30) 
                                                       ,ROUTING_INSTR_QLFR          VARCHAR2(30) 
                                                       ,SHIPMENT_STOPS              WSH_OTM_STOP_TAB 
                                                       ,SHIPMENT_SHIP_UNITS         WSH_OTM_SHIP_UNIT_TAB 
                                                       ,SHIPMENT_DELIVERIES         WSH_OTM_DLV_TAB 
                                                       ,SHIPMENT_RELEASES           WSH_OTM_RELEASE_TAB 
                                                       ,LPNS                        WSH_OTM_LPN_TAB 
                                                       ,STOP_LOCATIONS              WSH_OTM_STOPLOCTZ_TAB 
                                                       ,ITINERARY_ID                VARCHAR2(30) 
                                                       ,MOBILECAST_FLAG             VARCHAR2(1) 
                                                       ,ROADNET_FLAG                VARCHAR2(1) 
                                                      );
/                                                      
WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;