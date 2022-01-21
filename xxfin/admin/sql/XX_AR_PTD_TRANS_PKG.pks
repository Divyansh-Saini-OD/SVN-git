SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_PTD_TRANS_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AR_PTD_TRANS_PKG  
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name : XX_AR_PTD_TRANS_PKG                                             |
-- | RICE ID :  R0533                                                       |
-- | Description :This package is the executable of the wrapper program     |
-- |              that used for submitting the OD: CM Closing Balance
 --|               on Active Internal Bank Accounts of the user,            |
-- |                                                                        |
-- |              and the default format is EXCEL                           |
-- |                                                                        |
-- | Change Record:                                                         |
-- |===============                                                         |
-- |Version   Date              Author              Remarks                 |
-- |======   ==========     =============        =======================    |
-- |Draft 1A  02-MAR-09     Usha Ramachandran        Initial version        |
-- |                                                                        |
-- +========================================================================+

-- +=====================================================================+  |
-- | Name :  XX_AR_PTD_TRANS_PKG                                            |
-- | Description : The procedure will submit the OD: CM Closing Balance     |
 --               on Active Internal Bank Accounts                          |
-- | Parameters : P_GL_DATE_FROM,P_GL_DATE_TO                               |
-- |                                                                        |
-- | Returns :  x_err_buff,x_ret_code                                       |
-- +=====================================================================+

PROCEDURE XX_AR_PTD_TRANS_PROC(
                                           x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,P_GL_DATE_FROM		IN  VARCHAR2
				         ,P_GL_DATE_TO	 IN VARCHAR2
                
                 
					                                           );


END  XX_AR_PTD_TRANS_PKG;
/

SHO ERR;