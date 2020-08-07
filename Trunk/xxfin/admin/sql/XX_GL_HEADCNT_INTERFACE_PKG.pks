
CREATE OR REPLACE PACKAGE XX_GL_HEADCNT_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_HEADCNT_INTERFACE_PKG                               |
-- | Description      :  This PKG will be used to interface PeopleSoft |
-- |                      interface for GL head count journals to      |
-- |                          Oracle GL                                | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco				       |
-- |                                                                   |
-- +===================================================================+

-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for ce intface  |
-- |                                                                   | 
-- | Parameters : p_source_name,  p_debug_flg                          |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   x_return_message,   x_return_code                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE PROCESS_JOURNALS (x_return_message    OUT  VARCHAR2
                                 ,x_return_code      OUT  VARCHAR2
			         ,p_source_name       IN  VARCHAR2
                                 ,p_debug_flg         IN  VARCHAR2 DEFAULT 'N'
                                );




END XX_GL_HEADCNT_INTERFACE_PKG;

/







