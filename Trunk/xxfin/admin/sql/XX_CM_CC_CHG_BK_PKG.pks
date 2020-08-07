SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_CM_CC_CHG_BK_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_CM_CC_CHG_BK_PKG  
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_CC_CHG_BK_PKG                                          |
-- | RICE ID :  R0470                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: CM Credit Card 
-- |                 Chargeback of the user and the default format is EXCEL
--                                                                       |
-- |                                                                     |
-- |                                    |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  09-APR-09     Usha Ramachandran        Initial version     |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_CC_CHG_BK_PKG                                         |
-- | Description : The procedure will submit the OD: CM Credit Card Chargeback
 --                                                                      |
-- | Parameters : P_ADJUSTMENT_DATE_FROM,P_ADJUSTMENT_DATE_TO,P_PROVIDER_CODE,
-- |              P_CREDIT_CARD_TYPE
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_CM_CC_CHG_BK_PROC(
                                          x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,P_ADJUSTMENT_DATE_FROM IN  VARCHAR2
				         ,P_ADJUSTMENT_DATE_TO	 IN VARCHAR2
                 ,P_PROVIDER_CODE        IN VARCHAR2
                 ,P_CREDIT_CARD_TYPE     IN VARCHAR2
                 
                 
					                                           );


END  XX_CM_CC_CHG_BK_PKG;
/

SHO ERR;