SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE        "XX_QP_PRICE_REQUEST_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
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
-- |DRAFT 1A 24-APR-2007  B.Penski         Initial draft version       |
-- +===================================================================+


G_DEBUG           CONSTANT BOOLEAN := TRUE;
--p_Pricing_Events
G_PRICING_ORDER   CONSTANT VARCHAR2(5):= 'ORDER';
G_PRICING_LINE    CONSTANT VARCHAR2(5):= 'LINE';

G_MISS_NUM        CONSTANT  NUMBER      := FND_API.G_MISS_NUM;
G_MISS_DATE       CONSTANT  DATE        := FND_API.G_MISS_DATE;
G_MISS_CHAR       CONSTANT  VARCHAR2(1) := FND_API.G_MISS_CHAR;

TYPE PRICING_HEADER_REC_TYPE IS RECORD
(
       ORG_ID                          NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       HEADER_ID                       NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
       ORDER_NUMBER                    NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
       ORDER_TYPE_ID                   NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
       ORDER_SOURCE_ID                 NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
       SOLD_TO_ORG_CONTACT_ID          NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM, 
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
       BLANKET_NUMBER                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM
);
G_HEADER_REC	PRICING_HEADER_REC_TYPE;


TYPE PRICING_LINE_REC_TYPE IS RECORD
(
       ORDER_LINE_ID                   NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CREATED_DATE                    DATE   := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       CREATED_BY                      NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
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
       PRICE_LIST_TYPE                 VARCHAR2(30):= XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR, 
       CURRENCY_CODE                   VARCHAR2(15) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       ITEM_RELATIONSHIP_TYPE          NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       ACCOUNTING_RULE_ID              NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       INVOICING_RULE_ID               NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       MODEL_ID			       NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       ATTRIBUTE_CATEGORY              VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       CONFIG_HEADER_ID                NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       CONFIG_REVISION_NUM             NUMBER := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM,
       COMPONENT_CODE                  VARCHAR2(1000) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       REQUEST_DATE                    DATE := XX_QP_PRICE_REQUEST_PKG.G_MISS_DATE,
       SHIP_METHOD_CODE                VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
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
       BLANKET_NUMBER                  NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM , 
       REQUEST_TYPE                    VARCHAR2(30) := XX_QP_PRICE_REQUEST_PKG.G_MISS_CHAR,
       CART_ID                         NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM , 
       MODIFIER_ID                     NUMBER       := XX_QP_PRICE_REQUEST_PKG.G_MISS_NUM
);

G_LINE_REC	PRICING_LINE_REC_TYPE;

                       
END XX_QP_PRICE_REQUEST_PKG;
/
SHOW ERRORS;
--EXIT;