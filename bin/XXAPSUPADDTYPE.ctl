-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name        :                                                     |
-- | Description :                                                     |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author            Remarks                  |
-- |=======   ==========   =============      =========================|
-- |1.0       16-Jan-2018  Sunil Kalal        Loading for RMS Address  |
-- |                                          Types.                   |
-- +===================================================================+

options(skip=1)
load data 
 infile '$XXFIN_DATA/inbound/addresstype.txt'
 into table xx_ap_sup_address_type
 fields terminated by '|' 
 optionally enclosed by '"'
 trailing nullcols 
(ADDRESS_TYPE,ADDRESS_TYPE_DESC,DASHBOARD_IND,VENDOR_EXTRANET_IND Terminated By Whitespace,ATTRIBUTE1 "NULL",ATTRIBUTE2 "NULL", ATTRIBUTE3 "NULL",ATTRIBUTE4 "NULL",CREATION_DATE sysdate, CREATED_BY "-1",
LAST_UPDATE_DATE  sysdate, LAST_UPDATED_BY   "-1", LAST_UPDATE_LOGIN  "-1", ENABLE_FLAG CONSTANT 'Y',ADDR_TYPE_ID "XX_AP_SUP_ADDRESS_SEQ.NEXTVAL" ) 

