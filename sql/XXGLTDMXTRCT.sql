REM	_______________________________________________________________________________
REM
REM     TITLE                   :  XXGLTDMXTRCT.sql
REM     USED BY APPLICATION     :  GL
REM     PURPOSE                 :  Generates GL Code Combinations outbound file for TDM
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :  RAJI NATARAJAN Fixed defect 6457
REM     NOTES                   :  Sandeep Pandhare, Defect 10891 - Remove timestamp from filename
REM     NOTES                   :  Madhu Bolli, Defect#36303,122 Retrofit - Remove schema name from tables
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
prompt Starting GL outbound interface to TDM ...
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
FROM   fnd_flex_values v,
       fnd_flex_values_tl t,
       fnd_flex_value_sets s
WHERE  v.flex_value_set_id = s.flex_value_set_id
       AND v.flex_value_id = t.flex_value_id
       AND v.enabled_flag = 'Y'
       AND v.summary_flag = 'N'
       AND trunc(nvl(v.end_date_active,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
       AND upper(rtrim(s.flex_value_set_name)) LIKE 'OD_GL_GLOBAL_%';
       
REM Defect 10891       
spool &p_outdir.TDM_GLSEGXTRCT.dat

prompt FLEX VALUE SET|FLEX VALUE|DESCRIPTION|START DATE ACTIVE|END DATE ACTIVE

SELECT   s.flex_value_set_name
         ||'|'
         ||v.flex_value
         ||'|'
         ||t.description
         ||'|'
         ||trunc(v.start_date_active)
         ||'|'
         ||trunc(v.end_date_active)
FROM     fnd_flex_values v,
         fnd_flex_values_tl t,
         fnd_flex_value_sets s
WHERE    v.flex_value_set_id = s.flex_value_set_id
         AND v.flex_value_id = t.flex_value_id
         AND v.enabled_flag = 'Y'
         AND v.summary_flag = 'N'
         AND trunc(nvl(v.end_date_active,to_date('&&1','YYYY/MM/DD HH24:MI:SS') + 1)) > trunc(to_date('&&1','YYYY/MM/DD HH24:MI:SS'))
         AND upper(rtrim(s.flex_value_set_name)) LIKE 'OD_GL_GLOBAL_%'
ORDER BY 1;
prompt 3|TDM_GLSEGXTRCT&p_filedate.dat&p_traildate.&p_rowcount

spool off

REM Defect 10891
host mv &p_outdir.TDM_GLSEGXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_GLSEGXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_GLSEGXTRCT.dat&p_arc_date&p_msec

SELECT '|'
       ||to_char(COUNT(* )) row_count
FROM   gl_code_combinations g,
       fnd_id_flex_structures f
WHERE  g.chart_of_accounts_id = f.id_flex_num
       AND f.id_flex_code = 'GL#'
       AND upper(rtrim(f.id_flex_structure_code)) = 'OD_GLOBAL_COA';
       
REM Defect 10891       
spool &p_outdir.TDM_GLCCXTRCT.dat

prompt FLEX STRUCTURE|CHART OF ACCOUNTS ID|CODE COMBINATION ID|ACCOUNT TYPE|ENABLED FLAG|COMPANY|COST CENTER|ACCOUNT|LOCATION|INTERCOMPANY|LINE OF BUSINESS|FUTURE|START DATE ACTIVE|END DATE ACTIVE|PRESERVE FLAG|REFRESH FLAG

SELECT   f.id_flex_structure_code
         ||'|'
         ||g.chart_of_accounts_id
         ||'|'
         ||g.code_combination_id
         ||'|'
         ||DECODE(g.account_type,'A','Asset',
                                 'E','Expense',
                                 'L','Liability',
                                 'O','Owners Equity',
                                 'R','Revenue',
                                 'Other')
         ||'|'
         ||g.enabled_flag
         ||'|'
         ||g.segment1||'|'||g.segment2||'|'||g.segment3||'|'||g.segment4||'|'||g.segment5||'|'||g.segment6||'|'||g.segment7
         ||'|'
         ||trunc(g.start_date_active)
         ||'|'
         ||trunc(g.end_date_active)
         ||'|'
         ||g.preserve_flag
         ||'|'
         ||g.refresh_flag
FROM     gl_code_combinations g,
         fnd_id_flex_structures f
WHERE    g.chart_of_accounts_id = f.id_flex_num
         AND f.id_flex_code = 'GL#'
         AND upper(rtrim(f.id_flex_structure_code)) = 'OD_GLOBAL_COA'
ORDER BY 1;
prompt 3|TDM_GLCCXTRCT&p_filedate.dat&p_traildate.&p_rowcount

spool off

host mv &p_outdir.TDM_GLCCXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_GLCCXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_GLCCXTRCT.dat&p_arc_date&p_msec

prompt End of program
prompt
