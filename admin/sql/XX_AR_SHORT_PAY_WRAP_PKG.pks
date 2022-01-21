SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_AR_SHORT_PAY_WRAP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_AR_SHORT_PAY_WRAP_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_SHORT_PAY_WRAP_PKG                                     |
-- | RICE ID :  R0531                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that is used for submitting the OD: AR Productivity    |
-- |              Short Pay Queue Report with the desirable format of the|
-- |              user, and the default format is EXCEL                  |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  07-FEB-09      Trisha Saxena         Initial version       |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_SHORT_PAY_WRAP_PROC                                      |
-- | Description : The procedure will submit the OD: AR Productivity     |
-- |               Short Pay Queue Report in the specified format        |
-- | Parameters : p_short_pay_date_low, p_short_pay_date_high            |  
-- |              ,p_date_task_closed_low, p_date_task_closed_high       |
-- |              ,p_drt_member, p_task_status, p_open_balance_low       |
-- |              ,p_open_balance_high, p_account_manager, p_dsm, p_rsd  |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_SHORT_PAY_WRAP_PROC(x_err_buff                OUT VARCHAR2
                                 ,x_ret_code               OUT NUMBER
				 ,p_short_pay_date_low     IN VARCHAR2
				 ,p_short_pay_date_high    IN VARCHAR2
				 ,p_date_task_closed_low   IN VARCHAR2
				 ,p_date_task_closed_high  IN VARCHAR2
				 ,p_drt_member             IN VARCHAR2  
				 ,p_task_status            IN VARCHAR2
				 ,p_open_balance_low       IN VARCHAR2 
				 ,p_open_balance_high      IN VARCHAR2 
				 ,p_account_manager        IN VARCHAR2
				 ,p_dsm                    IN VARCHAR2
				 ,p_rsd                    IN VARCHAR2
				);

END XX_AR_SHORT_PAY_WRAP_PKG;
/

SHO ERR; 
