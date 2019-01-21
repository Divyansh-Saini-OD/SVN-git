SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
  
  CREATE OR REPLACE FORCE VIEW APPS.XXBI_FISCAL_WEEK_DIM_V (ID, VALUE, FISCAL_PERIOD_ID) AS 
  select distinct  fiscal_week_id as id, fiscal_week_id  as value, fiscal_period_id from XXBI_OD_FISCAL_CALENDAR_V
/
SHOW ERRORS;
EXIT;