REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_QA_POS.grt                                                   |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              11-Nov-2011       Paddy Sanjeevi          Original              |--
--| 1.1              15-Feb-2011       Paddy Sanjeevi          change fordefect 16977|
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE

DELETE from xx_pa_pb_excel_config where STAGING_TABLE_NAME='XX_QA_POS_STG';
COMMIT;

insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','SKU','V','SKU',0,'A',6,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','SKU_DESCRIPTION','V','SKU Description',0,'B',6,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','DEPT_ID','V','Dept Id',0,'C',6,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','ASSOCIATE_ID','V','Associate ID',0,'D',6,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','STORE_NUMBER','V','Store #',0,'E',6,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','TRANSACTION_DATE','D','Transaction Date',0,'F',6,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_POS_STG','RETURN_COMMENTS','V','Return Comments',0,'G',6,null,sysdate,33963,33963,sysdate,null);


commit;

EXIT;
