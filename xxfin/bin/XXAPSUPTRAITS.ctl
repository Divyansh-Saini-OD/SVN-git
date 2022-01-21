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
-- |1.0       16-Jan-2018  Sunil Kalal        Loading for RMS Supplier |
-- |                                          Traits.                  |
-- +===================================================================+


options(skip=1)
load data 
 infile '$XXFIN_DATA/inbound/suptraits.txt'
 into table xx_ap_sup_traits
 fields terminated by '|' 
 optionally enclosed by '"'
 trailing nullcols 
(SUP_TRAIT ,DESCRIPTION,MASTER_SUP_IND,MASTER_SUP ,ATTRIBUTE1 "NULL",ATTRIBUTE2 "NULL", ATTRIBUTE3 "NULL",ATTRIBUTE4 "NULL",ATTRIBUTE5 "NULL", ATTRIBUTE6 "NULL",CREATION_DATE sysdate, CREATED_BY "-1",
LAST_UPDATE_DATE  sysdate, LAST_UPDATED_BY   "-1", LAST_UPDATE_LOGIN  "-1", ENABLE_FLAG CONSTANT 'Y',SUP_TRAIT_ID "XX_AP_SUP_TRAITS_SEQ.NEXTVAL" ) 