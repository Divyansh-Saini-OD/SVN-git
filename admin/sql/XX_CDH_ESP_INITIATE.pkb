create or replace PACKAGE BODY XX_CDH_ESP_INITIATE AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ESP_INITIATE.pkb                            |
-- | Description :  Job To Initiate CDH ESP Schedule                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0      24-Nov-2008  Indra Varada       Initial version           |
-- |1.1      27-JAN-2019  Srinivas Reddy     Changed to replace user_lock 
--                                           to dbms_lock              |
-- +===================================================================+

FUNCTION get_downtime_start_date
(
 p_cdh_down_time_lag IN NUMBER
) RETURN DATE;

l_wait_time                    NUMBER;
l_cdh_down_time_lag            NUMBER;
l_down_time_start_date         DATE;
l_final_down_time_start_date   DATE;
l_current_time                 DATE := SYSDATE;

PROCEDURE get_chkpoint_values
(
 ps_chkpoint_name       IN  VARCHAR2
,p_chkpoint_run_time    OUT NUMBER
,p_force_run_flag       OUT VARCHAR2
,p_force_complete_flag  OUT VARCHAR2
,x_return_status        OUT VARCHAR2
,x_return_msg           OUT VARCHAR2
);

PROCEDURE initialize_values;

PROCEDURE MAIN (
      x_errbuf                OUT   VARCHAR2
     ,x_retcode               OUT   VARCHAR2
     ,p_chkpoint_name         IN    VARCHAR2
    )
AS

l_program_run_value               VARCHAR2(100);
l_program_run_date                VARCHAR2(20);
l_program_run_time                VARCHAR2(20);
l_program_run_day                 VARCHAR2(5);
l_chkpoint_run_time               NUMBER;
l_chkpoint_end_time               DATE;
l_force_run_flag                  VARCHAR2(2);
l_force_complete_flag             VARCHAR2(2);
user_terminate_exception          EXCEPTION;
method_call_exception             EXCEPTION;
l_reset_values                    BOOLEAN := FALSE;
l_return_status                   VARCHAR2(2) := 'S';
l_return_msg                      VARCHAR2(200);
BEGIN

  initialize_values;

  fnd_file.put_line(fnd_file.log,'DownTime Value:' || TO_CHAR(l_down_time_start_date,'DY MM/DD/YYYY HH24:MI:SS'));

  WHILE TRUE LOOP

       l_force_run_flag         := NULL;
       l_force_complete_flag    := NULL;
       l_chkpoint_end_time      := NULL;

      get_chkpoint_values (
         ps_chkpoint_name       => p_chkpoint_name,
         p_chkpoint_run_time    => l_chkpoint_run_time,
         p_force_run_flag       => l_force_run_flag,
         p_force_complete_flag  => l_force_complete_flag,
         x_return_status        => l_return_status,
         x_return_msg           => l_return_msg
       );

       IF l_return_status <> 'S' THEN
          RAISE method_call_exception;
       END IF;

       IF l_reset_values AND l_force_run_flag = 'N' THEN
              initialize_values;
              l_reset_values := FALSE;
              fnd_file.put_line (fnd_file.log,'Values are Reset: Current Time Reset To - ' || TO_CHAR(l_current_time,'DY MM/DD/YYYY HH24:MI:SS'));
       END IF;

       l_chkpoint_end_time          := l_current_time + (l_chkpoint_run_time/24);

      IF l_force_complete_flag NOT IN ('E','S') AND
         ((l_down_time_start_date IS NOT NULL AND l_chkpoint_end_time >= l_down_time_start_date AND SYSDATE < l_final_down_time_start_date)
         OR (l_force_run_flag = 'Y'))
      THEN
         IF l_force_run_flag = 'Y' THEN
            l_reset_values := TRUE;
         END IF;
         DBMS_LOCK.SLEEP(l_wait_time);
      ELSE
         EXIT;
      END IF;
  END LOOP;

 IF l_force_complete_flag = 'S' OR l_force_complete_flag = 'E' THEN
    RAISE user_terminate_exception;
 END IF;


EXCEPTION WHEN user_terminate_exception THEN
 fnd_file.put_line (fnd_file.log,'Program Terminated by user using the FIN Setup Options');
 IF l_force_complete_flag = 'E' THEN
     x_retcode := 2;
 END IF;
WHEN method_call_exception THEN
 fnd_file.put_line (fnd_file.log, l_return_msg);
 x_retcode := 2;
WHEN OTHERS THEN
 fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM);
 x_errbuf := 'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM;
 x_retcode := 2;
END;

FUNCTION get_downtime_start_date
(
 p_cdh_down_time_lag    IN  NUMBER
)RETURN DATE
IS
l_start_time          DATE;
l_expected_end_time   DATE;
l_program_run_value   VARCHAR2(50);
l_program_run_day     VARCHAR2(5);
l_increment_dates     NUMBER := 0;
l_program_run_date    VARCHAR2(40);
l_down_time_start     VARCHAR2(40) := NULL;
l_ret_date_val        DATE := NULL;
l_current_date        DATE := SYSDATE;

BEGIN


     WHILE l_increment_dates <= 6 LOOP

      l_program_run_value  := TO_CHAR(l_current_date+l_increment_dates,'DY MM/DD/YYYY HH24:MI:SS');
      l_program_run_day    := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);
      l_program_run_value  := substr (l_program_run_value,INSTR(l_program_run_value,' ')+1);
      l_program_run_date   := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);

      BEGIN

        SELECT target_value1 INTO l_down_time_start
        FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
        WHERE def.translate_id=val.translate_id
        AND   def.translation_name = 'XX_CRM_ENV_DOWN_TIMES'
        AND   NVL(val.source_value1,'X')=DECODE(val.source_value1,NULL,'X',l_program_run_date)
        AND   val.source_value2=l_program_run_day;

      EXCEPTION WHEN NO_DATA_FOUND THEN
       NULL;
      END;

      IF l_down_time_start IS NOT NULL THEN
         l_ret_date_val := TO_DATE(l_program_run_date || ' ' || l_down_time_start,'MM/DD/YYYY HH24:MI:SS');
         IF l_current_date < (l_ret_date_val + p_cdh_down_time_lag/1440)  THEN
           EXIT;
         ELSE
           l_down_time_start := NULL;
           l_ret_date_val    := NULL;
         END IF;
      END IF;

      l_increment_dates := l_increment_dates + 1;

     END LOOP;

     RETURN l_ret_date_val;

END get_downtime_start_date;

PROCEDURE get_chkpoint_values
(
 ps_chkpoint_name       IN  VARCHAR2
,p_chkpoint_run_time    OUT NUMBER
,p_force_run_flag       OUT VARCHAR2
,p_force_complete_flag  OUT VARCHAR2
,x_return_status        OUT VARCHAR2
,x_return_msg           OUT VARCHAR2
)
AS

BEGIN

  SELECT NVL(target_value1,0),NVL(UPPER(target_value2),'N'),NVL(UPPER(target_value3),'X')
  INTO p_chkpoint_run_time,p_force_run_flag,p_force_complete_flag
  FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
  WHERE def.translate_id=val.translate_id
  AND   def.translation_name = 'XX_CRM_ESP_CHKPOINTS'
  AND   source_value1 = ps_chkpoint_name;

EXCEPTION WHEN NO_DATA_FOUND THEN
 x_return_status := 'E';
 x_return_msg := 'Error In Method - get_chkpoint_values : FIN Translation Def - XX_CRM_ESP_CHKPOINTS is NOT Setup Properly';
END get_chkpoint_values;

PROCEDURE initialize_values
AS
BEGIN

l_wait_time                  := NVL(fnd_profile.value('XX_CDH_SEAMLESS_WAIT_TIME'),30000);
l_cdh_down_time_lag          := NVL(fnd_profile.value('XX_CDH_ENV_DOWN_TIME_LAG'),30);

l_down_time_start_date       := get_downtime_start_date
                                (l_cdh_down_time_lag
                                );
l_final_down_time_start_date := l_down_time_start_date + (l_cdh_down_time_lag/1440);
l_current_time               := SYSDATE;

END initialize_values;

END XX_CDH_ESP_INITIATE;
/
SHOW ERRORS;