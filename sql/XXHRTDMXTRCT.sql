REM	_____________________________________________________________________
REM
REM     TITLE                   :  XXHRTDMXTRCT.sql
REM     USED BY APPLICATION     :  HR
REM     PURPOSE                 :  Generates HR outbound files for TDM
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   : RAJI NATARAJAN, Wipro , Fixed defect 6451
REM     NOTES                   :  Sandeep Pandhare, Defect 10891 - Remove timestamp from filename
REM                             : Defect 2285 CR 720 Added inactive employees and inactive flag to output file
REM	_____________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt Starting HR outbound interface to TDM ...
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
FROM   per_employees_x e,
       per_addresses a
WHERE  e.employee_id = a.person_id
       AND a.primary_flag = 'Y'
       -- AND trunc(nvl(e.inactive_date,SYSDATE + 1)) > trunc(SYSDATE) removed per defect 2285
       AND a.country IN ('US',
                         'CA');
                         
REM Defect 10891                         
spool &p_outdir.TDM_HRXTRCT.dat

-- INACTIVE FLAG prompt added below per defect 2286
prompt EMPLOYEE NUMBER|FULL NAME|ADDRESS LINE 1|ADDRESS LINE 2|ADDRESS LINE 3|TOWN OR CITY|POSTAL CODE|COUNTRY|INACTIVE FLAG


-- decode(inactive_date) added below to select per defect 2285
SELECT   e.employee_num
         ||'|'
         ||e.full_name
         ||'|'
         ||a.address_line1
         ||'|'
         ||a.address_line2
         ||'|'
         ||a.address_line3
         ||'|'
         ||a.town_or_city
         ||'|'
         ||a.postal_code
         ||'|'
         ||a.country
         ||'|'
         ||decode(e.inactive_date, NULL,'N','Y')   
FROM     per_employees_x e,
         per_addresses a
WHERE    e.employee_id = a.person_id
         AND a.primary_flag = 'Y'
       --  AND trunc(nvl(e.inactive_date,SYSDATE + 1)) > trunc(SYSDATE) removed per defect 2285
         AND a.country IN ('US',
                           'CA')
ORDER BY 1;

prompt 3|TDM_HRXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off


REM Defect 10891
host mv &p_outdir.TDM_HRXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_HRXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_HRXTRCT.dat&p_arc_date&p_msec

prompt End of program
prompt
