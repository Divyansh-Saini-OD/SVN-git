CREATE OR REPLACE PACKAGE BODY xx_po_log_errors_pkg AS

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
                          p_error_attrib6       VARCHAR2 DEFAULT NULL) IS

  PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN

INSERT INTO xx_po_log_errors
    ( error_process_date
     ,error_module_name
     ,error_event
     ,error_severity
     ,error_cde
     ,error_dsc
     ,error_user_id
     ,error_login_id
     ,error_status
     ,error_attrib1
     ,error_attrib2
     ,error_attrib3
     ,error_attrib4
     ,error_attrib5
     ,error_attrib6
     ,error_log_time
    )
VALUES
    (p_error_process_date
     ,upper(p_error_module_name)
     ,p_error_event
     ,p_error_severity
     ,p_error_cde
     ,p_error_dsc
     ,p_error_user_id
     ,p_error_login_id
     ,'P'
     ,p_error_attrib1
     ,p_error_attrib2
     ,p_error_attrib3
     ,p_error_attrib4
     ,p_error_attrib5
     ,p_error_attrib6
     ,to_char(systimestamp,'hh24:mi:ss.ff6')
    );
COMMIT;
EXCEPTION
 WHEN OTHERS THEN
      raise_application_error(-20101, sqlerrm);
END po_log_errors;

END xx_po_log_errors_pkg;
/
