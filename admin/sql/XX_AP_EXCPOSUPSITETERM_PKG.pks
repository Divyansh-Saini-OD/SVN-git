SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_EXCPOSUPSITETERM_PKG
AS
-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name  :  XX_AP_EXCPOSUPSITETERM_PKG                                                       |
-- |  RICE ID   : R7037 AP Exceptions of PO vs Supplier Site Terms                              |
-- |  Description:  Common Report package for XML bursting                                      |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         11/10/2017   PrabeetSoy       Initial version                                  |
-- +============================================================================================+
P_START_DATE        DATE;
P_END_DATE          DATE;
g_DISTRIBUTION_LIST VARCHAR2(500);
G_EMAIL_SUBJECT     VARCHAR2(100);
g_EMAIL_CONTENT     VARCHAR2(240);
G_SMTP_SERVER       VARCHAR2(240);
FUNCTION beforeReport
  RETURN BOOLEAN;
FUNCTION afterReport
  RETURN BOOLEAN;
END XX_AP_EXCPOSUPSITETERM_PKG;
/

SHOW ERROR