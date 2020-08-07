CREATE OR REPLACE
PACKAGE BODY XX_CS_UWQ_DTLS_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_UWQ_DTLS_PKG                                           |
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

gc_exp_header       xx_om_global_exceptions.exception_header%TYPE  DEFAULT  'OTHERS';
gc_track_code       xx_om_global_exceptions.track_code%TYPE        DEFAULT  'OTC';
gc_sol_domain       xx_om_global_exceptions.solution_domain%TYPE   DEFAULT  'Sourcing';
gc_function         xx_om_global_exceptions.function_name%TYPE     DEFAULT  'E1254_UWQTimeZones';
gt_err_report_type  xx_om_report_exception_t;
gc_err_code         xx_om_global_exceptions.error_code%TYPE DEFAULT ' ';
gc_err_desc         xx_om_global_exceptions.description%TYPE DEFAULT ' ';
gc_entity_ref       xx_om_global_exceptions.entity_ref%TYPE;
gc_err_buf          VARCHAR2(240);
gc_ret_code         VARCHAR2(30);
gn_start_time       number;
gn_end_time         number;

gc_first_inc_id      NUMBER := 0;

/*************************************************************************
   Get Start and end times of the working day
**************************************************************************/
PROCEDURE GET_START_END (P_CAL_ID IN VARCHAR2,
                         P_DATE IN DATE,
                         X_START_TIME OUT NOCOPY NUMBER,
                         X_END_TIME   OUT NOCOPY NUMBER)
IS

BEGIN
  --x_start_time := 28800;
  --x_end_time   := 61200;

  BEGIN
    select b2.from_time, b2.to_time
    into   x_start_time, x_end_time
    from    bom_calendar_dates b1,
            bom_shift_times b2
    where b2.calendar_code = b1.calendar_code
    and    b1.calendar_code = P_CAL_ID
    and   trunc(b1.calendar_date) = trunc(p_date)
    and   b2.shift_num = 1
    and   not exists ( select 'x' from bom_calendar_exceptions
                    where calendar_code = b1.calendar_code
                    and  exception_date = b1.calendar_date
                    and  exception_set_id = b1.exception_set_id);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_start_time := 0;
      x_end_time   := 0;
    when others then
      gc_err_code := 'XX_OM_0001_UNKNOWN_ERROR';
      FND_MESSAGE.SET_NAME ('XXOM', 'XX_OM_0001_UNKNOWN_ERROR');
      FND_MESSAGE.SET_TOKEN('PARAM_NAME','E1254_UWQTimeZones');
      gc_err_desc := FND_MESSAGE.GET;
      gc_entity_ref:='E1254';
      gt_err_report_type :=
                      xx_om_report_exception_t (
                                                gc_exp_header
                                                ,gc_track_code
                                                ,gc_sol_domain
                                                ,gc_function
                                                ,gc_err_code
                                                ,SUBSTR(gc_err_desc,1,1000)
                                                ,gc_entity_ref
                                                ,0);
                  XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION (
                                                               gt_err_report_type
                                                               ,gc_err_buf
                                                               ,gc_ret_code
                                                              );
 END;

END;
/*************************************************************************
    Get Hours
************************************************************************/

FUNCTION GET_HOURS (P_CAL_ID IN VARCHAR2,
                    P_BAL_DAYS IN NUMBER,
                    P_REQ_DATE IN DATE,
                    P_SYS_DATE IN DATE)
RETURN NUMBER IS
lc_hours        number := 0;
lc_rem_date     date ;


BEGIN
   GN_START_TIME := 0;
   GN_END_TIME   := 0;
  -- First day
  IF P_BAL_DAYS = 0 THEN
    GET_START_END (P_CAL_ID => P_CAL_ID,
                  P_DATE   => P_SYS_DATE,
                  X_START_TIME => GN_START_TIME,
                  X_END_TIME   => GN_END_TIME);

    IF GN_START_TIME > 0 THEN
      IF to_number(to_char(p_sys_date,'HH24'))*3600 > gn_end_time then
        lc_hours := gn_end_time - to_number(to_char(p_req_date,'HH24'))*3600;
        lc_hours := lc_hours/3600;
      else
        lc_hours := to_number(to_char(p_sys_date,'HH24')) -
                    to_number(to_char(p_req_date,'HH24'));
      end if;
    ELSE
      lc_hours := 0;
    END IF;

  -- next day
  ELSIF P_BAL_DAYS = 1 THEN
    GET_START_END (P_CAL_ID => P_CAL_ID,
                  P_DATE   => P_SYS_DATE,
                  X_START_TIME => GN_START_TIME,
                  X_END_TIME   => GN_END_TIME);
    IF GN_START_TIME > 0 THEN
        if to_number(to_char(p_req_date,'HH24'))*3600 between gn_start_time and gn_end_time then
          lc_hours := gn_end_time - to_number(to_char(p_req_date,'HH24'))*3600;
          lc_hours := lc_hours/3600;
        else
          lc_hours := 0;
        end if;
        IF to_number(to_char(p_sys_date,'HH24'))*3600 > gn_end_time then
          lc_hours := lc_hours + 8;
        else
          lc_hours := lc_hours + (to_number(to_char(p_sys_date,'HH24'))*3600 - gn_start_time)/3600;
      end if;
    else
        lc_hours := 0;
    end if;

  -- Grater than 1 day
  elsif P_BAL_DAYS > 1 THEN
     GET_START_END (P_CAL_ID => P_CAL_ID,
                  P_DATE   => P_REQ_DATE,
                  X_START_TIME => GN_START_TIME,
                  X_END_TIME   => GN_END_TIME);
      IF GN_START_TIME > 0 THEN
       lc_hours := (gn_end_time - to_number(to_char(p_req_date,'HH24'))*3600)/3600;
      else
        lc_hours := 0;
      end if;

     lc_rem_date := p_req_date + 1;
     -- check wether working day or not
     for i in 1.. (P_BAL_DAYS -1) loop

        GET_START_END (P_CAL_ID => P_CAL_ID,
                  P_DATE   => lc_rem_date,
                  X_START_TIME => GN_START_TIME,
                  X_END_TIME   => GN_END_TIME);

        IF GN_START_TIME > 0 THEN
          lc_hours := lc_hours + 8;

        END IF;
        lc_rem_date := lc_rem_date + 1;
      end loop;

     -- last day
    lc_hours := lc_hours + (to_number(to_char(p_sys_date,'HH24'))*3600 - gn_start_time)/3600;

  end if;

  return lc_hours;
END;

/*************************************************************************
**************************************************************************/
  FUNCTION GET_TMZ_PRIORITY(p_sr_tm_id NUMBER,P_CAL_ID IN VARCHAR2)
  RETURN NUMBER AS
        lc_temp     DATE;
        lc_curtime  NUMBER;
  BEGIN
      GN_START_TIME := 0;
      GN_END_TIME   := 0;
      IF (p_sr_tm_id IS NOT NULL) AND (p_sr_tm_id > 1) THEN
         lc_temp := HZ_TIMEZONE_PUB.Convert_DateTime(1,p_sr_tm_id,sysdate);
      ELSE
         lc_temp := sysdate;
      END IF;
      lc_curtime := to_char(lc_temp,'hh24');
      GET_START_END (P_CAL_ID => P_CAL_ID,
                  P_DATE   => LC_TEMP,
                  X_START_TIME => GN_START_TIME,
                  X_END_TIME   => GN_END_TIME);
      IF GN_START_TIME > 0 THEN
        IF lc_curtime >= gn_start_time AND lc_curtime <= gn_end_time THEN
          RETURN 1;
         ELSE
          RETURN 2;
      END IF;
      ELSE
        RETURN 3;
      END IF;
  EXCEPTION
      WHEN OTHERS THEN
           RETURN 3;
  END GET_TMZ_PRIORITY;

/*****************************************************************************
******************************************************************************/
  FUNCTION GET_TIME_TO_DISP(p_tm_code VARCHAR2,
                            p_sr_time_by DATE,
                            P_CAL_ID IN VARCHAR2)
  RETURN VARCHAR2 AS
      lc_diff           NUMBER;
      lc_days           NUMBER;
      lc_hrs            NUMBER(9);
      lc_mins           NUMBER(9);
      lc_sr_date        date;
      lc_sys_date       date;
      lc_return_val     varchar2(50);
  BEGIN
   IF p_sr_time_by IS NOT NULL THEN
      lc_sr_date   := HZ_TIMEZONE_PUB.Convert_DateTime(p_tm_code,0,p_sr_time_by);
      lc_sys_date  := HZ_TIMEZONE_PUB.Convert_DateTime(p_tm_code,0,sysdate);

      lc_diff :=  lc_sys_date - lc_sr_date;
      lc_days := FLOOR(lc_diff);


      lc_hrs := GET_HOURS (P_CAL_ID => P_CAL_ID,
                                  P_BAL_DAYS => LC_DAYS,
                                  P_REQ_DATE => LC_SR_DATE,
                                  P_SYS_DATE => LC_SYS_DATE);

    --  dbms_output.put_line(' balance hours '||lc_hrs);
      lc_mins := (mod(lc_hrs,1)*60);
      lc_days := lc_hrs/24;
      lc_hrs := (mod(lc_days,1)*24);
      lc_days := floor(lc_days);
      lc_return_val := lc_days|| 'd ' || lc_hrs || 'h ' || lc_mins || 'm';
      RETURN LC_RETURN_VAL;
   ELSE
      RETURN NULL;
   END IF;

  END GET_TIME_TO_DISP;

/**************************************************************************/
/* FUNCTION  for elapsed time                                             */
/**************************************************************************/
FUNCTION get_elapsed_time (p_timezone_id in varchar2,
                            p_creation_date in date,
                            P_CAL_ID IN VARCHAR2)
RETURN VARCHAR2 IS

lc_balance        number;
lc_bal_days       number;
lc_bal_hours      number(9);
lc_bal_mins       number(9);
lc_return_val     varchar2(50);
lc_req_date       date;
lc_sys_date       date;

BEGIN
   lc_req_date  := HZ_TIMEZONE_PUB.Convert_DateTime(p_timezone_id,0,p_creation_date);
   lc_sys_date  := HZ_TIMEZONE_PUB.Convert_DateTime(p_timezone_id,0,sysdate);

   lc_balance   := lc_sys_date - lc_req_date;
 --  dbms_output.put_line (' balance '||lc_balance);
   lc_bal_days := FLOOR(lc_balance);
 --  dbms_output.put_line (' days '||lc_bal_days);
   lc_bal_hours := GET_HOURS (P_CAL_ID => P_CAL_ID,
                              P_BAL_DAYS => LC_BAL_DAYS,
                              P_REQ_DATE => LC_REQ_DATE,
                              P_SYS_DATE => LC_SYS_DATE);
  -- dbms_output.put_line(' hours '||lc_bal_hours);
   lc_bal_mins := (mod(lc_bal_hours,1)*60);
   lc_bal_days := lc_bal_hours/24;
   lc_bal_hours := (mod(lc_bal_days,1)*24);
   lc_bal_days := floor(lc_bal_days);
   lc_return_val := lc_bal_days|| 'd ' || lc_bal_hours || 'h ' || lc_bal_mins || 'm';
  return lc_return_val;

END;
/************************************************************************************/
FUNCTION GET_FIRST(p_row_no NUMBER,
                      p_incident_id NUMBER) RETURN NUMBER AS
  BEGIN
      IF p_row_no = 1 THEN
         gc_first_inc_id := p_incident_id;
      END IF;
      RETURN gc_first_inc_id;
  EXCEPTION
     WHEN OTHERS THEN
          RETURN 0;
  END GET_FIRST;

END XX_CS_UWQ_DTLS_PKG;
