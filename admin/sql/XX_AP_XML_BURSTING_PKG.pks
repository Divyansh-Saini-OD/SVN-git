SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_XML_BURSTING_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_XML_BURSTING_PKG                                                           |
  -- |                                              |
  -- |  Description:  Common Report package for XML bursting                                      |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   Digamber S       Initial version                                  |
  -- | 1.1         25-Aug-2020 Shanti Sethuraj  Modifled for jira NAIT-120526 and NAIT-120525     |
  -- +============================================================================================+
  g_SMTP_SERVER VARCHAR2(250);
  G_DISTRIBUTION_LIST VARCHAR2(500);
  G_EMAIL_SUBJECT     VARCHAR2(250);
  g_EMAIL_CONTENT     VARCHAR2(500);
  P_CONC_REQUEST_ID  		NUMBER;   -- added for jira NAIT-120526 and NAIT-120525
  P_HOLD_LOOKUP_CODe    varchar2(50);  -- added for jira NAIT-120526 and NAIT-120525 
  PROCEDURE Get_email_detail(
      P_CONC_NAME VARCHAR2,
      P_SMTP_SERVER OUT VARCHAR2,
      P_EMAIL_SUBJECT OUT VARCHAR2,
      P_EMAIL_CONTENT OUT VARCHAR2,
      P_DISTRIBUTION_LIST OUT VARCHAR2);
	  
	  --Added below two report functions for jira NAIT-120526 and NAIT-120525 
  FUNCTION beforeReport RETURN BOOLEAN;
  FUNCTION afterReport RETURN BOOLEAN;
END XX_AP_XML_BURSTING_PKG;
/

SHOW ERRORS;