-- +=============================================================================+
-- |                            Office Depot                                     |
-- +=============================================================================+
-- | Name            : XX_PO_INTEGRAL_CNV.ctl                                    |
-- | Rice ID         :                                                           |
-- | Description     : Control File to load the XX_PO_INTEGRAL_CNV_STG table     |
-- |                                                                             |
-- |                                                                             |
-- |Change History:                                                              |
-- |---------------                                                              |
-- |                                                                             |
-- |Version  Date        Author             Remarks                              |
-- |-------  ----------- -----------------  -------------------------------------|
-- |1.0      05-JUL-2017 Havish Kasina      Initial Draft version                |
-- +=============================================================================+

--OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_PO_INTEGRAL_CNV_STG
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (
LOCATION                CHAR"TRIM(:LOCATION)"
,PO_NUMBER                      CHAR"TRIM(:PO_NUMBER)"
,PO_LINE_NUMBER         CHAR"TRIM(:PO_LINE_NUMBER)"
,SKU                            CHAR"TRIM(:SKU)"
,ITEM_COST              CHAR"TRIM(:ITEM_COST)"
,RECEIVED_QTY       CHAR"TRIM(:RECEIVED_QTY)"
,BILLED_QTY             CHAR"TRIM(:BILLED_QTY)"
,REQUEST_ID  CONSTANT "-1"
,CREATION_DATE  SYSDATE
,CREATED_BY  "FND_GLOBAL.USER_ID"
,LAST_UPDATE_DATE  SYSDATE
,LAST_UPDATED_BY "FND_GLOBAL.USER_ID"
)
