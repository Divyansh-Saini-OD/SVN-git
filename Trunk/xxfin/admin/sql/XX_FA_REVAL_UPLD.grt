REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_FA_REVAL_UPLD.grt                                            |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              19-Oct-2012       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE


insert into xx_pa_pb_excel_config values 
('XX_FA_REVAL_LOC_STG','LOCATION','V','Location',0,'A',7,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_REVAL_LOC_STG','REVAL_PCT','V','Revaluation Percentage',0,'B',7,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_REVAL_LOC_STG','PROCESS_MODE','V','Process Mode',0,'C',7,null,sysdate,33963,33963,sysdate,null);

commit;

EXIT;
