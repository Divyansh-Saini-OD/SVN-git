CREATE OR REPLACE
PACKAGE "XX_QP_PRICE_REQUEST_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_QP_PRICE_REQUEST_PKG                                  |
-- | Description: Interface created to interact with  Oracle Advance   |
-- | Pricing (QP) for all Order entry applications in OD.              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 24-APR-2007  B.Penski         Package Spec. for attribute |
-- +===================================================================+

G_DEBUG           CONSTANT BOOLEAN := TRUE;
--p_Pricing_Event
G_PRICING_ORDER   CONSTANT VARCHAR2(5):= 'ORDER';
G_PRICING_LINE    CONSTANT VARCHAR2(5):= 'LINE';

G_MISS_NUM    CONSTANT  NUMBER      := FND_API.G_MISS_NUM;
G_MISS_DATE   CONSTANT  DATE        := FND_API.G_MISS_DATE;
G_MISS_CHAR   CONSTANT  VARCHAR2(1) := FND_API.G_MISS_CHAR;

TYPE PRICING_HEADER_REC_TYPE IS RECORD
(
       ORG_ID                          NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       HEADER_ID                       NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, --NO
       ORDER_NUMBER                    NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, --NO
       ORDER_TYPE_ID                   NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
       ORDER_SOURCE_ID                 VARCHAR2(50) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       CUST_ACCOUNT_NUMBER             NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PARTY_ID                        NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, -- WEB USER ID
       CURRENCY_CODE                   VARCHAR2(15) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ORDERED_DATE                    DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       SHIP_TO_COUNTRY_CODE            VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_CITY_CODE               VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_STATE_CODE              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_ZIP_CODE                VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_METHOD_CODE                VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       STORE_ID                        NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SOLD_TO_ORG_ID                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CUST_PO_NUMBER                  VARCHAR2(50) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ORDER_CATEGORY_CODE             VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       INVOICE_TO_ORG_ID               NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_TO_ORG_ID                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_FROM_ORG_ID                NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PRICE_LIST_ID                   NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       Blanket_Number                  NUMBER
);
G_HEADER_REC	PRICING_HEADER_REC_TYPE;


TYPE PRICING_LINE_REC_TYPE IS RECORD
(
       ORDER_LINE_ID                  NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CREATED_DATE                   DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       CREATED_BY                     VARCHAR2(50) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ORG_ID                          NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       LINE_CATEGORY_CODE              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ITEM_TYPE_CODE                  VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       LINE_NUMBER                     NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       START_DATE_ACTIVE               DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       END_DATE_ACTIVE                 DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       ORDER_LINE_TYPE_ID              NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       INVOICE_TO_PARTY_SITE_ID        NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       INVOICE_TO_PARTY_ID             NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       ORGANIZATION_ID                 NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       INVENTORY_ITEM_ID               NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       QUANTITY                        NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       UOM_CODE                        VARCHAR2(3) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       MARKETING_SOURCE_CODE_ID        NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PRICE_LIST_ID                   NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PRICE_LIST_LINE_ID              NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PRICE_LIST_TYPE                 VARCHAR2(30):= XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR, -- CREATE A 
       CURRENCY_CODE                   VARCHAR2(15) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       LINE_LIST_PRICE_EACH                 NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       LINE_ADJ_AMOUNT_EACH            NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       LINE_ADJ_PERCENT                NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       TOTAL_LINE_PRICE_EACH           NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       RELATED_ITEM_ID                 NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       ITEM_RELATIONSHIP_TYPE          VARCHAR2(15) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ACCOUNTING_RULE_ID              NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       INVOICING_RULE_ID               NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       MODEL_ID			       NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SPLIT_SHIPMENT_FLAG             VARCHAR2(1) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       BACKORDER_FLAG                  VARCHAR2(1) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ATTRIBUTE_CATEGORY              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       CONFIG_HEADER_ID                NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CONFIG_REVISION_NUM             NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       COMPLETE_CONFIGURATION_FLAG     VARCHAR2(1) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       VALID_CONFIGURATION_FLAG        VARCHAR2(1) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       COMPONENT_CODE                  VARCHAR2(1000) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       CONFIG_ITEM_ID                  NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       PROMISE_DATE                    DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       REQUEST_DATE                    DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       SCHEDULE_SHIP_DATE              DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       SHIP_TO_PARTY_SITE_ID           NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_TO_PARTY_ID                NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_PARTIAL_FLAG               VARCHAR2(240) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_SET_ID                     NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_METHOD_CODE                VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       FREIGHT_TERMS_CODE              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       FREIGHT_CARRIER_CODE            VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       FOB_CODE                        VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIPPING_INSTRUCTIONS           VARCHAR2(2000) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       PACKING_INSTRUCTIONS            VARCHAR2(2000) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIPPING_QUANTITY               NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       RESERVED_QUANTITY               VARCHAR2(240) := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       RESERVATION_ID                  NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIPMENT_PRIORITY_CODE          VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_COUNTRY_CODE            VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_CITY_CODE               VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_STATE_CODE              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       SHIP_TO_ZIP_CODE                VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       STORE_ID                        NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SOLD_TO_ORG_ID                  NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CUST_PO_NUMBER                  VARCHAR2(50) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       INVOICE_TO_ORG_ID               NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_TO_ORG_ID                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       SHIP_FROM_ORG_ID                NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       Blanket_Number                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM , 
       Request_type                    VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       cart_id                         number       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM , 
       modifier_id                     number       
);

G_LINE_REC	PRICING_LINE_REC_TYPE;

END;
