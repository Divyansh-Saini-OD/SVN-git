create or replace
PACKAGE XXCRM_LOADTERRALIGNDATA AS
-- | Package Name: XXCRM_LOADTERRALIGNDATA
-- | Author: Mohan Kalyanasundaram
-- | 10/12/2007
-- +====================================================================+
  /* TODO enter package declarations (types, exceptions, methods etc) here */
  PROCEDURE log_exception
    (    p_program_name            IN VARCHAR2
        ,p_error_location          IN VARCHAR2
        ,p_error_status            IN VARCHAR2
        ,p_oracle_error_code       IN VARCHAR2
        ,p_oracle_error_msg        IN VARCHAR2
        ,p_error_message_severity  IN VARCHAR2
        ,p_attribute1              IN VARCHAR2
    );

  PROCEDURE main_proc(x_errmsg OUT NOCOPY VARCHAR2, x_retcode OUT NUMBER);

END XXCRM_LOADTERRALIGNDATA;
/