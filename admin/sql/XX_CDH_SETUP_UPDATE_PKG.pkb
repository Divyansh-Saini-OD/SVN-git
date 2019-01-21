SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_SETUP_UPDATE_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_SETUP_UPDATE_PKG.pkb                        |
-- | Description :  Code to Update Profile and FinTranslation Setups   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  22-Jan-2009 Indra Varada       Initial draft version     |
-- +===================================================================+

AS

  PROCEDURE update_main
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_profile_name           IN  VARCHAR2,
       p_profile_value          IN  VARCHAR2,
       p_profile_level          IN  VARCHAR2,
       p_profile_level_value    IN  VARCHAR2,
       p_translation_name       IN  VARCHAR2,
       p_source_values          IN  VARCHAR2,
       p_target_values          IN  VARCHAR2,
       p_commit                 IN  VARCHAR2
   ) AS
   l_profile_status              BOOLEAN;
   l_fin_update_sql              VARCHAR2(2000);
   l_target_values               VARCHAR2(150);
   l_source_values               VARCHAR2(150);
   l_counter                     NUMBER := 1;
   l_target_val_sql              VARCHAR2(300);
   l_source_val_sql              VARCHAR2(300);
  BEGIN
     
    IF p_profile_name IS NOT NULL AND p_profile_value IS NOT NULL THEN
    
        fnd_file.put_line (fnd_file.log, 'Updating Profile Option Setup.........');
        fnd_file.put_line (fnd_file.log, 'Profile Option Name:' || p_profile_name);
        fnd_file.put_line (fnd_file.log, 'Profile Option Value:' || p_profile_value);
       
        l_profile_status := fnd_profile.SAVE(p_profile_name,p_profile_value,p_profile_level,p_profile_level_value);
       
        IF l_profile_status THEN
          fnd_file.put_line (fnd_file.log, 'Profile Option Update - Successful');
        ELSE
          fnd_file.put_line (fnd_file.log, 'Profile Option Update - Failed');
        END IF;
    
    END IF;
    
    IF p_translation_name IS NOT NULL AND p_source_values IS NOT NULL AND p_target_values IS NOT NULL THEN
       
        fnd_file.put_line (fnd_file.log, 'Updating FIN Translation Setup.........');
       
       l_source_values  := p_source_values || '/';
       l_target_values  := p_target_values || '/';
       
       l_fin_update_sql := 'UPDATE XX_FIN_TRANSLATEVALUES SET ';
       
       WHILE TRIM(l_target_values) IS NOT NULL LOOP
         l_target_val_sql  := l_target_val_sql || 'TARGET_VALUE' || TO_CHAR(l_counter) || '=''' || substr(l_target_values,0,instr(l_target_values,'/')-1) || '''';
         l_target_values := substr(l_target_values,instr(l_target_values,'/')+1);
         l_counter := l_counter + 1;
         IF l_target_values IS NOT NULL THEN
           l_target_val_sql := l_target_val_sql || ' AND ';
         END IF;
       END LOOP;
       
       l_fin_update_sql := l_fin_update_sql || l_target_val_sql 
                           || ' WHERE TRANSLATE_ID = (SELECT TRANSLATE_ID FROM XX_FIN_TRANSLATEDEFINITION
                                                      WHERE TRANSLATION_NAME = ''' || p_translation_name 
                                                      || ''') AND ';
        l_counter := 1;
        
        WHILE TRIM(l_source_values) IS NOT NULL LOOP
         l_source_val_sql  := l_source_val_sql || 'SOURCE_VALUE' || TO_CHAR(l_counter) || '=''' || substr(l_source_values,0,instr(l_source_values,'/')-1) || '''';
         l_source_values := substr(l_source_values,instr(l_source_values,'/')+1);
         l_counter := l_counter + 1;
         IF l_source_values IS NOT NULL THEN
           l_source_val_sql := l_source_val_sql || ' AND ';
         END IF;
       END LOOP;
      
        l_fin_update_sql := l_fin_update_sql || l_source_val_sql;  
        
        fnd_file.put_line (fnd_file.log, 'Update SQL:' || l_fin_update_sql);
        
       EXECUTE IMMEDIATE l_fin_update_sql;
        
        fnd_file.put_line (fnd_file.log, 'Total FIN Translation Setup Rows Updated:' || SQL%ROWCOUNT);
        
        IF SQL%ROWCOUNT > 0 THEN
           fnd_file.put_line (fnd_file.log, 'FIN Translation Update - Successful');
        ELSE
           fnd_file.put_line (fnd_file.log, 'FIN Translation Update - Failed');
        END IF;
     END IF;
     
     IF p_commit = 'Y' THEN
       COMMIT;
       fnd_file.put_line (fnd_file.log, 'Changes Committed');
     ELSE
       ROLLBACK;
       fnd_file.put_line (fnd_file.log, 'Changes Rolled Back');
     END IF;
     
  EXCEPTION WHEN OTHERS THEN
     fnd_file.put_line (fnd_file.log,'UnExpected Error Occured In the Procedure - update_main : ' || SQLERRM);
     x_errbuf := 'UnExpected Error Occured In the Procedure - update_main : ' || SQLERRM;
     x_retcode := 2;  
  END update_main;
  
END XX_CDH_SETUP_UPDATE_PKG;
/
SHOW ERRORS;
EXIT;