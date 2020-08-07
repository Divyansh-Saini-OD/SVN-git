-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Insert_xx_fin_translatevalues                                               |
-- | Description : This Script is used to update target values for Tax fields                  |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 14-JUN-2017  Thilak Kumar E          Defect# 42318                               |
-- +===========================================================================================+
--Updating Translation values for eXLS Summary Fields

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Total Tax Amt'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10074);

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Line Tax Row'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10138);

-- 2 rows updated

--Updating Translation values for eTXT Summary Fields

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Total Tax Amt'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10157);

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Line Tax Row'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10138);

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Tax-DNU'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10074);

-- 3 row updated

commit;