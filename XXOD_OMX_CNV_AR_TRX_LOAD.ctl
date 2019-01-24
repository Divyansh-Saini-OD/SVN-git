-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXOD_OMX_CNV_AR_TXN_LOAD.ctl                                               	|
-- | Rice Id      : C0704                                                         				|
-- | Description  : C0704 - Conversion of OMX/"OD North" AR Open Transactions into EBS          |
-- | Purpose      : Load data into Custom Table XXOD_OMX_CNV_AR_TRX_STG                         |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      |
-- |=======    ==========    =================    ==============================================+
-- | 1.0      06-JUN-2017    Madhu Bolli           Initial Version                              |
-- | 1.1      08-AUG-2017    Madhu Bolli           Modified to extract based on fixed length    |
-- |                                                                                            |
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
REPLACE
INTO TABLE XXOD_OMX_CNV_AR_TRX_STG
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (  
	   RECORD_ID					SEQUENCE(MAX)
	  ,ACCT_NO						CHAR "TRIM(:ACCT_NO)"
	  ,PAY_DUE_DATE					DATE "yyyymmdd"
	  ,INV_NO						CHAR "TRIM(:INV_NO)"
	  ,INV_SEQ_NO					CHAR"TRIM(:INV_SEQ_NO)"
	  ,INV_CREATION_DATE			DATE "yyyymmdd"
	  ,CNSG_NO						CHAR"TRIM(:CNSG_NO)"
	  ,BILL_CNSG_NO					CHAR"TRIM(:BILL_CNSG_NO)"
	  ,SUM_CYCLE					CHAR"TRIM(:SUM_CYCLE)"
	  ,SHIP_TO_LOC					CHAR"TRIM(:SHIP_TO_LOC)"
	  ,PO_NO						CHAR"TRIM(:PO_NO)"
	  ,TRAN_TYPE					CHAR"TRIM(:TRAN_TYPE)"
	  ,INV_AMT						CHAR"TRIM(:INV_AMT)"
	  ,TAX_AMT						CHAR"TRIM(:TAX_AMT)"
	  ,ORD_NO						CHAR"TRIM(:ORD_NO)"
	  ,TIER1_IND					CHAR"TRIM(:TIER1_IND)"
	  ,ADJ_CODE						CHAR"TRIM(:ADJ_CODE)"
	  ,DESCRIPTION					CHAR(2000)"TRIM(:DESCRIPTION)"
	  ,PROCESS_FLAG					CONSTANT "1"
	  ,BATCH_ID						CONSTANT "-1"
	  ,BATCH_SOURCE_NAME 			CONSTANT "-1"
	  ,CONV_ERROR_FLAG				CONSTANT "N"          
	  ,CONV_ERROR_MSG           	CONSTANT "-1"
	  ,REQUEST_ID               	CONSTANT "-1"
      ,CREATED_BY                   CONSTANT "-1"
      ,CREATION_DATE                SYSDATE          
      ,LAST_UPDATED_BY              CONSTANT "-1" 
      ,LAST_UPDATE_DATE             SYSDATE             
)

-- +=====================================
-- | END OF SCRIPT
-- +=====================================
