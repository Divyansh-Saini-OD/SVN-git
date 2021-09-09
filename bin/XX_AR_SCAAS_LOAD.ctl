-- +================================================================================================+
-- |                        Office Depot - SCaaS                                         	        |
-- |                                                                                            	|
-- +================================================================================================+
-- | Name         : XX_AR_SCAAS_LOAD.ctl                                                        	|
-- | Rice Id      :                                                                             	|
-- | Description  : Scaas Interface load program                                                 	|
-- | Purpose      :                                                	|
-- |                                                                                            	|
-- |                                                                                            	|
-- |Change Record:                                                                              	|
-- |===============                                                                             	|
-- |Version    Date          Author                Remarks                                      	|
-- |=======    ==========    =================    ==================================================+
-- |1.0 	   27-AUG-2021   Divyansh Saini   	  Initial Version                               	|
-- +================================================================================================+

OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XX_AR_SCAAS_INTERFACE
FIELDS TERMINATED BY '|'
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    ( 
	SUBSCRIPTION_ID	            CHAR"TRIM(:SUBSCRIPTION_ID)",
	SUBSCRIPTION_NUMBER	    CHAR"TRIM(:SUBSCRIPTION_NUMBER)",
	AOPS_NUMBER	            CHAR"TRIM(:AOPS_NUMBER)",
	N_EXT_ATTR1	            CHAR"TRIM(:N_EXT_ATTR1)",
	TRX_DATE	            "TO_DATE(SUBSTR(TRIM(:TRX_DATE),1,10), 'RRRR-MM-DD')",
	C_EXT_ATTR1	            CHAR"TRIM(:C_EXT_ATTR1)",
	CURRENCY_CODE	        CHAR"TRIM(:CURRENCY_CODE)",
	BILL_TO_CUSTOMER_OSR	CHAR"TRIM(:BILL_TO_CUSTOMER_OSR)",
	ACCOUNT_NUMBER	        CHAR"TRIM(:ACCOUNT_NUMBER)",
	ITEM_NAME	            CHAR"TRIM(:ITEM_NAME)",
	ITEM_DESCRIPTION	    CHAR"TRIM(:ITEM_DESCRIPTION)",
	QUANTITY	            CHAR"TRIM(:QUANTITY)",
	AMOUNT	                CHAR"TRIM(:AMOUNT)",
	UNIT_OF_MEASURE	        CHAR"TRIM(:UNIT_OF_MEASURE)",
	PAYMENT_TERM	        CHAR"TRIM(:PAYMENT_TERM)",
	status                  CONSTANT "NEW",
	created_by              CONSTANT "-1",
	creation_date           SYSDATE,
	last_update_date        SYSDATE,
	last_updated_by         CONSTANT  "-1"
)
