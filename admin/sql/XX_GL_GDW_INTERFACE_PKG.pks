
CREATE OR REPLACE PACKAGE XX_GL_GDW_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_GDW_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface global data|
-- |                     warehouse feed with with the Oracle GL        |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0       01/14/2009  P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+





-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for GDW intface |
-- |                                                                   | 
-- | Parameters :  p_source_name ,p_debug_flg                          |
-- |                                                                   |
-- |                                                                   |
-- | Returns :  x_return_message,  x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE PROCESS_JOURNALS (x_return_message    OUT  VARCHAR2
                                 ,x_return_code      OUT  VARCHAR2
			         ,p_source_name       IN  VARCHAR2
                                 ,p_debug_flg         IN  VARCHAR2 DEFAULT 'N'
                                );




END XX_GL_GDW_INTERFACE_PKG;

/




