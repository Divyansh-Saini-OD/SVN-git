REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_QA_QMR_INS.grt                                               |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.1              18-Oct-2011       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE

update apps.xx_pa_pb_excel_config  set data_type='V' 
where staging_table_name='XX_QA_CC_STG'
and staging_column_name in ('OD_PB_CASE_NUMBER','OD_OB_MFG_DATE','OD_OB_PUR_DATE');

commit;

EXIT;
