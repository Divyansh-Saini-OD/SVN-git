SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_DISPUTES_TAX_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AR_DISPUTES_TAX_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_DISPUTES_TAX_PKG                                       |
-- | RICE ID :  R0536                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Default Collector  |
-- |              report with the desirable format of the user, and the  |
-- |              default format is EXCEL                                |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  15-JAN-09      Harini Gopalswamy         Initial version   |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_DISPUTES_SALES_TAX_PROC                               |
-- | Description : The procedure will submit the OD: AR Default Collector|
-- |               report in the specified format                        |
-- | Parameters : p_period_from, p_period_to                             |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DISPUTES_SALES_TAX_PROC(
                                          x_err_buff      OUT VARCHAR2
                                         ,x_ret_code      OUT NUMBER
				         ,p_period_from   IN VARCHAR2
				         ,p_period_to     IN VARCHAR2
                                          );
END XX_AR_DISPUTES_TAX_PKG;
/
SHO ERR;