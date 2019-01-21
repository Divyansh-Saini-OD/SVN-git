SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_URCOSTVAR_PKG

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE XX_AP_URCOSTVAR_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_URCOSTVAR_PKG.pks                                  |
-- | Description :  Plsql package for Unresolved Cost Variance Report        |
-- | RICE ID     :  R7036 OD AP Unresolved Cost Variances Report             |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       10-Oct-2017 Jitendra Atale     Initial version                 |
-- +=========================================================================+
AS

FUNCTION beforeReport RETURN BOOLEAN;
FUNCTION afterReport RETURN BOOLEAN;
g_DISTRIBUTION_LIST VARCHAR2(500);
G_EMAIL_SUBJECT     VARCHAR2(100);
g_EMAIL_CONTENT     VARCHAR2(240);
G_SMTP_SERVER       VARCHAR2(240);


END XX_AP_URCOSTVAR_PKG;
/
SHOW ERRORS;