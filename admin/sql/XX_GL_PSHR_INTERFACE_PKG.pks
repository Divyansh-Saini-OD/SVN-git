
CREATE OR REPLACE PACKAGE XX_GL_PSHR_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_PSHR_INTERFACE_PKG                                  |
-- | Description      :  This PKG will be used to interface PeopleSoft |
-- |                     data feed with with the Oracle GL             |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |1.0       06-25/2007  P.Marco          Initial draft version       |
-- |                                                                   |
-- +===================================================================+


-- +===================================================================+
-- | Name  : DERIVE_COMPANY                                            |
-- | Description      : This Procedure will derive oracle company based|
-- |                    Peoplesoft company parameter                   | 
-- | Parameters :       People Soft Company                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Oracle Company                                 |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE DERIVE_COMPANY (p_ps_company       IN  VARCHAR2
			      ,x_ora_company      OUT VARCHAR2
			      ,x_error_message    OUT VARCHAR2
                              );




-- +===================================================================+
-- | Name  : DERIVE_LOCATION                                           |
-- | Description      : This Procedure will derive the Oracle LOCATION |
-- |                    from the PeopleSoft LOCATION using the values  |
-- |                    from the tranlation def. "GL_PSHR_COMPANY"     |
-- |                                                                   |
-- | Parameters :       PeopleSoft Location                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Oracle Location    			       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+




     PROCEDURE DERIVE_LOCATION (p_ps_location       IN  VARCHAR2
			       ,x_ora_location      OUT VARCHAR2
			       ,x_error_message     OUT VARCHAR2
                               );



-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for PSHR intface|
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




END XX_GL_PSHR_INTERFACE_PKG;

/




