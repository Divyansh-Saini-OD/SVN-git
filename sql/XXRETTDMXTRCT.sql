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
REM     NOTES                   :  Naveen Srinivas Db link removed LNS1
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
       || TO_CHAR(COUNT(*)) row_count 
  FROM hr_locations_all h 
 WHERE h.country IN ( 'US', 'CA' ) 
   AND h.location_code LIKE '00%'
   AND TRUNC(NVL(h.inactive_date, sysdate)) >= TRUNC(sysdate); 
                         
REM Defect 10891                         
spool &p_outdir.TDM_RETXTRCT.dat

PROMPT LOCATION CODE|DESCR|PHONE NBR|FAX NBR|MGR FNAME|MGR LNAME|ADDR LINE 1|ADDR LINE 2|CITY|STATE|ZIP|REGION ID|REGION DESCR|REGIONAL MGR FNAME|REGIONAL MGR LNAME|DISTRICT ID|DISTRICT DESCR|DISTRICT MGR FNAME|DISTRICT MGR LNAME|COUNTRY CODE

SELECT SUBSTR (h.location_code, 1, 6) 
       || '|' 
       || SUBSTR (h.description, INSTR(h.description, ':') + 1, 25) 
       || '|' 
       || REGEXP_REPLACE(h.telephone_number_1, '[^0-9]', '') 
       || '|' 
       || REGEXP_REPLACE(h.telephone_number_2, '[^0-9]', '') 
       || '|' 
       || SUBSTR (h.loc_information15, 1, INSTR(h.loc_information15, ' ') - 1) 
       || '|' 
       || SUBSTR (h.loc_information15, INSTR(h.loc_information15, ' ') + 1, 15) 
       || '|' 
       || SUBSTR (h.address_line_1, 1, 30) 
       || '|' 
       || SUBSTR (h.address_line_2, 1, 30) 
       || '|' 
       || SUBSTR (h.town_or_city, 1, 28) 
       || '|' 
       || SUBSTR (h.region_2, 1, 2) 
       || '|' 
       || SUBSTR (h.postal_code, 1, 9) 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || NULL 
       || '|' 
       || DECODE (h.country, 'US', 'USA', 'CA', 'CAN', h.country)
FROM   hr_locations_all h 
WHERE  h.country IN ( 'US', 'CA' ) 
  AND  h.location_code LIKE '00%'
  AND  TRUNC (NVL (h.inactive_date, sysdate)) >= TRUNC (sysdate) 
ORDER  BY 1;
prompt 3|TDM_RETXTRCT&p_filedate.dat&p_traildate.&p_rowcount
spool off

REM Defect 10891
host mv &p_outdir.TDM_RETXTRCT.dat $XXFIN_DATA/ftp/out/tdm
host cp $XXFIN_DATA/ftp/out/tdm/TDM_RETXTRCT.dat $XXFIN_ARCHIVE/outbound/TDM_RETXTRCT.dat&p_arc_date&p_msec

prompt End of program
prompt