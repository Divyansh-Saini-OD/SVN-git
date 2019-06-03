SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_PROCESS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PROCESS_PKG.pkb	              	       |
-- | Description :  OD QA Processing Package                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       19-Jul-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');




PROCEDURE XX_QA_PROC( x_errbuf      OUT NOCOPY VARCHAR2
                     ,x_retcode     OUT NOCOPY VARCHAR2
		    );

END;
/
