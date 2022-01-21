SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM         ON

PROMPT Creating Package Specification XX_AR_CREATE_ACCT_MASTER_PKG 
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_GL_GLSI_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_GSS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface GLSI       |
-- |                     data feed with with the Oracle GL             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0       06-25/2007  P.Marco          Initial draft version       |
-- |1.1       08-29/2008  Chandarakala D   Changes for defect  5327    |
-- |                                                                   |
-- +===================================================================+
-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for GLSIintface |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
     PROCEDURE PROCESS_JOURNALS (x_return_message    OUT  VARCHAR2
                                 ,x_return_code      OUT  VARCHAR2
			         ,p_source_name       IN  VARCHAR2
                                 ,p_debug_flg         IN  VARCHAR2 DEFAULT 'N'
                                );
-- +===================================================================+
-- | Name  :CREATE_SUSPENSE_LINES
-- | Description : This procedure will be used to find
-- |               the difference in balance of the credit
-- |               and debit amount of the journal entry
-- |               and create a new suspense line with it
-- |
-- |
-- | Parameters : p_grp_id
-- | 
-- +===================================================================+
    PROCEDURE  CREATE_SUSPENSE_LINES (p_grp_id  NUMBER
                                      ,p_sob_id NUMBER
				      );
END XX_GL_GLSI_INTERFACE_PKG;

/
SHO ERR;






