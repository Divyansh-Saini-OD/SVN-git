SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Oracle GSD   - Hyderabad, India                  |
-- +===================================================================+
-- | Name  :    XX_CS_TDS_AP_INV_REC                                   |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |1.0      02-AUG-11  Sreenivasa Tirumala     Initial draft version  |
-- |                                                                   |
-- +===================================================================+


SET TERM ON
PROMPT Creating Record type XX_CS_TDS_AP_INV_REC
SET TERM OFF

CREATE OR REPLACE TYPE XX_CS_TDS_AP_INV_REC IS OBJECT (
        "INVOICE_ID" NUMBER(15,0), 
            "INVOICE_NUM" VARCHAR2(50 BYTE), 
            "INVOICE_TYPE_LOOKUP_CODE" VARCHAR2(25 BYTE), 
            "INVOICE_DATE" DATE, 
            "PO_NUMBER" VARCHAR2(20 BYTE), 
            "VENDOR_ID" NUMBER(15,0), 
            "VENDOR_NUM" VARCHAR2(30 BYTE), 
            "VENDOR_NAME" VARCHAR2(240 BYTE), 
            "VENDOR_SITE_ID" NUMBER(15,0), 
            "VENDOR_SITE_CODE" VARCHAR2(15 BYTE), 
            "INVOICE_AMOUNT" NUMBER, 
            "INVOICE_CURRENCY_CODE" VARCHAR2(15 BYTE), 
            "EXCHANGE_RATE" NUMBER, 
            "EXCHANGE_RATE_TYPE" VARCHAR2(30 BYTE), 
            "EXCHANGE_DATE" DATE, 
            "TERMS_ID" NUMBER(15,0), 
            "TERMS_NAME" VARCHAR2(50 BYTE), 
            "DESCRIPTION" VARCHAR2(240 BYTE), 
            "AWT_GROUP_ID" NUMBER(15,0), 
            "AWT_GROUP_NAME" VARCHAR2(25 BYTE), 
            "LAST_UPDATE_DATE" DATE, 
            "LAST_UPDATED_BY" NUMBER(15,0), 
            "LAST_UPDATE_LOGIN" NUMBER(15,0), 
            "CREATION_DATE" DATE, 
            "CREATED_BY" NUMBER(15,0), 
            "ATTRIBUTE_CATEGORY" VARCHAR2(150 BYTE), 
            "ATTRIBUTE1" VARCHAR2(150 BYTE), 
            "ATTRIBUTE2" VARCHAR2(150 BYTE), 
            "ATTRIBUTE3" VARCHAR2(150 BYTE), 
            "ATTRIBUTE4" VARCHAR2(150 BYTE), 
            "ATTRIBUTE5" VARCHAR2(150 BYTE), 
            "ATTRIBUTE6" VARCHAR2(150 BYTE), 
            "ATTRIBUTE7" VARCHAR2(150 BYTE), 
            "ATTRIBUTE8" VARCHAR2(150 BYTE), 
            "ATTRIBUTE9" VARCHAR2(150 BYTE), 
            "ATTRIBUTE10" VARCHAR2(150 BYTE), 
            "ATTRIBUTE11" VARCHAR2(150 BYTE), 
            "ATTRIBUTE12" VARCHAR2(150 BYTE), 
            "ATTRIBUTE13" VARCHAR2(150 BYTE), 
            "ATTRIBUTE14" VARCHAR2(150 BYTE), 
            "ATTRIBUTE15" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE_CATEGORY" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE1" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE2" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE3" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE4" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE5" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE6" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE7" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE8" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE9" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE10" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE11" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE12" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE13" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE14" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE15" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE16" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE17" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE18" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE19" VARCHAR2(150 BYTE), 
            "GLOBAL_ATTRIBUTE20" VARCHAR2(150 BYTE), 
            "STATUS" VARCHAR2(25 BYTE), 
            "SOURCE" VARCHAR2(80 BYTE), 
            "GROUP_ID" VARCHAR2(80 BYTE), 
            "REQUEST_ID" NUMBER, 
            "PAYMENT_CROSS_RATE_TYPE" VARCHAR2(30 BYTE), 
            "PAYMENT_CROSS_RATE_DATE" DATE, 
            "PAYMENT_CROSS_RATE" NUMBER, 
            "PAYMENT_CURRENCY_CODE" VARCHAR2(15 BYTE), 
            "WORKFLOW_FLAG" VARCHAR2(1 BYTE), 
            "DOC_CATEGORY_CODE" VARCHAR2(30 BYTE), 
            "VOUCHER_NUM" VARCHAR2(50 BYTE), 
            "PAYMENT_METHOD_LOOKUP_CODE" VARCHAR2(25 BYTE), 
            "PAY_GROUP_LOOKUP_CODE" VARCHAR2(25 BYTE), 
            "GOODS_RECEIVED_DATE" DATE, 
            "INVOICE_RECEIVED_DATE" DATE, 
            "GL_DATE" DATE, 
            "ACCTS_PAY_CODE_COMBINATION_ID" NUMBER(15,0), 
            "USSGL_TRANSACTION_CODE" VARCHAR2(30 BYTE), 
            "EXCLUSIVE_PAYMENT_FLAG" VARCHAR2(1 BYTE), 
            "ORG_ID" NUMBER(15,0), 
            "AMOUNT_APPLICABLE_TO_DISCOUNT" NUMBER, 
            "PREPAY_NUM" VARCHAR2(50 BYTE), 
            "PREPAY_DIST_NUM" NUMBER(15,0), 
            "PREPAY_APPLY_AMOUNT" NUMBER, 
            "PREPAY_GL_DATE" DATE, 
            "INVOICE_INCLUDES_PREPAY_FLAG" VARCHAR2(1 BYTE), 
            "NO_XRATE_BASE_AMOUNT" NUMBER, 
            "VENDOR_EMAIL_ADDRESS" VARCHAR2(2000 BYTE), 
            "TERMS_DATE" DATE, 
            "REQUESTER_ID" NUMBER(10,0), 
            "SHIP_TO_LOCATION" VARCHAR2(40 BYTE), 
            "EXTERNAL_DOC_REF" VARCHAR2(240 BYTE), 
            "ACCTS_PAY_CODE_CONCATENATED" VARCHAR2(250 BYTE)
   );
/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SHOW ERROR


