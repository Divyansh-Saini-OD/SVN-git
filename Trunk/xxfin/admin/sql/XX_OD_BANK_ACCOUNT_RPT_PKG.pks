SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Specification XX_OD_BANK_ACCOUNT_RPT_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE XX_OD_BANK_ACCOUNT_RPT_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD		                             |
-- +=====================================================================+
-- | Name : XX_OD_BANK_ACCOUNT_RPT_PKG                                   |
-- | Defect# 13836		                                                 |
-- | Description : This package houses the report submission procedure   |
-- |              									                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  13-Jan-2012   Sai Kumar Reddy      Initial version         |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_OD_BANK_ACCOUNT_PRC                                      |
-- | Description : This procedure will submit the New Bank Account       |
-- |               report			                                     |
-- | Parameters  : 											             |
-- | 																	 |
-- | 												 |
-- | Returns     : err_buff,ret_code                                 	 |
-- +=====================================================================+

PROCEDURE XX_OD_BANK_ACCOUNT_PRC (
                             x_err_buff    OUT VARCHAR2,
                             x_ret_code    OUT NUMBER,
                             P_PERIOD 		 IN VARCHAR2,
                             P_FORMAT      IN VARCHAR2 DEFAULT 'EXCEL'
                            );
END XX_OD_BANK_ACCOUNT_RPT_PKG;
/