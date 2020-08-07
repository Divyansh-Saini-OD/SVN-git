create or replace
PACKAGE BODY XXOD_CRM_SR_PKG
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
-- |DRAFT 1A  23-OCT-2007 Christina S        Initial draft version     |
-- |                                                                   |
-- +===================================================================+
AS
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
RETURN VARCHAR2
IS
-- Local Declaration of variables
ln_old_group_id  NUMBER;
ln_new_group_id  NUMBER;
lc_reassign_flag VARCHAR2(1);
BEGIN
BEGIN
    SELECT group_id
    INTO ln_old_group_id
    FROM CS_INCIDENTS_AUDIT_B CIAB
    WHERE CIAB.incident_id   = p_incident_id
    AND   CIAB.old_group_id  IS NULL
    AND   CIAB.group_id      IS NOT NULL;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'XXCRM'  ,'XX_CRM_0001_SR_GROUP_NOT_FOUND' );
        FND_MESSAGE.SET_TOKEN('ERR_INCIDENT_ID',p_incident_id);
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME( 'XXCRM'  ,'XX_CRM_0002_REASSIGN_ERR' );
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
END;
BEGIN
    SELECT NVL(owner_group_id,0)
    INTO  ln_new_group_id
    FROM  cs_incidents CI
    WHERE CI.incident_id = p_incident_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME ( 'XXCRM'  ,'XX_CRM_0001_SR_GROUP_NOT_FOUND' );
        FND_MESSAGE.SET_TOKEN('ERR_INCIDENT_ID',p_incident_id);
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ( 'XXCRM'  ,'XX_CRM_0002_REASSIGN_ERR' );
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
END;

    IF(ln_old_group_id = ln_new_group_id) THEN
        lc_reassign_flag := 'N';
    ELSE
        lc_reassign_flag := 'Y';
    END IF;
    RETURN lc_reassign_flag;
END IS_REASSIGNED;
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
FUNCTION GET_TIME_DIFF (
                         p_start_date IN DATE DEFAULT NULL
                        ,p_end_date IN DATE   DEFAULT NULL
                        ,p_cal_id IN VARCHAR2 DEFAULT NULL
                        )
RETURN VARCHAR2
AS
-- Local Declaration of variables
lc_days              VARCHAR2(10);
lc_hours             VARCHAR2(10);
lc_min               VARCHAR2(10);
ld_first_day         DATE;
ld_last_day          DATE;
ln_business_hrs      NUMBER;
ln_total_hrs         NUMBER;
ln_last_day_hrs      NUMBER;
ln_first_day_hrs     NUMBER;
BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,p_start_date);
    FND_FILE.PUT_LINE(FND_FILE.LOG,p_end_date);
    IF (p_cal_id IS NOT NULL) THEN
        -- The following query fetches the first and last business days
        SELECT TRUNC(MIN(calendar_date)),TRUNC(MAX(calendar_date)),COUNT(calendar_date) * gn_business_hours
        INTO   ld_first_day,ld_last_day,ln_business_hrs
        FROM   bom_calendar_dates BCD
        WHERE  BCD.calendar_code = p_cal_id
        AND    TRUNC(BCD.calendar_date) BETWEEN TRUNC(p_start_date) AND TRUNC(p_end_date)
        AND    NOT EXISTS ( SELECT 'x'
                        FROM bom_calendar_exceptions
                        WHERE calendar_code = BCD.calendar_code
                        AND  exception_date = BCD.calendar_date
                        AND exception_set_id = BCD.exception_set_id
                       );
       -- To check if SR was created on a business day.
       IF TRUNC(p_start_date) = ld_first_day THEN
           IF p_start_date <= TO_DATE(TO_CHAR(ld_first_day,'DD-MON-RRRR')||' 08:30:00', 'DD-MON-RRRR HH24:MI:SS') THEN
               ln_first_day_hrs := 0;
           ELSIF p_start_date >= TO_DATE(TO_CHAR(ld_first_day,'DD-MON-RRRR')||' 17:00:00', 'DD-MON-RRRR HH24:MI:SS') THEN
               ln_first_day_hrs := gn_business_hours;
           ELSIF    p_start_date < TO_DATE(TO_CHAR(ld_first_day,'DD-MON-RRRR')||' 17:00:00', 'DD-MON-RRRR HH24:MI:SS')
               AND p_start_date > TO_DATE(TO_CHAR(ld_first_day,'DD-MON-RRRR')||' 08:30:00', 'DD-MON-RRRR HH24:MI:SS') THEN
                  SELECT (p_start_date - TO_DATE(TO_CHAR(ld_first_day,'DD-MON-RRRR')||' 08:30:00', 'DD-MON-RRRR HH24:MI:SS') )*24
                  INTO  ln_first_day_hrs
                  FROM dual;
           END IF;
       END IF;
       -- To check if SR was closed on business day
       IF TRUNC(p_end_date) = ld_last_day THEN
         IF p_end_date <= TO_DATE(TO_CHAR(ld_last_day,'DD-MON-RRRR')||' 08:30:00', 'DD-MON-RRRR HH24:MI:SS') THEN
              ln_last_day_hrs := gn_business_hours;
         ELSIF p_end_date >= TO_DATE(TO_CHAR(ld_last_day,'DD-MON-RRRR')||' 17:00:00', 'DD-MON-RRRR HH24:MI:SS') THEN
              ln_last_day_hrs := 0;
         ELSIF    p_end_date < TO_DATE(TO_CHAR(ld_last_day,'DD-MON-RRRR')||' 17:00:00', 'DD-MON-RRRR HH24:MI:SS')
            AND p_end_date > TO_DATE(TO_CHAR(ld_last_day,'DD-MON-RRRR')||' 08:30:00', 'DD-MON-RRRR HH24:MI:SS') THEN
                SELECT (TO_DATE(TO_CHAR(ld_last_day,'DD-MON-RRRR')||' 17:00:00', 'DD-MON-RRRR HH24:MI:SS') - p_end_date)*24
                INTO  ln_last_day_hrs
                FROM dual;
        END IF;
      END IF;
      --Get the total number of productive hours on the SR.
      ln_total_hrs := NVL(ln_business_hrs,0) - NVL(ln_first_day_hrs,0) - NVL(ln_last_day_hrs,0);
      lc_days      := FLOOR(ln_total_hrs/gn_business_hours)||'d ';
      lc_hours     := FLOOR(MOD(ln_total_hrs,gn_business_hours))||'h ';
      lc_min       := ROUND((MOD(ln_total_hrs,gn_business_hours)- FLOOR(MOD(ln_total_hrs,gn_business_hours)))*60)||'m';
      RETURN lc_days||lc_hours||lc_min;
    ELSE
        FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0010_CAL_NOT_FOUND');
        gc_error_message      := FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0004_GET_TIME_DIFF_ERR');
    gc_sqlcode            := SQLCODE;
    gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
    gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
    FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
    RETURN NULL;

END GET_TIME_DIFF;

-- +===================================================================+
-- | Name           : GET_MINS                                         |
-- | Description    : Converts the parameter from D:H:M format to      |
-- |                  minutes format.                                  |
-- | Parameters     : p_time                                           |
-- |                                                                   |
-- | Returns        : NUMBER                                           |
-- |                                                                   |
-- +===================================================================+
FUNCTION GET_MINS (p_time IN VARCHAR2 DEFAULT NULL)
RETURN NUMBER
AS
   -- Local Declaration of variables
   ln_time   NUMBER;
   ln_days   NUMBER;
   ln_hours  NUMBER;
   ln_mnts   NUMBER;
BEGIN
    IF (p_time IS NOT NULL) THEN
      ln_days := SUBSTR(p_time,1,(INSTR(p_time, 'd')-1));
      ln_hours := SUBSTR(p_time
                    ,(INSTR(p_time,'d')+2)
                    ,(INSTR(p_time,'h')-INSTR(p_time,'d')-2)
                   );
      ln_mnts :=  SUBSTR(p_time
                    ,(INSTR(p_time,'h')+2)
                    ,(INSTR(p_time,'m')-INSTR(p_time,'h')-2)
                   );
      ln_time  := (ln_days * gn_business_hours * 60) + (ln_hours * 60) + ln_mnts;
    RETURN ln_time;
    ELSE
        FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0009_INPUT_PARAM_ERR');
        FND_MESSAGE.SET_TOKEN('ERR_FUNC','GET_MINS');
        gc_error_message      := FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0005_GET_MINS_ERR');
    gc_sqlcode            := SQLCODE;
    gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
    gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
    FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
    RETURN NULL;
END GET_MINS;

-- +===================================================================+
-- | Name           : DISPLAY_DATE                                     |
-- | Description    : Converts the parameter from Minutes format to    |
-- |                  D:H:M format                                     |
-- | Parameters     : p_time                                           |
-- |                                                                   |
-- | Returns        : VARCHAR2                                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION DISPLAY_DATE (p_time IN NUMBER DEFAULT NULL)
RETURN VARCHAR2
AS
   ln_days   NUMBER;
   ln_hours  NUMBER;
   ln_mins   NUMBER;
   ln_hours_mins NUMBER :=0;
BEGIN
    IF (p_time IS NOT NULL) THEN
        ln_days  := TRUNC((p_time/60)/gn_business_hours);
        ln_hours := TRUNC((p_time/60));
        IF ln_hours < (ln_days * gn_business_hours) THEN
            ln_hours := 0;
        ELSE
            ln_hours_mins := (p_time/60) - (ln_days * gn_business_hours);
            ln_hours := TRUNC(((p_time/60) - (ln_days * gn_business_hours)));
        END IF;
        ln_mins  := TRUNC(MOD((ln_hours_mins * 60),60));
        RETURN ln_days||'d '||ln_hours||'h '||ln_mins||'m';
    ELSE
        FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0009_INPUT_PARAM_ERR');
        FND_MESSAGE.SET_TOKEN('ERR_FUNC','DISPLAY_DATE');
        gc_error_message      := FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0003_DISPLAY_DATE_ERR');
        gc_sqlcode            := SQLCODE;
        gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
END DISPLAY_DATE;

-- +===================================================================+
-- | Name           : CONVERT_TIME                                     |
-- | Description    : Converts the input date-time to corresponding    |
-- |                  date-time in Client time zone.                   |
-- | Parameters     : P_DATE                                           |
-- |                                                                   |
-- | Returns        : DATE                                             |
-- |                                                                   |
-- +===================================================================+
FUNCTION CONVERT_TIME(P_DATE IN DATE DEFAULT NULL )
RETURN DATE
AS
ld_date  DATE;
lc_server_tzcode VARCHAR2(100);
lc_client_tzcode VARCHAR2(100);
BEGIN
   IF (P_DATE IS NOT NULL) THEN
       BEGIN
           SELECT timezone_code
           INTO lc_server_tzcode
           FROM fnd_timezones_b
           WHERE upgrade_tz_id = fnd_profile.value('SERVER_TIMEZONE_ID');
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0011_SERVER_TIMEZONE');
               gc_sqlcode            := SQLCODE;
               gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
               gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
               FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
       END;
       BEGIN
           SELECT timezone_code
           INTO lc_client_tzcode
           FROM fnd_timezones_b
           WHERE upgrade_tz_id = fnd_profile.value('CLIENT_TIMEZONE_ID');
       EXCEPTION
           WHEN NO_DATA_FOUND THEN
               FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0012_CLIENT_TIMEZONE');
               gc_sqlcode            := SQLCODE;
               gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
               gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
               FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
       END;
       SELECT NVL(fnd_timezone_pub.adjust_datetime(   P_DATE
                                                     ,lc_server_tzcode
                                                     ,lc_client_tzcode
                                                )
              ,TRUNC(SYSDATE))
       INTO ld_date
       FROM DUAL;
       RETURN ld_date;
    ELSE
        FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0009_INPUT_PARAM_ERR');
        FND_MESSAGE.SET_TOKEN('ERR_FUNC','CONVERT_TIME');
        gc_error_message      := FND_MESSAGE.GET;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN NULL;
   END IF;
EXCEPTION
    WHEN OTHERS THEN
    FND_MESSAGE.SET_NAME ('XXCRM','XX_CRM_0006_CONVERT_TIME_ERR');
    gc_sqlcode            := SQLCODE;
    gc_sqlerrm            := SUBSTR(SQLERRM,1,250);
    gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
    FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
    RETURN NULL;
END CONVERT_TIME;

-- +===================================================================+
-- | Name           : SR_SLA                                           |
-- | Description    : Checks whether the SR meets the SLA by comparing |
-- |                  resolved_on date and resolved_by date.           |
-- | Parameters     : P_SR_NUMBER                                      |
-- |                                                                   |
-- | Returns        : NUMBER                                           |
-- |                                                                   |
-- +===================================================================+
FUNCTION SR_SLA(p_sr_number  IN VARCHAR2 DEFAULT NULL )
RETURN NUMBER
AS
ld_resolved_by  DATE;
ld_resolved_on  DATE;
BEGIN
BEGIN
SELECT  expected_resolution_date
       ,incident_resolved_date
INTO   ld_resolved_by
      ,ld_resolved_on
FROM   cs_incidents_all_b
WHERE  incident_number = p_sr_number;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'XXCRM'  ,'XX_CRM_0007_SR_NOT_FOUND' );
        FND_MESSAGE.SET_TOKEN('ERR_SR_NUMBER' , p_sr_number);
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN 0;
    WHEN OTHERS THEN
        FND_MESSAGE.SET_NAME ( 'XXCRM'  ,'XX_CRM_0008_SR_SLA_ERR' );
        gc_sqlcode := SQLCODE;
        gc_sqlerrm := SUBSTR(SQLERRM,1,250);
        gc_error_message      := FND_MESSAGE.GET||' '||gc_sqlcode||' '||gc_sqlerrm;
        FND_FILE.PUT_LINE(FND_FILE.LOG,gc_error_message);
        RETURN 0;
END;

IF NVL(ld_resolved_on,SYSDATE) <= ld_resolved_by THEN
    RETURN 1;
ELSE
    RETURN 0;
END IF;
END SR_SLA;

END XXOD_CRM_SR_PKG;
