-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- +================================================================================+
-- | NAME        : XX_OE_PAYMENTS_V.vw                                              |
-- | DESCRIPTION : Create the  view XX_OE_PAYMENTS_V                                |
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

CREATE OR REPLACE FORCE EDITIONABLE VIEW XX_OE_PAYMENTS_V
AS
(
SELECT 
ATTRIBUTE1,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE13,
ATTRIBUTE14,
ATTRIBUTE15,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE7,
ATTRIBUTE8,
ATTRIBUTE9,
CHECK_NUMBER,
COMMITMENT_APPLIED_AMOUNT,
COMMITMENT_INTERFACED_AMOUNT,
CONTEXT,
CREATED_BY,
CREATION_DATE,
CREDIT_CARD_APPROVAL_CODE,
CREDIT_CARD_APPROVAL_DATE,
CREDIT_CARD_CODE,
CREDIT_CARD_EXPIRATION_DATE,
CREDIT_CARD_HOLDER_NAME,
CREDIT_CARD_NUMBER,
DEFER_PAYMENT_PROCESSING_FLAG,
HEADER_ID,
INST_ID,
INVOICED_FLAG,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATE_LOGIN,
LINE_ID,
LOCK_CONTROL,
ORIG_SYS_PAYMENT_REF,
PAYMENT_AMOUNT,
PAYMENT_COLLECTION_EVENT,
PAYMENT_LEVEL_CODE,
PAYMENT_NUMBER,
PAYMENT_PERCENTAGE,
PAYMENT_SET_ID,
PAYMENT_TRX_ID,
PAYMENT_TYPE_CODE,
PREPAID_AMOUNT,
PROGRAM_APPLICATION_ID,
PROGRAM_ID,
PROGRAM_UPDATE_DATE,
RECEIPT_METHOD_ID,
REQUEST_ID,
TANGIBLE_ID,
TRXN_EXTENSION_ID
FROM OE_PAYMENTS
)
UNION ALL
(
SELECT 
ATTRIBUTE1,
ATTRIBUTE10,
ATTRIBUTE11,
ATTRIBUTE12,
ATTRIBUTE13,
ATTRIBUTE14,
ATTRIBUTE15,
ATTRIBUTE2,
ATTRIBUTE3,
ATTRIBUTE4,
ATTRIBUTE5,
ATTRIBUTE6,
ATTRIBUTE7,
ATTRIBUTE8,
ATTRIBUTE9,
CHECK_NUMBER,
COMMITMENT_APPLIED_AMOUNT,
COMMITMENT_INTERFACED_AMOUNT,
CONTEXT,
CREATED_BY,
CREATION_DATE,
CREDIT_CARD_APPROVAL_CODE,
CREDIT_CARD_APPROVAL_DATE,
CREDIT_CARD_CODE,
CREDIT_CARD_EXPIRATION_DATE,
CREDIT_CARD_HOLDER_NAME,
CREDIT_CARD_NUMBER,
DEFER_PAYMENT_PROCESSING_FLAG,
HEADER_ID,
INST_ID,
INVOICED_FLAG,
LAST_UPDATED_BY,
LAST_UPDATE_DATE,
LAST_UPDATE_LOGIN,
LINE_ID,
LOCK_CONTROL,
ORIG_SYS_PAYMENT_REF,
PAYMENT_AMOUNT,
PAYMENT_COLLECTION_EVENT,
PAYMENT_LEVEL_CODE,
PAYMENT_NUMBER,
PAYMENT_PERCENTAGE,
PAYMENT_SET_ID,
PAYMENT_TRX_ID,
PAYMENT_TYPE_CODE,
PREPAID_AMOUNT,
PROGRAM_APPLICATION_ID,
PROGRAM_ID,
PROGRAM_UPDATE_DATE,
RECEIPT_METHOD_ID,
REQUEST_ID,
TANGIBLE_ID,
TRXN_EXTENSION_ID
FROM XX_OE_PAYMENTS_SCM
);

SHOW ERRORS;
EXIT;