-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- +==================================================================================+
-- | Name :APPS.XX_CE_RAKUTEN_PRE_STG_TDR_V                                           |
-- | Description : Returns the data from XX_CE_MARKETPLACE_PRE_STG for RAKUTEN_MWS    |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     28-Jun-2018  Digamber S           Initial version                       |
-- +==================================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW XX_CE_RAKUTEN_PRE_STG_TDR_V (REC_ID, REPORT_DATE, PROCESS_NAME, FILENAME, FILE_TYPE, PROCESS_FLAG, ERR_MSG, SETTLEMENT_ID, INVOICEID, TRANDATE, TRANTYPE, ORDERID, ORDERITEMID, LISTINGID, REFERENCEID, ITEMNAME, BUYEREMAIL, QTYSHIPPED, BUYERPAID, COMMISSION, SHIPPINGFEE, PERITEMFEE, FEETOTAL, SALESTAX, RECYCLEFEE, SELLERRECEIVED) AS 
  SELECT REC_ID,
    REPORT_DATE,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
    PROCESS_FLAG,
    ERR_MSG,
    SETTLEMENT_ID,
    ATTRIBUTE1 INVOICEID,
    ATTRIBUTE2 TRANDATE,
    ATTRIBUTE3 TRANTYPE,
    ATTRIBUTE4 ORDERID,
    ATTRIBUTE5 ORDERITEMID,
    ATTRIBUTE6 LISTINGID,
    ATTRIBUTE7 REFERENCEID,
    ATTRIBUTE8 ITEMNAME,
    ATTRIBUTE9 BUYEREMAIL,
    ATTRIBUTE10 QTYSHIPPED,
    ATTRIBUTE11 BUYERPAID,
    ATTRIBUTE12 COMMISSION,
    ATTRIBUTE13 SHIPPINGFEE,
    ATTRIBUTE14 PERITEMFEE,
    ATTRIBUTE15 FEETOTAL,
    ATTRIBUTE16 SALESTAX,
    ATTRIBUTE17 RECYCLEFEE,
    ATTRIBUTE18 SELLERRECEIVED
  FROM XX_CE_MARKETPLACE_PRE_STG
  WHERE PROCESS_NAME ='RAKUTEN_MWS'
  AND FILENAME       ='RakutenTDRSettlement.csv';
/
SHOW ERR