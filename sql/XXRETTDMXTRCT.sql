REM    ______________________________________________________________________________
REM
REM     TITLE                   :  XXRETTDMXTRCT.sql
REM     USED BY APPLICATION     :  RETAIL
REM     PURPOSE                 :  Generates Retail outbound files for TDM
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - EBS, Office Depot
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :  RAJI NATARAJAN, Wipro , Fixed defect 6452
REM     NOTES                   :  Sandeep Pandhare, Defect 10891 - Remove timestamp from filename
REM    ______________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt Starting Retail outbound interface to TDM ...
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
FROM   hr_locations_all h,
       od.loc@legacydb2 l,
       od.region@legacydb2 r,
       od.distrct@legacydb2 d
WHERE  ltrim(substr(h.location_code,1,6),'0') = to_char(l.loc_id (+) )
       AND l.region_id = r.region_id
       AND l.district_id = d.district_id
       AND h.country IN ('US',
                         'CA');
                         
REM Defect 10891                         
spool &p_outdir.TDM_RETXTRCT.dat

PROMPT LOCATION CODE|DESCR|PHONE NBR|FAX NBR|MGR FNAME|MGR LNAME|ADDR LINE 1|ADDR LINE 2|CITY|STATE|ZIP|REGION ID|REGION DESCR|REGIONAL MGR FNAME|REGIONAL MGR LNAME|DISTRICT ID|DISTRICT DESCR|DISTRICT MGR FNAME|DISTRICT MGR LNAME|COUNTRY CODE

SELECT   substr(h.location_code,1,6)
         ||'|'
         ||substr(l.descr,1,25)
         ||'|'
         ||l.phone_nbr
         ||'|'
         ||l.fax_nbr
         ||'|'
         ||substr(l.mgr_fname,1,10)
         ||'|'
         ||substr(l.mgr_lname,1,15)
         ||'|'
         ||substr(l.addr_line_1,1,30)
         ||'|'
         ||substr(l.addr_line_2,1,30)
         ||'|'
         ||substr(l.city,1,28)
         ||'|'
         ||substr(l.state,1,2)
         ||'|'
         ||substr(l.zip,1,9)
         ||'|'
         ||l.region_id
         ||'|'
         ||substr(r.descr,1,30)
         ||'|'
         ||substr(r.mgr_fname,1,10)
         ||'|'
         ||substr(r.mgr_lname,1,15)
         ||'|'
         ||l.district_id
         ||'|'
         ||substr(d.descr,1,30)
         ||'|'
         ||substr(d.mgr_fname,1,10)
         ||'|'
         ||substr(d.mgr_lname,1,15)
         ||'|'
         ||l.country_cd
FROM     hr_locations_all h,
         od.loc@legacydb2 l,
         od.region@legacydb2 r,
         od.distrct@legacydb2 d
WHERE    ltrim(substr(h.location_code,1,6),'0') = to_char(l.loc_id (+) )
         AND l.region_id = r.region_id
         AND l.district_id = d.district_id
         AND h.country IN ('US',
                           'CA')
ORDER BY 1;
prompt 3|TDM_RETXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off

REM Defect 10891
host mv &p_outdir.TDM_RETXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_RETXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_RETXTRCT.dat&p_arc_date&p_msec

prompt End of program
prompt