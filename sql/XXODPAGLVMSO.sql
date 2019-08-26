REM	_______________________________________________________________________________________________________________________________
REM
REM     TITLE                   :  XXODPAVMSO.sql
REM     USED BY APPLICATION     :  PA , GL
REM     PURPOSE                 :  Generates PA , GL outbound files for VMS
REM     CREATED BY              :  Praveen Vanga, Developer - EBS, Office Depot
REM     INPUTS                  :  
REM     OUTPUTS                 :  generates .txt and .csv files
REM     HISTORY                 :  WHO -                 WHAT -          DATE -
REM     NOTES                   :  Praveen Vanga		RICE I3101       02/27/2017   Intial version
REM     NOTES                   :  Arun Dsouza 		    RICE I3101       09/27/2018   Modified to archive the files
REM     NOTES 					:  Priyam               RICE I301        04/15/2019   Modified to remove Task Number having IT and LB	
REM     NOTES 					:  Narendra             RICE I301        07/19/2019   Condition to Add Task Number having IT and LB and Project Asset Type as                                                                                    "ESTIMATED"		
REM     NOTES 					:  Narendra             RICE I301        08/02/2019   Add Condition to check Asset status should be estimated for capitalized Task        
REM     NOTES 					:  Narendra             RICE I301        08/25/2019   Filter out ALL tasks with code 02.IT.LB and with code 02.IT.PF that status As Built only.      
REM _______________________________________________________________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt Starting PA and GL outbound interface to VMS  ...
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
       ||TO_CHAR(SYSDATE,'YYYYMMDD')
       ||'.' file_date,
       '|'
       ||TO_CHAR(SYSDATE,'DD-MON-YYYY||HH24:MI:SS') trail_date,
       '_'||SUBSTR(SYSTIMESTAMP,-16,4) msec,
       '_'
       ||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS') arc_date 
FROM   dba_directories
WHERE  directory_name = 'XXFIN_OUTBOUND';


prompt &p_outdir.ODPAPOET1&p_filedate.csv
spool &p_outdir.ODPAPOET1&p_filedate.csv
Prompt Task Code,Task Name

SELECT DISTINCT ('"'|| SUBSTR(p.segment1
       ||'_'||     
       t.task_number
	   ||'_'||
       pei.expenditure_type
	   ||'_'||
       PRVR.NAME,1,100)||'"' )||','||
       ('"'|| SUBSTR(p.segment1
       ||'_'||     
       t.task_number
	   ||'_'||
       pei.expenditure_type
	   ||'_'||
       prvr.name,1,100)||'"' ) b	   
  FROM hr_all_organization_units prvr,
       pa_expenditure_items_all   pei,
       pa_tasks t,
       pa_projects_all p
   WHERE p.enabled_flag = 'Y'
   and p.project_status_code = 'APPROVED'
   AND p.TEMPLATE_FLAG <> 'Y'
   AND t.project_id=p.project_id 
   AND t.chargeable_flag = 'Y'
   AND pei.expenditure_type NOT LIKE '%:Accrued%'
   and t.task_number like '02%%IT%LB%'
   AND pei.task_id=t.task_id
   AND prvr.organization_id=pei.cc_prvdr_organization_id
   AND TRUNC(NVL(p.completion_date,TRUNC(SYSDATE) + 1)) > TRUNC(SYSDATE)
   AND TRUNC(NVL(t.completion_date,TRUNC(SYSDATE) + 1)) > TRUNC(SYSDATE)
   AND EXISTS (SELECT 'x'
                 FROM  xx_fin_translatevalues      xftv,
                       xx_fin_translatedefinition  xftd,
                       pa_segment_value_lookups l,
                       pa_segment_value_lookup_sets s
               WHERE xftv.translate_id = xftd.translate_id
                  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
                 AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
                 AND xftv.source_value1 = 'INCLUDE_ACCOUNT'
                 AND xftd.translation_name = 'XX_GL_VMS_I3101'
                 AND xftv.enabled_flag = 'Y'
                 AND xftd.enabled_flag = 'Y'
                 AND  l.segment_value = xftv.target_value1
                 AND s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
                 AND UPPER(RTRIM(s.segment_value_lookup_set_name)) = 'EXPENDITURE TYPE TO ACCOUNT'
                 AND l.segment_value_lookup = pei.expenditure_type
                )
   AND NOT EXISTS (SELECT 'X'
                    FROM PA_PROJECT_ASSETS_ALL ppaa,
                         PA_PROJECT_ASSET_ASSIGNMENTS ppas,
                         pa_tasks t1                         
                    WHERE ppaa.project_asset_id = ppas.project_asset_id
                    and ppas.project_id = t1.project_id
                    and ppas.task_id = t1.task_id
                    and ppaa.project_asset_type <> 'ESTIMATED'
					and t1.task_number like '02%%IT%PF%'
                    AND t1.project_id=t.project_id
                    AND t1.task_id=t.task_id
                     )
   ORDER BY 1;


spool off
host cp &p_outdir.ODPAPOET1&p_filedate.csv $XXFIN_DATA/archive/outbound
host mv &p_outdir.ODPAPOET1&p_filedate.csv $XXFIN_DATA/ftp/out/vms


prompt &p_outdir.ODPAPOET2&p_filedate.csv
spool &p_outdir.ODPAPOET2&p_filedate.csv
Prompt POET

SELECT DISTINCT '"'||SUBSTR(p.segment1
       ||'_'||     
       t.task_number
	   ||'_'||
       pei.expenditure_type
	   ||'_	'||
       prvr.name,1,200)  ||'"'           
  FROM hr_all_organization_units prvr,
       pa_expenditure_items_all   pei,
       pa_tasks t,
       pa_projects_all p
 WHERE p.enabled_flag = 'Y'
   and p.project_status_code = 'APPROVED'
   AND p.TEMPLATE_FLAG <> 'Y'
   AND t.project_id=p.project_id 
   AND t.chargeable_flag = 'Y'
   AND pei.expenditure_type NOT LIKE '%:Accrued%'
   and t.task_number like '02%%IT%LB%'
   AND pei.task_id=t.task_id
   AND prvr.organization_id=pei.cc_prvdr_organization_id
   AND TRUNC(NVL(p.completion_date,TRUNC(SYSDATE) + 1)) > TRUNC(SYSDATE)
   AND TRUNC(NVL(t.completion_date,TRUNC(SYSDATE) + 1)) > TRUNC(SYSDATE)
   AND EXISTS (SELECT 'x'
                 FROM  xx_fin_translatevalues      xftv,
                       xx_fin_translatedefinition  xftd,
                       pa_segment_value_lookups l,
                       pa_segment_value_lookup_sets s
               WHERE xftv.translate_id = xftd.translate_id
                  AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
                 AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
                 AND xftv.source_value1 = 'INCLUDE_ACCOUNT'
                 AND xftd.translation_name = 'XX_GL_VMS_I3101'
                 AND xftv.enabled_flag = 'Y'
                 AND xftd.enabled_flag = 'Y'
                 AND  l.segment_value = xftv.target_value1
                 AND s.segment_value_lookup_set_id = l.segment_value_lookup_set_id
                 AND UPPER(RTRIM(s.segment_value_lookup_set_name)) = 'EXPENDITURE TYPE TO ACCOUNT'
                 AND l.segment_value_lookup = pei.expenditure_type
                )
   AND NOT EXISTS (SELECT 'X'
                    FROM PA_PROJECT_ASSETS_ALL ppaa,
                         PA_PROJECT_ASSET_ASSIGNMENTS ppas,
                         pa_tasks t1                         
                    WHERE ppaa.project_asset_id = ppas.project_asset_id
                    and ppas.project_id = t1.project_id
                    and ppas.task_id = t1.task_id
                    and ppaa.project_asset_type <> 'ESTIMATED'
                    and t1.task_number like '02%%IT%PF%'
                    AND t1.project_id=t.project_id
                    AND t1.task_id=t.task_id
                     )
   ORDER BY 1;


spool off
host cp &p_outdir.ODPAPOET2&p_filedate.csv $XXFIN_DATA/archive/outbound
host mv &p_outdir.ODPAPOET2&p_filedate.csv $XXFIN_DATA/ftp/out/vms


prompt &p_outdir.ODGLACCT&p_filedate.csv
spool &p_outdir.ODGLACCT&p_filedate.csv
prompt GL String Code,GL String Name,GL String Description,Currency

SELECT
  SUBSTR(segment4||'.'||segment2||'.'||segment3||'.'||segment6,1,200)
||','||'"'|| 
SUBSTR((GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL(CHART_OF_ACCOUNTS_ID, 4,SEGMENT4)||'_'||GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL(CHART_OF_ACCOUNTS_ID, 2,SEGMENT2)||'_'||
       gl_flexfields_pkg.get_description_sql(chart_of_accounts_id, 3,segment3)||'_'||gl_flexfields_pkg.get_description_sql(chart_of_accounts_id, 6,segment6)),1,200)||'"'
||','||  
 '"'|| SUBSTR((GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL(CHART_OF_ACCOUNTS_ID, 4,SEGMENT4)||'_'||GL_FLEXFIELDS_PKG.GET_DESCRIPTION_SQL(CHART_OF_ACCOUNTS_ID, 2,SEGMENT2)||'_'||
       gl_flexfields_pkg.get_description_sql(chart_of_accounts_id, 3,segment3)||'_'||gl_flexfields_pkg.get_description_sql(chart_of_accounts_id, 6,segment6)),1,1000)||'"'
||','||
'USD' currency 
FROM gl_code_combinations a
WHERE enabled_flag='Y' 
 AND EXISTS (
                    SELECT 'x'
                      from  xx_fin_translatedefinition  xftd
                          , xx_fin_translatevalues      xftv
                     where a.segment3 = xftv.target_value1
					   AND xftv.translate_id = xftd.translate_id
                       AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
                       AND SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+1)
                       AND xftv.source_value1 = 'INCLUDE_ACCOUNT'
                       AND xftd.translation_name = 'XX_GL_VMS_I3101'
                       AND xftv.enabled_flag = 'Y'
                       AND xftd.enabled_flag = 'Y'
                       )
 AND EXISTS ( SELECT 'x'
                     FROM fnd_flex_values_vl ffvl,
					      fnd_flex_value_sets ffv
                    WHERE a.segment1 = ffvl.flex_value 
					  AND ffv.flex_value_set_name='OD_GL_GLOBAL_COMPANY'
                      AND ffvl.flex_value_set_id=ffv.flex_value_set_id
                      AND ffvl.attribute1='US_USD_P'
                      AND ffvl.enabled_flag='Y'
                 )
ORDER BY SEGMENT4,SEGMENT2,SEGMENT3,SEGMENT6 ASC
;

spool off
host cp &p_outdir.ODGLACCT&p_filedate.csv $XXFIN_DATA/archive/outbound
host mv &p_outdir.ODGLACCT&p_filedate.csv $XXFIN_DATA/ftp/out/vms


prompt End of program
prompt