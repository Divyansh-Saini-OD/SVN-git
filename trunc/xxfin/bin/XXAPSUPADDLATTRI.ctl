-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                 |
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
-- |1.0       16-Jan-2018  Sunil Kalal        Loading for RMS PI Pack  |
-- |                                          4 additional attributes  |
-- +===================================================================+


options(skip=1)
load data 
 infile '$XXFIN_DATA/inbound/supplier_dff.txt'
 into table XX_AP_SUP_ADDL_ATTRIBUTES
 fields terminated by '|' 
 optionally enclosed by '"'
 trailing nullcols 
(SUPPLIER,OD_CONTRACT_SIGNATURE,OD_CONTRACT_TITLE,OD_VEN_SIG_NAME,OD_VEN_SIG_TITLE, ATTRIBUTE1 "NULL",ATTRIBUTE2 "NULL",
ATTRIBUTE3 "NULL", ATTRIBUTE4 "NULL",CREATION_DATE sysdate, CREATED_BY "-1",LAST_UPDATE_DATE  sysdate, LAST_UPDATED_BY   "-1", LAST_UPDATE_LOGIN  "-1" )


 
