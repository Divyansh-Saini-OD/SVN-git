-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +================================================================================+
-- | NAME        : XX_OM_HEADER_ATTRIBUTES_V.vw                                     |
-- | DESCRIPTION : Create the  view XX_OM_HEADER_ATTRIBUTES_V                       |
-- |                                                                                |
-- |                            .                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ===========  =============        ====================================|
-- | 1.0      22-MAR-2018  Punit Gupta          Defect# NAIT-31437                  |
-- +================================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE FORCE EDITIONABLE VIEW XX_OM_HEADER_ATTRIBUTES_V
AS
(
SELECT 
ADVANTAGE_CARD_NUMBER,
ALT_DELV_ADDRESS,
AOPS_GEO_CODE,
APP_ID,
ATR_ORDER_FLAG,
BILL_LEVEL,
BILL_OVERRIDE_FLAG,
BILL_TO_NAME,
BMODE,
BRAND,
CATALOG_SRC_CD,
COMMENTS,
COMMISIONABLE_IND,
COST_CENTER_DEPT,
CREATED_BY,
CREATED_BY_ID,
CREATED_BY_STORE_ID,
CREATION_DATE,
CUST_CARR_ACCT_NO,
CUST_COMM_PREF,
CUST_CONTACT_NAME,
CUST_DEPT_DESCRIPTION,
CUST_PREF_EMAIL,
CUST_PREF_FAX,
CUST_PREF_PHEXTN,
CUST_PREF_PHONE,
DELIVERY_CODE,
DELIVERY_METHOD,
DESK_DEL_ADDR,
DEVICE_SERIAL_NUM,
EXTERNAL_TRANSACTION_NUMBER,
FAX_COMMENTS,
FREIGHT_TAX_AMOUNT,
FREIGHT_TAX_RATE,
FURTHER_ORD_INFO,
GIFT_FLAG,
HEADER_ID,
IMP_FILE_NAME,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATE_LOGIN,
LOCALE,
MPS_EXT_DATE,
MPS_EXT_FLAG,
NUM_CARTONS,
OD_ORDER_TYPE,
ORDER_ACTION_CODE,
ORDER_END_TIME,
ORDER_START_TIME,
ORDER_TAXABLE_CD,
ORDER_TOTAL,
ORIG_CUST_NAME,
OVERRIDE_DELIVERY_CHG_CD,
PAID_AT_STORE_ID,
PLACEMENT_METHOD_CODE,
RELEASE_NUMBER,
SALESREP_ID,
SHIP_TO_ADDRESS1,
SHIP_TO_ADDRESS2,
SHIP_TO_CITY,
SHIP_TO_COUNTRY,
SHIP_TO_COUNTY,
SHIP_TO_FLG,
SHIP_TO_GEOCODE,
SHIP_TO_NAME,
SHIP_TO_SEQUENCE,
SHIP_TO_STATE,
SHIP_TO_ZIP,
SPC_CARD_NUMBER,
SR_NUMBER,
TAX_EXEMPT_AMOUNT,
TAX_RATE,
TRACK_NUM,
TRANS_HEADER_STATUS,
TRAN_NUMBER,
WEB_USER_ID
FROM XX_OM_HEADER_ATTRIBUTES_ALL
)
UNION ALL
(
SELECT 
ADVANTAGE_CARD_NUMBER,
ALT_DELV_ADDRESS,
AOPS_GEO_CODE,
APP_ID,
ATR_ORDER_FLAG,
BILL_LEVEL,
BILL_OVERRIDE_FLAG,
BILL_TO_NAME,
BMODE,
BRAND,
CATALOG_SRC_CD,
COMMENTS,
COMMISIONABLE_IND,
COST_CENTER_DEPT,
CREATED_BY,
CREATED_BY_ID,
CREATED_BY_STORE_ID,
CREATION_DATE,
CUST_CARR_ACCT_NO,
CUST_COMM_PREF,
CUST_CONTACT_NAME,
CUST_DEPT_DESCRIPTION,
CUST_PREF_EMAIL,
CUST_PREF_FAX,
CUST_PREF_PHEXTN,
CUST_PREF_PHONE,
DELIVERY_CODE,
DELIVERY_METHOD,
DESK_DEL_ADDR,
DEVICE_SERIAL_NUM,
EXTERNAL_TRANSACTION_NUMBER,
FAX_COMMENTS,
FREIGHT_TAX_AMOUNT,
FREIGHT_TAX_RATE,
FURTHER_ORD_INFO,
GIFT_FLAG,
HEADER_ID,
IMP_FILE_NAME,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATE_LOGIN,
LOCALE,
MPS_EXT_DATE,
MPS_EXT_FLAG,
NUM_CARTONS,
OD_ORDER_TYPE,
ORDER_ACTION_CODE,
ORDER_END_TIME,
ORDER_START_TIME,
ORDER_TAXABLE_CD,
ORDER_TOTAL,
ORIG_CUST_NAME,
OVERRIDE_DELIVERY_CHG_CD,
PAID_AT_STORE_ID,
PLACEMENT_METHOD_CODE,
RELEASE_NUMBER,
SALESREP_ID,
SHIP_TO_ADDRESS1,
SHIP_TO_ADDRESS2,
SHIP_TO_CITY,
SHIP_TO_COUNTRY,
SHIP_TO_COUNTY,
SHIP_TO_FLG,
SHIP_TO_GEOCODE,
SHIP_TO_NAME,
SHIP_TO_SEQUENCE,
SHIP_TO_STATE,
SHIP_TO_ZIP,
SPC_CARD_NUMBER,
SR_NUMBER,
TAX_EXEMPT_AMOUNT,
TAX_RATE,
TRACK_NUM,
TRANS_HEADER_STATUS,
TRAN_NUMBER,
WEB_USER_ID
FROM XX_OM_HEADER_ATTRIBUTES_SCM
);

SHOW ERRORS;
EXIT;