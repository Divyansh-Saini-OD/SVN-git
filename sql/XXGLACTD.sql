REM	______________________________________________________________________________________________________
REM
REM     TITLE                   :   XXGLACTD.sql
REM     USED BY APPLICATION     :   GL
REM     PURPOSE                 :   GL segment values to TDM
REM     CREATED BY              :  Priyam Parmar
REM     INPUTS                  :  
REM     OUTPUTS                 :  generates XXGLACTDESC.txt 
REM     HISTORY                 :  WHO -                 WHAT -          DATE -
REM     NOTES                   :  Priyam Parmar		RICE INT043    05/20/2019   Intial version
REM                             :  Gaurav Thukral       RICE NAIT 205615 10/01/2021 Spin Project Modificaitons
REM	_____________________________________________________________________________________________________

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
column V_LEDGER_NAME new_value p_LEDGER_NAME noprint

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
SELECT NAME V_LEDGER_NAME FROM GL_LEDGERS WHERE LEDGER_ID=FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
prompt &p_LEDGER_NAME
prompt &p_outdir.XXGLACTDESC.txt
spool &p_outdir.XXGLACTDESC.txt

select 'COMPANY' ||'|'||b.flex_value||'|'||b.description
    from fnd_flex_values_vl b,
         fnd_flex_value_sets a
    where a.flex_value_set_name='OD_GL_GLOBAL_COMPANY'
         and b.flex_value_set_id=a.flex_value_set_id
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
   and b.enabled_flag='Y'
      UNION
      select 'COST CENTER' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_COST_CENTER'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
      UNION
      select 'ACCOUNT' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_ACCOUNT'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
      UNION
      select 'LOCATION' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
      UNION
      select 'INTERCOMPANY' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_COMPANY'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
      UNION
      select 'LOB' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_LOB'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
      UNION
      select 'FUTURE' ||'|'||b.flex_value||'|'||b.description
        from fnd_flex_values_vl b,
             fnd_flex_value_sets a
       where a.flex_value_set_name='OD_GL_GLOBAL_FUTURE'
         and b.flex_value_set_id=a.flex_value_set_id
         and b.enabled_flag='Y'
		 and 'US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
	UNION
	select 'COMPANY' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_COMPANY'
           and b.flex_value_set_id=a.flex_value_set_id
		   and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'COST CENTER' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_COST_CENTER'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'ACCOUNT' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_ACCOUNT'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'LOCATION' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_LOCATION'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'INTERCOMPANY' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_COMPANY'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'LOB' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_LOB'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
        UNION
        select 'FUTURE' ||'|'||b.flex_value||'|'||b.description
          from fnd_flex_values_vl b,
               fnd_flex_value_sets a
         where a.flex_value_set_name='R_OD_GL_GLOBAL_FUTURE'
           and b.flex_value_set_id=a.flex_value_set_id
           and b.enabled_flag='Y'
		   and 'R US USD Corp GAAP Primary' = '&p_LEDGER_NAME'
order by 1;

spool off
host mv &p_outdir.XXGLACTDESC.txt $XXFIN_DATA/ftp/out/tdm

prompt End of program
prompt
