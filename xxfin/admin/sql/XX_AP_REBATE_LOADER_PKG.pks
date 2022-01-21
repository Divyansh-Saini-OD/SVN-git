SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_REBATE_LOADER_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE  XX_AP_REBATE_LOADER_PKG
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
 
 

PROCEDURE MAIN (P_INVOICE_DATE	   DATE,
			    P_VENDOR_NO	       VARCHAR2,
				P_VENDOR_SITE_CODE VARCHAR2,
				P_INVOICE_AMT	   NUMBER,
				P_DESCRIPTION	   VARCHAR2,
				P_LINE_AMOUNT	   NUMBER,
				P_DISTCODE_CONCATENATED VARCHAR2,
				P_LINE_DESCRIPTION      VARCHAR2);

			  
END XX_AP_REBATE_LOADER_PKG;
/
SHOW ERROR
