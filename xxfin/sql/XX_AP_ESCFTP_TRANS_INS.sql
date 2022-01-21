  DECLARE
      ln_translate_id NUMBER;
  BEGIN
  
    SELECT distinct translate_id
      INTO ln_translate_id
      FROM XX_FIN_TRANSLATEDEFINITION TD
     WHERE td.translation_name = 'OD_FTP_PROCESSES'; 
  

     INSERT INTO XXFIN.XX_FIN_TRANSLATEVALUES  
           (TRANSLATE_ID	
           ,SOURCE_VALUE1	
           ,TARGET_VALUE1	
           ,TARGET_VALUE2	
           ,TARGET_VALUE3	
           ,TARGET_VALUE4	
           ,TARGET_VALUE5	
           ,TARGET_VALUE6	
           ,TARGET_VALUE7	
           ,CREATION_DATE	
           ,CREATED_BY	
           ,LAST_UPDATE_DATE	
           ,LAST_UPDATED_BY	
           ,LAST_UPDATE_LOGIN	
           ,START_DATE_ACTIVE	
           ,ENABLED_FLAG	
           ,TRANSLATE_VALUE_ID
          )
          VALUES
          (    ln_translate_id
              ,'OD_AP_ESCHEAT'
              ,'odsc02.na.odcorp.net'	
              ,'NA/PRODFTP'	
              ,'FTPPROD'	
              ,'$XXFIN_DATA/outbound'	
              ,'/acap/AbandonedProperty/AccountsPayableCheckOracle'	
              ,'N'	
              ,'$XXFIN_DATA/archive/outbound'	
              ,SYSDATE 
              ,-1	
              ,SYSDATE	
              ,-1	
              ,-1	
              ,SYSDATE	
              ,'Y'	
              ,XX_FIN_TRANSLATEVALUES_S.nextval
            );

     COMMIT;
     
     INSERT INTO XXFIN.XX_FIN_TRANSLATEVALUES  
           (TRANSLATE_ID	
           ,SOURCE_VALUE1	
           ,TARGET_VALUE1	
           ,TARGET_VALUE2	
           ,TARGET_VALUE3	
           ,TARGET_VALUE4	
           ,TARGET_VALUE5	
           ,TARGET_VALUE6	
           ,TARGET_VALUE7	
           ,CREATION_DATE	
           ,CREATED_BY	
           ,LAST_UPDATE_DATE	
           ,LAST_UPDATED_BY	
           ,LAST_UPDATE_LOGIN	
           ,START_DATE_ACTIVE	
           ,ENABLED_FLAG	
           ,TRANSLATE_VALUE_ID
          )
          VALUES
          (    ln_translate_id
              ,'OD_AP_PAR'
              ,'odsc02.na.odcorp.net'	
              ,'NA/PRODFTP'	
              ,'FTPPROD'	
              ,'$XXFIN_DATA/outbound'	
              ,'/acap/PostAudit/ORACLE_PAR_APCKS'	
              ,'N'	
              ,'$XXFIN_DATA/archive/outbound'	
              ,SYSDATE 
              ,-1	
              ,SYSDATE	
              ,-1	
              ,-1	
              ,SYSDATE	
              ,'Y'	
              ,XX_FIN_TRANSLATEVALUES_S.nextval
            );

   COMMIT;
  END;

