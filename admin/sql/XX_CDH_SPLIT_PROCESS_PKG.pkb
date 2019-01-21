create or replace PACKAGE BODY      XX_CDH_SPLIT_PROCESS_PKG
AS
-- +========================================================================================+
-- |                               Office Depot                                             |
-- +========================================================================================+
-- | Name        :  XX_CDH_SPLIT_PROCESS_PKG.pkb                                            |
-- |                                                                                        |
-- | Subversion Info:                                                                       |
-- |                                                                                        |
-- |                                                                                        |
-- | Description :                                                                          |
-- |                                                                                        |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date         Author             Remarks                                       |
-- |========  ===========  =================  ==============================================|
-- |1.0       13-JUL-2015  Havish Kasina      Initial version                               |
-- |2.0       25-AUG-2015  Havish Kasina      added log messages                            |
-- |3.0       29-SEP-2015  Havish Kasina      Added identifying_address_flag                |
-- |4.0       19-OCT-2015  Havish Kasina      Removed the apps schema in the existing code  |
-- +========================================================================================+

--
--  "who" info
--
   anonymous_apps_user   CONSTANT NUMBER := -1;
   
  PROCEDURE log_exception (p_error_location   IN VARCHAR2,
                            p_error_msg        IN VARCHAR2)
   IS
   -- +===================================================================+
   -- | Name  : log_exception                                             |
   -- | Description     : The log_exception procedure logs all exceptions |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters      : p_error_location     IN -> Error location       |
   -- |                   p_error_msg          IN -> Error message        |
   -- +===================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   ln_login     NUMBER := fnd_global.login_id;
   ln_user_id   NUMBER := fnd_global.user_id;
   
   BEGIN   
      XX_COM_ERROR_LOG_PUB.log_error 
      (  p_return_code              => FND_API.G_RET_STS_ERROR,
         p_msg_count                => 1,
         p_application_name         => 'XXCRM',
         p_program_type             => 'Custom Messages',
         p_program_name             => 'XX_CDH_SPLIT_PROCESS_PKG',
         p_attribute15              => 'XX_CDH_SPLIT_PROCESS_PKG',
         p_program_id               => NULL,
         p_module_name              => 'MOD4A',
         p_error_location           => p_error_location,
         p_error_message_code       => NULL,
         p_error_message            => p_error_msg,
         p_error_message_severity   => 'MAJOR',
         p_error_status             => 'ACTIVE',
         p_created_by               => ln_user_id,
         p_last_updated_by          => ln_user_id,
         p_last_update_login        => ln_login
      );      
   EXCEPTION   
      WHEN OTHERS
      THEN
      fnd_file.put_line(fnd_file.log,'Error while writing to the log exception...' || SQLERRM); 
      
   END log_exception;

   -------------------------------------------------------------------------------
   PROCEDURE relink_party_sites (
                                   p_party_id        IN            NUMBER,
                                   p_party_sites_obj IN            XX_CDH_PARTY_SITE_OBJ_TYPE,
                                   x_party_id        OUT           NUMBER,
                                   x_return_status   OUT NOCOPY    VARCHAR2,
                                   x_error_message   OUT NOCOPY    VARCHAR2
                                )
   IS
-------------------------------------------------------------------------------
      l_rtn_sts                       VARCHAR2 (1) := fnd_api.g_ret_sts_success;
      l_id                            NUMBER       := NULL;
      l_curr_dt                       DATE         := SYSDATE;
      i                               PLS_INTEGER;
      e_process_exception             EXCEPTION;
      l_user_id                       NUMBER;
      
   BEGIN
      x_party_id     := NULL;
      x_return_status:= NULL;
      x_error_message:= NULL;
      
      IF (p_party_sites_obj.COUNT = 0 OR p_party_id IS NULL)
      THEN
         x_party_id      := p_party_id;
         x_return_status := 'ERROR';
         x_error_message := 'Either p_party_id or p_party_sites_obj have NULL Values';
         RAISE e_process_exception;
      END IF;

      BEGIN
         SELECT user_id
           INTO l_user_id
           FROM fnd_user
          WHERE user_name = 'ODCRMBPEL';
      EXCEPTION
         WHEN OTHERS
         THEN
            l_user_id := anonymous_apps_user;
      END;
      
      log_exception (p_error_location   => 'Before Entering the Loop',
                     p_error_msg        => 'Processing party id'||p_party_id); 
      
        I := p_party_sites_obj.FIRST;
        
        IF I IS NOT NULL THEN
            LOOP
               x_party_id     := NULL;
               x_return_status:= NULL;
               x_error_message:= NULL;
               
               log_exception (p_error_location   => 'Updating record for party site id for record '|| i ,
                              p_error_msg        => 'Party Site Id : '||p_party_sites_obj(i).party_site_id); 
                BEGIN
                  UPDATE hz_party_sites
                     SET party_id = p_party_id,
					               identifying_address_flag = 'N',
                         last_update_date = l_curr_dt,
                         last_updated_by = l_user_id
                   WHERE party_site_id = p_party_sites_obj(i).party_site_id;
                   
                    IF SQL%ROWCOUNT= 0 
                      THEN
                        x_party_id      := p_party_id;
                        x_return_status := 'ERROR';
                        x_error_message := 'Unable to update the party id :'||p_party_id ||' for Party site id :'||p_party_sites_obj(i).party_site_id ||' EXCEPTION = '|| SQLERRM;
                        
                        log_exception (p_error_location   => 'ERROR While Updaing ..',
                                       p_error_msg        => x_return_status || x_error_message); 
                                       
                        RAISE e_process_exception;
                    ELSE
                        x_party_id      := p_party_id;
                        x_return_status := 'SUCCESS';
                        x_error_message := NULL;
                        
                        log_exception (p_error_location   => 'After Update..',
                                       p_error_msg        => x_return_status || x_error_message ||' for party site id:'||p_party_sites_obj(i).party_site_id); 
                    END IF;                     
                END;
             EXIT WHEN I = p_party_sites_obj.LAST;
              I := p_party_sites_obj.NEXT(I);
             END LOOP;              
       END IF;
          
    COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
      ROLLBACK;
        IF x_error_message IS NULL
        THEN
           x_party_id      := p_party_id;
           x_return_status := 'ERROR';
           x_error_message := 'EXCEPTION ='|| SQLERRM;
           log_exception (p_error_location   => 'Party Id: '||p_party_id ,
                          p_error_msg        => x_return_status || x_error_message); 
           --DBMS_OUTPUT.PUT_LINE(x_error_message);
        END IF;
        
   END relink_party_sites;
END XX_CDH_SPLIT_PROCESS_PKG; 
/
SHOW ERRORS;