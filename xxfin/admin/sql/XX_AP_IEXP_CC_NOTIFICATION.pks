create or replace 
PACKAGE      XX_AP_IEXP_CC_NOTIFICATION
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                             ORACLE                                                |
-- +===================================================================================+
-- | Name        : XX_AP_IEXP_CC_NOTIFICATION                                             |
-- | Description : This Package will be executable code for the Daily processing report|
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-AUG-2018  Bhargavi Ankolekar     Initial draft version                    |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                           ORACLE                                                  |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Package is used to generate the iExpense Credit statement of   |
-- |                termed employees which require action.                             |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 11-AUG-2018  Bhargavi Ankolekar      Initial draft version               |
-- +===================================================================================+



PROCEDURE  CC_MAIN ( x_errbuff OUT VARCHAR2,
                           x_retcode OUT NUMBER,
                           P_MODE VARCHAR2,
p_mail varchar2);

PROCEDURE CC_OPEN(p_mail varchar2);
PROCEDURE CC_ACCEPTED(p_mail varchar2);

END;
/