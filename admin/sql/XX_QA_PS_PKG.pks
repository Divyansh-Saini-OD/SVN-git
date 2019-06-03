SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_PS_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_PS_PKG.pkb		               	       |
-- | Description :  OD QA PS Processing Package                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       13-Jun-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');


PROCEDURE XX_PS_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                        ,x_retcode     OUT NOCOPY VARCHAR2
		       );

END;
/
