-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- +==================================================================================+
-- | Name :AXX_CE_SEARS_PRE_STG_V                                           |
-- | Description : Returns the data from XX_CE_MARKETPLACE_PRE_STG for NEWEGG_MPL    |
-- |   RICE_Id:I3123                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     14-dec-2018  Priyam S           Initial version                       |
-- +==================================================================================+

  CREATE OR REPLACE FORCE EDITIONABLE VIEW XX_CE_NEWEGG_TRAN_PRE_STG_V (REC_ID, REPORT_DATE, PROCESS_NAME, FILENAME, FILE_TYPE, REQUEST_ID, PROCESS_FLAG, ERR_MSG, SETTLEMENT_ID, TRANSACTION_DATE, TRANSACTION_TYPE, ORDER_ID, INVOICE_ID, SELLER_PART_NUMBER, NEWEGG_ITEM_NUMBER, ITEM_DESCRIPTION, ITEM_CONDITION, AMOUNT, SHIPPING, COMMISSION_FEE, SETTLEMENT_ID_NEGG) AS 
  SELECT REC_ID,
    REPORT_DATE,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
    REQUEST_ID,
    PROCESS_FLAG,
    ERR_MSG,
    SETTLEMENT_ID,
    ATTRIBUTE1 Transaction_Date,
    ATTRIBUTE2 Transaction_Type,
    ATTRIBUTE3 Order_ID,
    ATTRIBUTE4 Invoice_ID,
    ATTRIBUTE5 Seller_Part_Number,
    ATTRIBUTE6 Newegg_Item_Number,
    ATTRIBUTE7 Item_Description,
    ATTRIBUTE8 Item_Condition,
    ATTRIBUTE9 Amount,
    ATTRIBUTE10 Shipping,
    ATTRIBUTE11 COMMISSION_FEE,
    ATTRIBUTE12 SETTLEMENT_ID_NEGGT
  FROM XX_CE_MARKETPLACE_PRE_STG
  WHERE PROCESS_NAME ='NEWEGG_MPL'
  AND FILE_TYPE      ='NEGGT';

/
SHOW ERROR