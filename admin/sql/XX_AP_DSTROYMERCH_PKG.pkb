SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_DSTROYMERCH_PKG

WHENEVER SQLERROR CONTINUE
CREATE or REPLACE PACKAGE BODY XX_AP_DSTROYMERCH_PKG
  -- +=========================================================================+
  -- |                  Office Depot - Project Simplify                        |
  -- +=========================================================================+
  -- | Name        :  XX_AP_DSTROYMERCH_PKG.pkb                               |
  -- | Description :  Plsql package for Destroyed Merchandised Summary Report  |
  -- | RICE ID     :  R7034 OD: Destroyed Merchandise Summary Report                          |
  -- |Change Record:                                                           |
  -- |===============                                                          |
  -- |Version   Date        Author             Remarks                         |
  -- |========  =========== ================== ================================|
  -- |1.0       15-Oct-2017 Ragni Gupta        Initial version                 |
    -- +=======================================================================+
AS
FUNCTION beforeReport return boolean is  lv_start_date DATE := trunc(to_date(sysdate));
	lv_end_date DATE := trunc(to_date(sysdate));
  lv_qtr VARCHAR2(2);-- :=3;
  lv_month VARCHAR2(15);-- :='SEP-17';
  
  BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside before report - '||P_FREQUENCY);
  --G_where_clause:= ' and 1=1';
	IF P_START_DATE IS NOT NULL AND P_END_DATE IS NOT NULL THEN
		G_where_clause := ' and trunc(aia.creation_date) BETWEEN fnd_date.canonical_to_date(''' ||P_START_DATE || ''') and fnd_date.canonical_to_date(''' || P_END_DATE|| ''')';
  FND_FILE.PUT_LINE(FND_FILE.LOG,'G_where_clause - '||G_where_clause);
  
	ELSIF P_START_DATE IS NOT NULL AND P_END_DATE IS NULL THEN
		G_where_clause := ' and trunc(aia.creation_date) >= fnd_date.canonical_to_date(''' ||P_START_DATE|| ''')';

	ELSIF P_END_DATE IS NOT NULL AND P_START_DATE IS NULL THEN
		G_where_clause := ' and trunc(aia.creation_date) <= fnd_date.canonical_to_date(''' ||P_END_DATE|| ''')';

	ELSif P_END_DATE IS  NULL AND P_START_DATE IS NULL THEN
  
        BEGIN
        SELECT TO_CHAR(TO_DATE(sysdate, 'DD-MON-YY'), 'Q')INTO lv_qtr
        FROM DUAL;
        
        SELECT TO_CHAR(sysdate, 'MON-YY') INTO lv_month
        FROM dual;
        FND_FILE.PUT_LINE(FND_FILE.LOG,lv_qtr ||'  '||lv_month);
        EXCEPTION WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,
                       'ERROR at XX_AP_DSTROYMERCH_PKG.beforeReport wile cacluating current qtr/month:- ' ||
                       sqlerrm);
        END;
        if P_FREQUENCY = 'Quarterly' THEN
            BEGIN
              SELECT min(start_date) , max(end_date)
              INTO lv_start_date, lv_end_date
              FROM gl_periods 
              WHERE period_year = EXTRACT (year from sysdate)
              AND quarter_num = NVL(TO_NUMBER(lv_qtr), quarter_num);
            END;
        end if;
        
        if P_FREQUENCY = 'Monthly' THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,
                 'inside mnthly');
          BEGIN
            SELECT min(start_date) , max(end_date)
            INTO lv_start_date, lv_end_date
            FROM gl_periods 
            WHERE period_year = EXTRACT (year from sysdate)
            AND period_name = NVL(lv_month, period_name);
          END;
        end if;
        
        if P_FREQUENCY = 'Weekly' THEN
          BEGIN 
            /*SELECT to_date(next_day(SYSDATE - 7, 'sat')) , TO_DATE(SYSDATE)+7
            INTO lv_start_date, lv_end_date
            FROM gl_periods 
            WHERE period_year = EXTRACT (year from sysdate)
            AND rownum=1;*/
            SELECT to_date(next_day(SYSDATE-7, 'sun')) , to_date(next_day(SYSDATE, 'sat'))
            INTO lv_start_date, lv_end_date
            FROM gl_periods 
            WHERE period_year = EXTRACT (year from sysdate)
            AND rownum=1;
          END;
      end if;
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                 'lv_start : '||lv_start_date||'lv_end : '||lv_end_date);
                 
		G_where_clause := ' and xarh.frequency_code = DECODE(''' ||P_FREQUENCY || ''',''Quarterly'', ''QY'',''Monthly'', ''MY'',''Weekly'',''WY'')
		'	|| ' and trunc(aia.creation_date) BETWEEN (''' || lv_start_date || ''') and (''' || lv_end_date|| ''')';
	

	END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG,
                 'Dynamic where clause is : '||G_where_clause);
  --null;
    return true;
  EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,
                 'ERROR at XX_AP_DSTROYMERCH_PKG.beforeReport:- ' ||
                 sqlerrm);
END beforeReport;
END XX_AP_DSTROYMERCH_PKG;
/
SHOW ERRORS;