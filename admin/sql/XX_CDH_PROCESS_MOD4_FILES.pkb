CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_PROCESS_MOD4_FILES
AS
   -- +=========================================================================+
   -- |                        Office Depot                                      |
   -- +=========================================================================+
   -- | Name  : XX_CDH_PROCESS_MOD4_FILES                                   |
   -- | Rice ID: C0701                                                          |
   -- | Description      : This Program will get "XXOD_OMX_MOD4_INTERFACE"      |
   -- |                    Translation Data as well as updates the batch_id     |
   -- |                                                                         |
   -- |Change Record:                                                           |
   -- |===============                                                          |
   -- |Version Date        Author            Remarks                            |
   -- |======= =========== =============== =====================================|
   --|1.0     10-FEB-2015 Abhi K          Initial draft version                |
   --|1.1     20-MAR-2015 Abhi K          Code Review
   -- +=========================================================================+
   
   PROCEDURE get_config_info (retcode                OUT NUMBER,
                              errbuf                 OUT VARCHAR2,
                              p_file_name            IN     VARCHAR2,
                              lc_config_details      OUT VARCHAR2)
   IS
   
     --------------------------------
      -- Local Variable Declaration --
      --------------------------------
      lc_error_msg   VARCHAR2 (1000);
   BEGIN
      SELECT    TRIM (xxftlv.TARGET_VALUE3)
             || '|'
             || TRIM (xxftlv.TARGET_VALUE2)
             || '|'
             || TRIM (xxftlv.TARGET_VALUE6)
             || '|'
             || TRIM (xxftlv.TARGET_VALUE5)
             || '|'
        INTO lc_config_details
        FROM XX_FIN_TRANSLATEDEFINITION xxftl, XX_FIN_TRANSLATEVALUES xxftlv
       WHERE     xxftl.translate_id = xxftlv.translate_id
             AND xxftl.Translation_Name = 'XXOD_OMX_MOD4_INTERFACE'
             AND p_file_name LIKE
                       SUBSTR (TARGET_VALUE2,
                               1,
                                 INSTR (TARGET_VALUE2,
                                        '.',
                                        -1,
                                        1)
                               - 1)
                    || '%'
             AND TARGET_VALUE2 IS NOT NULL;

      DBMS_OUTPUT.PUT_LINE(substr(lc_config_details,1,255));
    EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :='NO DATA for the Translation XXOD_OMX_MOD4_INTERFACE'
            || ' ' || SQLERRM;
         DBMS_OUTPUT.PUT_LINE(substr(lc_config_details,1,255));
      WHEN OTHERS
      THEN
         lc_error_msg :=
            'Unable to fetch DATA for the Translation XXOD_OMX_MOD4_INTERFACE :' || ' ' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         
        DBMS_OUTPUT.PUT_LINE(substr(lc_config_details,1,255));
   END;


   PROCEDURE update_table (retcode           OUT NUMBER,
                           errbuf            OUT VARCHAR2,
                           p_tab_name     IN     VARCHAR2,
                           p_source       IN     VARCHAR2,
                           p_file_name    IN     VARCHAR2,
                           p_request_id   IN     NUMBER,
                           p_user_id      IN     VARCHAR2,
                           p_login_id     IN     NUMBER)
   IS
      --------------------------------
      -- Local Variable Declaration --
      --------------------------------
      lc_error_msg      VARCHAR2(4000);
      lc_update_table   VARCHAR2(32000);
      lc_batch_id       number;
   BEGIN
      lc_error_msg  := NULL;
      lc_update_table := NULL;
      lc_batch_id     := 0;

      IF p_source = 'sfdc'
      THEN
         SELECT XXOD_OMX_MOD4_batch_ID_S.NEXTVAL INTO lc_batch_id FROM DUAL;

         lc_update_table :=
               'UPDATE'
            || ' '
            || p_tab_name
            || ' '
            || 'SET batch_id ='
            || lc_batch_id
            || ','
            || 'FILE_NAME ='
            || ' '
            || p_file_name
            || ','
            || 'Request_id = '
            || ' '
            || p_request_id
            || ','
            || 'created_by = '
            || ' '
            ||  p_login_id   
            || ','
            || 'last_updated_by = '
            || ' '
            ||  p_login_id
            || ' '  
            || 'where batch_id is null and Status = ''N'' and file_name is null';
            
            lc_error_msg := 'Created new Batch_id :'||lc_batch_id ||'in the table '||p_tab_name;
      ELSE
         lc_update_table :=
               'UPDATE'
            || ' '
            || p_tab_name
            || ' '
            || 'SET FILE_NAME ='
            || ' '
            || p_file_name
            || ','
            || 'Request_id = '
            || ' '
            || p_request_id
            || ','
            || 'created_by = '
            || ' '
            ||  p_login_id  
            || ','
            || 'last_updated_by = '
            || ' '
            ||  p_login_id    
            || ' '  
            || 'where batch_id is not null and Status = ''N'' and file_name is null';
            
            lc_error_msg := 'Updated the file name '||p_file_name||'in the table '||p_tab_name;
      END IF;
  
      DBMS_OUTPUT.PUT_LINE(substr(lc_update_table,1,255));

      EXECUTE IMMEDIATE lc_update_table;
      
EXCEPTION    
       WHEN OTHERS
      THEN
       IF lc_error_msg is null then
         lc_error_msg :=
            'Unable to update_table ERROR:' || ' ' || SQLERRM;
       END IF;     
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         
        DBMS_OUTPUT.PUT_LINE(substr(lc_update_table,1,255));
        
   END;
END XX_CDH_PROCESS_MOD4_FILES; 
/
SHOW ERRORS;

