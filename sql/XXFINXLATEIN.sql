REM     ___________________________________________________________________________________________________
REM
REM     TITLE                   :  XXFINXLATEIN.sql
REM     USED BY APPLICATION     :  AP
REM     PURPOSE                 :  Loads custom translation tables to refresh non-Prod instances
REM     LIMITATIONS             :
REM     CREATED BY              :  ANAMITRA BANERJEE, Lead Developer - Oracle Financials, Office Depot Inc.
REM     INPUTS                  :
REM     OUTPUTS                 :
REM     HISTORY                 :  WHO -        WHAT -          DATE -
REM     NOTES                   :
REM     ___________________________________________________________________________________________________

set concat .
set echo off
set feed off
set head off
set linesize 32767
set pagesize 0
set trimspool on
set verify off

prompt
prompt *** Starting program OD: FIN Translation inbound interface ***
prompt

column dir_path new_value p_datain noprint

SELECT directory_path
       ||'/' dir_path
FROM   dba_directories
WHERE  directory_name = 'XXFIN_DATA';
prompt Loading Translation values ...
prompt

host cp $XXFIN_DATA/ftp/out/XX_FIN_TRANSLATEVALUES.dat &p_datain

prompt *** End of program ***
prompt
