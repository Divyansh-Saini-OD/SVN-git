SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_GL_CROSS_VALID_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  APPS.XX_GL_CROSS_VALID_PKG.pkb		       |
-- | Description :  Process for 10g to 11g                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       13-Dec-2012 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

PROCEDURE XX_GL_CROSS_VALIDATION
	      ( p_coa_name            IN VARCHAR2
	       ,p_company             IN VARCHAR2 DEFAULT NULL
	       ,p_cost_center         IN VARCHAR2
	       ,p_account             IN VARCHAR2
	       ,p_location            IN VARCHAR2
	       ,p_intercompany        IN VARCHAR2 DEFAULT NULL
	       ,p_lob                 IN VARCHAR2
	       ,p_future              IN VARCHAR2 DEFAULT NULL
	       ,x_return_msg          OUT VARCHAR2         --Changed parameter from p_return_msg to x_return_msg
	       ,x_valid_combo         OUT VARCHAR2         --Changed parameter from p_valid_combo to x_valid_combo
	       ,x_company             OUT VARCHAR2	   --Fixed defect 6051
	      );        
  
END;
/
