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

  CREATE OR REPLACE FORCE EDITIONABLE VIEW XX_CE_NEWEGG_SUM_PRE_STG_V (REC_ID, REPORT_DATE, PROCESS_NAME, FILENAME, FILE_TYPE, REQUEST_ID, PROCESS_FLAG, ERR_MSG, SETTLEMENT_ID, SETTLEMENT_DATE, SETTLEMENT_DATE_FROM, SETTLEMENT_DATE_TO, SETTLEMENT_ID_NEGGS, CHECK_NUMBER, ITEM_PRICE, SHIPPING, OTHER, TOTAL_ORDER_AMOUNT, REFUNDS, CHARGEBACK, MISCELLANEOUS_ADJUSTMENT, TOTAL_REFUNDS, NEWEGG_COMMISSION_FEE, NEWEGG_TRANSACTION_FEE, NEWEGG_REFUND_COMMISSION_FEE, NEWEGG_MONTHLY_FEE, NEWEGG_STORAGE_FEE, NEWEGG_RMA_BUYOUT_FEE, NEWEGG_PREMIER_FEE, NEWEGG_SHIPPING_LABEL_FEE, TOTAL_NEWEGG_FEE, TOTAL_SETTLEMENT) AS 
  SELECT REC_ID,
    REPORT_DATE,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
    REQUEST_ID,
    PROCESS_FLAG,
    ERR_MSG,
    SETTLEMENT_ID,
    ATTRIBUTE1 Settlement_Date,
    ATTRIBUTE2 Settlement_Date_From,
    ATTRIBUTE3 SETTLEMENT_DATE_TO,
    ATTRIBUTE4 Settlement_ID_NEGGS,
    ATTRIBUTE5 Check_Number,
    ATTRIBUTE6 Item_Price,
    ATTRIBUTE7 Shipping,
    ATTRIBUTE8 Other,
    ATTRIBUTE9 Total_Order_Amount,
    ATTRIBUTE10 Refunds,
    ATTRIBUTE11 ChargeBack,
    ATTRIBUTE12 Miscellaneous_Adjustment,
    ATTRIBUTE13 Total_Refunds,
    ATTRIBUTE14 Newegg_Commission_Fee,
    ATTRIBUTE15 Newegg_Transaction_Fee,
    ATTRIBUTE16 Newegg_Refund_Commission_Fee,
    ATTRIBUTE17 Newegg_Monthly_Fee,
    ATTRIBUTE18 Newegg_Storage_Fee,
    ATTRIBUTE19 Newegg_RMA_Buyout_Fee,
    ATTRIBUTE20 Newegg_Premier_Fee,
    ATTRIBUTE21 Newegg_Shipping_Label_Fee,
    ATTRIBUTE22 Total_Newegg_Fee,
    ATTRIBUTE23 Total_Settlement
  FROM XX_CE_MARKETPLACE_PRE_STG
  where PROCESS_NAME ='NEWEGG_MPL'
  AND FILE_TYPE      ='NEGGS';

/
SHOW ERROR