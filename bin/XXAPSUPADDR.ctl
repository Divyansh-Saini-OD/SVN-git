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
-- |1.0       16-Jan-2018  Sunil Kalal        Loading for RMS Addresses|
-- |                                          for Vendor Contacts.     |
-- +===================================================================+


options(skip=1)
load data 
 infile '$XXFIN_DATA/inbound/addr.txt'
 into table xx_ap_sup_vendor_contact_stg
 fields terminated by '|' 
optionally enclosed by '"'
 trailing nullcols 
(ADDR_KEY,MODULE,KEY_VALUE_1,KEY_VALUE_2, SEQ_NO,ADDR_TYPE, PRIMARY_ADDR_IND, ADD_1,ADD_2,ADD_3,CITY,STATE,COUNTRY_ID,POST, CONTACT_NAME, CONTACT_PHONE,CONTACT_TELEX, CONTACT_FAX,
CONTACT_EMAIL, ORACLE_VENDOR_SITE_ID, OD_PHONE_NBR_EXT,OD_PHONE_800_NBR, OD_COMMENT_1,OD_COMMENT_2,OD_COMMENT_3,OD_COMMENT_4,OD_EMAIL_IND_FLG,OD_SHIP_FROM_ADDR_ID, 
ATTRIBUTE1 "NULL",ATTRIBUTE2 "NULL",ATTRIBUTE3 "NULL", ATTRIBUTE4 "NULL", ATTRIBUTE5 "NULL",CREATION_DATE sysdate, CREATED_BY "-1",LAST_UPDATE_DATE  sysdate, 
LAST_UPDATED_BY   "-1", LAST_UPDATE_LOGIN  "-1",ENABLE_FLAG CONSTANT 'Y',ADDR_TYPE_ID CONSTANT "1"  )