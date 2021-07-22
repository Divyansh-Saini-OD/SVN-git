  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XX_OE_HEADER_ATTRIBUTES_ALL_V                                               |
  -- |  Description   : OE Header Attribute view based on union of EBS custom and seeded tables     |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         14-Jul-2021  Ankit Jaiswal   Initial version                                  |
  -- +============================================================================================+
CREATE OR REPLACE VIEW XX_OE_HEADER_ATTRIBUTES_ALL_V
AS
SELECT
    HEADER_ID
    ,COMMENTS
    ,RELEASE_NUMBER
    ,COST_CENTER_DEPT
    ,DESK_DEL_ADDR
    ,CUST_CARR_ACCT_NO
    ,CATALOG_SRC_CD
    ,BRAND
    ,BMODE
    ,LOCALE
    ,ADVANTAGE_CARD_NUMBER
    ,GIFT_FLAG
    ,FAX_COMMENTS
    ,TRACK_NUM
    ,SHIP_TO_FLG
    ,ALT_DELV_ADDRESS
    ,FURTHER_ORD_INFO
    ,ORIG_CUST_NAME
    ,CREATED_BY_STORE_ID
    ,PAID_AT_STORE_ID
    ,SPC_CARD_NUMBER
    ,SALESREP_ID
    ,DELIVERY_CODE
    ,CREATED_BY_ID
    ,DELIVERY_METHOD
    ,PLACEMENT_METHOD_CODE
    ,NUM_CARTONS
    ,CUST_COMM_PREF
    ,CUST_PREF_EMAIL
    ,CUST_PREF_FAX
    ,CUST_PREF_PHONE
    ,CUST_PREF_PHEXTN
    ,CUST_CONTACT_NAME
    ,WEB_USER_ID
    ,CREATION_DATE
    ,CREATED_BY
    ,LAST_UPDATE_DATE
    ,LAST_UPDATED_BY
    ,LAST_UPDATE_LOGIN
    ,OD_ORDER_TYPE
    ,SHIP_TO_NAME
    ,BILL_TO_NAME
    ,SHIP_TO_SEQUENCE
    ,SHIP_TO_ADDRESS1
    ,SHIP_TO_ADDRESS2
    ,SHIP_TO_CITY
    ,SHIP_TO_STATE
    ,SHIP_TO_COUNTRY
    ,SHIP_TO_ZIP
    ,IMP_FILE_NAME
    ,TAX_RATE
    ,TRANS_HEADER_STATUS
    ,COMMISIONABLE_IND
    ,ORDER_ACTION_CODE
    ,ORDER_START_TIME
    ,ORDER_END_TIME
    ,ORDER_TAXABLE_CD
    ,OVERRIDE_DELIVERY_CHG_CD
    ,ORDER_TOTAL
    ,SHIP_TO_GEOCODE
    ,CUST_DEPT_DESCRIPTION
    ,SHIP_TO_COUNTY
    ,TRAN_NUMBER
    ,AOPS_GEO_CODE
    ,TAX_EXEMPT_AMOUNT
    ,SR_NUMBER
    ,ATR_ORDER_FLAG
    ,MPS_EXT_FLAG
    ,MPS_EXT_DATE
    ,DEVICE_SERIAL_NUM
    ,APP_ID
    ,EXTERNAL_TRANSACTION_NUMBER
    ,FREIGHT_TAX_RATE
    ,FREIGHT_TAX_AMOUNT
    ,BILL_LEVEL
    ,BILL_OVERRIDE_FLAG
    ,BILL_COMP_FLAG
    ,PARENT_ORDER_NUM
    ,COST_CENTER_SPLIT
    ,CANADA_PST_TAX
    ,CUST_DEPT_NO
    ,DESKTOP_LOC_ADDR
    ,LOYALTY_ID
    ,ACTION_CODE
FROM
    XX_OE_HEADER_ATTRIBUTES_ALL
UNION
SELECT
    HEADER_ID
    ,COMMENTS
    ,RELEASE_NUMBER
    ,COST_CENTER_DEPT
    ,DESK_DEL_ADDR
    ,CUST_CARR_ACCT_NO
    ,CATALOG_SRC_CD
    ,BRAND
    ,BMODE
    ,LOCALE
    ,ADVANTAGE_CARD_NUMBER
    ,GIFT_FLAG
    ,FAX_COMMENTS
    ,TRACK_NUM
    ,SHIP_TO_FLG
    ,ALT_DELV_ADDRESS
    ,FURTHER_ORD_INFO
    ,ORIG_CUST_NAME
    ,CREATED_BY_STORE_ID
    ,PAID_AT_STORE_ID
    ,SPC_CARD_NUMBER
    ,SALESREP_ID
    ,DELIVERY_CODE
    ,CREATED_BY_ID
    ,DELIVERY_METHOD
    ,PLACEMENT_METHOD_CODE
    ,NUM_CARTONS
    ,CUST_COMM_PREF
    ,CUST_PREF_EMAIL
    ,CUST_PREF_FAX
    ,CUST_PREF_PHONE
    ,CUST_PREF_PHEXTN
    ,CUST_CONTACT_NAME
    ,WEB_USER_ID
    ,CREATION_DATE
    ,CREATED_BY
    ,LAST_UPDATE_DATE
    ,LAST_UPDATED_BY
    ,LAST_UPDATE_LOGIN
    ,OD_ORDER_TYPE
    ,SHIP_TO_NAME
    ,BILL_TO_NAME
    ,SHIP_TO_SEQUENCE
    ,SHIP_TO_ADDRESS1
    ,SHIP_TO_ADDRESS2
    ,SHIP_TO_CITY
    ,SHIP_TO_STATE
    ,SHIP_TO_COUNTRY
    ,SHIP_TO_ZIP
    ,IMP_FILE_NAME
    ,TAX_RATE
    ,TRANS_HEADER_STATUS
    ,COMMISIONABLE_IND
    ,ORDER_ACTION_CODE
    ,ORDER_START_TIME
    ,ORDER_END_TIME
    ,ORDER_TAXABLE_CD
    ,OVERRIDE_DELIVERY_CHG_CD
    ,ORDER_TOTAL
    ,SHIP_TO_GEOCODE
    ,CUST_DEPT_DESCRIPTION
    ,SHIP_TO_COUNTY
    ,TRAN_NUMBER
    ,AOPS_GEO_CODE
    ,TAX_EXEMPT_AMOUNT
    ,SR_NUMBER
    ,ATR_ORDER_FLAG
    ,MPS_EXT_FLAG
    ,MPS_EXT_DATE
    ,DEVICE_SERIAL_NUM
    ,APP_ID
    ,EXTERNAL_TRANSACTION_NUMBER
    ,FREIGHT_TAX_RATE
    ,FREIGHT_TAX_AMOUNT
    ,BILL_LEVEL
    ,BILL_OVERRIDE_FLAG
    ,BILL_COMP_FLAG
    ,PARENT_ORDER_NUM
    ,COST_CENTER_SPLIT
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
FROM
    XX_OM_HEADER_ATTRIBUTES_ALL;