-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | NAME        : XX_AR_ORDER_RECEIPT_DTL.vw                                 |
-- | RICE#       :                                                            |                                          
-- | DESCRIPTION : Defect 38344 . Added wallet_type and wallet_id.            |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ===========  =============        ==============================|
-- | V1.0     05-JUL-2016  Suresh Ponnambalam   Initial version               |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

CREATE OR REPLACE FORCE VIEW "XXAPPS_HISTORY_QUERY"."XX_AR_ORDER_RECEIPT_DTL" ("ORDER_PAYMENT_ID", "ORDER_NUMBER", "ORIG_SYS_DOCUMENT_REF", "ORIG_SYS_PAYMENT_REF", "PAYMENT_NUMBER", "HEADER_ID", "ORDER_SOURCE", "ORDER_TYPE", "CASH_RECEIPT_ID", "RECEIPT_NUMBER", "CUSTOMER_ID", "STORE_NUMBER", "PAYMENT_TYPE_CODE", "CREDIT_CARD_CODE", "CREDIT_CARD_NUMBER", "CREDIT_CARD_HOLDER_NAME", "CREDIT_CARD_EXPIRATION_DATE", "PAYMENT_AMOUNT", "RECEIPT_METHOD_ID", "CC_AUTH_MANUAL", "MERCHANT_NUMBER", "CC_AUTH_PS2000", "ALLIED_IND", "PAYMENT_SET_ID", "PROCESS_CODE", "CC_MASK_NUMBER", "OD_PAYMENT_TYPE", "CHECK_NUMBER", "ORG_ID", "REQUEST_ID", "IMP_FILE_NAME", "CREATION_DATE", "CREATED_BY", "LAST_UPDATE_DATE", "LAST_UPDATED_BY", "REMITTED", "MATCHED", "SHIP_FROM", "RECEIPT_STATUS", "CUSTOMER_RECEIPT_REFERENCE", "CREDIT_CARD_APPROVAL_CODE", "CREDIT_CARD_APPROVAL_DATE", "CUSTOMER_SITE_BILLTO_ID", "RECEIPT_DATE", "SALE_TYPE", "ADDITIONAL_AUTH_CODES", "PROCESS_DATE", "SINGLE_PAY_IND",
  "CURRENCY_CODE", "LAST_UPDATE_LOGIN", "CLEARED_DATE", "IDENTIFIER", "SETTLEMENT_ERROR_MESSAGE", "ORIGINAL_CASH_RECEIPT_ID", "MPL_ORDER_ID", "TOKEN_FLAG", "EMV_CARD", "EMV_TERMINAL", "EMV_TRANSACTION", "EMV_OFFLINE", "EMV_FALLBACK", "EMV_TVR","WALLET_TYPE","WALLET_ID")
AS
  SELECT "ORDER_PAYMENT_ID",
    "ORDER_NUMBER",
    "ORIG_SYS_DOCUMENT_REF",
    "ORIG_SYS_PAYMENT_REF",
    "PAYMENT_NUMBER",
    "HEADER_ID",
    "ORDER_SOURCE",
    "ORDER_TYPE",
    "CASH_RECEIPT_ID",
    "RECEIPT_NUMBER",
    "CUSTOMER_ID",
    "STORE_NUMBER",
    "PAYMENT_TYPE_CODE",
    "CREDIT_CARD_CODE",
    "CREDIT_CARD_NUMBER",
    "CREDIT_CARD_HOLDER_NAME",
    "CREDIT_CARD_EXPIRATION_DATE",
    "PAYMENT_AMOUNT",
    "RECEIPT_METHOD_ID",
    "CC_AUTH_MANUAL",
    "MERCHANT_NUMBER",
    "CC_AUTH_PS2000",
    "ALLIED_IND",
    "PAYMENT_SET_ID",
    "PROCESS_CODE",
    "CC_MASK_NUMBER",
    "OD_PAYMENT_TYPE",
    "CHECK_NUMBER",
    "ORG_ID",
    "REQUEST_ID",
    "IMP_FILE_NAME",
    "CREATION_DATE",
    "CREATED_BY",
    "LAST_UPDATE_DATE",
    "LAST_UPDATED_BY",
    "REMITTED",
    "MATCHED",
    "SHIP_FROM",
    "RECEIPT_STATUS",
    "CUSTOMER_RECEIPT_REFERENCE",
    "CREDIT_CARD_APPROVAL_CODE",
    "CREDIT_CARD_APPROVAL_DATE",
    "CUSTOMER_SITE_BILLTO_ID",
    "RECEIPT_DATE",
    "SALE_TYPE",
    "ADDITIONAL_AUTH_CODES",
    "PROCESS_DATE",
    "SINGLE_PAY_IND",
    "CURRENCY_CODE",
    "LAST_UPDATE_LOGIN",
    "CLEARED_DATE",
    "IDENTIFIER",
    "SETTLEMENT_ERROR_MESSAGE",
    "ORIGINAL_CASH_RECEIPT_ID",
    "MPL_ORDER_ID",
    "TOKEN_FLAG",
    "EMV_CARD",
    "EMV_TERMINAL",
    "EMV_TRANSACTION",
    "EMV_OFFLINE",
    "EMV_FALLBACK",
    "EMV_TVR",
	"WALLET_TYPE",
	"WALLET_ID"
  FROM GSI_HISTORY."XX_AR_ORDER_RECEIPT_DTL"@history_public;
  
SHOW ERRORS;
EXIT;