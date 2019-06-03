CREATE OR REPLACE PACKAGE xx_po_log_errors_pkg AS

PROCEDURE po_log_errors ( p_error_process_date  DATE,
                          p_error_module_name   VARCHAR2,
                          p_error_event         VARCHAR2,
                          p_error_severity      VARCHAR2,
                          p_error_cde           VARCHAR2,
                          p_error_dsc           VARCHAR2,
                          p_error_user_id       NUMBER,
                          p_error_login_id      NUMBER   DEFAULT fnd_global.login_id,
                          p_error_attrib1       VARCHAR2 DEFAULT NULL,
                          p_error_attrib2       VARCHAR2 DEFAULT NULL,
                          p_error_attrib3       VARCHAR2 DEFAULT NULL,
                          p_error_attrib4       VARCHAR2 DEFAULT NULL,
                          p_error_attrib5       VARCHAR2 DEFAULT NULL,
                          p_error_attrib6       VARCHAR2 DEFAULT NULL);
END xx_po_log_errors_pkg;
