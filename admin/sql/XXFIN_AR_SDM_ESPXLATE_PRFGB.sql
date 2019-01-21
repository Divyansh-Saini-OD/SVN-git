--*
--* Create xx_fin_translatevalues for EFARPURG
--*
Insert into xxfin.xx_fin_translatevalues 
      (TRANSLATE_ID
      ,SOURCE_VALUE1
      ,SOURCE_VALUE2
      ,TARGET_VALUE1
      ,TARGET_VALUE2
      ,TARGET_VALUE3
      ,TARGET_VALUE4
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,START_DATE_ACTIVE
      ,ENABLED_FLAG
      ,TRANSLATE_VALUE_ID) 
VALUES 
      ((select translate_id 
        from   apps.xx_fin_translatedefinition 
        where  TRANSLATION_NAME = 'ESP_E9AR_JOB_DEF')
      ,'E9ARPURG'
      ,'USPGMC01'
      ,'OD (US) AR Batch Jobs'
      ,'XXFIN'
      ,'XX_AR_TRANS_PURGE_WRAPPER'
      ,',,HEADERS,18,,N,N!PRGWDWENDDATE1,10000,N,N'
      ,CURRENT_DATE
      ,22765
      ,CURRENT_DATE
      ,22765
      ,CURRENT_DATE
      ,'Y'
      ,XX_FIN_TRANSLATEVALUES_S.NEXTVAL)

--*
--* Create xx_fin_translatevalues for variable PURGDATE
--*
Insert into xxfin.xx_fin_translatevalues 
      (translate_id
      ,SOURCE_VALUE1
      ,SOURCE_VALUE2
      ,SOURCE_VALUE3
      ,TARGET_VALUE1
      ,TARGET_VALUE2
      ,TARGET_VALUE3
      ,TARGET_VALUE4
      ,CREATION_DATE
      ,CREATED_BY
      ,LAST_UPDATE_DATE
      ,LAST_UPDATED_BY
      ,START_DATE_ACTIVE
      ,ENABLED_FLAG
      ,TRANSLATE_VALUE_ID) 
VALUES 
      ((select translate_id 
        from   apps.xx_fin_translatedefinition 
        where  TRANSLATION_NAME = 'ESP_E9AR_ARG_DEF')
      ,'%'
      ,'%'
      ,'!PRGWDWENDDATE1'
      ,'S'
      ,'SELECT TO_CHAR(CURRENT_DATE,''YYYY/MM/DD'')||'' 23:00:00'' FROM DUAL'
      ,'EFAR,PRGWDWENDDATE1'
      ,CURRENT_DATE
      ,22765
      ,CURRENT_DATE
      ,22765
      ,CURRENT_DATE
      ,'Y'
      ,XX_FIN_TRANSLATEVALUES_S.NEXTVAL)



