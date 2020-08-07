SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE XX_CS_UWQ_DTLS_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_UWQ_DTLS                                           |
-- | Rice ID : E1254                                                   |
-- | Description: This package contains the function that determines   |
-- |              Remaining Time to Resolve, Response and Elapsed Time.|
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-Jul-07   Raj Jagarlamudi  Initial draft version       |
-- |1.1       11-Aug-07   Raj Jagarlamudi  Added Get time functions    |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

FUNCTION GET_TMZ_PRIORITY(p_sr_tm_id NUMBER,
                          P_CAL_ID IN VARCHAR2)
RETURN NUMBER;

FUNCTION GET_TIME_TO_DISP(p_tm_code VARCHAR2,
                          p_sr_time_by DATE,
                          P_CAL_ID IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION get_elapsed_time (p_timezone_id in varchar2,
                            p_creation_date in date,
                            P_CAL_ID IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION  GET_HOURS (P_CAL_ID IN VARCHAR2,
                    P_BAL_DAYS IN NUMBER,
                    P_REQ_DATE IN DATE,
                    P_SYS_DATE IN DATE)
RETURN NUMBER;   

FUNCTION GET_FIRST(p_row_no NUMBER,
                   p_incident_id NUMBER,
                   p_group_name VARCHAR2 ) RETURN NUMBER;

END XX_CS_UWQ_DTLS_PKG;

/
SHOW ERRORS;
EXIT;