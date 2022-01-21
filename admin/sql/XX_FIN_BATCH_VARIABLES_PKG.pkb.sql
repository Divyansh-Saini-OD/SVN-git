create or replace 
PACKAGE BODY XX_FIN_BATCH_VARIABLES_PKG AS


-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_FIN_BATCH_VARIABLES_PKG                                                         |
-- |  Description:  This package is used to process variables used by batch jobs run by ESP     |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         08-Jan-2009  Joe Klein        Initial version                                  |
-- +============================================================================================+

-- ===========================================================================
-- function for getting any variable value                                    
-- ===========================================================================
  FUNCTION get
  (p_subtrack      IN VARCHAR2 DEFAULT NULL,
   p_variable_name IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2
  IS
   v_value VARCHAR2(240);
  BEGIN
    SELECT value INTO v_value 
      FROM XX_FIN_BATCH_VARIABLES
      WHERE subtrack = p_subtrack
      AND variable_name = p_variable_name;
    RETURN v_value;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN RETURN NULL;
  END get;


-- ===========================================================================
-- procedure for setting individual AP variable                                  
-- ===========================================================================
  PROCEDURE set_batch_single_variable_efap
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL)
  IS
    v_subtrack VARCHAR2(240) := 'EFAP';
  BEGIN
  UPDATE XX_FIN_BATCH_VARIABLES
    SET value = p_value
    WHERE subtrack = v_subtrack
     AND variable_name = p_variable_name;
    IF SQL%NOTFOUND THEN
      fnd_file.put_line(fnd_file.LOG,'Error: *** No variable ' || p_variable_name || ' found for subtrack ' || v_subtrack || ' ***');
    END IF;
  END set_batch_single_variable_efap;


-- ===========================================================================
-- procedure for setting individual AR variable                                  
-- ===========================================================================
  PROCEDURE set_batch_single_variable_efar
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL)
  IS
    v_subtrack VARCHAR2(240) := 'EFAR';
  BEGIN
  UPDATE XX_FIN_BATCH_VARIABLES
    SET value = p_value
    WHERE subtrack = v_subtrack
     AND variable_name = p_variable_name;
    IF SQL%NOTFOUND THEN
      fnd_file.put_line(fnd_file.LOG,'Error: *** No variable ' || p_variable_name || ' found for subtrack ' || v_subtrack || ' ***');
    END IF;
  END set_batch_single_variable_efar;


-- ===========================================================================
-- procedure for setting individual CE variable                                  
-- ===========================================================================
  PROCEDURE set_batch_single_variable_efce
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL)
  IS
    v_subtrack VARCHAR2(240) := 'EFCE';
  BEGIN
  UPDATE XX_FIN_BATCH_VARIABLES
    SET value = p_value
    WHERE subtrack = v_subtrack
     AND variable_name = p_variable_name;
    IF SQL%NOTFOUND THEN
      fnd_file.put_line(fnd_file.LOG,'Error: *** No variable ' || p_variable_name || ' found for subtrack ' || v_subtrack || ' ***');
    END IF;
  END set_batch_single_variable_efce;


-- ===========================================================================
-- procedure for setting individual GL variable                                  
-- ===========================================================================
  PROCEDURE set_batch_single_variable_efgl
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL)
  IS
    v_subtrack VARCHAR2(240) := 'EFGL';
  BEGIN
  UPDATE XX_FIN_BATCH_VARIABLES
    SET value = p_value
    WHERE subtrack = v_subtrack
     AND variable_name = p_variable_name;
    IF SQL%NOTFOUND THEN
      fnd_file.put_line(fnd_file.LOG,'Error: *** No variable ' || p_variable_name || ' found for subtrack ' || v_subtrack || ' ***');
    END IF;
  END set_batch_single_variable_efgl;


-- ===========================================================================
-- procedure for setting individual PA variable                                  
-- ===========================================================================
  PROCEDURE set_batch_single_variable_efpa
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_variable_name IN VARCHAR2 DEFAULT NULL,
   p_value IN VARCHAR2 DEFAULT NULL)
  IS
    v_subtrack VARCHAR2(240) := 'EFPA';
  BEGIN
  UPDATE XX_FIN_BATCH_VARIABLES
    SET value = p_value
    WHERE subtrack = v_subtrack
     AND variable_name = p_variable_name;
    IF SQL%NOTFOUND THEN
      fnd_file.put_line(fnd_file.LOG,'Error: *** No variable ' || p_variable_name || ' found for subtrack ' || v_subtrack || ' ***');
    END IF;
  END set_batch_single_variable_efpa;


-- ===========================================================================
-- procedure for setting AP batch variables                                   
-- ===========================================================================
  PROCEDURE set_batch_variables_efap
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_procdate IN DATE DEFAULT SYSDATE)
  IS
    v_subtrack VARCHAR2(240) := 'EFAP';
  BEGIN

    --Variable FM1CCYYMMDD (fiscal month start date)
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(start_date,'YYYY/MM/DD HH24:MI:SS')
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'FM1CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'FM1CCYYMMDD',(SELECT to_char(start_date,'YYYY/MM/DD HH24:MI:SS')
                                    FROM apps.gl_periods
                                    WHERE p_procdate BETWEEN start_date
                                    AND end_date
                                    AND period_set_name = 'OD 445 CALENDAR'
                                  )
              );
    END IF;

    --Variable APXIIMPT_DEBUG
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value = CASE value WHEN 'Y' THEN 'Y' ELSE 'N' END
      WHERE subtrack = v_subtrack
       AND variable_name = 'APXIIMPT_DEBUG';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'APXIIMPT_DEBUG','N');
    END IF; 

    --Variable LESS01CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS01CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS01CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable LESS02CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -2),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS02CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS02CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -2),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable LESS03CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -3),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS03CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS03CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -3),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable LESS04CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -4),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS04CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS04CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -4),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable LESS05CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -5),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS05CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS05CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -5),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;
     
    --Variable LESS06CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -6),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS06CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS06CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -6),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable PLUS01CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate +1),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PLUS01CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PLUS01CCYYMMDD',(SELECT to_char(TRUNC(p_procdate +1),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable PLUS02CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate +2),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PLUS02CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PLUS02CCYYMMDD',(SELECT to_char(TRUNC(p_procdate +2),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable PLUS03CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate +3),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PLUS03CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PLUS03CCYYMMDD',(SELECT to_char(TRUNC(p_procdate +3),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable PROCDATE
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PROCDATE';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PROCDATE',(SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;
        
  END set_batch_variables_efap;


-- ===========================================================================
-- procedure for setting AR batch variables                                   
-- ===========================================================================
  PROCEDURE set_batch_variables_efar
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_procdate IN DATE DEFAULT SYSDATE)
  IS
    v_subtrack VARCHAR2(240) := 'EFAR';
  BEGIN

    --Variable PER_CUR_MMM_YY
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT period_name
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'PER_CUR_MMM_YY';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PER_CUR_MMM_YY',(SELECT period_name
                                            FROM apps.gl_periods
                                            WHERE p_procdate BETWEEN start_date
                                            AND end_date
                                            AND period_set_name = 'OD 445 CALENDAR')
              );
    END IF;

  END set_batch_variables_efar;


-- ===========================================================================
-- procedure for setting CE batch variables                                   
-- ===========================================================================
  PROCEDURE set_batch_variables_efce
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_procdate IN DATE DEFAULT SYSDATE)
  IS
    v_subtrack VARCHAR2(240) := 'EFCE';
  BEGIN

    --Variable PROCDATE
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PROCDATE';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PROCDATE',(SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable LESS01CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS01CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS01CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;
    
      --Variable LESS07CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -7),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS07CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS07CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

 --Variable LESS90CCYYMMDD
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate -90),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'LESS90CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'LESS90CCYYMMDD',(SELECT to_char(TRUNC(p_procdate -1),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;
    
    --Variable PER_CUR_MMM_YY
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT period_name
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'PER_CUR_MMM_YY';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PER_CUR_MMM_YY',(SELECT period_name
                                            FROM apps.gl_periods
                                            WHERE p_procdate BETWEEN start_date
                                            AND end_date
                                            AND period_set_name = 'OD 445 CALENDAR')
              );
    END IF;

  END set_batch_variables_efce;


-- ===========================================================================
-- procedure for setting GL batch variables                                   
-- ===========================================================================
  PROCEDURE set_batch_variables_efgl
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_procdate IN DATE DEFAULT SYSDATE)
  IS
    v_subtrack VARCHAR2(240) := 'EFGL';
  BEGIN

    --Variable PROCDATE
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PROCDATE';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PROCDATE',(SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;

    --Variable PROCDATE2
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate),'MM-DD-YYYY')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PROCDATE2';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PROCDATE2',(SELECT to_char(TRUNC(p_procdate),'MM-DD-YYYY') FROM dual));
    END IF;

    --Variable FY (fiscal year)
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(period_year)
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'FY';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'FY',(SELECT to_char(period_year)
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR'));
    END IF;

    --Variable FM1CCYYMMDD (fiscal month start date)
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(start_date,'YYYY/MM/DD HH24:MI:SS')
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'FM1CCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'FM1CCYYMMDD',(SELECT to_char(start_date,'YYYY/MM/DD HH24:MI:SS')
                                    FROM apps.gl_periods
                                    WHERE p_procdate BETWEEN start_date
                                    AND end_date
                                    AND period_set_name = 'OD 445 CALENDAR'
                                  )
              );
    END IF;
    
    --Variable FMPE (previous fiscal month end date)
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(end_date,'YYYY/MM/DD HH24:MI:SS')
       FROM apps.gl_periods
       WHERE end_date = (SELECT start_date -1
                          FROM apps.gl_periods
                          WHERE sysdate BETWEEN start_date
                          AND end_date
                          AND period_set_name = 'OD 445 CALENDAR')
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'FMPE';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'FMPE',(SELECT to_char(end_date,'YYYY/MM/DD HH24:MI:SS')
                                  FROM apps.gl_periods
                                  WHERE end_date = (SELECT start_date -1
                                                    FROM apps.gl_periods
                                                    WHERE sysdate BETWEEN start_date
                                                    AND end_date
                                                    AND period_set_name = 'OD 445 CALENDAR')
                                  AND period_set_name = 'OD 445 CALENDAR')
              );
    END IF;

    --Variable PER_CUR_MMM_YY
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT period_name
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'PER_CUR_MMM_YY';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PER_CUR_MMM_YY',(SELECT period_name
                                            FROM apps.gl_periods
                                            WHERE p_procdate BETWEEN start_date
                                            AND end_date
                                            AND period_set_name = 'OD 445 CALENDAR')
              );
    END IF;

  END set_batch_variables_efgl;


-- ===========================================================================
-- procedure for setting PA batch variables                                   
-- ===========================================================================
  PROCEDURE set_batch_variables_efpa
  (errbuff OUT NOCOPY VARCHAR2,
   retcode OUT NOCOPY VARCHAR2,
   p_procdate IN DATE DEFAULT SYSDATE)
  IS
    v_subtrack VARCHAR2(240) := 'EFPA';
  BEGIN

    --Variable PROCDATE
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS')
       FROM dual)
    WHERE subtrack = v_subtrack
     AND variable_name = 'PROCDATE';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'PROCDATE',(SELECT to_char(TRUNC(p_procdate),'YYYY/MM/DD HH24:MI:SS') FROM dual));
    END IF;
        
    --Variable FMECCYYMMDD (fiscal month end date)
    UPDATE XX_FIN_BATCH_VARIABLES
    SET value =
      (SELECT to_char(end_date,'YYYY/MM/DD HH24:MI:SS')
       FROM apps.gl_periods
       WHERE p_procdate BETWEEN start_date
       AND end_date
       AND period_set_name = 'OD 445 CALENDAR')
    WHERE subtrack = v_subtrack
     AND variable_name = 'FMECCYYMMDD';
    IF SQL%NOTFOUND THEN
       INSERT INTO XX_FIN_BATCH_VARIABLES
       VALUES (v_subtrack,'FMECCYYMMDD',(SELECT to_char(end_date,'YYYY/MM/DD HH24:MI:SS')
                                    FROM apps.gl_periods
                                    WHERE p_procdate BETWEEN start_date
                                    AND end_date
                                    AND period_set_name = 'OD 445 CALENDAR'
                                  )
              );
    END IF;

  END set_batch_variables_efpa;


END XX_FIN_BATCH_VARIABLES_PKG;