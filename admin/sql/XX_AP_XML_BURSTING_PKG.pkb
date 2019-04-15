SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE Body XX_AP_XML_BURSTING_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_XML_BURSTING_PKG                                                           |
  -- |  RICE ID   :
  -- |  Description:  Common Report package for XML bursting                                      |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/10/2017   Digamber S       Initial version                                  |
  -- | 1.1         19-Mar-2019  Shanti Sethuraj  Added oracle instance name in the email subject  |
  -- |                                           for the jira NAIT-87655                          |
  -- | 1.2         15-Apr-2019 Shanti Sethuraj  Modifed for Jira NAIT-91067                      |
  -- +============================================================================================+
PROCEDURE GET_EMAIL_DETAIL(
    P_CONC_NAME VARCHAR2,
    P_SMTP_SERVER OUT VARCHAR2,
    P_EMAIL_SUBJECT OUT VARCHAR2,
    P_EMAIL_CONTENT OUT VARCHAR2,
    P_DISTRIBUTION_LIST OUT VARCHAR2)
IS
  L_EMAIL_SUBJECT     VARCHAR2(250);
  L_EMAIL_CONTENT     VARCHAR2(500);
  L_DISTRIBUTION_LIST VARCHAR2(500);
  L_SMTP_SERVER       VARCHAR2(250);
  l_instance_name     VARCHAR2(250); --added for jira NAIT-87655
BEGIN
  BEGIN
    SELECT XFTV.target_value2,
      XFTV.TARGET_VALUE3,
      XFTV.target_value4,
      FND_PROFILE.VALUE('XX_XDO_SMTP_HOST')
    INTO L_EMAIL_SUBJECT,
      L_EMAIL_CONTENT,
      L_DISTRIBUTION_LIST,
      L_SMTP_SERVER
    FROM xx_fin_translatedefinition XFTD ,
      xx_fin_translatevalues XFTV
    WHERE XFTD.translate_id   = xftv.translate_id
    AND XFTD.translation_name = 'XX_AP_TRADE_PAY_EMAIL'
    AND XFTV.source_value1    = p_conc_name -- 'TRADE_PAY_REPORT'
    AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active, sysdate+1)
    AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active, sysdate+1)
    AND XFTV.enabled_flag = 'Y'
    AND XFTD.enabled_flag = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
    L_EMAIL_SUBJECT     := p_conc_name||' Report';
    L_EMAIL_CONTENT     := 'Please find report attachment for '||p_conc_name||' Report';
    L_DISTRIBUTION_LIST := 'trade_notifications@officedepot.com';
    L_SMTP_SERVER       := FND_PROFILE.VALUE('XX_XDO_SMTP_HOST');
  END;
  SELECT instance_name INTO l_instance_name FROM v$instance; --added for jira NAIT-87655
  IF p_conc_name     ='XXAPBYPASSINV' THEN                        --added for jira NAIT-87655
    L_EMAIL_SUBJECT := l_instance_name ||' '|| L_EMAIL_SUBJECT ;  --added for jira NAIT-87655
  END IF;                                                         --added for jira NAIT-87655
  IF p_conc_name     ='XXAPPVARXML' THEN                               --added for jira NAIT-91067
    L_EMAIL_SUBJECT := l_instance_name ||' '|| L_EMAIL_SUBJECT ;       --added for jira NAIT-91067
  END IF;                                                              --added for jira NAIT-91067
  P_EMAIL_SUBJECT     := L_EMAIL_SUBJECT ;
  P_EMAIL_CONTENT     := L_EMAIL_CONTENT ;
  P_DISTRIBUTION_LIST :=L_DISTRIBUTION_LIST;
  P_SMTP_SERVER       := L_SMTP_SERVER;
END Get_email_detail;
END XX_AP_XML_BURSTING_PKG;
/
SHOW ERRORS;