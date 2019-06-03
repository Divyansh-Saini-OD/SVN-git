SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_QA_RGA_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_RGA_PKG.pks		               	       |
-- | Description :  OD QA RGA Processing Package                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');


PROCEDURE XX_RGA_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                        , x_retcode     OUT NOCOPY VARCHAR2
		       );

END;
/
SHOW ERRORS PACKAGE  XX_QA_RGA_PKG;
  
EXIT;