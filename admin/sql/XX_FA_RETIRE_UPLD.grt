REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_FA_RETIRE_UPLD.grt                                           |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              26-Jan-2013       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE

insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','process_mode','V','Process Mode',0,'A',9,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','Asset_id','V','Asset',0,'B',9,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','book_type_code','V','Asset Book',0,'C',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','Retirement_type','V','Retirement Type',0,'D',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','Retirement_date','D','Retirement Date',0,'E',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','Units_retired','V','Units Retired',0,'F',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','cost_to_be_retired','V','Cost to be Retired',0,'G',9,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','pos_to_be','V','Proceeds of Sale To be',0,'H',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','cost_of_removal','V','Cst of removal',0,'I',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','retire_convention','V','Retirement Convention',0,'J',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','sold_to','V','Sold To',0,'K',9,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','comments','V','Comments',0,'L',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','location','V','Location',0,'M',9,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_FA_RETIRE_STG','expense_account','V','Expense Account',0,'N',9,null,sysdate,33963,33963,sysdate,null);


commit;

EXIT;


