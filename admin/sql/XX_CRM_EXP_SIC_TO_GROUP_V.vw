CREATE VIEW apps.xx_crm_exp_sic_to_group_v
(sic_code,sic_group)
as
SELECT source_value1,source_value2
FROM apps.XX_FIN_TRANSLATEVALUES vl,apps.xx_fin_translatedefinition def
WHERE vl.TRANSLATE_ID = def.translate_id
AND def.translation_name = 'XX_CRM_SFDC_SIC_TO_GROUP';