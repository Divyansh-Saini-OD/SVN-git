SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_AR_DUNNING_TRANSMISSION_PKG
PROMPT Program exits IF the creation is not successful
WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_AR_DUNNING_TRANSMISSION_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_DUNNING_TRANSMISSION_PKG                               |
-- | RICE ID :  R0530                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Dunning            |
-- |              Transmission report with the desirable format of the   |
-- |              user, and the default format is EXCEL                  |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  20-JAN-09      Jennifer Jegam         Initial version      |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_DUN_TRANS_PROC                             |
-- | Description : The procedure will submit the OD: AR Dunning          |
-- |               Transmission report in the specified format           |
-- | Parameters : p_trans_date_from, p_trans_date_to, p_trans_method,    |
-- |              p_trans_status, p_collector_name                       |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DUN_TRANS_PROC(
                                          x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,p_trans_date_from    IN VARCHAR2
				         ,p_trans_date_to      IN VARCHAR2
					 ,p_trans_method       IN VARCHAR2
					 ,p_trans_status       IN VARCHAR2
					 ,p_collector_name     IN VARCHAR2
                                          );


END XX_AR_DUNNING_TRANSMISSION_PKG;
/
 SHO ERR;