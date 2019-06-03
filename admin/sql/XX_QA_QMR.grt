REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_QA_QMR_COGNOS.grt                                            |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into xx_pa_pb_excel_config table                 |--
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              15-Aug-2011       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_SC_ENTRY_DATE','D','Month',0,'A',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_SKU','N','SKU',0,'B',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_PB_ITEM_DESC','V','SKU Description',0,'C',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_PB_YN','V','PB',0,'D',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_DI_YN','V','DI',0,'E',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_DIVISION_ID','N','Div ID',0,'F',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_PB_DIVISION','V','Division',0,'G',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_DEPT_ID','N','Dept ID',0,'H',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_PB_SC_DEPT_NAME','V','Department',0,'I',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_CLASS_ID','N','Class Id',0,'J',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_CLASS','V','Class',0,'K',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_SUBCLASS_ID','N','Subclass ID',0,'L',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_SUBCLASS','V','Subclass',0,'M',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_VENDOR_NAME','V','Vendor Name',0,'N',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_REPLEN_STATUS','V','Replen Status',0,'O',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_ONHAND_UNITS','N','On Hand Units',0,'P',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_SALE_AMT','N','Sales $',0,'Q',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_SALE_UNITS','N','Units Sold',0,'R',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_RETURN_AMT','N','Return $',0,'S',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_RETURN_UNITS','N','Units Ret',0,'T',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_DNC_AMT','N','DNC $',0,'U',3,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_COGNOS_STG','OD_OB_DNC_UNITS','N','DNC Units',0,'V',3,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_PB_CASE_NUMBER','N','Case Number',0,'A',5,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_SAFETY','V','Safety',0,'B',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_SOURCE','V','Source',0,'C',5,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_SC_ENTRY_DATE','D','Date of issue',0,'D',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_SKU','N','SKU',0,'E',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_MFG_DATE','D','MFG Date',0,'F',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_PUR_DATE','D','Purchase Date',0,'G',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_ISSUE_TYPE','V','Issue Type',0,'H',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_REASON','V','Reason',0,'I',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_PB_COMMENTS','V','Comment',0,'J',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_CC_STG','OD_OB_STATE','V','State',0,'K',5,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_REVIEW_ID','N','Review Id',0,'A',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_SC_ENTRY_DATE','D','Month',0,'B',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_SKU','N','SKU',0,'C',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_PB_ITEM_DESC','V','Product Name',0,'D',4,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_OVERALL_RAT','N','Overall Rating',0,'E',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_MEET_EXPECT','N','Meet Expectations',0,'F',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_QUALITY_RAT','N','Quality',0,'G',4,null,sysdate,33963,33963,sysdate,null);


insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_REC_FRND','V','Recommed',0,'H',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_PROS','V','Pros',0,'I',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_OB_CONS','V','Cons',0,'J',4,null,sysdate,33963,33963,sysdate,null);

insert into xx_pa_pb_excel_config values 
('XX_QA_BAZAAR_STG','OD_PB_COMMENTS','V','Review Text',0,'K',4,null,sysdate,33963,33963,sysdate,null);


commit;

--EXIT;
