REM     ___________________________________________________________________________________________________
REM
REM     TITLE                   :  XXFINXLATEOUT.sql
REM     USED BY APPLICATION     :  AP
REM     PURPOSE                 :  Extracts custom translation tables to refresh non-Prod instances
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
prompt *** Starting program OD: FIN Translation outbound interface ***
prompt

column dir_path new_value p_dataout noprint

SELECT directory_path
       ||'/' dir_path
FROM   dba_directories
WHERE  directory_name = 'XXFIN_OUTBOUND';
prompt Extracting Translation values ...
prompt

spool &p_dataout.XX_FIN_TRANSLATEVALUES.dat

SELECT v.translate_id
       ||'|'
       ||v.source_value1
       ||'|'
       ||v.source_value2
       ||'|'
       ||v.source_value3
       ||'|'
       ||v.source_value4
       ||'|'
       ||v.source_value5
       ||'|'
       ||v.source_value6
       ||'|'
       ||v.source_value7
       ||'|'
       ||v.target_value1
       ||'|'
       ||v.target_value2
       ||'|'
       ||v.target_value3
       ||'|'
       ||v.target_value4
       ||'|'
       ||v.target_value5
       ||'|'
       ||v.target_value6
       ||'|'
       ||v.target_value7
       ||'|'
       ||v.target_value8
       ||'|'
       ||v.target_value9
       ||'|'
       ||v.target_value10
       ||'|'
       ||v.target_value11
       ||'|'
       ||v.target_value12
       ||'|'
       ||v.target_value13
       ||'|'
       ||v.target_value14
       ||'|'
       ||v.target_value15
       ||'|'
       ||v.target_value16
       ||'|'
       ||v.target_value17
       ||'|'
       ||v.target_value18
       ||'|'
       ||v.target_value19
       ||'|'
       ||v.target_value20
       ||'|'
       ||v.creation_date
       ||'|'
       ||v.created_by
       ||'|'
       ||v.last_update_date
       ||'|'
       ||v.last_updated_by
       ||'|'
       ||v.last_update_login
       ||'|'
       ||v.start_date_active
       ||'|'
       ||v.end_date_active
       ||'|'
       ||v.read_only_flag
       ||'|'
       ||v.enabled_flag
       ||'|'
       ||v.source_value8
       ||'|'
       ||v.source_value9
       ||'|'
       ||v.source_value10
       ||'|'
       ||v.translate_value_id
FROM   xxfin.xx_fin_translatevalues v,
       xxfin.xx_fin_translatedefinition d
WHERE  v.translate_id = d.translate_id
       AND upper(rtrim(d.translation_name)) IN ('IPO_PROJECT',
                                                'IPO_SHIP_TO_LOCATION',
                                                'IPO_ITEM_CONVERSION',
                                                'IPO_ORGANIZATION_CODE',
                                                'PO_ORG_RESP');
spool off

host mv &p_dataout.XX_FIN_TRANSLATEVALUES.dat $XXFIN_DATA/ftp/out

prompt *** End of program ***
prompt
