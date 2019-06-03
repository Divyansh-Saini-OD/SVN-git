REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_QA_CAPUPD.grt                                                |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              26-Jul-2011       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             


insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','CAPID','V','CAP ID',0,'A',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','DS_ID','V','DS ID',0,'B',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','DEFECT_SUMMARY','V','Defect Summary',0,'C',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','ROOTCAUSE','V','Root Cause',0,'D',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','CORRECTIVE_ACTION','V','Corrective Action',0,'E',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','PREVENTIVE_ACTION','V','Preventive Action',0,'F',2,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CAP_DS_INT','CA_IMPL_DATE','D','CAP Implementation Date',0,'G',2,null,sysdate,33963,33963,sysdate,null);


commit;

EXIT;
