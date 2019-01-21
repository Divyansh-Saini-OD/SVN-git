
-- Update records from XX_CDH_SOLAR_CONVERSION_GROUP
BEGIN
UPDATE apps.xx_cdh_solar_conversion_group
set converted_flag = 'Y'
where conversion_group_id = 'RSD1';
COMMIT;
END;
/
show errors
