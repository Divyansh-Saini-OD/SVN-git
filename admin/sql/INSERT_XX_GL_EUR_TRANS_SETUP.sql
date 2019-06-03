SET FEEDBACK     ON
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                       Oracle                                                   |
-- +================================================================================+
-- | SQL Script to insert seeded values                                             |
-- |                                                                                |
-- | INSERT_XX_GL_EUR_TRANS_SETUP                                                   |
-- |  Rice ID : I2122                                                               |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author               Remarks                             |
-- |=======   ==========   =============        ====================================|
-- | V1.0     20-Nov-2013  Paddy Sanjeevi    	Initial version                     |
-- +================================================================================+

DECLARE
 l_translate_id 	NUMBER;
 l_translate_id_FX 	NUMBER;
BEGIN
  BEGIN
    SELECT translate_id
      INTO l_translate_id
      FROM xxfin.XX_FIN_TRANSLATEDEFINITION 
     WHERE translation_name='GL_RATE_REQUESTS';
  EXCEPTION
    WHEN others THEN
      l_translate_id:=NULL;
  END;
  BEGIN
    SELECT translate_id
      INTO l_translate_id_fx
      FROM xxfin.XX_FIN_TRANSLATEDEFINITION 
     WHERE translation_name='GL_RATE_REQUESTS_FX';
  EXCEPTION
    WHEN others THEN
      l_translate_id_fx:=NULL;
  END;

  IF l_translate_id IS NOT NULL THEN

     BEGIN
       Insert into APPS.XX_FIN_TRANSLATEVALUES
       	(TRANSLATE_ID, 
	 SOURCE_VALUE1, 
	 SOURCE_VALUE2, 
	 TARGET_VALUE2, 
	 TARGET_VALUE3, 
	 TARGET_VALUE4, 
	 TARGET_VALUE5, 
	 TARGET_VALUE10, 
	 CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, 
	 START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
       Values
         (l_translate_id, 
	  'EUR_DAILY', 
	  'FX', 
	  'EUR_DAILY_RATES.TXT', 
	  'EUR_DAILY_RATES.TXT', 
	  'Y', 
	  'N', 
	  'XXFIN_OUTBOUND', SYSDATE,	   33963,SYSDATE,33963,SYSDATE,'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
     EXCEPTION
       WHEN others THEN
	 NULL;
     END;

     BEGIN
       Insert into APPS.XX_FIN_TRANSLATEVALUES
       	(TRANSLATE_ID, 
	 SOURCE_VALUE1, 
	 SOURCE_VALUE2, 
	 TARGET_VALUE2, 
	 TARGET_VALUE3, 
	 TARGET_VALUE4, 
	 TARGET_VALUE5, 
	 TARGET_VALUE10, 
	 CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, 
	 START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
       Values
         (l_translate_id, 
	  'EUR_AVG', 
	  'FX', 
	  'EUR_AVG_RATES.TXT', 
	  'EUR_AVG_RATES.TXT', 
	  'Y', 
	  'N', 
	  'XXFIN_OUTBOUND', SYSDATE,	   33963,SYSDATE,33963,SYSDATE,'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
     EXCEPTION
       WHEN others THEN
	 NULL;
     END;
  END IF;
  IF l_translate_id_fx IS NOT NULL THEN

     BEGIN
       Insert into APPS.XX_FIN_TRANSLATEVALUES
       	(TRANSLATE_ID, 
	 SOURCE_VALUE1, 
	 TARGET_VALUE1, 
	 TARGET_VALUE2, 
	 TARGET_VALUE3, 
	 TARGET_VALUE4, 
	 TARGET_VALUE5, 
	 TARGET_VALUE6, 
	 TARGET_VALUE7, 	 CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, 
	 START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
       VALUES
        (l_translate_id_fx, 
	 'EUR_DAILY', 
	 'Ending Rate', 
	 '%', 
	 'EUR', 
	 'Y', 
	 'DAY,<from_currency>,<conversion_date>,<conversion_rate>,00000000, ,<to_currency>,<inverse_conversion_rate>', 
	 'YYMMDD', 
	 '00000000.0000000', 
	  SYSDATE,33963,SYSDATE,33963,
	  SYSDATE, 'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
     EXCEPTION
       WHEN others THEN
	 NULL;
     END;

     BEGIN
       Insert into APPS.XX_FIN_TRANSLATEVALUES
       	(TRANSLATE_ID, 
	 SOURCE_VALUE1, 
	 TARGET_VALUE1, 
	 TARGET_VALUE2, 
	 TARGET_VALUE3, 
	 TARGET_VALUE4, 
	 TARGET_VALUE5, 
	 TARGET_VALUE6, 
	 TARGET_VALUE7, 	 CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY, 
	 START_DATE_ACTIVE, ENABLED_FLAG, TRANSLATE_VALUE_ID)
       VALUES
        (l_translate_id_fx, 
	 'EUR_AVG', 
	 'Average Rate', 
	 '%', 
	 'EUR', 
	 'N', 
	 'AVG,<from_currency>,<conversion_date>,<conversion_rate>,00000000, ,<to_currency>,<inverse_conversion_rate>',
	 'YYMMDD', 
	 '00000000.0000000', 
	  SYSDATE,33963,SYSDATE,33963,
	  SYSDATE, 'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
     EXCEPTION
       WHEN others THEN
	 NULL;
     END;
  END IF;
  COMMIT;
END;
 /

SHOW ERROR