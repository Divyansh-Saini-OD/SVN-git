-- +==================================================================================+
-- |                  Office Depot						                             |
-- +==================================================================================+
-- | Name :APPS.XX_CE_GOOGLE_PRE_STG_V                                           |
-- | Description : Returns the data from XX_CE_MARKETPLACE_PRE_STG for GOOGLE_MPL    |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     16-Jan-2020  Amit Kumar           Initial version                       |
-- +==================================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW  XX_CE_GOOGLE_PRE_STG_V AS
SELECT REC_ID,
  REPORT_DATE,
  PROCESS_NAME,
  FILENAME,
  FILE_TYPE,
  REQUEST_ID,
  PROCESS_FLAG,
  ERR_MSG,
  SETTLEMENT_ID ,
  ATTRIBUTE1 id ,
  ATTRIBUTE2 transfer_date ,
  ATTRIBUTE3 transfer_id ,
  ATTRIBUTE4 start_date ,
  ATTRIBUTE5 end_date ,
  ATTRIBUTE6 transfer_amount ,
  ATTRIBUTE7 transfer_currency ,
  ATTRIBUTE8 transaction_type ,
  ATTRIBUTE9 order_id ,
  ATTRIBUTE10 merchant_order_id ,
  ATTRIBUTE11 shipment_id ,
  ATTRIBUTE12 carrier ,
  ATTRIBUTE13 carrier_tracking_id ,
  ATTRIBUTE14 adjustment_id ,
  ATTRIBUTE15 amount_type ,
  ATTRIBUTE16 amount_description ,
  ATTRIBUTE17 commission_category ,
  ATTRIBUTE18 commission_category_rate ,
  ATTRIBUTE19 amount ,
  ATTRIBUTE20 currency ,
  ATTRIBUTE21 post_date ,
  ATTRIBUTE22 post_datetime ,
  ATTRIBUTE23 timezone ,
  ATTRIBUTE24 order_item_id
FROM xx_ce_marketplace_pre_stg
WHERE process_name = 'GOOGLE_MPL'
AND FILE_TYPE      ='GOOGLE'
order by id , transfer_date;
/
SHOW ERROR