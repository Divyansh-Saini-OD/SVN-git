SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE APPS.XX_QA_ED_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_ED_PKG.pks		               	       |
-- | Description :  OD QA ED Processing Package                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- |1.1       12-Jan-2012 Paddy Sanjeevi     Added parameter in send_rpt
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');


PROCEDURE XX_ED_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                       , x_retcode     OUT NOCOPY VARCHAR2
		       );
		       
PROCEDURE send_rpt( p_subject IN VARCHAR2
                  , p_email   IN VARCHAR2
                  , p_ccmail  IN VARCHAR2
                  , p_text    IN VARCHAR2
                  , p_edid    IN VARCHAR2
		  , p_affidavit IN VARCHAR2
                  );		       

END;
/
SHOW ERRORS PACKAGE  XX_QA_ED_PKG;
  
EXIT;