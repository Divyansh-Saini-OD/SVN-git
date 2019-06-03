CREATE OR REPLACE package APPS.XX_PA_PROJ_INFO_PURGE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PROJ_INFO_PURGE_PKG.pks                      |
-- | Description :  his objective of this API is to delete projects    |
-- |                 from the PA system.                               |
-- |               All detail information will be deleted.             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       23-Oct-2009 Rama Dwibhashyam     Initial version           |
-- +===================================================================+
procedure PURGE_PROJECT_INFO (
                               x_errbuf            OUT NOCOPY VARCHAR2
		                     , x_retcode           OUT NOCOPY VARCHAR2
                             , p_project_number     IN  VARCHAR2
                             , p_project_type       IN  VARCHAR2  
                             , p_template_flag      IN  VARCHAR2
                             , p_process_errors     IN  VARCHAR2
                             );
                             
                             
END XX_PA_PROJ_INFO_PURGE_PKG ;
/
