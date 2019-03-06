-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_OM_WSH_OTM_OUTBOUND.typ                          |
-- | Rice ID      :E0271_EBSOTMDataMap                                 |
-- | Description  :OD EBS OTM Data Map type creation script for        |
-- |               Deliveries                                          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-jan-2007  Shashi Kumar     Initial draft version       |
-- |1.0      17-MAR-2007  Shashi Kumar     Baselined after testing     |
-- |                                                                   |
-- +===================================================================+

SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing types......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_DLV_TAB
PROMPT

DROP TYPE XX_OM_WSH_OTM_DLV_TAB;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_DLV_OBJ
PROMPT

DROP TYPE XX_OM_WSH_OTM_DLV_OBJ;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_DET_TAB
PROMPT

DROP TYPE XX_OM_WSH_OTM_DET_TAB;

PROMPT
PROMPT Dropping Type XX_OM_WSH_OTM_DET_OBJ
PROMPT

DROP TYPE XX_OM_WSH_OTM_DET_OBJ;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Types ......
PROMPT

CREATE OR REPLACE  TYPE XX_OM_WSH_OTM_DET_OBJ AS OBJECT(
DELIVERY_DETAIL_ID          NUMBER,
LOT_NUMBER                  VARCHAR2(32),
SERIAL_NUMBER               VARCHAR2(30),
TO_SERIAL_NUMBER            VARCHAR2(30),
GROSS_WEIGHT                NUMBER,
WEIGHT_UOM_CODE             VARCHAR2(150),
VOLUME                      NUMBER,
VOLUME_UOM_CODE             VARCHAR2(150),
REQUESTED_QUANTITY          NUMBER,
SHIPPED_QUANTITY            NUMBER,
INVENTORY_ITEM_ID           VARCHAR2(30),
CONTAINER_FLAG              VARCHAR2(1),
PARENT_DELIVERY_DETAIL_ID   NUMBER,
CUST_PO_NUMBER              VARCHAR2(50),
SOURCE_HEADER_NUMBER        VARCHAR2(150),
CUST_PO_NUMBER_QLFR         VARCHAR2(20),
SOURCE_HEADER_NUMBER_QLFR   VARCHAR2(20),
DELIVERY_ID                 NUMBER,
NET_WEIGHT                  NUMBER,
ATTRIBUTE1                  VARCHAR2(250),
ATTRIBUTE2                  VARCHAR2(250),
ATTRIBUTE3                  VARCHAR2(250),
ATTRIBUTE4                  VARCHAR2(250),
ATTRIBUTE5                  VARCHAR2(250),
ATTRIBUTE6                  VARCHAR2(250)
);
/

CREATE TYPE XX_OM_WSH_OTM_DET_TAB AS TABLE OF XX_OM_WSH_OTM_DET_OBJ;
/

CREATE TYPE XX_OM_WSH_OTM_DLV_OBJ AS OBJECT(
transaction_code              VARCHAR2(3),
delivery_id                   NUMBER,
name                          VARCHAR2(30) ,
freight_terms                 VARCHAR2(30),
fob_code                      VARCHAR2(30),
carrier_id                    VARCHAR2(30),
service_level                 VARCHAR2(30),
mode_of_transport             VARCHAR2(30),
INITIAL_PICKUP_LOCATION_ID    VARCHAR2(30),
ULTIMATE_DROPOFF_LOCATION_ID  VARCHAR2(30),
EARLIEST_PICKUP_DATE          DATE,
LATEST_PICKUP_DATE            DATE,
EARLIEST_DROPOFF_DATE         DATE,
LATEST_DROPOFF_DATE           DATE,
GROSS_WEIGHT                  NUMBER,
WEIGHT_UOM_CODE               VARCHAR2(150) ,
VOLUME                        NUMBER,
VOLUME_UOM_CODE               VARCHAR2(150),
NET_WEIGHT                    NUMBER,
REVISION                      NUMBER,
REASON_OF_TRANSPORT           VARCHAR2(30),
DESCRIPTION                   VARCHAR2(30),
ADDITIONAL_SHIPMENT_INFO      VARCHAR2(500),
ROUTING_INSTRUCTIONS          VARCHAR2(120),
TOTAL_ITEM_COUNT              NUMBER,
REVISION_QLFR                 VARCHAR2(20),
REASON_OF_TRANSPORT_QLFR      VARCHAR2(20),
DESCRIPTION_QLFR              VARCHAR2(20),
ADDITIONAL_SHIPMENT_INFO_QLFR VARCHAR2(20),
ROUTING_INSTRUCTIONS_QLFR     VARCHAR2(20),
HPATTRIBUTE1                  VARCHAR2(240),
HCATTRIBUTE1                  VARCHAR2(240),
ATTRIBUTE1                    VARCHAR2(240),
ATTRIBUTE2                    VARCHAR2(240),
rl_details                    XX_OM_WSH_OTM_DET_TAB,
lpn                           WSH_OTM_LPN_TAB
);
/

CREATE TYPE XX_OM_WSH_OTM_DLV_TAB AS TABLE OF XX_OM_WSH_OTM_DLV_OBJ;
/

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;