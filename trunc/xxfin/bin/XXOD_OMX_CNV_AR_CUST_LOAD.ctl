-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOD_OMX_CNV_AR_CUST_LOAD.ctl                                               |
-- | Rice Id      :                                                          				    |
-- | Description  : Conversion of OMX/"OD North" AR Customers into EBS                          |
-- | Purpose      : Load data into Custom Table XXOD_OMX_CNV_AR_CUST_STG                        |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- | 1.0      04-DEC-2017    Punit Gupta          Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
REPLACE
INTO TABLE XXOD_OMX_CNV_AR_CUST_STG
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (  
	   RECORD_ID					SEQUENCE(MAX)
	  ,ODN_CUST_NUM					CHAR "TRIM(:ODN_CUST_NUM)"
	  ,ODN_CUST_NAME			    CHAR "TRIM(:ODN_CUST_NAME)"
	  ,ORG_ADDRESS1			        CHAR "TRIM(:ORG_ADDRESS1)"
	  ,ORG_ADDRESS2					CHAR "TRIM(:ORG_ADDRESS2)"
	  ,ORG_CITY					    CHAR "TRIM(:ORG_CITY)"
	  ,ORG_STATE					CHAR "TRIM(:ORG_STATE)"
	  ,ORG_ZIPCODE					CHAR "TRIM(:ORG_ZIPCODE)"
	  ,ORG_CONTACT_NAME				CHAR "TRIM(:ORG_CONTACT_NAME)"
	  ,ORG_CONTACT_EMAIL			CHAR "TRIM(:ORG_CONTACT_EMAIL)"
	  ,ORG_CONTACT_PHONE			CHAR "TRIM(:ORG_CONTACT_PHONE)"
	  ,BILL_TO_CNSGNO			    CHAR "TRIM(:BILL_TO_CNSGNO)"
	  ,BILL_TO_ADDRESS1			    CHAR "TRIM(:BILL_TO_ADDRESS1)"
	  ,BILL_TO_ADDRESS2				CHAR "TRIM(:BILL_TO_ADDRESS2)"
	  ,BILL_TO_CITY					CHAR "TRIM(:BILL_TO_CITY)"
	  ,BILL_TO_STATE				CHAR "TRIM(:BILL_TO_STATE)"
	  ,BILL_TO_ZIPCODE				CHAR "TRIM(:BILL_TO_ZIPCODE)"
	  ,BILL_TO_CONTACT_NAME			CHAR "TRIM(:BILL_TO_CONTACT_NAME)"
	  ,BILL_TO_CONTACT_EMAIL		CHAR "TRIM(:BILL_TO_CONTACT_EMAIL)"
	  ,BILL_TO_CONTACT_PHONE		CHAR "TRIM(:BILL_TO_CONTACT_PHONE)"
	  ,SHIP_TO_CNSGNO			    CHAR "TRIM(:SHIP_TO_CNSGNO)"
	  ,SHIP_TO_ADDRESS1			    CHAR "TRIM(:SHIP_TO_ADDRESS1)"
	  ,SHIP_TO_ADDRESS2				CHAR "TRIM(:SHIP_TO_ADDRESS2)"
	  ,SHIP_TO_CITY					CHAR "TRIM(:SHIP_TO_CITY)"
	  ,SHIP_TO_STATE				CHAR "TRIM(:SHIP_TO_STATE)"
	  ,SHIP_TO_ZIPCODE				CHAR "TRIM(:SHIP_TO_ZIPCODE)"
	  ,SHIP_TO_CONTACT_NAME			CHAR "TRIM(:SHIP_TO_CONTACT_NAME)"
	  ,SHIP_TO_CONTACT_EMAIL		CHAR "TRIM(:SHIP_TO_CONTACT_EMAIL)"
	  ,SHIP_TO_CONTACT_PHONE		CHAR "TRIM(:SHIP_TO_CONTACT_PHONE)"
	  ,INTERFACE_ID                 
	  ,REQUEST_ID               	
	  ,BATCH_ID						
      ,RECORD_STATUS                CONSTANT "N"
	  ,BILL_TO_RPT_FLG              CONSTANT "N"
	  ,SHIP_TO_RPT_FLG              CONSTANT "N"
	  ,CONV_ERROR_MSG           	
	  ,CREATION_DATE                SYSDATE
	  ,CREATED_BY                   CONSTANT "-1"
	  ,LAST_UPDATE_DATE             SYSDATE
      ,LAST_UPDATED_BY              CONSTANT "-1" 
      ,LAST_UPDATE_LOGIN	        CONSTANT "-1" 
	  
)
-- +=====================================
-- | END OF SCRIPT
-- +=====================================
