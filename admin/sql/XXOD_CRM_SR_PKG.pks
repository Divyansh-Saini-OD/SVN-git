SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XXOD_CRM_SR_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name         : XXOD_CRM_SR_PKG                                    |
-- | Rice ID      : CTR Reports                                        |
-- | Description  : This package contains functions which are used in  |
-- |                the C2R Reports.                                   |
-- |              1.IS_REASSIGNED - Checks whether the Service Request |
-- |                has been reassigned to other Group or not.         |
-- |              2.GET_TIME_DIFF - Computes the Time taken to         |
-- |                respond and resolve the service requests.          |
-- |              3.GET_MINS - Converts the parameter from D:H:M format|
-- |                minutes format.                                    |
-- |              4.DISPLAY_DATE - Converts the parameter from Minutes |
-- |                format to D:H:M format                             |
-- |              5.CONVERT_TIME - Converts the input date-time to     |
-- |                corresponding date-time in Client time zone.       |
-- |              6.SR_SLA - Checks whether the SR meets the SLA by    |
-- |                comparing resolved_on date and resolved_by date.   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  23-OCT-2007 Christina S      Initial draft version       |
-- |          11-NOV-2009 Bala E	       Added function              |
-- |      1.1 22-MAY-2014 Jay Gupta        Defect#30029 - working hr -9|
-- +===================================================================+
IS

-- Declaration of Global Variables
gn_business_hours       NUMBER := 9.0; --V1.1 8.5; -- Used in calculation instead of Working Hours(from 8.30 AM to 5 PM).
gc_sqlcode              VARCHAR2 (100);
gc_sqlerrm              VARCHAR2 (300);
gc_error_message        VARCHAR2 (2000);

-- +===================================================================+
-- | Name           : IS_REASSIGNED                                    |
-- | Description    : Gets the Old Group Id and compares with last     |
-- |                  updated group id and assigns value to the        |
-- |                  reassign_flag of the Service Request.            |
-- | Parameters     : p_incident_id                                    |
-- |                                                                   |
-- | Returns        : VARCHAR2                                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION IS_REASSIGNED(p_incident_id cs_incidents_all_b.incident_id%TYPE DEFAULT NULL)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name           : GET_TIME_DIFF                                    |
-- | Description    : Calculates the time taken to respond or resolve  |
-- |                  the service request.                             |
-- | Parameters     : p_start_date                                     |
-- |                  p_end_date                                       |
-- |                  p_tm_code                                        |
-- |                  p_cal_id                                         |
-- |                                                                   |
-- | Returns        : VARCHAR2                                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION GET_TIME_DIFF(p_start_date IN DATE DEFAULT NULL
                       ,p_end_date   IN DATE DEFAULT NULL
                       ,p_cal_id     IN VARCHAR2 DEFAULT NULL
                      )
RETURN VARCHAR2;

-- +===================================================================+
-- | Name           : GET_MINS                                         |
-- | Description    : Converts the parameter from D:H:M format to      |
-- |                  minutes format.                                  |
-- | Parameters     : p_time                                           |
-- |                                                                   |
-- | Returns        : NUMBER                                           |
-- |                                                                   |
-- +===================================================================+
FUNCTION GET_MINS(p_time IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER;

-- +===================================================================+
-- | Name           : DISPLAY_DATE                                     |
-- | Description    : Converts the parameter from Minutes format to    |
-- |                  D:H:M format                                     |
-- | Parameters     : p_time                                           |
-- |                                                                   |
-- | Returns        : VARCHAR2                                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION DISPLAY_DATE(p_time IN NUMBER DEFAULT NULL)
RETURN VARCHAR2;

-- +===================================================================+
-- | Name           : CONVERT_TIME                                     |
-- | Description    : Converts the input date-time to corresponding    |
-- |                  date-time in Client time zone.                   |
-- | Parameters     : P_DATE                                           |
-- |                                                                   |
-- | Returns        : DATE                                             |
-- |                                                                   |
-- +===================================================================+
FUNCTION CONVERT_TIME(P_DATE IN DATE DEFAULT NULL)
RETURN DATE;

-- +===================================================================+
-- | Name           : SR_SLA                                           |
-- | Description    : Checks  whether the SR meets the SLA by comparing |
-- |                  resolved_on date and resolved_by date.           |
-- | Parameters     : P_SR_NUMBER                                      |
-- |                                                                   |
-- | Returns        : VARCHAR2                                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION SR_SLA(p_sr_number  IN VARCHAR2 DEFAULT NULL )
RETURN NUMBER;


FUNCTION GET_TIME_DIFFERENCE(p_start_date IN VARCHAR2 DEFAULT NULL
                       ,p_end_date   IN VARCHAR2 DEFAULT NULL
                       ,p_cal_id     IN VARCHAR2 DEFAULT NULL
                      )
RETURN VARCHAR2;


END XXOD_CRM_SR_PKG;
/
SHOW ERROR