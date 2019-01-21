create or replace
PACKAGE XXCRM_CUST_ASSIGNMENTS_LOAD AS

  /* TODO enter package declarations (types, exceptions, methods etc) here */

  PROCEDURE start_process(x_errmsg  OUT NOCOPY VARCHAR2,
                        x_retcode OUT NUMBER
                    );           
  PROCEDURE main_process(x_errmsg  OUT NOCOPY VARCHAR2,
                        x_retcode OUT NUMBER,
                        p_startseq NUMBER,
                        p_endseq NUMBER
                    );           
FUNCTION XXTPS_CUSTASSIGNMENT_LOAD (
      p_customer_number       VARCHAR2,
      p_ship_to_id      VARCHAR2,
      p_rep_id  VARCHAR2)
RETURN VARCHAR2;

PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2,
    p_attribute1 IN VARCHAR2);

END XXCRM_CUST_ASSIGNMENTS_LOAD;
/