REM	_______________________________________________________________________________
REM
REM     TITLE                   :  XXPATDMXTRCT.sql
REM     USED BY APPLICATION     :  PA
REM     PURPOSE                 :  Generates PA outbound files for TDM
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :  RAJI NATARAJAN, Wipro , Fixed defect 6457
REM     NOTES                   :  Sandeep Pandhare, Defect 10645 - Add chargeable Task only
REM     NOTES                   :  Sandeep Pandhare, Defect 10891 - Remove timestamp from filename
REM     NOTES                   :  Madhu Bolli, Defect#36307-122 Retrofit - Remove schema name from tables
REM	_______________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt Starting PA outbound interface to TDM  ...
prompt

column out_dir new_value p_outdir noprint
column file_date new_value p_filedate noprint
column trail_date new_value p_traildate noprint
column row_count new_value p_rowcount noprint
column msec  new_value p_msec noprint
column arc_date new_value p_arc_date noprint

SELECT directory_path
       ||'/' out_dir,
       '_'
       ||to_char(SYSDATE,'YYYYMMDD_HH24MISS')
       ||'.' file_date,
       '|'
       ||to_char(SYSDATE,'DD-MON-YYYY||HH24:MI:SS') trail_date,
       '_'||SUBSTR(SYSTIMESTAMP,-16,4) msec,
       '_'
       ||to_char(SYSDATE,'YYYYMMDD_HH24MISS') arc_date 
FROM   dba_directories
WHERE  directory_name = 'XXFIN_OUTBOUND';

SELECT '|'
       ||to_char(COUNT(* )) row_count
FROM   pa_projects_all p,
       pa_tasks t,
       pa_project_players l,
       per_employees_x e,
       hr_operating_units h
WHERE  p.project_id = t.project_id
       AND p.project_id = l.project_id
       AND l.person_id = e.employee_id
       AND p.org_id = h.organization_id
       AND p.enabled_flag = 'Y'
       AND p.project_status_code = 'APPROVED'
       AND l.project_role_type = 'PROJECT MANAGER'
       AND t.chargeable_flag = 'Y'
       AND trunc(nvl(p.completion_date,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
       AND trunc(nvl(t.completion_date,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
       AND p.org_id IN (xx_fin_country_defaults_pkg.f_org_id('US'),
                        xx_fin_country_defaults_pkg.f_org_id('CA'));
                        
REM Defect 10891 spool &p_outdir.TDM_PAPMXTRCT&p_filedate.dat
spool &p_outdir.TDM_PAPMXTRCT.dat

prompt PROJECT NUMBER|PROJECT NAME|PROJECT START DATE|PROJECT COMPLETION DATE|TASK NUMBER|TASK NAME|TASK START DATE|TASK COMPLETION DATE|PROJECT MANAGER|OPERATING UNIT

SELECT   p.segment1
         ||'|'
         ||p.NAME
         ||'|'
         ||trunc(p.start_date)
         ||'|'
         ||trunc(p.completion_date)
         ||'|'
         ||t.task_number
         ||'|'
         ||t.task_name
         ||'|'
         ||trunc(t.start_date)
         ||'|'
         ||trunc(t.completion_date)
         ||'|'
         ||e.full_name
         ||'|'
         ||h.NAME
FROM     pa_projects_all p,
         pa_tasks t,
         pa_project_players l,
         per_employees_x e,
         hr_operating_units h
WHERE    p.project_id = t.project_id
         AND p.project_id = l.project_id
         AND l.person_id = e.employee_id
         AND p.org_id = h.organization_id
         AND p.enabled_flag = 'Y'
         AND p.project_status_code = 'APPROVED'
         AND l.project_role_type = 'PROJECT MANAGER'
         AND t.chargeable_flag = 'Y'
         AND trunc(nvl(p.completion_date,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
         AND trunc(nvl(t.completion_date,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
         AND p.org_id IN (xx_fin_country_defaults_pkg.f_org_id('US'),
                          xx_fin_country_defaults_pkg.f_org_id('CA'))
ORDER BY 1;
prompt 3|TDM_PAPMXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off

REM Defect 10891
host mv &p_outdir.TDM_PAPMXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_PAPMXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_PAPMXTRCT.dat&p_arc_date&p_msec


SELECT '|'
       ||to_char(COUNT(* )) row_count
FROM   (SELECT l.segment_value_lookup
        FROM   pa_segment_value_lookup_sets s,
               pa_segment_value_lookups l
        WHERE  s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
               AND upper(rtrim(s.segment_value_lookup_set_name)) = 'EXPENDITURE TYPE TO ACCOUNT'
        UNION 
        SELECT l.segment_value_lookup
        FROM   pa_segment_value_lookup_sets s,
               pa_segment_value_lookups l
        WHERE  s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
               AND upper(rtrim(s.segment_value_lookup_set_name)) = 'EXPENDITURE ORG TO COST CENTER');

REM Defect 10891
spool &p_outdir.TDM_PAXPXTRCT.dat

prompt EXP TYPE OR ORG|EXP TYPE OR ORG VALUE|ACCOUNT OR LOCATION VALUE

SELECT 'TYPE'
       ||'|'
       ||l.segment_value_lookup
       ||'|'
       ||l.segment_value
FROM   pa_segment_value_lookup_sets s,
       pa_segment_value_lookups l
WHERE  s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
       AND upper(rtrim(s.segment_value_lookup_set_name)) = 'EXPENDITURE TYPE TO ACCOUNT'
UNION 
SELECT 'ORG'
       ||'|'
       ||l.segment_value_lookup
       ||'|'
       ||l.segment_value
FROM   pa_segment_value_lookup_sets s,
       pa_segment_value_lookups l
WHERE  s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
       AND upper(rtrim(s.segment_value_lookup_set_name)) = 'EXPENDITURE ORG TO COST CENTER'
ORDER BY 1;
prompt 3|TDM_PAXPXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off

REM Defect 10891
host mv &p_outdir.TDM_PAXPXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_PAXPXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_PAXPXTRCT.dat&p_arc_date&p_msec

prompt End of program
prompt