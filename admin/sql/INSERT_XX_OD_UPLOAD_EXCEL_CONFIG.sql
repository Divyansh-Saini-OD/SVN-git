SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Oracle                                                   |
-- +================================================================================+
-- | SQL Script to insert seeded values                                             |
-- |                                                                                |
-- | INSERT_XX_OD_UPLOAD_EXCEL_CONFIG.sql                                           |
-- |  Rice ID : E3072 , Defect # : 23811                                            |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     27-SEP-2013  Archana N.       	Initial version                     |
-- +================================================================================+

delete from xxfin.xx_od_upload_excel_config
where staging_table_name IN ('XX_PA_MASS_ADJUST_EXT_STG','XX_PA_MASS_ADJUST_UPLD_STG');

INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_EXT_STG','PROJECT_NUMBER','V','PROJECT_NUMBER',0,'A',4,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTEXTPRG','OD: PA Mass Adjustments Extract Program',NULL);
INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_NUMBER','V','PROJECT_NUMBER',0,'A',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program','Y');
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_NAME','V','PROJECT_NAME',0,'B',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
  INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_LONG_NAME','V','PROJECT_LONG_NAME',0,'C',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_STATUS','V','PROJECT_STATUS',0,'D',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_START_DATE','D','PROJECT_START_DATE',0,'E',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_END_DATE','D','PROJECT_END_DATE',0,'F',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
  INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_LOCATION','V','PROJECT_LOCATION',0,'G',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','PROJECT_ORG','V','PROJECT_ORG',0,'H',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL); 
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_NUMBER','V','TASK_NUMBER',0,'I',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program','Y');
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_NAME','V','TASK_NAME',0,'J',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_START_DATE','D','TASK_START_DATE',0,'K',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_END_DATE','D','TASK_END_DATE',0,'L',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
  INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_LOCATION','V','TASK_LOCATION',0,'M',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','TASK_ORG','V','TASK_ORG',0,'N',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL); 
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','ASSIGN_ASSETS','V','ASSIGN_ASSETS',0,'O',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','ALLOW_CHARGES','V','ALLOW_CHARGES',0,'P',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','SERVICE_TYPE','V','SERVICE_TYPE',0,'Q',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','EMPLOYEE_NAME','V','EMPLOYEE_NAME',0,'R',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','EMPLOYEE_NUMBER','V','EMPLOYEE_NUMBER',0,'S',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program','Y');
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','ROLE','V','ROLE',0,'T',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','ROLE_START_DATE','D','ROLE_START_DATE',0,'U',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);
 INSERT into xxfin.xx_od_upload_excel_config values('XX_PA_MASS_ADJUST_UPLD_STG','ROLE_END_DATE','D','ROLE_END_DATE',0,'V',5,NULL,SYSDATE,
 596299,596299,SYSDATE,NULL,'XXFIN','XXPAMASSADJSTUPLDPRG','OD: PA Mass Adjustments Upload Program',NULL);



COMMIT;

 /
SHOW ERROR