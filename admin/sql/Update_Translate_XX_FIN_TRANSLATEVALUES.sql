-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Insert_xx_fin_translatevalues                                               |
-- | Description : This Script is used to update target values for Summary Fields              |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 27-MAR-2017  Suresh N                Initial draft version                       |
-- +===========================================================================================+
--Updating Translation values for eXLS Summary Fields

update XX_FIN_TRANSLATEDEFINITION
set TARGET_FIELD24 = 'SUMMARY_FIELD',
TARGET_FIELD25 = 'SUMMARY_FIELD_LOV'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS');

-- 1 row updated

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE24 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10070, 10157, 10083, 10084, 10086, 10093, 10094, 10095, 10096);

-- 9 rows updated

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE25 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10070, 10157, 10083, 10084, 10086, 10093, 10094, 10095, 10096, 10025, 10027, 10029, 10030);

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE25 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10032, 10123, 10124, 10125, 10126, 10127, 10128, 10129, 10130, 10131, 10132);

-- 24 rows updated

--Updating Translation values for eXLS Summary Fields

update XX_FIN_TRANSLATEDEFINITION
set TARGET_FIELD25 = 'SUMMARY_FIELD',
TARGET_FIELD26 = 'SUMMARY_FIELD_LOV'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS');

-- 1 row updated

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE25 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10070, 10157, 10083, 10084, 10086, 10093, 10094, 10095, 10096, 10156);

-- 10 rows updated

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10070, 10157, 10083, 10084, 10086, 10093, 10094, 10095, 10096, 10156, 10025, 10027, 10029, 10030, 10160, 10161);

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10032, 10123, 10124, 10125, 10126, 10127, 10128, 10129, 10130, 10131, 10132, 10151, 10152, 10153, 10154, 10155);

-- 30 rows updated

commit;