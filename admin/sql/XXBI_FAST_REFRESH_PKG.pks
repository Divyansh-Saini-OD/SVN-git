SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace package XXBI_FAST_REFRESH_PKG AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XXBI_FAST_REFRESH                                                       |
-- | Description : Custom package for XXBI Refresh.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        08-Apr-2010     Prasad               Initial version                          |
-- +=========================================================================================+
G_LEVEL_ID                      CONSTANT  NUMBER       := 10001;
G_LEVEL_VALUE                   CONSTANT  NUMBER       := 0;
--This procedure is invoked to print in the log file
PROCEDURE display_log( p_message IN VARCHAR2
                         );
--This procedure is invoked to print in the output
PROCEDURE display_out(p_message IN VARCHAR2);

PROCEDURE xxbi_cmplte_rfrsh_mv(x_error_code   OUT nocopy NUMBER,   
                               x_error_buf    OUT nocopy VARCHAR2,   
                               p_mv_name      IN  VARCHAR2,
                               p_refresh_flag IN  VARCHAR2,   
                               p_load_flag    IN  VARCHAR2,
                               p_rebuild_flag IN VARCHAR2, 
			       p_create_log  IN VARCHAR2

                              );
/*
--This procedure extracts Completed Tasks
PROCEDURE FAST_REFRESH_CONTACTS( x_errbuf      OUT NOCOPY VARCHAR2
                                ,x_retcode     OUT NOCOPY VARCHAR2
                               );

PROCEDURE FAST_REFRESH_ASGNMNTS( x_errbuf       OUT NOCOPY VARCHAR2
                                ,x_retcode      OUT NOCOPY VARCHAR2
                               );
PROCEDURE FAST_REFRESH_SITEDATA( x_errbuf      OUT NOCOPY VARCHAR2
                                ,x_retcode     OUT NOCOPY VARCHAR2
                               );
*/
PROCEDURE XXBI_CMPLTE_RFRSH_CONTACTS_MV ( x_error_code     OUT NOCOPY NUMBER
                                         ,x_error_buf      OUT NOCOPY VARCHAR2
                                         ,p_refresh_flag   IN         VARCHAR2
                                         ,p_load_flag      IN         VARCHAR2
                                         ,p_rebuild_flag   IN         VARCHAR2
			                       ,p_create_log     IN         VARCHAR2
                                        );
PROCEDURE xxbi_cmplte_rfrsh_asgnmnts_mv(x_error_code   OUT nocopy NUMBER,   
                                        x_error_buf    OUT nocopy VARCHAR2,   
                                        p_refresh_flag IN  VARCHAR2,   
                                        p_load_flag    IN  VARCHAR2,
                                        p_rebuild_flag   IN         VARCHAR2,
			                      p_create_log     IN         VARCHAR2
                                       );

PROCEDURE XXBI_CMPLTE_RFRSH_SITEDATA_MV ( x_error_code     OUT NOCOPY NUMBER
                                         ,x_error_buf      OUT NOCOPY VARCHAR2
                                         ,p_refresh_flag   IN         VARCHAR2
                                         ,p_load_flag      IN         VARCHAR2
                                         ,p_rebuild_flag   IN         VARCHAR2
			                       ,p_create_log     IN         VARCHAR2
                                        );

PROCEDURE alter_xxbi_user_site_dtl(x_error_code   OUT nocopy NUMBER,   
                                   x_error_buf    OUT nocopy VARCHAR2  
                                  );

PROCEDURE xxbi_populate_rsddata(x_error_code     OUT NOCOPY NUMBER,
                                x_error_buf      OUT NOCOPY VARCHAR2
                               );

END XXBI_FAST_REFRESH_PKG;
/
SHOW ERRORS;