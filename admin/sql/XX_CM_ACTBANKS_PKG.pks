SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE SPECIFICATION XX_CM_ACTBANKS_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CM_ACTBANKS_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_CM_ACTBANKS_PKG                                           |
-- | RICE ID :  R0540                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that is used for submitting the OD: CM Active Banks    |
-- |              Listing program with the desirable format of the       |
-- |              user, and the default format is EXCEL                  |
-- |                                                                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  19-FEB-09       Ganesan              Initial version       |
-- |                                                                     |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_CM_ACTBANKS_WRAP_PROC                                    |
-- | Description : The procedure will submit the OD: AR Productivity     |
-- |               Short Pay Queue Report in the specified format        |
-- | Parameters : p_bank_name, p_bank_number, p_bank_branch_name,        |  
-- |              ,p_bank_branch_number                                  |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_CM_ACTBANKS_WRAP_PROC(x_err_buff            OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
				   ,p_bank_name          IN VARCHAR2
				   ,p_bank_number        IN VARCHAR2
				   ,p_bank_branch_name   IN VARCHAR2
				   ,p_bank_branch_number IN VARCHAR2
				  );

END XX_CM_ACTBANKS_PKG;
/

SHO ERR 
