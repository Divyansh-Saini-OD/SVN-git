-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update_xx_fin_translatevalues                                               |
-- | Description : This Script is used to update the field name of Invoice Line Numbering      |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 01-Aug-2017  Thilak Kumar E          Defect# 42380                               |
-- +===========================================================================================+
--Updating Translation values for eTXT Summary Fields

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Transaction Line Numbering'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_HDR_FIELDS')
and source_value4 like 'LINE_NUM_PER_INV_LINE';

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Transaction Line Numbering', source_value1 = '10166'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value4 like 'LINE_NUM_PER_INV_LINE';

update XX_FIN_TRANSLATEVALUES
set source_value1 = '10167'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value4 like 'LINE_NUM_PER_INV';

update XX_FIN_TRANSLATEVALUES
set source_value2 = 'Transaction Line Numbering'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_TRL_FIELDS')
and source_value4 like 'LINE_NUM_PER_INV_LINE';

-- 3 row updated

commit;

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10164,10165,10167,10160,10161,10166);

commit;