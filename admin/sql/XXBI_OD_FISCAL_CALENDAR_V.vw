SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace view XXBI_OD_FISCAL_CALENDAR_V as
select 
  cast(to_char(map.accounting_date,'J') as number) as julian_id, 
  map.accounting_date, 
  map.period_name,
  to_char(map.accounting_date,'DAY')  fiscal_day_descr, 
  (ps.period_year * 100) + ceil((((map.accounting_date) - (ps.year_start_date)) + 1)/7) as fiscal_week_id,
  ceil((((map.accounting_date) - (ps.year_start_date)) + 1)/7) as fiscal_week_number,
  'Week ' || ceil((((map.accounting_date) - (ps.year_start_date)) + 1)/7) || ' of ' || ps.period_year as fiscal_week_descr,
  (ps.period_year * 100) + ps.period_num as fiscal_period_id,
  ps.period_num as fiscal_period_number,
  map.period_name as fiscal_period_descr,
  ps.start_date as fiscal_period_start_date,
  ps.end_date as fiscal_period_end_date,
  (ps.period_year * 10) + ps.quarter_num as fiscal_qtr_id,
  ps.quarter_num as quarter_number,
  'QTR ' || ps.quarter_num || ' of ' || ps.period_year as fiscal_qtr_desc,
  ps.quarter_start_date as fiscal_qtr_start_date,
  ps.period_year as fiscal_year_id,
  ps.year_start_date as fiscal_year_start_date
from 
  gl.GL_DATE_PERIOD_MAP map,
  gl.gl_period_statuses ps, 
  apps.FND_APPLICATION_VL app,
  gl.GL_SETS_OF_BOOKS bks
where 
  map.period_name = ps.period_name
  and map.period_set_name = 'OD 445 CALENDAR' --JEBE_MONTH_VAT,OD_GLOBAL_GL_CA,OD 445 CALENDAR
  and ps.application_id = app.application_id
  and app.application_name = 'General Ledger'
  and ps.set_of_books_id = bks.set_of_books_id
  and bks.set_of_books_id = apps.fnd_profile.value('GL_SET_OF_BKS_ID');
/
SHOW ERRORS;
EXIT;