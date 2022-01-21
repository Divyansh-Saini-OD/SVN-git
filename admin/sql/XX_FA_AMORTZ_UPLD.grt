REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_FA_AMORTZ_UPLD.grt                                           |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              26-Nov-2012       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE


insert into xx_pa_pb_excel_config values 
('XX_FA_AMORTZ_STG','asset_id','V','Asset',0,'A',8,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_AMORTZ_STG','life_to_process','V','Asset Life',0,'B',8,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_AMORTZ_STG','amrtz_to_process','V','Amortization',0,'C',8,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_AMORTZ_STG','amrtz_date_to_process','D','Amortization Date',0,'D',8,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_AMORTZ_STG','process_mode','V','Process Mode',0,'E',8,null,sysdate,33963,33963,sysdate,null);

commit;

EXIT;
