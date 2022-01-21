-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                 |
-- +==================================================================================+
-- | Name :APPS.XX_CE_OD_MKTPLC_EXCP_V                                           |
-- | Description : Returns the data from XX_CE_OD_MKTPLC_EXCP_V for RAKUTEN_MWS    |
-- |   RICE_Id:I3123                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date         Author               Remarks                               |
-- |=======   ==========   =============        ======================================|
-- | V1.0     09-AUG-18  Priyam P           Initial version                       |
-- +==================================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW "APPS"."XX_CE_OD_MKTPLC_EXCP_V" ("REPORT_DATE", "PROCESS_NAME", "FILENAME", "REQUEST_ID","ORDER_ID", "PO_NUM", "TXN_DATE", "TXN_TYPE", "LINE_NO", "PRICE_TYPE", "FEE_TYPE", "AMOUNT", "EXP_TYPE", "ERR_MSG") AS 
  SELECT REPORT_DATE,
    PROCESS_NAME,
    FILE_NAME FILENAME,
    REQUEST_ID,
    ATTRIBUTE1 ORDER_ID,
    ATTRIBUTE3 PO_NUM,
    ATTRIBUTE7 TXN_DATE,
    ATTRIBUTE6 TXN_TYPE,
    NULL LINE_NO ,
    NULL PRICE_TYPE,
    NULL FEE_TYPE,
    ATTRIBUTE21 AMOUNT,
    'LOAD' EXP_TYPE,
    ERR_MSG
  FROM XX_CE_MKTPLC_PRE_STG_EXCPN
  WHERE PROCESS_NAME='WALMART_MPL'
   union all
  SELECT REPORT_DATE,
    PROCESS_NAME,
    FILE_NAME FILENAME,
    REQUEST_ID,
    ATTRIBUTE4 ORDER_ID,
    NULL PO_NUM,
    ATTRIBUTE2 TXN_DATE,
    ATTRIBUTE3 TXN_TYPE,
    NULL LINE_NO ,
    NULL PRICE_TYPE,
    NULL FEE_TYPE,
    ATTRIBUTE11 AMOUNT,
    'LOAD' EXP_TYPE,
    ERR_MSG
  from XX_CE_MKTPLC_PRE_STG_EXCPN
  WHERE PROCESS_NAME='RAKUTEN_MPL'
  UNION ALL
  SELECT REPORT_DATE,
    PROCESS_NAME,
    FILE_NAME FILENAME,
    REQUEST_ID,
    NULL ORDER_ID,
    ATTRIBUTE2 PO_NUM,
    ATTRIBUTE3 TXN_DATE,
    ATTRIBUTE6 TXN_TYPE,
    NULL LINE_NO ,
    NULL PRICE_TYPE,
    null FEE_TYPE,
    ATTRIBUTE8 AMOUNT,
    'LOAD' EXP_TYPE,
    ERR_MSG
  from xx_ce_mktplc_pre_stg_excpn
  where process_name='SEARS_MPL'
   UNION ALL
    SELECT REPORT_DATE,
    PROCESS_NAME,
    FILE_NAME FILENAME,
    REQUEST_ID,
    NULL ORDER_ID,
    NULL PO_NUM,
    NULL TXN_DATE,
    NULL TXN_TYPE,
    NULL LINE_NO ,
    NULL PRICE_TYPE,
    NULL FEE_TYPE,
    NULL AMOUNT,
    'LOAD' EXP_TYPE,
    ERR_MSG
  FROM XX_CE_MKTPLC_PRE_STG_EXCPN
  WHERE PROCESS_NAME='EBAY_MPL'
  and RECORD_TYPE='D'
    UNION ALL
    SELECT REPORT_DATE,
    PROCESS_NAME,
    FILE_NAME FILENAME,
    REQUEST_ID,
    NULL ORDER_ID,
    NULL PO_NUM,
    NULL TXN_DATE,
    NULL TXN_TYPE,
    NULL LINE_NO ,
    NULL PRICE_TYPE,
    NULL FEE_TYPE,
    NULL AMOUNT,
    'LOAD' EXP_TYPE,
    ERR_MSG
  From Xx_Ce_Mktplc_Pre_Stg_Excpn
  Where Process_Name='NEWEGG_MPL';
/
SHOW ERROR