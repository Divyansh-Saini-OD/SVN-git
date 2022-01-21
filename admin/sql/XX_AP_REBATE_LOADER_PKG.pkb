SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_REBATE_LOADER_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AP_REBATE_LOADER_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name :  XX_AP_REBATE_LOADER_PKG                                          |
-- | Description :  This package is used to load rebate loader program        |
-- |                                                                          |
-- | RICEID      :  E3515 AP Check Rebate Loader                              |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |1.0       19-May-2017    praveen vanga       Initial version              |
-- |                                                                          |
-- +==========================================================================+

 
 /*  Main Procedure to process the records from WEBADI and insert into custom table */

PROCEDURE MAIN (P_INVOICE_DATE	   DATE,
			    P_VENDOR_NO	       VARCHAR2,
				P_VENDOR_SITE_CODE VARCHAR2,
				P_INVOICE_AMT	   NUMBER,
				P_DESCRIPTION	   VARCHAR2,
				P_LINE_AMOUNT	   NUMBER,
				P_DISTCODE_CONCATENATED VARCHAR2,
				P_LINE_DESCRIPTION      VARCHAR2)
AS
BEGIN

 
   -- insert records into custom table
   INSERT INTO XX_AP_BULK_CHECK_INVOICE_STG
    (
	INVOICE_DATE	,
	VENDOR_NO	    ,
	VENDOR_SITE_CODE,
	INVOICE_AMT		,
	DESCRIPTION		,
	LINE_AMOUNT		,
	DISTCODE_CONCATENATED,
    LINE_DESCRIPTION,
	PROCESS_FLAG ,		
	ERROR_FLAG	 ,
	CREATION_DATE ,
	CREATED_BY	  ,
	LAST_UPDATE_DATE ,		
	LAST_UPDATED_BY	 
	)
	Values
	(P_INVOICE_DATE	,
	 P_VENDOR_NO	    ,
	 P_VENDOR_SITE_CODE,
	 P_INVOICE_AMT		,
	 P_DESCRIPTION		,
	 P_LINE_AMOUNT		,
	 P_DISTCODE_CONCATENATED,
     P_LINE_DESCRIPTION,
	 1,		
	 'N',
 	 SYSDATE,
 	 FND_GLOBAL.USER_ID,
	 SYSDATE,		
	 FND_GLOBAL.USER_ID
	);

EXCEPTION
  WHEN OTHERS THEN
	null;
     	
END MAIN;


END XX_AP_REBATE_LOADER_PKG;
/
SHOW ERROR
