SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_ESP_JOB_SCHEDULER 
-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                      Office Depot CDH Team                               |
-- +==========================================================================+
-- | Name        : XX_CDH_ESP_JOB_SCHEDULER                                   |
-- | Rice ID     : C0024 Conversions/Common View Loader                       |
-- | Description : Program used to control ESP Scheduling                     |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |1.0      12-Dec-2008 Indra Varada           Initial Version               |
-- |                                                                          |
-- +==========================================================================+
AS

FUNCTION get_downtime_start_date
 ( p_cdh_run_time_hrs  NUMBER
 ) RETURN VARCHAR2;

PROCEDURE MAIN (
      x_errbuf                OUT   VARCHAR2
     ,x_retcode               OUT   VARCHAR2 
    )
AS

l_program_run_value          VARCHAR2(100);
l_program_run_date           VARCHAR2(20);
l_program_run_time           VARCHAR2(20);
l_program_run_day            VARCHAR2(5);
l_down_time_start            VARCHAR2(20) := NULL;
l_down_time_start_date       DATE;
l_wait_time                  NUMBER;
l_cdh_run_time_hrs           NUMBER;
l_estimated_run_time         DATE;
BEGIN

  l_wait_time                  := NVL(fnd_profile.value('XX_CDH_SEAMLESS_WAIT_TIME'),30000);
  l_cdh_run_time_hrs           := NVL(fnd_profile.value('XX_CDH_CONV_RUN_TIME'),12);
  
  -- l_program_run_value  := TO_CHAR(SYSDATE,'DY MM/DD/YYYY HH24:MI:SS');
  
  l_down_time_start := get_downtime_start_date (l_cdh_run_time_hrs);
  
  fnd_file.put_line(fnd_file.log,'DownTime Value:' || l_down_time_start);
  
  l_estimated_run_time := SYSDATE + (l_cdh_run_time_hrs/24);
    
  IF l_down_time_start IS NOT NULL THEN
     
     l_down_time_start_date := TO_DATE(l_down_time_start,'MM/DD/YYYY HH24:MI:SS');
     
     IF l_estimated_run_time >= l_down_time_start_date THEN
       
       l_down_time_start_date := l_down_time_start_date - (1/48);

       WHILE SYSDATE < l_down_time_start_date LOOP
            USER_LOCK.SLEEP(l_wait_time);
       END LOOP;

     ELSE
       fnd_file.put_line(fnd_file.log,'Program Completed Without Any Waits');
     END IF;
     
  ELSE
    fnd_file.put_line(fnd_file.log,'Program Completed Without Any Waits'); 
  END IF;
  
EXCEPTION WHEN OTHERS THEN
 fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM);
 x_errbuf := 'UnExpected Error Occured In the Procedure - event_main : ' || SQLERRM;
 x_retcode := 2;  
END;

FUNCTION get_downtime_start_date( p_cdh_run_time_hrs NUMBER
      ) RETURN VARCHAR2
IS
l_start_time          DATE;
l_expected_end_time   DATE;
l_program_run_value   VARCHAR2(50);
l_program_run_day     VARCHAR2(5);
l_increment_dates     NUMBER := 0;
l_program_run_date    VARCHAR2(40);
l_down_time_start     VARCHAR2(40) := NULL;
l_ret_val             VARCHAR2(80) := NULL;

BEGIN
   /*IF INSTR(p_dat_val,'+') = 1 THEN
        RETURN TO_DATE(TO_CHAR(TO_DATE(p_program_run_date,'MM/DD/YYYY')+1,'MM/DD/YYYY')||' '||LTRIM(p_dat_val,'+'),'MM/DD/YYYY HH24:MI:SS');
     ELSE
        RETURN TO_DATE(p_program_run_date || ' ' || p_dat_val, 'MM/DD/YYYY HH24:MI:SS');
     END IF;*/

     WHILE l_increment_dates <= 6 LOOP
      l_program_run_value  := TO_CHAR(SYSDATE+l_increment_dates,'DY MM/DD/YYYY HH24:MI:SS');
      l_program_run_day    := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);
      l_program_run_value  := substr (l_program_run_value,INSTR(l_program_run_value,' ')+1); 
      l_program_run_date   := substr (l_program_run_value,0,INSTR(l_program_run_value,' ')-1);
      
      BEGIN
  
        SELECT target_value1 INTO l_down_time_start
        FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
        WHERE def.translate_id=val.translate_id
        AND   def.translation_name = 'XX_CDH_ENV_DOWN_TIMES'
        AND   NVL(val.source_value1,-1)=DECODE(val.source_value1,NULL,-1,l_program_run_date)
        AND   val.source_value2=l_program_run_day;
  
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      END;
      
      IF l_down_time_start IS NOT NULL THEN
         l_ret_val := l_program_run_date || ' ' || l_down_time_start;
         EXIT;
      END IF;
      
      l_increment_dates := l_increment_dates + 1;
     
     END LOOP; 

     RETURN l_ret_val;
     
END get_downtime_start_date;

END XX_CDH_ESP_JOB_SCHEDULER;
/
SHOW ERRORS;