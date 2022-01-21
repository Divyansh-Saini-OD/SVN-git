SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_UI_VIEW_PKG

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE XX_AP_UI_VIEW_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_UI_VIEW_PKG.pks                                    |
-- | Description :  Plsql package for UI Views                               |
-- | RICE ID     :  E3522_OD Trade Match Foundation                          |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       18-Oct-2017 Paddy Sanjeevi     Initial version                 |
-- +=========================================================================+
AS

p_org_id			NUMBER;
p_vendor_id			NUMBER;
p_vendor_site_id	NUMBER;
p_employee_no		VARCHAR2(15);

FUNCTION xx_ap_ui_emp_summ_f return xx_ap_ui_emp_summ_t pipelined;

FUNCTION xx_ap_ui_empvnd_summ_f(p_org_id IN NUMBER,p_vendor_id IN NUMBER, p_vendor_site_id IN NUMBER, p_employee_no IN VARCHAR2)
return xx_ap_ui_empvnd_summ_t pipelined;

PROCEDURE xx_empvnd_set(p_org IN NUMBER,p_vendor IN NUMBER, p_vendor_site IN NUMBER, p_employee IN VARCHAR2);

FUNCTION get_org RETURN NUMBER;

FUNCTION get_p_vendor RETURN NUMBER;

FUNCTION get_p_vendor_site RETURN NUMBER;

FUNCTION get_p_employee RETURN VARCHAR2;

END;
/
SHOW ERRORS;
