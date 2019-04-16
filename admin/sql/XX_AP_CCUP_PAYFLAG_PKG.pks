CREATE OR REPLACE
PACKAGE XX_AP_CCUP_PAYFLAG_PKG
AS

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                            ORACLE                                                 |
-- +===================================================================================+
-- | Name        :                                                                     |
-- | Description : This Package is used to update the payment flag of the credit card  | 
-- |                transactions having description as 'LATE PAYMENT CHARGES'          |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 02-JAN-2019  Bhargavi Ankolekar     Initial draft version                |
-- +===================================================================================+

P_START_DATE VARCHAR2(30);
P_END_DATE VARCHAR2(30);
L_START_DATE VARCHAR2(30):=P_START_DATE; 
L_END_DATE VARCHAR2(30):=P_START_DATE;

PROCEDURE XX_AP_MAIN_CCUPDATE_FLAG( X_ERRBUFF OUT VARCHAR2,
                           X_RETCODE OUT NUMBER,
                            P_START_DATE IN VARCHAR2,
                            P_END_DATE IN VARCHAR2,
	                        P_MODE IN VARCHAR2,
	                        P_EMAIL IN VARCHAR2);

PROCEDURE CC_UPDATE_PAYMENT_FLAG(P_START_DATE IN VARCHAR2,
                            P_END_DATE IN VARCHAR2);
  
PROCEDURE CC_BEFORE_UPDATE_REPORT(P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2,
   P_MAIL IN VARCHAR2);

   PROCEDURE CC_AFTER_UPDATE_REPORT(P_START_DATE IN VARCHAR2 ,
    P_END_DATE   IN VARCHAR2);
   
END XX_AP_CCUP_PAYFLAG_PKG;
/