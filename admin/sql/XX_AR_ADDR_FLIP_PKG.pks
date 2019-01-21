SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_ADDR_FLIP_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace PACKAGE XX_AR_ADDR_FLIP_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_ADDR_FLIP_PKG                                          |
-- | RICE ID :                                                           |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Address Flip Report|
-- |              for tax with the desirable format of the               |
-- |              user, and the default format is EXCEL                  |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0  22-JUN-09      Lavanya Ramamoorthy        Initial version   |
-- |                                                                     |
-- +=====================================================================+
-- +=====================================================================+
-- | Name :  XX_AR_ADDR_FLIP_PROC                                        |
-- | Description : The procedure will submit the OD: AR Address Flip     |
-- |             Report For Tax in the specified format                  |
-- | Parameters : p_process_date_from, p_process_date_to,                |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+
PROCEDURE XX_AR_ADDR_FLIP_PROC(
                                          x_err_buff           OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
				         ,p_process_date_from    IN VARCHAR2
				         ,p_process_date_to      IN VARCHAR2
					                                           );
END XX_AR_ADDR_FLIP_PKG;

/

SHO ERR