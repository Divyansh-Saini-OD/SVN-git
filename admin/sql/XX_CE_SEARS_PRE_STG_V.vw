-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- +==================================================================================+
-- | Name :AXX_CE_SEARS_PRE_STG_V                                           |
-- | Description : Returns the data from XX_CE_MARKETPLACE_PRE_STG for SEARS_MPL    |
-- |   RICE_Id:I3123                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     18-Jun-2018  Priyam S           Initial version                       |
-- +==================================================================================+

CREATE OR REPLACE force EDITIONABLE VIEW XX_CE_SEARS_PRE_STG_V (REC_ID, SETTLEMENT_ID, PROCESS_NAME, FILENAME, FILE_TYPE, REQUEST_ID, REPORT_DATE, PROCESS_FLAG, ERR_MSG, PO_NUMBER, PO_DATE, SELLPO_INVOICE_ID, NAPS_INVOICE_NUMBER, TYPE, INVOICE_DATE, INVOICE_AMOUNT, EFT_NUMBER, EFT_DATE, EFT_AMOUNT, SITE, RMA_NUM, CUST_ORDER_NUM, TOTAL_SELLING_PRICE, COMMISSION_TO_SEARS, TOTAL_SHIPPING_FEE, BALANCE_TO_SELLER, RETURN_REASON_CODE, SHIPPING_TAX_AMOUNT, SALES_TAX_AMOUNT, REGULATORY_FEE_AMOUNT)
AS
  SELECT REC_ID,
    SETTLEMENT_ID,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
    REQUEST_ID,
    REPORT_DATE,
    PROCESS_FLAG,
    ERR_MSG,
    ATTRIBUTE1 PO_NUMBER,
    ATTRIBUTE2 PO_DATE,
    ATTRIBUTE3 SELLPO_INVOICE_ID,
    ATTRIBUTE4 NAPS_INVOICE_NUMBER,
    ATTRIBUTE5 TYPE,
    ATTRIBUTE6 INVOICE_DATE,
    ATTRIBUTE7 INVOICE_AMOUNT,
    ATTRIBUTE8 EFT_NUMBER,
    ATTRIBUTE9 EFT_DATE,
    ATTRIBUTE10 EFT_AMOUNT,
    ATTRIBUTE11 SITE,
    ATTRIBUTE12 RMA_NUM,
    ATTRIBUTE13 CUST_ORDER_NUM,
    ATTRIBUTE14 TOTAL_SELLING_PRICE,
    ATTRIBUTE15 COMMISSION_TO_SEARS,
    ATTRIBUTE16 TOTAL_SHIPPING_FEE,
    ATTRIBUTE17 BALANCE_TO_SELLER,
    ATTRIBUTE18 RETURN_REASON_CODE,
    ATTRIBUTE19 SHIPPING_TAX_AMOUNT,
    ATTRIBUTE20 SALES_TAX_AMOUNT,
    ATTRIBUTE21 REGULATORY_FEE_AMOUNT
  FROM XX_CE_MARKETPLACE_PRE_STG
  WHERE PROCESS_NAME ='SEARS_MPL'
  AND UPPER(FILE_TYPE) LIKE 'SEA%';

/
SHOW ERROR