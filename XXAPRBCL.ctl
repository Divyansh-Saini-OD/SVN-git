-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XXAPRBCL.ctl                                            |
-- | Purpose      : Insret data into Custom Table XX_AP_BULK_CHECK_INVOICE_STG                  |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date          Author                Remarks                                     |
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1.0   12-Aug-2016  Radhika Patnala      Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+
OPTIONS(SKIP=1)
LOAD DATA
APPEND
INTO TABLE XXFIN.XX_AP_BULK_CHECK_INVOICE_STG
FIELDS TERMINATED BY "|"
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
    (
	INVOICE_DATE			CHAR"TRIM(:INVOICE_DATE)",
	VENDOR_NO	                CHAR"TRIM(:VENDOR_NO)",
	VENDOR_SITE_CODE		CHAR"TRIM(:VENDOR_SITE_CODE)",
	INVOICE_AMT			CHAR"TRIM(:INVOICE_AMT)",
	DESCRIPTION			CHAR"RTRIM(LTRIM(:DESCRIPTION))",
	LINE_AMOUNT			CHAR"TRIM(:LINE_AMOUNT)",
	DISTCODE_CONCATENATED           CHAR"TRIM(:DISTCODE_CONCATENATED)",
        LINE_DESCRIPTION	        CHAR"RTRIM(LTRIM(:LINE_DESCRIPTION))",
	PROCESS_FLAG			CONSTANT "1",		
	ERROR_FLAG			CONSTANT "N",
	CREATION_DATE			SYSDATE,
	CREATED_BY	  	    	"FND_GLOBAL.USER_ID",
	LAST_UPDATE_DATE		SYSDATE,		
	LAST_UPDATED_BY			"FND_GLOBAL.USER_ID"
	)
-- +=====================================
-- | END OF SCRIPT
-- +=====================================
