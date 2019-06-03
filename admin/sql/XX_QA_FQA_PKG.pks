SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE APPS.XX_QA_FQA_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_FQA_PKG.pkb		               	       |
-- | Description :  OD QA FQA Processing Package                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-May-2011 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

lc_send_mail           VARCHAR2(1) := FND_PROFILE.VALUE('XX_PB_QA_SEND_MAIL');



PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_cc_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 );

FUNCTION IS_APPROVER_VALID(p_plan IN VARCHAR2) RETURN VARCHAR2;

PROCEDURE XX_FQA_PROCESS( x_errbuf      OUT NOCOPY VARCHAR2
                         ,x_retcode     OUT NOCOPY VARCHAR2
		       );

END;
/
