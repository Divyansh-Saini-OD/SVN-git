-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      IBY: Store and Merchant Number Loading                |
-- | Description : To Load the store and merchant number from the file |
-- |                      staging table XX_IBY_STORE_MERCHANT_STG      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author             Remarks                 |
-- |=======   ===========  =============       ======================= |
-- |1.0       29-JAN-2008  Gowri Shankar       Initial version         |
-- |                                                                   |
-- +===================================================================+
LOAD DATA APPEND
INTO TABLE xxfin.xx_iby_store_merchant_stg 
WHEN attribute1 = 'MERCHANT  '
TRAILING NULLCOLS
(
     store_number                  POSITION(11:14) CHAR "trim(to_char(:store_number,'000000'))"
    ,merchant_number               POSITION(56:65) CHAR
    ,brand_code                    CONSTANT 'OD'
    ,card_code                     CONSTANT 'AM'
    ,attribute1                    POSITION(01:10)
	,created_by            "fnd_global.user_id"
    ,creation_date         SYSDATE
    ,last_update_date      SYSDATE
    ,last_updated_by       "fnd_global.user_id"
    ,last_update_login     "fnd_global.login_id"
)