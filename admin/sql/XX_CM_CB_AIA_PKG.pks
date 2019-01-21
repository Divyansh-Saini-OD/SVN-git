SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_CM_CB_AIA_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_CM_CB_AIA_PKG  
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_CB_AIA_PKG                                             |
-- | RICE ID :  R0541                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: CM Closing Balance
 --               on Active Internal Bank Accounts of the user,          |
-- |                                                                     |
-- |              and the default format is EXCEL                        |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  09-FEB-09     Usha Ramachandran        Initial version     |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_CB_AIA_PROC                                           |
-- | Description : The procedure will submit the OD: CM Closing Balance
 --               on Active Internal Bank Accounts                       |
-- | Parameters : P_BANK_NAME,P_BANK_ACCOUNT_NAME,P_BANK_BRANCH_NAME,
-- |               P_STATEMENT_NUMBER
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_CM_CB_AIA_PROC(
                                          x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,P_BANK_NAME		IN  VARCHAR2
				         ,P_BANK_ACCOUNT_NAME	 IN VARCHAR2
					 , P_BANK_BRANCH_NAME  IN VARCHAR2
					 ,P_STATEMENT_NUMBER   IN VARCHAR2
                 
                 
					                                           );


END  XX_CM_CB_AIA_PKG;
/

SHO ERR;