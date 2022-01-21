SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_IEXP_UNSUB_CCNOTIFY_PKG AUTHID CURRENT_USER
-- +============================================================================+
-- |                  Office Depot - Project Simplify                           |
-- +============================================================================+
-- | Name        :  XX_IEXP_UNSUB_CCNOTIFY_PKG.pkb		                |
-- | Description :  Plsql package for Iexpenses Unsubmitted CC Txns Notification|
-- | RICE ID     : E3117                                                        |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date        Author             Remarks                            |
-- |========  =========== ================== ===================================|
-- |1.0       05-May-2015 Paddy Sanjeevi     Initial version                    |
-- +============================================================================+
AS



FUNCTION get_supervisor_email(p_person_id IN NUMBER,p_manager_id OUT NUMBER,p_mgr_email OUT VARCHAR2)
RETURN BOOLEAN;

PROCEDURE xx_iexp_unsub_ccntfy_emp ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
  		                   );
 
PROCEDURE xx_iexp_unsub_ccntfy_mgr ( x_errbuf      	OUT NOCOPY VARCHAR2
                                    ,x_retcode     	OUT NOCOPY VARCHAR2
    		                   );

PROCEDURE xx_iexp_unaprv_mgr_ntfy ( x_errbuf      	OUT NOCOPY VARCHAR2
                                   ,x_retcode     	OUT NOCOPY VARCHAR2
                		  );

END;
/
