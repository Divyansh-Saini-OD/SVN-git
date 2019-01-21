
  CREATE OR REPLACE FORCE VIEW "APPS"."XX_CRM_SIC_GROUP_V" ("SIC_CODE", "SIC_GROUP", "ENABLED_FLAG") AS 
  SELECT val.source_value1,
       val.source_value2,
       val.enabled_flag
FROM apps.xx_fin_translatedefinition def,
     apps.xx_fin_translatevalues val
WHERE def.translation_name = 'XX_CRM_SFDC_SIC_TO_GROUP'
AND def.translate_id = val.translate_id;
 
