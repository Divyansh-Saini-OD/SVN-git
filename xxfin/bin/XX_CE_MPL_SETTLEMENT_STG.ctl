-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CE_MPL_SETTLEMENT_STG.ctl                                              	|
-- | Rice Id      :                                                                       	|
-- | Description  : Load data from amazon mws settlement file to staging table			|
-- | RICE ID 	  : I3091_CM Marketplace Inbound Interface                    			|
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   09-Sep-2014   Avinash Baddam       Initial Version                               |
-- +============================================================================================+
OPTIONS (errors=0, skip=1)
LOAD DATA
INFILE *
APPEND
INTO TABLE XXFIN.XX_CE_MPL_SETTLEMENT_STG
FIELDS TERMINATED BY x'09'
TRAILING NULLCOLS
    (SETTLEMENT_ID       	
    ,SETTLEMENT_START_DATE
    ,SETTLEMENT_END_DATE 
    ,DEPOSIT_DATE           	
    ,TOTAL_AMOUNT 		
    ,CURRENCY  		
    ,TRANSACTION_TYPE	
    ,ORDER_ID		
    ,MERCHANT_ORDER_ID	
    ,ADJUSTMENT_ID		
    ,SHIPMENT_ID		
    ,MARKETPLACE_NAME	
    ,SHIPMENT_FEE_TYPE	
    ,SHIPMENT_FEE_AMOUNT	
    ,ORDER_FEE_TYPE		
    ,ORDER_FEE_AMOUNT	
    ,FULFILLMENT_ID		
    ,POSTED_DATE		
    ,ORDER_ITEM_CODE	
    ,MERCHANT_ORDER_ITEM_ID 
    ,MERCHANT_ADJUSTMENT_ITEM_ID 
    ,SKU			
    ,QUANTITY_PURCHASED	
    ,PRICE_TYPE		
    ,PRICE_AMOUNT		
    ,ITEM_RELATED_FEE_TYPE	
    ,ITEM_RELATED_FEE_AMOUNT 
    ,MISC_FEE_AMOUNT	
    ,OTHER_FEE_AMOUNT	
    ,OTHER_FEE_REASON_DESCRIPTION 
    ,DIRECT_PAYMENT_TYPE	
    ,DIRECT_PAYMENT_AMOUNT	
    ,OTHER_AMOUNT		
    ,CREATED_BY          	"fnd_global.user_id"
    ,CREATION_DATE       	SYSDATE
    ,LAST_UPDATED_BY     	"fnd_global.user_id"
    ,LAST_UPDATE_DATE    	SYSDATE
    ,LAST_UPDATE_LOGIN   	"fnd_global.login_id"
    ,RECORD_ID              	"XXFIN.XX_CE_MPL_SETTLEMENT_STG_ID_S.nextval"
    ,REQUEST_ID			"fnd_global.conc_request_id"
    ,RECORD_STATUS
    ,ERROR_DESCRIPTION
    ,ACTION
    ,PROVIDER_TYPE
    ,STORE_NUMBER
    ,TERMINAL_NUMBER
    ,CARD_NUMBER
    ,AUTH_NUMBER
    ,ATTRIBUTE1
    ,ATTRIBUTE2
    ,ATTRIBUTE3
    ,ATTRIBUTE4
    ,ATTRIBUTE5
    ,ATTRIBUTE6
    ,ATTRIBUTE7
    ,ATTRIBUTE8
    ,ATTRIBUTE9
    ,ATTRIBUTE10)
  
    


