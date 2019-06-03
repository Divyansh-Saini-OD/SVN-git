SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_CAP_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_CAP_PKG.pkb		               	       |
-- | Description :  OD QA CAP Processing Package                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       25-Apr-2011 Paddy Sanjeevi     Initial version           |
-- |1.1       14-Jun-2011 Paddy Sanjeevi     Defect 12079              |
-- |1.2       25-Sep-2012 Paddy Sanjeevi     Defect 20454              |
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');

PROCEDURE XX_CAP_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       );

FUNCTION xx_cap_response( p_act IN VARCHAR2
			 ,p_act_ID IN VARCHAR2) RETURN NUMBER;

END;
/
