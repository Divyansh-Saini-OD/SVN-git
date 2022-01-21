create or replace 
PACKAGE      XX_AP_IEXP_CREDIT_ALERT
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AP_IEXP_CREDIT_ALERT                                         |
-- | Description : This Package will be executable code for the Daily processing report|                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Kirubha Samuel     Initial draft version                    |
-- +===================================================================================+
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                            ORACLE                                                 |
-- +===================================================================================+
-- | Name        : DATA_EXTRACT                                                        |
-- | Description : This Package is used to generate the iExpense Credit statement alert|
-- |                and also to purge them.                                            |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 21-JUN-2010  Kirubha Samuel     Initial draft version                    |
-- |          21-JUN-2018  Bhargavi Ankolekar    Added a description and start date    | 
-- |                                             as per the jira #50787                |
-- +===================================================================================+

P_END_DATE VARCHAR2(30);
P_mode VARCHAR2(20);
L_MODE  VARCHAR2(20) := P_MODE;
P_START_DATE VARCHAR2(30);
l_start_date VARCHAR2(30) :=p_start_date; ---- Added as per jira #50787
L_END_DATE VARCHAR2(30) :=P_END_DATE;
p_mail VARCHAR2(20);---- Added as per jira #50787
l_mail VARCHAR2(10) :=p_mail;

PROCEDURE  CREDIT_MAIN ( x_errbuff OUT VARCHAR2,
                           x_retcode OUT NUMBER,
                           P_mode VARCHAR2,
                           p_start_date VARCHAR2, -- Added as per the jira #50787
						   p_end_date VARCHAR2,
						   p_mail VARCHAR2);

PROCEDURE CREDIT_ALERT(p_start_date VARCHAR2,p_end_date VARCHAR2,p_mail varchar2);
PROCEDURE CREDIT_PURGE(p_start_date VARCHAR2,p_end_date VARCHAR2);
PROCEDURE CREDIT_PURGE_ALERT(p_end_date VARCHAR2,p_mail varchar2);
END;
/