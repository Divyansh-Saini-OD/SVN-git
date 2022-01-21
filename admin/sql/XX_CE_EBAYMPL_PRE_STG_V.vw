  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XX_CE_EBAYMPL_PRE_STG_V                                                   |
  -- |  Description   : Ebay settlement view based on XX_CE_EBAYMPL_PRE_STG table                 |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         23-Sep-2020  Mayur Palsokar   Initial version                                  |
  -- +============================================================================================+

CREATE OR REPLACE VIEW XX_CE_EBAYMPL_PRE_STG_V
AS 
  SELECT 
    REC_ID,
    REPORT_DATE,
    PROCESS_NAME,
    FILENAME,
    FILE_TYPE,
    REQUEST_ID,
    PROCESS_FLAG,
    ERR_MSG,
    SETTLEMENT_ID,
	ATTRIBUTE1 PAYOUTID, 
    ATTRIBUTE2 TRANSACTIONID,
    ATTRIBUTE3 ORDERID,
    ATTRIBUTE4 TRANSACTIONTYPE,
	ATTRIBUTE5 TRANSACTIONDATE,
    ATTRIBUTE6 MARKETPLACEFEES_VALUE,
    ATTRIBUTE7 TRANSACTIONSTATUS,
    ATTRIBUTE8 LEGACYORDERID,
	ATTRIBUTE9 PAYSUM_PAYMETHOD,
    ATTRIBUTE10 PAYSUM_PAYMENTSTATUS,
    ATTRIBUTE11 LINEITEMS_SKU,
    ATTRIBUTE12 LINEITEMS_TITLE,
    ATTRIBUTE13 LINEITEMS_LINEITEMCOST_VALUE,
    ATTRIBUTE14 LINEITEMS_QUANTITY,
    ATTRIBUTE15 LINEITEMS_DELIVERYCOST_VALUE,
    ATTRIBUTE16 LINEITEMS_TAXTYPE,
    ATTRIBUTE17 LINEITEMS_EBAYREMITTAXES_VALUE,
    ATTRIBUTE18 CREATED_BY,
    ATTRIBUTE19 CREATION_DATE,
    ATTRIBUTE20 LAST_UPDATED_BY,
    ATTRIBUTE21 LAST_UPDATE_DATE,
    ATTRIBUTE22 LAST_UPDATE_LOGIN
  FROM XX_CE_MARKETPLACE_PRE_STG
  WHERE PROCESS_NAME = 'NEW_EBAY_MPL'
  AND FILE_TYPE      = 'EBAY_FINANCE_API'
  ORDER BY PAYOUTID;