-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update_xx_fin_translatevalues                                               |
-- | Description : This Script is used to update the field name of Total Tax Amt               |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 30-NOV-2017  Thilak Kumar E          Defect# NAIT-21714 and NAIT-21725           |
-- +===========================================================================================+
--Updating Translation values for eXLS Summary Fields

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE25 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10074,10003,10005,10028,10080,10081,10082,10085);

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE24 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10074,10080,10081,10082,10085);

--Updating Translation values for eTXT Summary Fields

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = 'N'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10166,10167);

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE26 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10003,10005,10028,10080,10081,10082,10085);

update XX_FIN_TRANSLATEVALUES
set TARGET_VALUE25 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBL_TXT_DET_FIELDS')
and source_value1 in (10080,10081,10082,10085);

--Updating Translation values for Include Core

update XX_FIN_TRANSLATEVALUES
set SOURCE_VALUE9 = 'Y'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (10028,10032,10036,10114);

--Updating Translation values for Include Core/Detail

update XX_FIN_TRANSLATEVALUES
set SOURCE_VALUE9 = 'N'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (SELECT FIELD_ID FROM XX_CDH_EBILLING_FIELDS_V  
 WHERE include_in_core = 'Y'
 AND field_name not in 
 ('Consolidated Bill Number'
 ,'Department'
 ,'Department Description'
 ,'Desktop'
 ,'Invoice Number'
 ,'Ordered By'
 ,'Original Invoice Amt'
 ,'Original Invoice Number'
 ,'Purchase Order'
 ,'Reconcile Date'
 ,'Release Number'
 ,'Ship To Location'
 ,'Ship To Name'
 ,'Total Discount Amt'
 ,'Total Freight Amt'
 ,'Total Miscellaneous Amt'
 ,'Total Tax Amt'
 ));
 
update XX_FIN_TRANSLATEVALUES
set SOURCE_VALUE10 = 'N'
where TRANSLATE_ID = (select TRANSLATE_ID from XX_FIN_TRANSLATEDEFINITION
where TRANSLATION_NAME ='XX_CDH_EBILLING_FIELDS')
and source_value1 in (SELECT FIELD_ID FROM XX_CDH_EBILLING_FIELDS_V  
WHERE include_in_detail = 'Y'
AND field_name not in
 ('Consolidated Bill Number'
 ,'Department'
 ,'Department Description'
 ,'Desktop'
 ,'Electronic Detail Sequence #'
 ,'Ext Price'
 ,'Invoice Number'
 ,'Item Description'
 ,'Line Association Discount Amt'
 ,'Line Bulk Discount Amt'
 ,'Line Coupon Amt'
 ,'Line  Freight Amt'
 ,'Line  Gift Card Amt'
 ,'Line Level Comment'
 ,'Line  Miscellaneous Amt'
 ,'Line Tax Row'
 ,'Line Tiered Discount Amt'
 ,'Ordered By'
 ,'Original Invoice Number'
 ,'Purchase Order'
 ,'Qty Shipped'
 ,'Reconcile Date'
 ,'Release Number'
 ,'Ship To Location'
 ,'Ship To Name'
 ,'SKU'
 ,'U/M'
 ,'Unit Price'
 ));

commit;

Exit;