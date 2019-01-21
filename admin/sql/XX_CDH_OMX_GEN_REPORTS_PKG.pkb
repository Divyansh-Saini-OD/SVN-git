create or replace PACKAGE BODY      XX_CDH_OMX_GEN_REPORTS_PKG
AS
-- +==================================================================================+
-- |                        Office Depot                                              |
-- +==================================================================================+
-- | Name  : XX_CDH_OMX_GEN_REPORTS_PKG                                               |
-- | Rice ID: C0700                                                                   |
-- | Description      : This program will process all the records and creates the     |
-- |                    ebilling contacts and link to corresponding billing document  |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version Date        Author            Remarks                                     |
-- |======= =========== =============== ==============================================|
-- |1.0     23-FEB-2015 Havish Kasina   Initial draft version                         |
-- |2.0     13-MAR-2015 Havish Kasina   Code review changes                           |
-- |3.0     31-MAR-2015 Havish Kasina   Changes done as per defect id : 1009          |
-- |4.0     19-MAY-2015 Havish Kasina   Changes done as per defect id : 1322          |
-- |5.0      8-JUL-2015 Havish Kasina   Changes done as per defect id : 34883         |
-- |6.0      8-JUL-2015 Havish Kasina   MOD5 Changes                                  |
-- |7.0     15-SEP-2015 Havish Kasina   Changes done as per Defect 1710               |
-- |8.0     12-MAY-2016 Havish Kasina   Changes done as per Defect 37158              |
-- +==================================================================================+
   --------------------------------
   -- Global Variable Declaration --
   --------------------------------
   gd_last_update_date    DATE          := SYSDATE;
   gn_last_updated_by     NUMBER        := fnd_global.user_id;
   gd_creation_date       DATE          := SYSDATE;
   gn_created_by          NUMBER        := fnd_global.user_id;
   gn_last_update_login   NUMBER        := fnd_global.login_id;
   gn_request_id          NUMBER        := fnd_global.conc_request_id;
   gd_cycle_date          DATE          := SYSDATE;
   gn_conc_request_id     NUMBER        := fnd_global.conc_request_id;  -- request_id
   gn_conc_prog_appl_id   NUMBER        := fnd_global.prog_appl_id; -- program_application_id
   gn_conc_program_id     NUMBER        := fnd_global.conc_program_id;  -- program_id
   gc_success             VARCHAR2(100) := 'SUCCESS';
   gc_failure             VARCHAR2(100) := 'FAILURE';
   g_debug_flag           BOOLEAN;
   gc_date                VARCHAR2 (200):= TO_CHAR (SYSDATE-1, 'MM/DD/YYYY');

   PROCEDURE log_msg (p_string IN VARCHAR2)
   IS
   -- +===================================================================+
   -- | Name  : log_msg                                                   |
   -- | Description     : The log_msg procedure displays the log messages |
   -- |                                                                   |
   -- |                                                                   |
   -- | Parameters      : p_string             IN -> Log Message          |
   -- +===================================================================+
   BEGIN
   
      IF (g_debug_flag)
      THEN      
         fnd_file.put_line (fnd_file.LOG, p_string);         
      END IF;
      
   END log_msg;

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
   ln_login     NUMBER := gn_last_update_login;
   ln_user_id   NUMBER := gn_created_by;
   
   BEGIN   
      XX_COM_ERROR_LOG_PUB.log_error 
      (  p_return_code              => FND_API.G_RET_STS_ERROR,
         p_msg_count                => 1,
         p_application_name         => 'XXCRM',
         p_program_type             => 'Custom Messages',
         p_program_name             => 'XX_CDH_OMX_GEN_REPORTS',
         p_attribute15              => 'XX_CDH_OMX_GEN_REPORTS',
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
      log_msg('Error while writing to the log exception...' || SQLERRM);      
   END log_exception;
   
-- Logging the program name and total records processed information
   PROCEDURE log_file (p_success_records   IN NUMBER,
                       p_failed_records    IN NUMBER,
                       p_batch_id          IN NUMBER,
                       p_file_name         IN VARCHAR2,
                       p_status            IN VARCHAR2)
   IS   
   -- +==============================================================================+
   -- | Name        : log_table                                                      |
   -- | Description : This procedure is used to log  program name and total_records  |
   -- |                                                                              |
   -- | Parameters : p_success_records         IN  -> Success records                |
   -- |              p_failed_records          IN  -> Failed records                 |
   -- |              p_batch_id                IN  -> Batch Id                       |
   -- |              p_file_name               IN  -> File Name                      |
   -- |              p_status                  IN  -> Status                         |
   -- +==============================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   lc_error_msg         VARCHAR2 (4000):= NULL;
   lc_program_name      VARCHAR2 (200);
   e_process_exception  EXCEPTION;
   
   BEGIN
      -------------------------------------------------------------------
      --Insert record in xx_cdh_omx_file_log table for tracking purpose .
      ----------------------------------------------------------------
      BEGIN   
         SELECT fcp.user_concurrent_program_name 
           INTO lc_program_name
           FROM fnd_concurrent_programs_vl fcp, fnd_concurrent_requests fcr
          WHERE fcp.concurrent_program_id = fcr.concurrent_program_id
            AND fcr.request_id = gn_request_id;   
          
      EXCEPTION      
         WHEN NO_DATA_FOUND
         THEN
         lc_error_msg :='Concurrent Program Name not found for Request ID: '|| gn_request_id;
         RAISE e_process_exception;                       
         WHEN OTHERS
         THEN
           IF lc_error_msg is NULL 
           THEN 
               lc_error_msg :='Unable to fetch Concurrent Program name for Request ID :'|| gn_request_id|| ' '|| SQLERRM;
           END IF;
           RAISE e_process_exception;                        
      END;
   
         log_msg('Inserting the log records into log table');
         INSERT INTO xx_cdh_omx_file_log_stg (program_id,
                                              program_name,
                                              program_run_date,
                                              file_name,
                                              success_records,
                                              failure_records,
                                              status,
                                              request_id,
                                              cycle_date,
                                              batch_num,
                                              error_message,
                                              creation_date,
                                              created_by,
                                              last_updated_by,
                                              last_update_date,
                                              last_update_login)
                                       VALUES (gn_request_id,
                                              lc_program_name,
                                              SYSDATE,
                                              p_file_name,
                                              p_success_records,
                                              p_failed_records,
                                              p_status,
                                              gn_request_id,
                                              gd_cycle_date,
                                              p_batch_id,
                                              NULL,
                                              gd_creation_date,
                                              gn_created_by,
                                              gn_last_updated_by,
                                              gd_last_update_date,
                                              gn_last_update_login);
                        
   EXCEPTION   
      WHEN OTHERS
      THEN
      IF lc_error_msg is NULL 
      THEN
         lc_error_msg :='Unable to insert the records in log table' || SQLERRM;
      END IF;
      log_msg (lc_error_msg);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.LOG_FILE',
                     p_error_msg        => lc_error_msg);                     
   END log_file;
   

-- Get Config details
   PROCEDURE get_config_details (p_process_type       IN    VARCHAR2,
                                 p_config_details_rec OUT   xx_fin_translatevalues%ROWTYPE,
                                 p_return_status      OUT   VARCHAR2,
                                 p_return_msg         OUT   VARCHAR2
                                )
   IS
   --+===============================================================================+
   -- | Name  : get_config_details                                                   |
   -- | Description     : This procedure is to retreive the translation values       |
   -- |                   for respective process type                                |
   -- |                                                                              |
   -- | Parameters      : p_process_type         IN   -> Process Type                |
   -- |                   p_config_details_rec   OUT  -> Config Details              |
   -- |                   p_return_status        OUT  -> Return Status               |
   -- |                   p_return_msg           OUT  -> Return Message              |
   -- +==============================================================================+  
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
   lc_translation_name        xx_fin_translatedefinition.translation_name%TYPE := 'XXOD_OMX_MOD4_INTERFACE';
   lc_error_msg               VARCHAR2(4000);       
   BEGIN  
   --========================================================================
   -- Retreiving Translation Definition Values
   --========================================================================
      p_config_details_rec := NULL;
      p_return_status      := NULL;
      p_return_msg         := NULL;
      log_msg('Retreiving Translation Definition Values ');  
              
      SELECT xftv.*
        INTO p_config_details_rec
        FROM xx_fin_translatevalues xftv
            ,xx_fin_translatedefinition xftd
      WHERE xftv.translate_id = xftd.translate_id
        AND xftd.translation_name = lc_translation_name
        AND xftv.source_value1 = p_process_type
        AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
        AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
        AND xftv.enabled_flag = 'Y'
        AND xftd.enabled_flag = 'Y';  
        
      p_return_status:= gc_success;
      p_return_msg   := NULL;
   EXCEPTION  
      WHEN NO_DATA_FOUND 
      THEN
      lc_error_msg:= 'Interface (Process Type) is not defined: '||p_process_type;
      log_msg(lc_error_msg);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.GET_CONFIG_DETAILS',
                     p_error_msg        => lc_error_msg);
      p_return_status      := gc_failure;
      p_return_msg         := lc_error_msg;  
      p_config_details_rec := NULL;    
      WHEN OTHERS THEN
      lc_error_msg:= 'Interface (Process Type) could not be retrieved: '||p_process_type;
      log_msg(lc_error_msg);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.GET_CONFIG_DETAILS',
                     p_error_msg        => lc_error_msg);
      p_return_status      := gc_failure;
      p_return_msg         := lc_error_msg;
      p_config_details_rec := NULL; 
   END get_config_details;

-- Move the file from Source directory to Destination and Archive directories   
PROCEDURE move_file  (p_file_name          IN     VARCHAR2,
                      p_config_details_rec IN     xx_fin_translatevalues%ROWTYPE,
                      p_sfdc_source        IN     VARCHAR2,
                      p_return_status      OUT    VARCHAR2,
                      p_return_msg         OUT    VARCHAR2,
                      p_copy_file_complete OUT    VARCHAR2
                     )
   IS
   -- +=================================================================================+
   -- | Name  : move_file                                                               |
   -- | Description : This procedure picks the outbound file from source directory and  |
   -- |               sends the file to destination directory                           |
   -- | Parameters  :     p_file_name           IN  -> file name                        |
   -- |                   p_config_details_rec  IN  -> Configuration Details            |
   -- |                   p_sfdc_source         IN                                      |
   -- |                   p_return_status       OUT -> return status                    |
   -- |                   p_return_msg          OUT -> return message                   |
   -- |                   p_copy_file_complete  OUT                                     |
   -- +=================================================================================+
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
   lc_sourcepath             VARCHAR2 (200);
   lc_destpath               VARCHAR2 (200);
   lc_archivepath            VARCHAR2 (200);
   lc_error_msg              VARCHAR2 (4000);
   e_error_exception         EXCEPTION;
   ln_copy_conc_request_id   NUMBER;   
   lb_complete               BOOLEAN;
   lc_phase                  VARCHAR2 (100);
   lc_status                 VARCHAR2 (100);
   lc_dev_phase              VARCHAR2 (100);
   lc_dev_status             VARCHAR2 (100);
   lc_message                VARCHAR2 (100);  
       
   BEGIN  
       lc_sourcepath             := NULL;
       lc_destpath               := NULL;
       lc_archivepath            := NULL;
       lc_error_msg              := NULL;
       ln_copy_conc_request_id   := NULL;   
       lb_complete               := NULL;
       lc_phase                  := NULL;
       lc_status                 := NULL;
       lc_dev_phase              := NULL;
       lc_dev_status             := NULL;
       lc_message                := NULL; 
       
      log_msg('Move file from Source Directory to Destination and Archive directories');
      
      -- Get the Source Path      
         BEGIN      
             SELECT directory_path
               INTO lc_sourcepath
               FROM all_directories
              WHERE directory_name = p_config_details_rec.target_value7;          
         EXCEPTION         
         WHEN NO_DATA_FOUND
         THEN
             lc_error_msg := 'Source Directory is not found ';
             RAISE e_error_exception;
         WHEN OTHERS
         THEN
             lc_error_msg := 'Unable to fetch Source directory ' || SQLERRM;
             RAISE e_error_exception;             
         END;
         
      -- Get the Destination Path      
         BEGIN      
             SELECT directory_path
               INTO lc_destpath
               FROM all_directories
              WHERE directory_name = p_config_details_rec.target_value8;          
         EXCEPTION        
         WHEN NO_DATA_FOUND
         THEN
             lc_error_msg := 'Destination Directory is not found ';
             RAISE e_error_exception;
         WHEN OTHERS
         THEN
             lc_error_msg := 'Unable to fetch Destination directory ' || SQLERRM;
             RAISE e_error_exception;             
         END;
         
      -- Getthe Archive Path
         BEGIN         
             SELECT directory_path
               INTO lc_archivepath
               FROM all_directories
              WHERE directory_name = p_config_details_rec.target_value9;              
         EXCEPTION         
         WHEN NO_DATA_FOUND
         THEN 
            lc_error_msg := 'Archive Directory is not found';
            log_msg(lc_error_msg);
            log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.MOVE_FILE',
                           p_error_msg        => lc_error_msg);                                                      
         WHEN OTHERS
         THEN
            lc_error_msg :='Unable to fetch Archive Directory path' || SQLERRM;
            log_msg(lc_error_msg);
            log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.MOVE_FILE',
                           p_error_msg        => lc_error_msg);                           
         END;
                               
       IF p_sfdc_source = 'Y'
       THEN      
      -- Config Details       
         lc_sourcepath  := lc_sourcepath || '/' || p_file_name;
         lc_destpath    := lc_destpath || '/sfdc/extracts/' || p_file_name;
         lc_archivepath := lc_archivepath;
       ELSE
         lc_sourcepath  := lc_sourcepath || '/' || p_file_name;
         lc_destpath    := lc_destpath || '/' || p_file_name;
         lc_archivepath := lc_archivepath;
       END IF;
         
         fnd_file.put_line(fnd_file.log,'File Name is ....'||p_file_name);  
         fnd_file.put_line(fnd_file.log,'Source directory name is....'||p_config_details_rec.target_value7);     
         fnd_file.put_line(fnd_file.log,'Source Path is....'||lc_sourcepath);
         fnd_file.put_line(fnd_file.log,'Destination directory name is....'||p_config_details_rec.target_value8); 
         fnd_file.put_line(fnd_file.log,'Destination Path is....'||lc_destpath);
         fnd_file.put_line(fnd_file.log,'Archive directory name is....'||p_config_details_rec.target_value9); 
         fnd_file.put_line(fnd_file.log,'Archive Path is....'||lc_archivepath);
       
      -- Calling File Copy Program       
         log_msg ('Calling File Copy Program to copy the outbound file from Source to Destination');
         ln_copy_conc_request_id := fnd_request.submit_request (    application   => 'XXFIN',
                                                                    program       => 'XXCOMFILCOPY',
                                                                    description   => NULL,
                                                                    start_time    => NULL,
                                                                    sub_request   => FALSE,
                                                                    argument1     => lc_sourcepath,
                                                                    argument2     => lc_destpath,
                                                                    argument3     => NULL,
                                                                    argument4     => NULL,
                                                                    argument5     => 'Y',
                                                                    argument6     => lc_archivepath,
                                                                    argument7     => NULL,
                                                                    argument8     => NULL,
                                                                    argument9     => NULL,
                                                                    argument10    => NULL,
                                                                    argument11    => NULL,
                                                                    argument12    => NULL,
                                                                    argument13    => NULL
                                                                 );                                                                
      -- Checking whether the request is Success or Not                                                         

         IF ln_copy_conc_request_id > 0
         THEN
            COMMIT;  
            lb_complete :=
               fnd_concurrent.wait_for_request
                                      (request_id      => ln_copy_conc_request_id,
                                       INTERVAL        => 30,
                                       max_wait        => 0,                                                          
                                       phase           => lc_phase,
                                       status          => lc_status,
                                       dev_phase       => lc_dev_phase,
                                       dev_status      => lc_dev_status,
                                       MESSAGE         => lc_message
                                      );                      
         ELSE           
            lc_error_msg:= 'Unable to launch File Copy Program ';
            RAISE e_error_exception;                                                              
         END IF;
            
       p_return_status      := gc_success;
       p_return_msg         := NULL;
       p_copy_file_complete := lc_dev_phase;
       
   EXCEPTION           
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
         lc_error_msg := 'Unable to copy and mail the file' || SQLERRM;
         END IF;
         log_msg(lc_error_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.MOVE_FILE',
                        p_error_msg        => lc_error_msg);
         p_return_msg   := lc_error_msg;
         p_return_status:= gc_failure;
   END move_file;  
   
   PROCEDURE send_mail (p_file_name          IN     VARCHAR2,
                        p_attach_text        IN     VARCHAR2,
                        p_config_details_rec IN     xx_fin_translatevalues%ROWTYPE,
                        p_mail_subject       IN     VARCHAR2,
                        p_copy_file_complete IN     VARCHAR2,
                        p_return_status      OUT    VARCHAR2,
                        p_return_msg         OUT    VARCHAR2
                                       )
   IS
   -- +=================================================================================+
   -- | Name  : send_mail                                                               |
   -- | Description : This procedure is to mail the file with attachment or without     |
   -- |               attachement to Dist list                                          |
   -- | Parameters  :     p_file_name           IN  -> file name                        |
   -- |                   p_attach_text         IN  -> Body of the mail                 |
   -- |                   p_config_details_rec  IN  -> Configuration Details            |
   -- |                   p_mail_subject        IN  -> Subject of the mail              |
   -- |                   p_copy_file_complete  IN                                      |
   -- |                   p_return_status       OUT -> return status                    |
   -- |                   p_return_msg          OUT -> return message                   |  
   -- +=================================================================================+
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
   lc_error_msg              VARCHAR2 (4000);
   e_error_exception         EXCEPTION;
   lc_conn                   UTL_SMTP.connection;
       
   BEGIN  
     p_return_status := NULL;
     lc_error_msg    := NULL;
     
     fnd_file.put_line(fnd_file.log,'Sender Email is....'||p_config_details_rec.target_value10);
     fnd_file.put_line(fnd_file.log,'Recipient Email is....'||p_config_details_rec.target_value4);
        
     IF  p_file_name IS NOT NULL AND UPPER(p_copy_file_complete) IN ('COMPLETE')
     THEN
      log_msg('Send mail with attachment');
                   
      -- Calling xx_pa_pb_mail procedure to mail with outbound file attachment to Dist List                     
         lc_conn := xx_pa_pb_mail.begin_mail ( sender          => p_config_details_rec.target_value10,
                                               recipients      => p_config_details_rec.target_value4,
                                               cc_recipients   => NULL,
                                               subject         => p_mail_subject,
                                               mime_type       => xx_pa_pb_mail.multipart_mime_type
                                             );                                                 
       -- Attach the file in the mail
          xx_pa_pb_mail.xx_attach_excel (lc_conn, p_file_name);
       -- End of attachmaent in the mail
          xx_pa_pb_mail.end_attachment (conn => lc_conn);
       -- Attach text in the mail
          xx_pa_pb_mail.attach_text (conn   => lc_conn,
                                     DATA   => 'Please find the attached report for the details');
       -- End mail                               
          xx_pa_pb_mail.end_mail (conn => lc_conn);
              
     ELSE
      log_msg('Send mail without attachment');
             
      -- Calling xx_pa_pb_mail procedure to mail with text in the mail body                    
       lc_conn := xx_pa_pb_mail.begin_mail (sender          => p_config_details_rec.target_value10,
                                            recipients      => p_config_details_rec.target_value4,
                                            cc_recipients   => NULL,
                                            subject         => p_mail_subject,
                                            mime_type       => xx_pa_pb_mail.multipart_mime_type
                                           );
       --Attach text in the mail                                              
       xx_pa_pb_mail.attach_text (conn   => lc_conn,
                                  DATA   => p_attach_text);
       --End of mail                                    
       xx_pa_pb_mail.end_mail (conn => lc_conn);
                
     END IF;
     
     p_return_status:= gc_success;
     p_return_msg   := NULL;
   EXCEPTION           
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
         lc_error_msg := 'Unable to mail the file' || SQLERRM;
         END IF;
         log_msg(lc_error_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_GEN_REPORTS_PKG.SEND_MAIL',
                        p_error_msg        => lc_error_msg);
         p_return_msg   := lc_error_msg;
         p_return_status:= gc_failure;
   END send_mail;               
                              
-- Get the Customer details
   PROCEDURE get_customer_info ( p_aops_customer_number IN  VARCHAR2,
                                 p_cust_account_id      OUT NUMBER,
                                 p_account_number       OUT VARCHAR2,
                                 p_account_name         OUT VARCHAR2,
                                 p_return_msg           OUT VARCHAR2,
                                 p_return_status        OUT VARCHAR2
                               )
   IS  
   -- +=======================================================================+
   -- | Name  : get_customer_info                                             |
   -- | Description     : This procedure provides the oracle account name,    |
   -- |                   oracle account number and customer account id       |
   -- |                                                                       |
   -- | Parameters      : p_cust_account_id      OUT -> Customer Account Id   |
   -- |                   p_account_number       OUT -> Account Number        |
   -- |                   p_account_name         OUT -> Account Name          |
   -- |                   p_return_msg           OUT -> Return Message        |
   -- |                   p_return_status        OUT -> Return Status         |
   -- |                   p_aops_customer_number IN  -> AOPS Customer Number  |
   -- +=======================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------  
   lc_error_msg               VARCHAR2(4000);   
   BEGIN   
      p_cust_account_id      := NULL;
      p_account_number       := NULL;
      p_account_name         := NULL;
      lc_error_msg           := NULL;
      p_return_status        := NULL;
    
      SELECT cust_account_id, 
             account_name, 
             account_number
        INTO p_cust_account_id,
             p_account_name,
             p_account_number
        FROM hz_cust_accounts hca
       WHERE hca.orig_system_reference = LPAD (TO_CHAR (p_aops_customer_number),8,0)|| '-'|| '00001-A0'
         AND hca.status = 'A';
                                            
      fnd_file.put_line(fnd_file.log,'Customer Account Id :'|| p_cust_account_id);
      fnd_file.put_line(fnd_file.log,'Customer Account Name :'||p_account_name);
      fnd_file.put_line(fnd_file.log,'Customer Account Number :'||p_account_number);                 
      p_return_status   := gc_success;
      p_return_msg      := NULL;
   
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
      lc_error_msg :='customer details are not found for AOPS Customer Number : '|| p_aops_customer_number;
      log_msg (lc_error_msg);
      log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_CUSTOMER_INFO',
                      p_error_msg         =>  lc_error_msg);             
      p_cust_account_id := NULL;
      p_account_number  := NULL;
      p_account_name    := NULL;
      p_return_status   := gc_failure;
      p_return_msg      := lc_error_msg;             
      WHEN OTHERS
      THEN
      lc_error_msg := 'unable to fetch the customer details for AOPS customer: '|| p_aops_customer_number || ' - ' || SQLERRM;
      log_msg (lc_error_msg);
      log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_CUSTOMER_INFO',
                      p_error_msg         =>  lc_error_msg);   
      p_cust_account_id := NULL;
      p_account_number  := NULL;
      p_account_name    := NULL;
      p_return_status   := gc_failure;
      p_return_msg      := lc_error_msg;          
   END get_customer_info;

-- Get the AOPS Address Reference           
   FUNCTION get_aops_addr_reference (p_cust_account_id   IN NUMBER,
                                     p_consignee_num     IN VARCHAR2
                                    )
   RETURN VARCHAR2
   IS
   -- +=======================================================================+
   -- | Name  : get_aops_addr_reference                                       |
   -- | Description     : This function return the aops address reference     |
   -- |                                                                       |
   -- |                                                                       |
   -- | Parameters      : p_cust_account_id     IN -> Customer Account Id     |
   -- |                   p_consignee_num       IN -> OMX address reference   |
   -- +=======================================================================+
   --------------------------------
   -- Local Variable Declaration --
   --------------------------------
   l_site_ref_num   VARCHAR2 (200);
   lc_error_msg     VARCHAR2 (4000);
   
   BEGIN   
      l_site_ref_num := NULL;
      lc_error_msg   := NULL;
      
      SELECT hcas.orig_system_Reference
        INTO l_site_ref_num
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_accounts hca,
             hz_parties hp,
             hz_party_sites hps
       WHERE hcas.cust_account_id   =   hca.cust_account_id
         AND hp.party_id            =   hca.party_id
         AND hp.party_id            =   hps.party_id
         AND hcas.party_site_id     =   hps.party_site_id
         AND hca.cust_account_id    =   p_cust_account_id
		 AND hcas.status            =   'A'
         --AND SUBSTR (hps.orig_system_reference,8,INSTR (SUBSTR (hps.orig_system_reference, 8), '-') - 1) = p_consignee_num; -- Commented as per Defect 1239-- p_consignee_num->omx bill_to/ship_to consignee number
         --AND SUBSTR(hps.orig_system_reference,8,LENGTH(SUBSTR(hps.orig_system_reference,8))-4) = p_consignee_num; -- Added as per Defect#1239
		 AND SUBSTR(hps.orig_system_reference,8,INSTR(hps.orig_system_reference,'-OMX')-8) = p_consignee_num; -- Added as per Version 6.0, MOD5 Changes
      log_msg('AOPS address reference for OMX consignee number'||p_consignee_num);
      RETURN l_site_ref_num; 
           
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
      lc_error_msg:= 'No AOPS address reference found for OMX consignee number';
      log_msg(lc_error_msg);
      log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_AOPS_ADDR_REFERENCE',
                      p_error_msg         =>  lc_error_msg); 
      l_site_ref_num := NULL;
      
      RETURN l_site_ref_num;      
      WHEN TOO_MANY_ROWS
      THEN
      lc_error_msg:= 'Too many AOPS address references found for OMX consignee number';
      log_msg(lc_error_msg);
      log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_AOPS_ADDR_REFERENCE',
                      p_error_msg         =>  lc_error_msg);
      l_site_ref_num := NULL;
      RETURN l_site_ref_num;      
      WHEN OTHERS
      THEN
      lc_error_msg:= 'unable to fetch AOPS address reference for OMX consignee number';
      log_msg(lc_error_msg);
      log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_AOPS_ADDR_REFERENCE',
                      p_error_msg         =>  lc_error_msg);
      l_site_ref_num := NULL;
      RETURN l_site_ref_num;      
   END get_aops_addr_reference;

   PROCEDURE gen_address_exception_report ( x_retcode             OUT NOCOPY  NUMBER,
                                            x_errbuf              OUT NOCOPY  VARCHAR2,
                                            p_execution_date      IN          VARCHAR2,
                                            p_status              IN          VARCHAR2,
                                            p_debug_flag          IN          VARCHAR2
                                          )
   IS
   -- +============================================================================+
   -- | Name  : gen_address_exception_report                                       |
   -- | Description     : This procedure generates the address exception report    |
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters      : p_execution_date     IN -> Execution Date                |
   -- |                   p_status             IN -> Status                        |
   -- |                   p_debug_flag         IN -> Debug Flag                    |   
   -- |                   x_retcode            OUT                                 |
   -- |                   x_errbuf             OUT                                 |
   -- +============================================================================+

   CURSOR cur_extract(p_execution_date IN DATE,
                      p_status         IN xx_cdh_omx_addr_exceptions_stg.status%TYPE)      
   IS
   SELECT *
     FROM xx_cdh_omx_addr_exceptions_stg
    WHERE status = NVL(p_status,status)
      AND TRUNC (creation_date) >= NVL (p_execution_date, TRUNC (SYSDATE));
      
   ld_execution_date           DATE   := FND_DATE.CANONICAL_TO_DATE(p_execution_date); 
   lc_exists                   VARCHAR2 (1)  := 'N';
   lc_aops_ship_to_reference   VARCHAR2 (100);
   lc_aops_bill_to_reference   VARCHAR2 (100);
   ln_cust_account_id          NUMBER;
   lc_oracle_customer_name     VARCHAR2 (200);
   lc_oracle_account_number    VARCHAR2 (200);
   lc_filehandle               UTL_FILE.file_type;
   lc_filename                 VARCHAR2 (200):= 'xxod_omx_address_exceptions_report';
   lc_file_name                VARCHAR2 (200);
   lc_file                     VARCHAR2 (200):= '_' || TO_CHAR (SYSDATE, 'MMDDYYYY_HH24MISS');
   lc_mode                     VARCHAR2 (1)  := 'W';
   lc_source_path              VARCHAR2 (200);
   lc_header_string            VARCHAR2 (4000);
   lc_string                   VARCHAR2 (4000);
   ln_count                    NUMBER;
   lc_attach_text              VARCHAR2 (4000);
   lc_subject                  VARCHAR2 (200);
   lc_error_msg                VARCHAR2 (4000);
   lr_config_details_rec       xx_fin_translatevalues%ROWTYPE  := NULL;
   lc_process_type             VARCHAR2(200)  := 'Address Exceptions';
   lc_return_status            VARCHAR2(100);
   ln_batch_id                 NUMBER := NULL;
   e_process_exception         EXCEPTION;
   e_cursor_exception          EXCEPTION;
   ln_total_records            NUMBER;
   ln_success_records          NUMBER;
   ln_failed_records           NUMBER;
   lc_email                    VARCHAR2 (200);
   lc_status                   VARCHAR2(10);
   lc_utl_file_fopen           VARCHAR2 (2)    := 'Y';
   lc_copy_file_complete       VARCHAR2 (100);
   lc_date                     VARCHAR2 (200);
   
   BEGIN
      fnd_file.put_line(fnd_file.log,'Input parameters .....:');
      fnd_file.put_line(fnd_file.log,'p_execution_date: ' || p_execution_date);
      fnd_file.put_line(fnd_file.log,'p_status: ' || p_status);
      fnd_file.put_line(fnd_file.log,'p_debug_flag:' || p_debug_flag);

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;
      
      lc_return_status      := NULL;
      lc_error_msg          := NULL;
      ln_total_records      := 0;
      ln_success_records    := 0;
      ln_failed_records     := 0;
      lr_config_details_rec := NULL;
      lc_source_path        := NULL;
      lc_date               := NULL;
      
      
      -- Calling  Get Config Details   
      log_msg('Calling Get Config Details');   
      get_config_details (p_process_type       =>  lc_process_type,
                          p_config_details_rec =>  lr_config_details_rec,
                          p_return_status      =>  lc_return_status,
                          p_return_msg         =>  lc_error_msg
                         );
       
      log_msg('Get Config Details Return Status :'||lc_return_status);
      log_msg('Get Config Details Return Message :'||lc_error_msg);
                          
      -- Get the Source Directory Name      
      lc_source_path := lr_config_details_rec.target_value7; 
      IF lc_source_path IS  NULL
      THEN 
         RAISE e_process_exception;
      END IF;
            
      lc_file_name := lc_filename || lc_file || '.csv';

      ---- Building a header string to spit out the the file to the specific output directory
      log_msg('Building header string');
      lc_header_string :=    'AOPS Customer Number'
                          || ','
                          || 'ODN Customer Number'
                          || ','
                          || 'ODN Bill To Consignee'
                          || ','
                          || 'ODN Ship To Consignee'
                          || ','
                          || 'Oracle Customer Number'
                          || ','
                          || 'Oracle Customer Name'
                          || ','
                          || 'AOPS Bill To Address Reference'
                          || ','
                          || 'AOPS Ship To Address Reference';

      FOR cur_extract_rec IN cur_extract(p_execution_date=> ld_execution_date,
                                         p_status        => p_status)
      LOOP
         lc_exists := 'Y';
      BEGIN
           ln_batch_id               := NULL;
           lc_error_msg              := NULL;
           lc_return_status          := NULL;
           ln_cust_account_id        := NULL;
           lc_oracle_account_number  := NULL;
           lc_oracle_customer_name   := NULL;
           lc_aops_ship_to_reference := NULL;
           lc_aops_bill_to_reference := NULL;
           log_msg('  ');
           log_msg('Processing the record for AOPS Customer Number :'||cur_extract_rec.aops_customer_number);
            -- Get the batch id             
            ln_batch_id := cur_extract_rec.batch_id;                        
            -- Calling customer info procedure to get customer name and customer account id 
            log_msg('Calling get customer info ');                       
            get_customer_info (  p_aops_customer_number => cur_extract_rec.aops_customer_number,
                                 p_cust_account_id      => ln_cust_account_id,
                                 p_account_number       => lc_oracle_account_number,
                                 p_account_name         => lc_oracle_customer_name,
                                 p_return_msg           => lc_error_msg,
                                 p_return_status        => lc_return_status
                              );
                              
            log_msg('Get Customer Info return status :'||lc_return_status);
            log_msg('Get Customer Info return message :'||lc_error_msg);
                                             
        -- Get the AOPS SHIP_TO Address Reference  
        log_msg('Calling aops address reference for SHIP_TO');          
        lc_aops_ship_to_reference := get_aops_addr_reference (p_cust_account_id   => ln_cust_account_id,
                                                              p_consignee_num     => cur_extract_rec.ship_to_consignee
                                                             );
        log_msg ('Aops ship to address reference for SHIP_TO :'|| lc_aops_ship_to_reference);
            
        log_msg('Calling aops address reference for BILL_TO '); 
        -- Get the AOPS BILL_TO Address Reference            
        lc_aops_bill_to_reference := get_aops_addr_reference (
                                                               p_cust_account_id   => ln_cust_account_id,
                                                               p_consignee_num     => cur_extract_rec.bill_to_consignee
                                                             );
        log_msg ('Aops bill to address reference for BILL_TO :'|| lc_aops_bill_to_reference);
        
        --UTL File open
        
            IF lc_utl_file_fopen = 'Y'
            THEN
               lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, lc_mode);
               UTL_FILE.put_line (lc_filehandle, lc_header_string);
               lc_utl_file_fopen := 'N';
            END IF;

        -- Building a exception string to spit out the the file to the specific output directory            
        lc_string :=      TO_CHAR(cur_extract_rec.aops_customer_number)
                       || ','
                       || '='
                       || '"'
                       || TO_CHAR(cur_extract_rec.omx_customer_number)
                       || '"'
                       || ','
                       || '='
                       || '"'
                       || TO_CHAR(cur_extract_rec.bill_to_consignee)
                       || '"'
                       || ','
                       || '='
                       || '"'
                       || TO_CHAR(cur_extract_rec.ship_to_consignee)
                       || '"'
                       || ','
                       || TO_CHAR(cur_extract_rec.customer_number)
                       || ','
                       || TO_CHAR(lc_oracle_customer_name)
                       || ','
                       || '='
                       || '"'
                       || TO_CHAR(lc_aops_bill_to_reference)
                       || '"'
                       || ','
                       || '='
                       || '"'
                       || TO_CHAR(lc_aops_ship_to_reference)
                       || '"';

        UTL_FILE.put_line (lc_filehandle, lc_string);
               
           -- Updating the status to C 
           log_msg('Updating Status.......');
            UPDATE xx_cdh_omx_addr_exceptions_stg
               SET status = 'C',
                   last_update_date = gd_last_update_date,
                   last_updated_by  = gn_last_updated_by
             WHERE record_id = cur_extract_rec.record_id;
            COMMIT;            
        
        ln_success_records:= ln_success_records + 1;
            
      EXCEPTION
        WHEN UTL_FILE.INVALID_MODE
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2; 
          RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
               
        WHEN UTL_FILE.INVALID_PATH
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;  
          RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
                 
        WHEN UTL_FILE.INVALID_FILEHANDLE
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;
          RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
          
        WHEN UTL_FILE.INVALID_OPERATION
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;
          RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
                      
        WHEN UTL_FILE.WRITE_ERROR
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;
          RAISE_APPLICATION_ERROR (-20056, 'Write Error');
          
        WHEN UTL_FILE.INTERNAL_ERROR
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;
          RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
          
        WHEN UTL_FILE.FILE_OPEN
        THEN
          UTL_FILE.FCLOSE_ALL;
          x_retcode := 2;
          RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
          
        WHEN OTHERS
        THEN            
            IF lc_error_msg IS NULL
            THEN  
               lc_error_msg:= 'Error while processing record '|| cur_extract_rec.record_id ||SQLERRM;
            END IF;          
            log_msg(lc_error_msg);
            log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GEN_ADDRESS_EXCEPTION_REPORT',
                            p_error_msg         =>  lc_error_msg); 
                            
             --Updating the status to E
             log_msg('Updating Status..........');
             UPDATE xx_cdh_omx_addr_exceptions_stg
               SET status = 'E',
                   error_message = lc_error_msg,
                   last_update_date = gd_last_update_date,
                   last_updated_by  = gn_last_updated_by
             WHERE record_id = cur_extract_rec.record_id;
                                   
        ln_failed_records:= ln_failed_records + 1;     
      END;
      ln_total_records := ln_total_records + 1;      
      END LOOP;
      
      log_msg ('  ');
      fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
      fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
      fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_total_records);

      UTL_FILE.fclose (lc_filehandle);

      IF lc_exists = 'N'
      THEN      
         BEGIN   
            -- Added Logic as Per Version 1.5, To get the current batch id
            SELECT last_number-1  
              INTO ln_batch_id
              FROM all_sequences
            WHERE sequence_name ='XXOD_OMX_MOD4_BATCH_ID_S';
            log_msg ('Batch Id is ' || ln_batch_id);			  
			-- End of adding changes as per Version 1.5
         
            SELECT COUNT (1)
              INTO ln_count
              FROM xx_cdh_mod4_sfdc_cust_stg
             WHERE billing_type = 'AE'
			   AND status = 'I' -- Added as per Version 5.0	
			   AND batch_id = ln_batch_id ; -- Added as per Version 5.0			   
            log_msg ('Customers count with Billing Type ="AE" is ' || ln_count);
                
         EXCEPTION             
            WHEN OTHERS
            THEN
               ln_count := 0;
               lc_error_msg := 'Unable to fetch the customers count with Billing Type = "AE" '|| SQLERRM;
               log_msg(lc_error_msg);
         END;

         IF ln_count > 0
         THEN
            ld_execution_date := ld_execution_date - 1;
            SELECT TO_CHAR(NVL(ld_execution_date,SYSDATE-1),'MM/DD/YYYY')
              INTO lc_date
              FROM DUAL;
            --lc_attach_text :='Address Exception File has not been received from ODN for '|| lc_date|| '. However, '|| TO_CHAR(ln_count)|| ' customers with billing type "AE" have been received from SFDC and sent to ODN';  -- Commented as per Version 5.0 
            lc_attach_text :='Address Exception File has not been received from ODN for '|| lc_date|| '. However, Customers with billing type "AE" have been received from SFDC and sent to ODN'; -- Added as per Version 5.0			
            lc_subject := 'ODN Address Exception details not received for '||lc_date;
            
            log_msg(lc_subject);
            log_msg(lc_attach_text);
            -- Get the Email      
            lc_email := lr_config_details_rec.target_value4; 
            fnd_file.put_line(fnd_file.log,'Email is :'||lc_email);
            
            IF lc_email IS NULL
            THEN 
               log_msg(lc_error_msg);
               RAISE e_process_exception;
            END IF;
            
         -- Call Send mail   
            log_msg('Calling send mail');      
            send_mail(p_file_name          => NULL,
                      p_attach_text        => lc_attach_text,
                      p_config_details_rec => lr_config_details_rec,
                      p_mail_subject       => lc_subject,
                      p_copy_file_complete => NULL,
                      p_return_status      => lc_return_status,
                      p_return_msg         => lc_error_msg                                          
                                         );  
                                         
             log_msg('send mail return status :'|| lc_return_status);    
             log_msg('send mail return message :' || lc_error_msg);
                                              
             IF lc_return_status <> gc_success 
             THEN                 
             RAISE e_process_exception;                 
             END IF;             
         END IF;         
         
      ELSE
         -- Call move file to move the file from source to destination
         
         IF  ln_success_records > 0
         THEN 
           log_msg('Calling move file');
           move_file  (p_file_name           => lc_file_name,
                       p_config_details_rec  => lr_config_details_rec,
                       p_sfdc_source         => 'N',
                       p_return_status       => lc_return_status,
                       p_return_msg          => lc_error_msg,
                       p_copy_file_complete  => lc_copy_file_complete
                     ) ;  
         ELSE
           RAISE e_process_exception;                     
         END IF;     
                        
         -- Call Send mail
         IF lc_return_status = gc_success
         THEN
            
         log_msg('Calling send mail');      
         send_mail(p_file_name          => lc_file_name,
                   p_attach_text        => 'Attached are the Address Exceptions Details for '||TO_CHAR(ln_batch_id),
                   p_config_details_rec => lr_config_details_rec,
                   p_mail_subject       => lr_config_details_rec.target_value11 ||' '|| gc_date||' : Batch Id: '||TO_CHAR(ln_batch_id),
                   p_copy_file_complete => lc_copy_file_complete,
                   p_return_status      => lc_return_status,
                   p_return_msg         => lc_error_msg                                          
                  );  
                                         
            log_msg('send mail return status :'|| lc_return_status);    
            log_msg('send mail return message :' || lc_error_msg);
                                           
         -- Calling log_file procedure
            IF lc_return_status = gc_success
            THEN
                lc_status := 'C';
            ELSE
                lc_status := 'E';
            END IF;
                 
            fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
            log_file (p_success_records   => ln_success_records,
                      p_failed_records    => ln_failed_records,
                      p_batch_id          => ln_batch_id,
                      p_file_name         => lc_file_name,
                      p_status            => lc_status);  
                      
         ELSE 
          RAISE e_process_exception;
         END IF;
      END IF; 
   
   EXCEPTION
       
       WHEN OTHERS
       THEN
          IF lc_error_msg IS NULL
          THEN
             lc_error_msg := 'Unable to process the program :'||SQLERRM;
          END IF;
          fnd_file.put_line(fnd_file.log,lc_error_msg);
          log_msg(lc_error_msg);
          log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GEN_ADDRESS_EXCEPTION_REPORT',
                          p_error_msg         =>  lc_error_msg);
          x_retcode := 2;
   END gen_address_exception_report;

--update the status in MOD4 staging table

  PROCEDURE update_sfdc_status(p_status                IN       VARCHAR2,
                               p_aops_customer_number  IN       VARCHAR2,
                               p_error_message         IN OUT   VARCHAR2)
  IS  
  -- +==========================================================================+
  -- | Name  : update_sfdc_status                                               |
  -- | Description: This is to update the status in staging table               |
  -- |                                                                          |
  -- | Parameters : p_aops_customer_number   IN    -> AOPS Customer Number      |
  -- |              p_status                IN     -> Status in staging table   |
  -- |              p_error_message        IN OUT  -> Error Message             |
  -- +==========================================================================+
   BEGIN

     UPDATE xx_cdh_mod4_sfdc_cust_stg
     SET status           = p_status,
         error_message    = p_error_message,
         last_update_date = gd_last_update_date,
         last_updated_by  = gn_last_updated_by
      WHERE aops_customer_number     = p_aops_customer_number;

  EXCEPTION
    WHEN OTHERS
    THEN
      IF p_error_message IS NULL
      THEN
        p_error_message := 'Error while updating the status  '|| SQLERRM ;
      END IF;
      log_msg (p_error_message);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.UPDATE_SFDC_STATUS',
                     p_error_msg        => p_error_message);
  END update_sfdc_status;

-- Validate Bill Documents Information
   PROCEDURE check_billdocs_info (p_return_status             OUT     VARCHAR2,
                                  p_return_msg                IN OUT  VARCHAR2,
                                  p_aops_customer_number      IN      VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : check_billdocs_info                                                    |
   -- | Description     : This procedure validates the billing document information    |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_return_status          OUT    -> Return Status             |
   -- |                   p_return_msg             IN OUT -> Return message            |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number      |
   -- +================================================================================+

   ln_count                NUMBER;
   lc_error_msg            VARCHAR2 (4000);
         
   BEGIN
       ln_count     := NULL;
       
      SELECT COUNT (1),error_message
        INTO ln_count,lc_error_msg
        FROM xx_cdh_omx_bill_docs_stg
       WHERE 1 = 1
         AND status = 'C'
         AND aops_customer_number = p_aops_customer_number
         AND ROWNUM < 2
       GROUP BY error_message;
       
       log_msg('Ebilling documents processed successfully.');
  
      p_return_status := gc_success;
      p_return_msg    := lc_error_msg||'.';
            
      EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN    
         BEGIN                     
            SELECT NVL(error_message,'No Bill Docs')
              INTO lc_error_msg
              FROM xx_cdh_omx_bill_docs_stg
             WHERE     1 = 1
               AND status = 'E'
               AND aops_customer_number = p_aops_customer_number               
               AND ROWNUM < 2;
               
               p_return_status := gc_failure;
               p_return_msg    := lc_error_msg||'.';
                     
               log_msg('Ebilling documents received and error message is '||lc_error_msg);

         EXCEPTION    

            WHEN NO_DATA_FOUND
            THEN          
               lc_error_msg:= 'Ebilling document has not been received from ODN';
               p_return_status := gc_failure;
               p_return_msg    := lc_error_msg||'.';
               
            WHEN OTHERS
            THEN
               lc_error_msg :='Unable to fetch the error message from the Ebilling documents staging table '||SQLERRM;
               p_return_status := gc_failure;
               p_return_msg    := lc_error_msg||'.';
         END;         

        WHEN OTHERS
        THEN
           IF lc_error_msg IS NULL
           THEN 
              lc_error_msg :='No Ebilling documents';
           END IF;
         
           p_return_status := gc_failure;
           p_return_msg    := lc_error_msg||'.';
        
   END check_billdocs_info;
   

--  Validate Bill Contacts Information
   PROCEDURE check_billcontacts_info (p_return_status             OUT    VARCHAR2,
                                      p_return_msg                IN OUT VARCHAR2,
                                      p_aops_customer_number      IN     VARCHAR2)
   IS 
   -- +================================================================================+
   -- | Name  : check_billcontacts_info                                                |
   -- | Description     : This procedure validates the billing contacts information    |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_return_status          OUT    -> Return Status             |
   -- |                   p_return_msg             IN OUT -> Return message            |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number      |
   -- +================================================================================+

   ln_count                NUMBER;
   lc_error_msg            VARCHAR2 (4000);
   
   BEGIN
      SELECT COUNT (1),error_message
        INTO ln_count,lc_error_msg
        FROM xx_cdh_omx_ebill_contacts_stg
       WHERE     1 = 1
         AND status = 'C'
         AND aops_customer_number = p_aops_customer_number
         AND ROWNUM < 2
       GROUP BY error_message;
             
      log_msg('Ebilling contacts processed successfully');

      p_return_status := gc_success;
      p_return_msg    := p_return_msg||chr(32)||lc_error_msg||'.';
      
      EXCEPTION
      WHEN NO_DATA_FOUND 
      THEN
         BEGIN
             SELECT NVL(error_message,'No eBill Contacts')
               INTO lc_error_msg
               FROM xx_cdh_omx_ebill_contacts_stg
              WHERE     1 = 1
                AND status = 'E'
                AND aops_customer_number = p_aops_customer_number
                AND ROWNUM < 2;
             
             p_return_status := gc_success;
             p_return_msg    := p_return_msg||chr(32)||lc_error_msg||'.';                   
             log_msg('Ebilling contacts received and error message is '||lc_error_msg);
             
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN                         
               lc_error_msg:= 'Ebilling contacts have not been received from ODN';
               p_return_status := gc_failure;
               p_return_msg    := p_return_msg|| chr(32)||lc_error_msg||'.';
            WHEN OTHERS
            THEN
               lc_error_msg :='Unable to fetch the error message from the Ebilling Contacts staging table '||SQLERRM;
               p_return_status := gc_failure;
               p_return_msg    := p_return_msg|| chr(32)||lc_error_msg||'.';
         END;
       
         WHEN OTHERS
         THEN            
            IF lc_error_msg IS NULL
            THEN 
              lc_error_msg :='No Ebill Contacts';
            END IF;
            p_return_status := gc_failure;
            p_return_msg    := p_return_msg|| chr(32)||lc_error_msg||'.';
   END check_billcontacts_info;
   
   FUNCTION get_billing_docs_info(p_aops_customer_number   IN  VARCHAR2,
                                  p_batch_id               IN  NUMBER,
                                  p_return_msg             OUT VARCHAR2,
                                  p_bill_docs_info         OUT xx_cdh_omx_bill_docs_stg%ROWTYPE)
   RETURN VARCHAR2
   IS 
   -- +================================================================================+
   -- | Name  : get_billing_docs_info                                                  |
   -- | Description     : This procedure gives the delivery_method for the respective  |
   -- |                   customer                                                     |
   -- |                                                                                |
   -- | Parameters      :p_aops_customer_number   IN  -> AOPS Customer Number          |
   -- |                  p_batch_id               IN  -> Batch Id                      |
   -- |                  p_return_msg             OUT -> Return Message                |
   -- |                  p_bill_docs_info         OUT -> Billing documents info        |
   -- +================================================================================+

   BEGIN      
      p_return_msg     := NULL;
      p_bill_docs_info := NULL;
      
      SELECT *
        INTO p_bill_docs_info
        FROM xx_cdh_omx_bill_docs_stg
       WHERE aops_customer_number = p_aops_customer_number
         AND batch_id  = p_batch_id
       ORDER BY batch_id ;
       
       log_msg('Print Daily Flag ...:' ||p_bill_docs_info.print_daily_flag);
       log_msg('Summary Bill Flag ...:'||p_bill_docs_info.summary_bill_flag);
     
   RETURN gc_success;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
          p_return_msg := 'No Billing documents found for AOPS customer :'||p_aops_customer_number;
          fnd_file.put_line(fnd_file.log,p_return_msg);
          log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_BILLING_DOCS_INFO',
                          p_error_msg         =>  p_return_msg);
      RETURN gc_failure;
      WHEN OTHERS
      THEN
          p_return_msg := 'Unable to fetch Billing Documents details :'||' '||SQLERRM;
          fnd_file.put_line(fnd_file.log,p_return_msg);
          log_exception ( p_error_location     =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GET_BILLING_DOCS_INFO'
                          ,p_error_msg          =>  p_return_msg);
       RETURN gc_failure;
       
   END get_billing_docs_info;

-- Validate the Information for Direct or Indirect Customer
   PROCEDURE check_sites_converted (p_return_status             OUT    VARCHAR2,
                                    p_return_msg                IN OUT VARCHAR2,
                                    p_aops_customer_number      IN     VARCHAR2)
   IS
   -- +====================================================================================+
   -- | Name  : check_customer_billing_type                                                |
   -- | Description     : This procedure checks if the customer is Indirect Simple (IS)    |
   -- |                   and then get the count of records from the staging table and     |
   -- |                   oracle table. If count does not match, then update the status    |
   -- |                   in MOD4 staging table for their respective AOPS Customer Number  |
   -- |                                                                                    |
   -- |                                                                                    |
   -- | Parameters      : p_return_status          OUT    -> Return Status                 |
   -- |                   p_return_msg             IN OUT -> Return message                |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number          |
   -- +====================================================================================+

   ln_stg_count             NUMBER;
   ln_oracle_count          NUMBER;
   lc_error_msg             VARCHAR2 (4000);
   BEGIN
         -- Get count from staging table
         SELECT COUNT (DISTINCT BILL_TO_CONSIGNEE)
           INTO ln_stg_count
           FROM xx_cdh_omx_ebill_contacts_stg
          WHERE aops_customer_number = p_aops_customer_number;
          
          log_msg(' Staging table Record count :'||ln_stg_count);

         -- Get count from Oracle table
         SELECT COUNT (1)
           INTO ln_oracle_count
           FROM hz_cust_accounts hca, 
                hz_cust_acct_sites_all hcas,
                hz_party_sites hps
          WHERE 1 = 1
            AND hca.cust_account_id = hcas.cust_account_id
            AND hcas.party_site_id =  hps.party_site_id
            AND hca.orig_system_reference =LPAD (TO_CHAR (p_aops_customer_number), 8, 0)|| '-'|| '00001-A0'
            AND hps.orig_system_reference NOT LIKE '%OMX00%'
            AND hcas.status = 'A'
            AND hps.status = 'A';
            
         log_msg('Oracle table Record count :'||ln_oracle_count);
         
         --IF ln_oracle_count > 0
         --THEN
         --   ln_oracle_count:= ln_oracle_count - 2;
         --END IF;
         
         IF ln_stg_count <> ln_oracle_count
         THEN         
               lc_error_msg:= 'Sites mismatched : ODN='||ln_stg_count||'; ODS :'||ln_oracle_count;
         END IF;
         p_return_status := gc_success;
         p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';  
   EXCEPTION
      WHEN OTHERS
      THEN            
          IF lc_error_msg IS NULL
          THEN 
             lc_error_msg :='Unable to get the converted sites details '||SQLERRM;
          END IF;
          log_msg(lc_error_msg);
          log_exception( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.CHECK_CUSTOMER_BILLING_TYPE',
                         p_error_msg         =>  lc_error_msg);             
          p_return_status := gc_failure;
          p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
   END check_sites_converted;

-- Validate the AP Contacts Information
   PROCEDURE check_apcontacts_info (p_return_status             OUT    VARCHAR2,
                                    p_return_msg                IN OUT VARCHAR2,
                                    p_aops_customer_number      IN     VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : check_apcontacts_info                                                  |
   -- | Description     : This procedure validates the ap contacts information         |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_return_status          OUT    -> Return Status             |
   -- |                   p_return_msg             IN OUT -> Return message            |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number      |
   -- +================================================================================+
      ln_count                NUMBER;
      lc_error_msg            VARCHAR2 (4000);
      
   BEGIN

      SELECT COUNT (1),error_message
        INTO ln_count,lc_error_msg
        FROM xx_cdh_omx_ap_contacts_stg
       WHERE 1 = 1
         AND status = 'C'
         AND aops_customer_number = p_aops_customer_number
         AND ROWNUM < 2
       GROUP BY error_message;
         
      log_msg('AP contacts processed successfully');
      
      p_return_status := gc_success;
      p_return_msg    := p_return_msg ||chr(32)|| lc_error_msg||'.';
      
      EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN
         BEGIN
             SELECT NVL(error_message,'No AP Contacts')
               INTO lc_error_msg
               FROM xx_cdh_omx_ap_contacts_stg
              WHERE 1 = 1
                AND status = 'E'
                AND aops_customer_number = p_aops_customer_number
                AND ROWNUM < 2;
                
                p_return_status := gc_success;
                p_return_msg    := p_return_msg ||chr(32)|| lc_error_msg||'.';
                
              log_msg('AP contacts received and error message is '||lc_error_msg);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN        
              lc_error_msg:= 'AP contacts have not been received from ODN';              
               p_return_status := gc_success;
               p_return_msg    := p_return_msg ||chr(32)|| lc_error_msg||'.';
            WHEN OTHERS
            THEN
               lc_error_msg :='Unable to fetch the error message from the AP Contacts staging table '||SQLERRM;
               p_return_status := gc_failure;
               p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
         END;
      
      WHEN OTHERS
      THEN           
          IF lc_error_msg IS NULL
          THEN 
             lc_error_msg :='No AP contacts';
          END IF;  
          p_return_status := gc_failure;
          p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
   END check_apcontacts_info;

-- Validate Dunning Information
   PROCEDURE check_dunning_info (p_return_status             OUT       VARCHAR2,
                                 p_return_msg                IN OUT    VARCHAR2,
                                 p_aops_customer_number      IN        VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : check_dunning_info                                                     |
   -- | Description     : This procedure validates the dunning information             |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_return_status          OUT    -> Return Status             |
   -- |                   p_return_msg             IN OUT -> Return message            |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number      |
   -- +================================================================================+

   ln_count                 NUMBER;
   lc_error_msg             VARCHAR2 (4000);

   BEGIN
      SELECT COUNT (1),error_message
        INTO ln_count,lc_error_msg
        FROM xx_cdh_omx_dunning_stg
       WHERE 1 = 1
         AND status = 'C'
         AND aops_customer_number = p_aops_customer_number
         AND ROWNUM < 2
       GROUP BY error_message;
      
       log_msg('Dunning processed successfully');

      p_return_status := gc_success;
      p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
      
   EXCEPTION   
      WHEN NO_DATA_FOUND
      THEN
         BEGIN
              SELECT NVL(error_message,'No Dunning Info')
                INTO lc_error_msg
                FROM xx_cdh_omx_dunning_stg
               WHERE 1 = 1
                 AND status = 'E'
                 AND aops_customer_number = p_aops_customer_number
                 AND ROWNUM < 2;
                 
               p_return_status := gc_success;
               p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';                 
               log_msg('Dunning details received and error message is '||lc_error_msg);
               
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN          
              lc_error_msg:= 'Dunning Information have not been received from ODN ';
              p_return_status := gc_success;
              p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
            WHEN OTHERS
            THEN
              lc_error_msg :='Unable to fetch the error message from the Dunning staging table '||SQLERRM;
              p_return_status := gc_failure;
              p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
         END;
 
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
          THEN 
            lc_error_msg :='No Dunning details.';
          END IF;           
          p_return_status := gc_failure;
          p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
          
   END check_dunning_info;


   PROCEDURE check_creditlimit_info (p_return_status             OUT    VARCHAR2,
                                     p_return_msg                IN OUT VARCHAR2,
                                     p_aops_customer_number      IN     VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : check_creditlimit_info                                                 |
   -- | Description     : This procedure validates the Customer information            |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_return_status          OUT    -> Return Status             |
   -- |                   p_return_msg             IN OUT -> Return message            |
   -- |                   p_aops_customer_number   IN     -> AOPS Customer Number      |
   -- +================================================================================+
   
   ln_count                 NUMBER;
   lc_error_msg             VARCHAR2 (4000);

   BEGIN
      SELECT COUNT (1),error_message
        INTO ln_count,lc_error_msg
        FROM xx_cdh_omx_cust_info_stg
       WHERE 1 = 1
         AND status = 'C'
         AND aops_customer_number = p_aops_customer_number
         AND ROWNUM < 2
       GROUP BY error_message;
         
      log_msg('Credit Limit details processed successfully');

      p_return_status := gc_success;
      p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
      
      EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN
           BEGIN
            SELECT NVL(error_message,'No Credit Info')
              INTO lc_error_msg
              FROM xx_cdh_omx_cust_info_stg
             WHERE 1 = 1
               AND status = 'E'
               AND aops_customer_number = p_aops_customer_number
               AND ROWNUM < 2;
             p_return_status := gc_success;
             p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';  
             log_msg('Credit Limit details received and error message is '||lc_error_msg);
            
           EXCEPTION
            WHEN NO_DATA_FOUND
            THEN          
               lc_error_msg:='Customer Credit Limit Information have not been received from ODN ';
               p_return_status := gc_success;
               p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
            WHEN OTHERS
            THEN
               lc_error_msg :='Unable to fetch the error message from the Customer Info staging table '||SQLERRM;
               p_return_status := gc_failure;
               p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
           END;
      
        WHEN OTHERS
        THEN
          IF lc_error_msg IS NULL
          THEN 
             lc_error_msg :='No Credit Limit Details.';
          END IF;           
          p_return_status := gc_failure;
          p_return_msg    := p_return_msg ||chr(32)||lc_error_msg||'.';
         
   END check_creditlimit_info;
   
   -- Procedure to generate SFDC Status File

   PROCEDURE generate_sfdc_status_file (x_retcode             OUT NOCOPY NUMBER,
                                        x_errbuf              OUT NOCOPY VARCHAR2,
                                        p_execution_date      IN         VARCHAR2,
                                        p_debug_flag          IN         VARCHAR2)
   IS
   -- +============================================================================+
   -- | Name  : generate_sfdc_status_file                                          |
   -- | Description     : This procedure generates the SFDC status file            |
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters      : p_execution_date     IN -> Execution Date                |
   -- |                   p_debug_flag         IN -> Debug Flag                    |
   -- |                   x_retcode            OUT                                 |
   -- |                   x_errbuf             OUT                                 |
   -- +============================================================================+

   CURSOR cur_extract
   IS
     SELECT *
       FROM xx_cdh_mod4_sfdc_cust_stg
      WHERE status = 'I'
        AND billing_type IN ('DI', 'IS')
        --AND TRUNC (creation_date) >= NVL(p_execution_date - 1 ,TRUNC(SYSDATE -1))
		; 

   CURSOR cur_gen_file
   IS
     SELECT *
       FROM xx_cdh_mod4_sfdc_cust_stg
      WHERE status = 'P';
      
  -- ld_execution_date            DATE   := FND_DATE.CANONICAL_TO_DATE(p_execution_date); 
   lc_ebill_docs_retstatus      VARCHAR2 (100);
   lc_ebill_contacts_retstatus  VARCHAR2 (100);     
   lc_error_msg                 VARCHAR2 (32000);
   lc_return_msg                VARCHAR2 (32000);
   lc_return_status             VARCHAR2 (100);
   lc_filehandle                UTL_FILE.file_type;
   lc_filename                  VARCHAR2 (200):= 'xxod_cdh_mod4_status_update';
   lc_file_name                 VARCHAR2 (200);
   lc_file                      VARCHAR2 (200):= '_' || TO_CHAR (SYSDATE, 'MMDDYYYY_HH24MISS');
   lc_mode                      VARCHAR2 (1) := 'W';
   lc_source_path               VARCHAR2 (200);
   lc_header_string             VARCHAR2 (4000);
   lc_string                    VARCHAR2 (4000);
   lc_exists                    VARCHAR2 (1) := 'N';
   ln_count                     NUMBER;
   ln_success_records           NUMBER;
   ln_failed_records            NUMBER;
   ln_total_records             NUMBER;
   lr_bill_docs_info            xx_cdh_omx_bill_docs_stg%ROWTYPE ;         
   lc_billing_flag              VARCHAR2(10);
   lc_delivery_method           VARCHAR2(100);
   lr_config_details_rec        xx_fin_translatevalues%ROWTYPE;
   lc_process_type              VARCHAR2(200):= 'sfdc status file';
   ln_batch_id                  NUMBER;
   e_process_exception          EXCEPTION;
   lc_subject                   VARCHAR2 (200);
   lc_status                    VARCHAR2 (10);
   lc_default_delivery_used     VARCHAR2(1);
   lc_utl_file_fopen            VARCHAR2 (2) := 'Y';
   lc_copy_file_complete        VARCHAR2 (100);
   
   BEGIN
      fnd_file.put_line(fnd_file.log,'Input parameters .....:');
      fnd_file.put_line(fnd_file.log,'p_execution_date: ' || p_execution_date);
      fnd_file.put_line(fnd_file.log,'p_debug_flag:' || p_debug_flag);

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;
      
      FOR cur_extract_rec IN cur_extract
      LOOP
         lc_error_msg                := NULL;
         lc_return_status            := NULL;
         lc_ebill_docs_retstatus     := NULL;
         lc_ebill_contacts_retstatus := NULL;
         lr_bill_docs_info           := NULL;
         lc_billing_flag             := NULL;
         lc_delivery_method          := NULL;
         lc_status                   := NULL;
         lc_default_delivery_used    := NULL;
         BEGIN
            log_msg('   ');
            log_msg('Processing the AOPS customer Number :'||cur_extract_rec.aops_customer_number);
           
           -- Calling check_billdocs_info procedure
            log_msg('Calling Check Bill Docs');
            check_billdocs_info (p_return_status          => lc_ebill_docs_retstatus,
                                 p_return_msg             => lc_error_msg,
                                 p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                   
            log_msg(' Check Bill Docs Return Status :'||lc_ebill_docs_retstatus);
            log_msg(' Check Bill Docs Return Message :'||lc_error_msg);
            
            IF lc_ebill_docs_retstatus <> gc_failure
            THEN                     
             -- Calling get billing documents info
              log_msg('Calling get bill docs info');
              lc_return_status :=get_billing_docs_info(p_aops_customer_number     => cur_extract_rec.aops_customer_number,
                                                       p_batch_id                 => cur_extract_rec.batch_id,
                                                       p_return_msg               => lc_return_msg,
                                                       p_bill_docs_info           => lr_bill_docs_info);
               
              log_msg('Get Bill Docs Info Return Message '|| lc_return_msg);
             
              IF lr_bill_docs_info.summary_bill_flag = 'N'
              THEN
                 lc_billing_flag := lr_bill_docs_info.print_daily_flag;

              ELSIF lr_bill_docs_info.summary_bill_flag <> 'N'
                THEN
                   lc_billing_flag := lr_bill_docs_info.summary_bill_flag;
                   
              END IF;
             
              -- Calling derive delivery method
              log_msg('Calling derive delivery method');
              lc_return_status := APPS.XX_CDH_OMX_BILL_DOCUMENTS_PKG.derive_delivery_method(p_billing_flag      => lc_billing_flag,
                                                                                            p_delivery_method   => lc_delivery_method,
                                                                                            p_default_used      => lc_default_delivery_used,
                                                                                            p_error_msg         => lc_return_msg);
                                
              log_msg('Derive delivery method return message '|| lc_return_msg);
              log_msg('Delivery Method is :'|| lc_delivery_method);                                      
             
             
              IF lc_return_status <> gc_failure   
              THEN   
              -- Check if doc type is "ePDF"            
                IF lc_delivery_method = 'ePDF'
                THEN
                  -- Calling check_billcontacts_info procedure
                  log_msg('Calling Check Bill Contacts');
                  check_billcontacts_info ( p_return_status          => lc_ebill_contacts_retstatus,
                                            p_return_msg             => lc_error_msg,
                                            p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                                         
                  log_msg(' Check Bill Contacts Return Status :'||lc_ebill_contacts_retstatus);
                  log_msg(' Check Bill Contacts Return Message :'||lc_error_msg);
                                         
                  -- Check the billing type
                  IF cur_extract_rec.billing_type = 'IS' AND lc_ebill_contacts_retstatus <> gc_failure -- Bill Contacts Return Status
                  THEN
                     log_msg('Calling Check Sites Converted ');
                     check_sites_converted (p_return_status          => lc_return_status,
                                            p_return_msg             => lc_error_msg,
                                            p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                                         
                     log_msg(' Check Sites Converted Return Status :'||lc_return_status);
                     log_msg(' Check Sites Converted Return Message :'||lc_error_msg);
                  END IF;                          
                ELSE 
                  lc_ebill_contacts_retstatus := gc_success;                        
                END IF;
              END IF;
              
            END IF;
            -- Calling Check AP Contacts
            log_msg('Calling Check AP Contacts');
            check_apcontacts_info (p_return_status          => lc_return_status,
                                   p_return_msg             => lc_error_msg,
                                   p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                                   
            log_msg(' Check AP Contacts Return Status :'||lc_return_status);
            log_msg(' Check AP Contacts Return Message :'||lc_error_msg);                      
            
            -- Calling Check Dunning Info
            log_msg('Calling Check Dunning Info');
            check_dunning_info (p_return_status          => lc_return_status,
                                p_return_msg             => lc_error_msg,
                                p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                                
            log_msg(' Check Dunning Info Return Status :'||lc_return_status);
            log_msg(' Check Dunning Info Return Message :'||lc_error_msg);
            
            -- Calling Check Credit Limit
            log_msg('Calling Check Credit Limit');
            check_creditlimit_info (p_return_status          => lc_return_status,
                                    p_return_msg             => lc_error_msg,
                                    p_aops_customer_number   => cur_extract_rec.aops_customer_number);
                                    
            log_msg(' Check Credit Limit Info Return Status :'||lc_return_status);
            log_msg(' Check Credit Limit Info Return Message :'||lc_error_msg);
                                
                                 
            IF lc_ebill_docs_retstatus <> gc_failure AND lc_ebill_contacts_retstatus <> gc_failure
            THEN
                 lc_status := 'P';
             
            ELSE
                 lc_status := 'E';
            END IF;
            
            lc_error_msg := SUBSTR(lc_error_msg,1,4000);
            
             log_msg('Calling update sfdc status ');
             update_sfdc_status(p_status             => lc_status,
                              p_aops_customer_number => cur_extract_rec.aops_customer_number,
                              p_error_message        => lc_error_msg);
             COMMIT;                     
                  
            
         EXCEPTION
            WHEN OTHERS 
            THEN
              IF lc_error_msg IS NULL
              THEN
                 lc_error_msg:='Unable to process the records for AOPS customer number :'||cur_extract_rec.aops_customer_number;
              END IF;
              log_msg(lc_error_msg);
              log_exception( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GENERATE_SFDC_STATUS_FILE',
                             p_error_msg         =>  lc_error_msg);            
         END;
      END LOOP;

      ln_success_records:= 0;
      ln_failed_records := 0;
      ln_total_records  := 0;
      
      -- Calling  Get Config Details 
      log_msg('  ');
      log_msg('Calling Get Config Details');     
      get_config_details (p_process_type       =>  lc_process_type,
                          p_config_details_rec =>  lr_config_details_rec,
                          p_return_status      =>  lc_return_status,
                          p_return_msg         =>  lc_error_msg
                         );
                          
      log_msg('Get Config Details Return Status :'||lc_return_status);
      log_msg('Get Config Details Return Message :'||lc_error_msg);
      
      -- Get the Source Directory Name      
      lc_source_path := lr_config_details_rec.target_value7; 
      IF lc_source_path IS NULL
      THEN 
         RAISE e_process_exception;
      END IF;
      
      lc_file_name := lc_filename || lc_file || '.csv';

      ---- Building a header string to spit out the the file to the specific output directory
      log_msg('Building header string');
      lc_header_string :=   '"'
                         || 'OMX_CUSTOMER_NUMBER' 
                         || '"'
                         || ','
                         || '"' 
                         || 'PROCESSED_DATE'
                         || '"';                        

      FOR cur_gen_file_rec IN cur_gen_file
      LOOP
         lc_error_msg      := NULL;
         lc_return_status  := NULL;
         lc_string         := NULL;
         lc_exists         := 'Y';
         BEGIN
            --UTL File open
        
            IF lc_utl_file_fopen = 'Y'
            THEN
               lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, lc_mode);
               UTL_FILE.put_line (lc_filehandle, lc_header_string);
               lc_utl_file_fopen := 'N';
            END IF;
            
            -- Building a exception string to spit out the file to the specific output directory
            lc_string :=    '"'
                         || cur_gen_file_rec.omx_customer_number
                         || '"'
                         || ','
                         || '"'
                         || TO_CHAR (cur_gen_file_rec.creation_date, 'RRRR-MM-DD')
                         || '"';

            UTL_FILE.put_line (lc_filehandle, lc_string);
            
            --Count Sucessful records loaded into the exception file
            ln_success_records := ln_success_records + 1;
            
            --Updating the staging table
            UPDATE xx_cdh_mod4_sfdc_cust_stg
               SET status = 'C',
			       Process_flag = NULL,
                   last_update_date = gd_last_update_date,
                   last_updated_by = gn_last_updated_by
             WHERE record_id = cur_gen_file_rec.record_id ;
            
         EXCEPTION
            WHEN UTL_FILE.INVALID_MODE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2; 
              RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
                   
            WHEN UTL_FILE.INVALID_PATH
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;  
              RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
                     
            WHEN UTL_FILE.INVALID_FILEHANDLE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
              
            WHEN UTL_FILE.INVALID_OPERATION
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
                          
            WHEN UTL_FILE.WRITE_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20056, 'Write Error');
              
            WHEN UTL_FILE.INTERNAL_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
              
            WHEN UTL_FILE.FILE_OPEN
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
              
            WHEN OTHERS
            THEN
               IF lc_error_msg IS NULL
               THEN
                  lc_error_msg:= 'Unable to process the record :'||cur_gen_file_rec.record_id||' '||SQLERRM;
               END IF;
               log_msg(lc_error_msg);
               log_exception( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GENERATE_SFDC_STATUS_FILE',
                              p_error_msg         =>  lc_error_msg);
               
             ln_failed_records := ln_failed_records + 1; 
         END;
         ln_total_records := ln_total_records + 1;
      END LOOP;

      UTL_FILE.fclose (lc_filehandle);
      
      fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
      fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
      fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_total_records);
      
      IF ln_success_records > 0
        THEN                            
        -- Call Send mail   
        log_msg('Calling move file');
           move_file  (p_file_name           => lc_file_name,
                       p_config_details_rec  => lr_config_details_rec,
                       p_sfdc_source         => 'Y',
                       p_return_status       => lc_return_status,
                       p_return_msg          => lc_error_msg,
                       p_copy_file_complete  => lc_copy_file_complete
                       ) ;   
                                                  
        log_msg('move file return status :'|| lc_return_status);    
        log_msg('move file return message :' || lc_error_msg);
      ELSE
         RAISE e_process_exception;                     
      END IF;
                                             
         --Checking move file return status
         IF lc_return_status = gc_success
         THEN
            -- Calling log_file procedure
            fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
            log_file (p_success_records   => ln_success_records,
                      p_failed_records    => ln_failed_records,
                      p_batch_id          => ln_batch_id,
                      p_file_name         => lc_file_name,
                      p_status            => 'C');
         ELSE
            -- Calling log_file procedure
            fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
            log_file (p_success_records   => ln_success_records,
                      p_failed_records    => ln_failed_records,
                      p_batch_id          => ln_batch_id,
                      p_file_name         => lc_file_name,
                      p_status            => 'E'); 
            
            RAISE e_process_exception;   
         END IF; 
          
   EXCEPTION      
      WHEN OTHERS 
      THEN
        IF lc_error_msg IS NULL
        THEN
           lc_error_msg := 'Unable to process '||SQLERRM;
        END IF;
        fnd_file.put_line(fnd_file.log,lc_error_msg);
        log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GENERATE_SFDC_STATUS_FILE'
                       ,p_error_msg         =>  lc_error_msg);
        x_retcode := 2;
        ROLLBACK;
  
   END generate_sfdc_status_file;

   -- Generate eBill Contacts Exception Report

   PROCEDURE gen_ebillcont_exception_report (x_retcode              OUT NOCOPY  NUMBER,
                                             x_errbuf               OUT NOCOPY  VARCHAR2,
                                             p_execution_date       IN          VARCHAR2,
                                             p_debug_flag           IN          VARCHAR2,
                                             p_status               IN          VARCHAR2,
                                             p_aops_acct_number     IN          VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : gen_ebillcont_exception_report                                         |
   -- | Description     : This procedure generates eBill Contacts Exception Report     |
   -- |                                                                                |
   -- |                                                                                |
   -- | Parameters      : p_execution_date      IN -> Execution Date                   |
   -- |                   p_debug_flag          IN -> Debug Flag                       |
   -- |                   p_status              IN -> Status                           |
   -- |                   p_aops_acct_number    IN -> AOPS Customer Number             |
   -- |                   x_retcode            OUT                                     |
   -- |                   x_errbuf             OUT                                     |
   -- +================================================================================+

   CURSOR cur_extract(p_execution_date     IN DATE,
                      p_status             IN xx_cdh_omx_ebill_contacts_stg.status%TYPE,
                      p_aops_acct_number   IN xx_cdh_omx_ebill_contacts_stg.aops_customer_number%TYPE)
   IS
     SELECT *
       FROM xx_cdh_omx_ebill_contacts_stg
      WHERE TRUNC (creation_date) = NVL(p_execution_date,TRUNC (SYSDATE))
        AND status = NVL(p_status,status)
        AND aops_customer_number = NVL(p_aops_acct_number,aops_customer_number);
        
   ld_execution_date           DATE   := FND_DATE.CANONICAL_TO_DATE(p_execution_date); 
   lc_aops_bill_to_reference   VARCHAR2 (100);
   ln_cust_account_id          NUMBER;
   lc_oracle_customer_name     VARCHAR2 (200);
   lc_oracle_account_number    VARCHAR2 (200);
   lc_filehandle               UTL_FILE.file_type;
   lc_filename                 VARCHAR2 (200) := 'xxod_omx_ebill_contacts_exception_report';
   lc_file_name                VARCHAR2 (200);
   lc_file                     VARCHAR2 (200):= '_' || TO_CHAR (SYSDATE, 'MMDDYYYY_HH24MISS');
   lc_mode                     VARCHAR2 (1) := 'W';
   lc_source_path              VARCHAR2 (200);
   lc_header_string            VARCHAR2 (4000);
   lc_string                   VARCHAR2 (4000);
   ln_total_records            NUMBER;
   ln_success_records          NUMBER;
   ln_failed_records           NUMBER;
   lc_process_type             VARCHAR2 (200):='eBilling Contacts';
   lr_config_details_rec       xx_fin_translatevalues%ROWTYPE;
   lc_error_msg                VARCHAR2 (4000);
   lc_return_status            VARCHAR2 (100);
   e_process_exception         EXCEPTION;
   e_cursor_exception          EXCEPTION;
   ln_batch_id                 NUMBER;
   lc_subject                  VARCHAR2 (200);
   lc_attach_text              VARCHAR2 (1000);
   lc_status                   VARCHAR2 (1);
   lc_utl_file_fopen           VARCHAR2 (2):= 'Y';
   lc_copy_file_complete       VARCHAR2 (100);
   
   BEGIN
      fnd_file.put_line(fnd_file.log,'Input parameters .....:');
      fnd_file.put_line(fnd_file.log,'p_execution_date: ' || p_execution_date);
      fnd_file.put_line(fnd_file.log,'p_debug_flag:' || p_debug_flag);
      fnd_file.put_line(fnd_file.log,'p_status:' || p_status);
      fnd_file.put_line(fnd_file.log,'p_aops_acct_number:' || p_aops_acct_number);

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;

      ln_total_records      := 0;
      ln_success_records    := 0;
      ln_failed_records     := 0;
      lc_file_name          := NULL;
      lr_config_details_rec := NULL;
      lc_subject            := NULL;
      lc_attach_text        := NULL;
      lc_status             := NULL;
      
      -- Calling  Get Config Details  
      log_msg('Calling Get Config Details');     
      get_config_details (p_process_type       =>  lc_process_type,
                          p_config_details_rec =>  lr_config_details_rec,
                          p_return_status      =>  lc_return_status,
                          p_return_msg         =>  lc_error_msg
                         );
      log_msg('Get Config Details Return Status :'||lc_return_status);
      log_msg('Get Config Details Return Message :'||lc_error_msg); 
                        
      -- Get the Source Directory Name      
      lc_source_path := lr_config_details_rec.target_value7; 
      IF lc_source_path IS NULL
      THEN 
         RAISE e_process_exception;
      END IF;

      lc_file_name := lc_filename || lc_file || '.csv';

      ---- Building a header string to spit out the the file to the specific output directory
      log_msg('Building header string');
      lc_header_string :=
            'Date'
         || ','
         || 'AOPS Customer Number'
         || ','
         || 'Oracle Cusotmer Number'
         || ','
         || 'Oracle Customer Name'
         || ','
         || 'OMX Customer Number'
         || ','
         || 'ODN Consignee Reference'
         || ','
         || 'ODN Contact email address'
         || ','
         || 'AOPS Address Reference'
         || ','
         || 'Exception Message';

      FOR cur_extract_rec IN cur_extract(p_execution_date     => ld_execution_date,
                                         p_status             => p_status,
                                         p_aops_acct_number   => p_aops_acct_number)
      LOOP
         BEGIN   
         ln_batch_id                := 0;
         lc_error_msg               := NULL;
         lc_return_status           := NULL;  
         ln_cust_account_id         := NULL; 
         lc_oracle_customer_name    := NULL;
         lc_oracle_customer_name    := NULL;
         lc_aops_bill_to_reference  := NULL;
            log_msg('  ');
            log_msg('Processing the AOPS customer number :'||cur_extract_rec.aops_customer_number);
            -- Get the batch id             
            ln_batch_id := cur_extract_rec.batch_id;                        
            -- Calling customer info procedure to get customer name and customer account id 
            log_msg('Calling get customer info ');                       
            get_customer_info (  p_aops_customer_number => cur_extract_rec.aops_customer_number,
                                 p_cust_account_id      => ln_cust_account_id,
                                 p_account_number       => lc_oracle_account_number,
                                 p_account_name         => lc_oracle_customer_name,
                                 p_return_msg           => lc_error_msg,
                                 p_return_status        => lc_return_status
                              );
            log_msg('Get Customer Info return status :'||lc_return_status);
            log_msg('Get Customer Info return message :'||lc_error_msg);
            
            IF lc_return_status <> gc_success
            THEN
               RAISE e_cursor_exception;
            END IF;

            -- Get the AOPS BILL_TO Address Reference
            log_msg('Calling aops address reference');
            lc_aops_bill_to_reference := get_aops_addr_reference ( p_cust_account_id   => ln_cust_account_id,
                                                                   p_consignee_num     => cur_extract_rec.bill_to_consignee);

            log_msg ('Aops bill to address reference :'|| lc_aops_bill_to_reference);
            
            --UTL File open
        
            IF lc_utl_file_fopen = 'Y'
            THEN
               lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, lc_mode);
               UTL_FILE.put_line (lc_filehandle, lc_header_string);
               lc_utl_file_fopen := 'N';
            END IF;
            
            -- Building a exception string to spit out the the file to the specific output directory
            lc_string :=      cur_extract_rec.creation_date
                           || ','
                           || cur_extract_rec.aops_customer_number
                           || ','
                           || cur_extract_rec.oracle_customer_number
                           || ','
                           || lc_oracle_customer_name
                           || ','
                           || '='
                           || '"'
                           || cur_extract_rec.omx_customer_number
                           || '"'
                           || ','
                           || '='
                           || '"'
                           || cur_extract_rec.bill_to_consignee
                           || '"'
                           || ','
                           || cur_extract_rec.email_address
                           || ','
                           || '='
                           || '"'
                           || lc_aops_bill_to_reference
                           || '"'
                           || ','
                           || cur_extract_rec.error_message;

            UTL_FILE.put_line (lc_filehandle, lc_string);


            --Count Sucessful records loaded into the exception file

            ln_success_records := ln_success_records + 1;
         EXCEPTION
            WHEN UTL_FILE.INVALID_MODE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2; 
              RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
                   
            WHEN UTL_FILE.INVALID_PATH
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;  
              RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
                     
            WHEN UTL_FILE.INVALID_FILEHANDLE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
              
            WHEN UTL_FILE.INVALID_OPERATION
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
                          
            WHEN UTL_FILE.WRITE_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20056, 'Write Error');
              
            WHEN UTL_FILE.INTERNAL_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
              
            WHEN UTL_FILE.FILE_OPEN
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
            WHEN OTHERS
            THEN
               IF lc_error_msg IS NULL
               THEN  
                  lc_error_msg:= 'Error while processing record '|| cur_extract_rec.record_id ||SQLERRM;
               END IF;          
               log_msg(lc_error_msg);
               log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GEN_EBILLCONT_EXCEPTION_REPORT',
                               p_error_msg         =>  lc_error_msg); 
                                   
               ln_failed_records := ln_failed_records + 1;
         END;
         
         ln_total_records := ln_total_records + 1;
      END LOOP;

      UTL_FILE.fclose (lc_filehandle);
      
      log_msg('  ');
      fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
      fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
      fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_total_records);
      
        -- Call move file to move the file from source to destination
         
         IF  ln_success_records > 0
         THEN 
           log_msg('Calling move file');
           move_file  (p_file_name           => lc_file_name,
                       p_config_details_rec  => lr_config_details_rec,
                       p_sfdc_source         => 'N',
                       p_return_status       => lc_return_status,
                       p_return_msg          => lc_error_msg,
                       p_copy_file_complete  => lc_copy_file_complete
                     ) ;  
         ELSE
           RAISE e_process_exception;                     
         END IF;     
                        
         -- Call Send mail
         IF lc_return_status = gc_success
         THEN
            
         log_msg('Calling send mail');      
         send_mail(p_file_name          => lc_file_name,
                   p_attach_text        => 'Attached are the Ebill Contacts Exception details for '||TO_CHAR(ln_batch_id),
                   p_config_details_rec => lr_config_details_rec,
                   p_mail_subject       => lr_config_details_rec.target_value11 ||' '|| gc_date||' : Batch Id: '||TO_CHAR(ln_batch_id),
                   p_copy_file_complete => lc_copy_file_complete,
                   p_return_status      => lc_return_status,
                   p_return_msg         => lc_error_msg                                          
                  );  
                                         
            log_msg('send mail return status :'|| lc_return_status);    
            log_msg('send mail return message :' || lc_error_msg);
                                           
         -- Calling log_file procedure
            IF lc_return_status = gc_success
            THEN
                lc_status := 'C';
            ELSE
                lc_status := 'E';
            END IF;
                 
            fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
            log_file (p_success_records   => ln_success_records,
                      p_failed_records    => ln_failed_records,
                      p_batch_id          => ln_batch_id,
                      p_file_name         => lc_file_name,
                      p_status            => lc_status);  
                      
         ELSE 
          RAISE e_process_exception;
         END IF;

   EXCEPTION
      WHEN OTHERS
      THEN
          IF lc_error_msg IS NULL
          THEN
             lc_error_msg := 'Unable to process the program :'||SQLERRM;
          END IF;
          fnd_file.put_line(fnd_file.log,lc_error_msg);
          log_msg(lc_error_msg);
          log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GEN_EBILLCONT_EXCEPTION_REPORT',
                          p_error_msg         =>  lc_error_msg);
          x_retcode := 2;
          ROLLBACK;
   END gen_ebillcont_exception_report;


   -- Reconcile Counts

   PROCEDURE reconcile_omx_counts (x_retcode        OUT NOCOPY  NUMBER,
                                   x_errbuf         OUT NOCOPY  VARCHAR2,
                                   p_batch_id       IN          NUMBER,
                                   p_debug_flag     IN          VARCHAR2,
                                   p_status         IN          VARCHAR2,
                                   p_execution_date IN          VARCHAR2)
   IS
   -- +================================================================================================+
   -- | Name  : reconcile_omx_counts                                                                   |
   -- | Description     : This procedure reconcile the counts received from OMX with trailer record    |
   -- |                   for each file and notifies if there any discrepencies                        |
   -- |                                                                                                |
   -- | Parameters      : p_batch_id            IN  -> Batch Id                                        |
   -- |                   p_debug_flag          IN  -> Debug Flag                                      |
   -- |                   p_status              IN  -> Status                                          |
   -- |                   p_execution_date      IN  -> Execution Date                                  |
   -- |                   x_retcode             OUT                                                    |
   -- |                   x_errbuf              OUT                                                    |
   -- +================================================================================================+

   CURSOR cur_extract(p_status         IN xx_cdh_omx_reconcile_count_stg.status%TYPE,
                      p_batch_id       IN xx_cdh_omx_reconcile_count_stg.batch_id%TYPE,
                      p_execution_date IN DATE)
   IS
     SELECT *
     FROM xx_cdh_omx_reconcile_count_stg
     WHERE status = NVL(p_status,status)
       AND batch_id = NVL (p_batch_id, batch_id)
       AND TRUNC(creation_date) >=  NVL(p_execution_date,TRUNC(SYSDATE))
     ORDER BY batch_id;
     
   ld_execution_date          DATE   := FND_DATE.CANONICAL_TO_DATE(p_execution_date); 
   lc_error_msg               VARCHAR2(4000);
   ln_ods_bill_contacts_cnt   NUMBER;
   ln_ods_bill_docs_cnt       NUMBER;
   ln_ods_addr_exceptions_cnt NUMBER;
   ln_ods_ap_contacts_cnt     NUMBER;
   ln_ods_dunning_cnt         NUMBER;
   ln_ods_credits_cnt         NUMBER;
   lc_subject                 VARCHAR2(200);
   ln_total_records           NUMBER;
   lr_config_details_rec      xx_fin_translatevalues%ROWTYPE;
   lc_process_type            VARCHAR2(200):= 'Reconcile Counts';
   lc_return_status           VARCHAR2(100);
   lc_email                   VARCHAR2(200);
   lc_attach_text             VARCHAR2(32000);
   e_process_exception        EXCEPTION;
   ln_batch_id                NUMBER;
   lc_exists                  VARCHAR(2) := 'N';
      
   BEGIN
   fnd_file.put_line(fnd_file.log,'Input parameters .....:');
   fnd_file.put_line(fnd_file.log,'p_batch_id:' || p_batch_id);
   fnd_file.put_line(fnd_file.log,'p_debug_flag:' || p_debug_flag);
   fnd_file.put_line(fnd_file.log,'p_status:' || p_status);
   fnd_file.put_line(fnd_file.log,'p_execution_date:' || p_execution_date);

   IF (p_debug_flag = 'Y')
   THEN
      g_debug_flag := TRUE;
   ELSE
     g_debug_flag := FALSE;
   END IF;
   
   lc_error_msg               := NULL;
   lc_subject                 := NULL;
   ln_total_records           := 0;
   lr_config_details_rec      := NULL;
   lc_return_status           := NULL;
   lc_attach_text             := NULL;
   
         
     FOR cur_extract_rec IN cur_extract(p_status          => p_status,
                                        p_batch_id        => p_batch_id,
                                        p_execution_date  => ld_execution_date)
     LOOP
        lc_exists := 'Y';
        BEGIN
          ln_batch_id                :=NULL;
          ln_ods_bill_contacts_cnt   :=NULL;
          ln_ods_bill_docs_cnt       :=NULL;
          ln_ods_addr_exceptions_cnt :=NULL;
          ln_ods_ap_contacts_cnt     :=NULL;
          ln_ods_dunning_cnt         :=NULL;
          ln_ods_credits_cnt         :=NULL;
          ln_batch_id := cur_extract_rec.batch_id;
          -- Check Billing documents count ( Detail count vs Trailer count)                
           IF cur_extract_rec.no_of_omx_ebill_docs IS NOT NULL
           THEN                 
              BEGIN
                 -- Get the detail count from the billing documents staging table
                 SELECT COUNT(1)
                   INTO ln_ods_bill_docs_cnt
                   FROM xx_cdh_omx_bill_docs_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                    
                IF cur_extract_rec.no_of_omx_ebill_docs <> ln_ods_bill_docs_cnt
                  THEN                                         
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_ebill_docs = ln_ods_bill_docs_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                                                                               
                    lc_attach_text:= 'Number of Ebilling Documents actually received: '||ln_ods_bill_docs_cnt||chr(10)||
                                     'Number of Ebilling documents in Trailer: '||cur_extract_rec.no_of_omx_ebill_docs|| ' are not matching' ;                                             
                ELSE
                                                
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_ebill_docs = ln_ods_bill_docs_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                END IF;
              EXCEPTION
                   WHEN OTHERS 
                   THEN                
                      lc_error_msg:= 'Unable to fetch the billing documents received count from Billing documents staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
              END;
                    
           END IF;
                               
            -- Check Billing contacts count ( Detail count vs Trailer count)
                    
           IF cur_extract_rec.no_of_omx_ebill_contacts IS NOT NULL
           THEN                 
              BEGIN
                 -- Get the detail count from the billing contacts staging table 
                 SELECT COUNT(1)
                   INTO ln_ods_bill_contacts_cnt
                   FROM xx_cdh_omx_ebill_contacts_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                   
                IF cur_extract_rec.no_of_omx_ebill_contacts <> ln_ods_bill_contacts_cnt
                THEN                                         
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_ebill_contacts = ln_ods_bill_contacts_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id; 
                                                  
                    lc_attach_text:= lc_attach_text ||chr(10)||'Number of Ebilling Contacts actually received: '||ln_ods_bill_contacts_cnt||chr(10)||
                                     'Number of Ebilling contacts in Trailer: '||cur_extract_rec.no_of_omx_ebill_contacts|| ' are not matching' ;  
                                                                                                                
                ELSE
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_ebill_contacts = ln_ods_bill_contacts_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                END IF;
              EXCEPTION
                   WHEN OTHERS 
                   THEN                               
                      lc_error_msg:= 'Unable to fetch the billing contacts received count from Billing contacts staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
              END;                   
                    
           END IF;
                               
            -- Check address exceptions count ( Detail count vs Trailer count)
                    
           IF cur_extract_rec.no_of_omx_addr_exceptions IS NOT NULL
           THEN                 
              BEGIN
                 -- Get the detail count from the address exceptions staging table 
                 SELECT COUNT(1)
                   INTO ln_ods_addr_exceptions_cnt
                   FROM xx_cdh_omx_addr_exceptions_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                   
                IF cur_extract_rec.no_of_omx_addr_exceptions <> ln_ods_addr_exceptions_cnt
                THEN
                                             
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_addr_exceptions = ln_ods_addr_exceptions_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;   
                                       
                     lc_attach_text:= lc_attach_text ||chr(10)||'Number of Address Exceptions actually received: '||ln_ods_addr_exceptions_cnt||chr(10)||
                                     'Number of Address Exceptions in Trailer: '||cur_extract_rec.no_of_omx_addr_exceptions|| ' are not matching' ;                                                                                                    
                ELSE
                                                
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_addr_exceptions = ln_ods_addr_exceptions_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                END IF;
              EXCEPTION
                   WHEN OTHERS 
                   THEN               
                      lc_error_msg:= 'Unable to fetch the Address Exceptions received count from Address Exceptions staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
                END;

             END IF;
                                  
            -- Check AP contacts count ( Detail count vs Trailer count)                
             IF cur_extract_rec.no_of_omx_ap_contacts IS NOT NULL
             THEN                 
                BEGIN
                 -- Get the detail count from the AP contacts staging table 
                 SELECT COUNT(1)
                   INTO ln_ods_ap_contacts_cnt
                   FROM xx_cdh_omx_ap_contacts_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                    
                  IF cur_extract_rec.no_of_omx_ap_contacts <> ln_ods_ap_contacts_cnt
                  THEN                                         
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_ap_contacts = ln_ods_ap_contacts_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id; 
                                                  
                     lc_attach_text:= lc_attach_text ||chr(10)||'Number of AP Contacts actually received: '||ln_ods_ap_contacts_cnt||chr(10)||
                                     'Number of AP Contacts in Trailer: '||cur_extract_rec.no_of_omx_ap_contacts|| ' are not matching' ;   
                                                               
                  ELSE                                           
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_ap_contacts = ln_ods_ap_contacts_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                  END IF;
                EXCEPTION
                   WHEN OTHERS 
                   THEN                
                      lc_error_msg:= 'Unable to fetch the AP Contacts received count from AP Contacts staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
                END;
                    
             END IF;
                                  
            -- Check Dunning count ( Detail count vs Trailer count)
                    
             IF cur_extract_rec.no_of_omx_dunning IS NOT NULL
             THEN                 
                BEGIN
                 -- Get the detail count from the Dunning staging table 
                 SELECT COUNT(1)
                   INTO ln_ods_dunning_cnt
                   FROM xx_cdh_omx_dunning_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                   
                  IF cur_extract_rec.no_of_omx_dunning <> ln_ods_dunning_cnt
                  THEN                                         
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_dunning = ln_ods_dunning_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id; 
                                                    
                     lc_attach_text:= lc_attach_text ||chr(10)||'Number of Dunning records actually received: '||ln_ods_dunning_cnt||chr(10)||
                                     'Number of Dunning records in Trailer: '||cur_extract_rec.no_of_omx_dunning|| ' are not matching' ;                                            
                  ELSE
                                                
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_dunning = ln_ods_dunning_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                  END IF;
                EXCEPTION
                   WHEN OTHERS 
                   THEN                
                      lc_error_msg:= 'Unable to fetch the Dunning received count from the Dunning staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
                END;                      
                    
             END IF;
                                  
            -- Check Credit limits count ( Detail count vs Trailer count)
                    
             IF cur_extract_rec.no_of_omx_credits IS NOT NULL
             THEN                 
                BEGIN
                 -- Get the detail count from the Customer info staging table 
                 SELECT COUNT(1)
                   INTO ln_ods_credits_cnt
                   FROM xx_cdh_omx_cust_info_stg
                  WHERE batch_id =cur_extract_rec.batch_id;
                                                                   
                  IF cur_extract_rec.no_of_omx_credits <> ln_ods_credits_cnt
                  THEN                                        
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'E',
                           no_of_ods_credits = ln_ods_credits_cnt,
                           error_message = 'Counts Mismatched',
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;

                     lc_attach_text:= lc_attach_text ||chr(10)||'Number of Customer Information records actually received: '||ln_ods_credits_cnt||chr(10)||
                                     'Number of Customer Information records in Trailer: '||cur_extract_rec.no_of_omx_credits|| ' are not matching' ;                                              
                  ELSE
                                                
                    UPDATE xx_cdh_omx_reconcile_count_stg
                    SET    status = 'C',
                           no_of_ods_credits = ln_ods_credits_cnt,
                           last_update_date = gd_last_update_date,
                           last_updated_by =gn_last_updated_by
                    WHERE  batch_id = cur_extract_rec.batch_id
                      AND  record_id = cur_extract_rec.record_id;
                                                  
                  END IF;
                EXCEPTION
                   WHEN OTHERS 
                   THEN                
                      lc_error_msg:= 'Unable to fetch the Credit Limits received count from the Customer Info staging table '||SQLERRM;
                      log_msg(lc_error_msg);                               
                END;                   
                    
             END IF;
                   
          EXCEPTION
          
           WHEN OTHERS 
           THEN
              IF lc_error_msg IS NOT NULL
              THEN
                 lc_error_msg := 'Unable to process the record '||SQLERRM;
              END IF;
           log_msg(lc_error_msg);
           log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.RECONCILE_OMX_COUNTS',
                           p_error_msg         =>  lc_error_msg);
                
          END;
          ln_total_records:= ln_total_records + 1;
       END LOOP;
       
       COMMIT;
     IF lc_exists ='Y' 
     THEN 
       IF lc_attach_text IS NOT NULL
       THEN
          lc_attach_text:= 'Batch Id is :'||ln_batch_id||chr(10)||lc_attach_text;
          log_msg('  ');
          log_msg(lc_attach_text);
          -- Calling  Get Config Details   
          log_msg('  ');
          log_msg('Calling Get Config Details');   
          get_config_details (p_process_type       =>  lc_process_type,
                              p_config_details_rec =>  lr_config_details_rec,
                              p_return_status      =>  lc_return_status,
                              p_return_msg         =>  lc_error_msg
                             );
           
          log_msg('Get Config Details Return Status :'||lc_return_status);
          log_msg('Get Config Details Return Message :'||lc_error_msg);     
                              
          -- Get the Email      
          lc_email := lr_config_details_rec.target_value4; 
          fnd_file.put_line(fnd_file.log,'Email is :'||lc_email);
          IF lc_email IS NULL
          THEN 
             log_msg(lc_error_msg);
             RAISE e_process_exception;
          END IF;
           
        -- Call Send mail   
          log_msg('Calling send mail');      
          send_mail(p_file_name          => NULL,
                    p_attach_text        => lc_attach_text,
                    p_config_details_rec => lr_config_details_rec,
                    p_mail_subject       => lr_config_details_rec.target_value11 ||' '|| gc_date||' : Batch Id: '||TO_CHAR(ln_batch_id),                                           
                    p_copy_file_complete => NULL,
                    p_return_status      => lc_return_status,
                    p_return_msg         => lc_error_msg                                          
                   );                                          
          log_msg('send mail return status :'|| lc_return_status);    
          log_msg('send mail return message :' || lc_error_msg); 
          
       ELSE
          log_msg('  ');
          log_msg('No mismatch records found');      
       END IF;
     ELSE
     log_msg('  ');
     log_msg('No records found to process');
    END IF; 
   EXCEPTION
       WHEN OTHERS
       THEN
          IF lc_error_msg IS NULL
          THEN
             lc_error_msg := 'Unable to process the program :'||SQLERRM;
          END IF;
          fnd_file.put_line(fnd_file.log,lc_error_msg);
          log_msg(lc_error_msg);
          log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.RECONCILE_OMX_COUNTS',
                          p_error_msg         =>  lc_error_msg);
          x_retcode := 2;
          ROLLBACK;
END reconcile_omx_counts;

-- Generate Status Report
   PROCEDURE generate_status_report (x_retcode              OUT NOCOPY NUMBER,
                                     x_errbuf               OUT NOCOPY VARCHAR2,
                                     p_execution_date       IN         VARCHAR2,
                                     p_debug_flag           IN         VARCHAR2,
                                     p_aops_acct_number     IN         VARCHAR2)
   IS
   -- +================================================================================+
   -- | Name  : generate_status_report                                                 |
   -- | Description     : This procedure generates a status report and emails the      |
   -- |                   output to Dist list                                          |
   -- |                                                                                |
   -- | Parameters      : p_execution_date      IN -> Execution Date                   |
   -- |                   p_debug_flag          IN -> Debug Flag                       |
   -- |                   p_aops_acct_number    IN -> AOPS Customer Number             |
   -- |                   x_retcode            OUT                                     |
   -- |                   x_errbuf             OUT                                     |
   -- +================================================================================+

   CURSOR cur_extract (p_execution_date      IN  DATE,
                       p_aops_acct_number    IN  xx_cdh_mod4_sfdc_cust_stg.aops_customer_number%TYPE)
   IS
     (SELECT  a.record_id,
             a.batch_id,
             a.aops_customer_number,
             a.omx_customer_number,
             a.creation_date,
             a.billing_type,
             a.split_customer,
             DECODE(a.status,'C','Completed','I','Interfaced to OMX','E','Error','N','New','P','Processed','Z','Split Customer') as status,
             a.error_message,
             b.oracle_customer_number,
             b.active_consignee,
             b.print_daily_flag,
             b.summary_bill_flag,
             b.payment_term,
             b.ods_payment_term,
             b.summary_bill_cycle,
             b.print_exp_rep_flag,
             b.print_inv_detail_flag,
             b.print_remittance_page,
             b.sort_by_consignee_exp_rpt,
             b.sort_by_po_exp_rpt,
             b.sort_by_costcenter_exp_rpt,
             c.credit_limit,
             c.statement_cycle,  -- Added as per Defect 1322
             c.statement_type    -- Added as per Defect 1322
       FROM  xx_cdh_mod4_sfdc_cust_stg a,
             xx_cdh_omx_bill_docs_stg  b,
             xx_cdh_omx_cust_info_stg  c
       WHERE TRUNC(a.creation_date) BETWEEN  NVL(TRUNC(p_execution_date)-1,SYSDATE) AND  NVL(TRUNC(p_execution_date),SYSDATE)
         AND p_execution_date IS NOT NULL
         AND a.aops_customer_number = b.aops_customer_number(+)
         AND a.batch_id = b.batch_id(+)
         AND a.aops_customer_number = c.aops_customer_number(+)
         AND a.batch_id = c.batch_id(+)
         AND a.aops_customer_number = NVL(p_aops_acct_number,a.aops_customer_number)
         --AND a.status <> 'N' -- Commented as per defect 1043
		 UNION
		 SELECT  a.record_id,
             a.batch_id,
             a.aops_customer_number,
             a.omx_customer_number,
             a.creation_date,
             a.billing_type,
             a.split_customer,
             DECODE(a.status,'C','Completed','I','Interfaced to OMX','E','Error','N','New','P','Processed','Z','Split Customer') as status,
             a.error_message,
             b.oracle_customer_number,
             b.active_consignee,
             b.print_daily_flag,
             b.summary_bill_flag,
             b.payment_term,
             b.ods_payment_term,
             b.summary_bill_cycle,
             b.print_exp_rep_flag,
             b.print_inv_detail_flag,
             b.print_remittance_page,
             b.sort_by_consignee_exp_rpt,
             b.sort_by_po_exp_rpt,
             b.sort_by_costcenter_exp_rpt,
             c.credit_limit,
             c.statement_cycle,  -- Added as per Defect 1322
             c.statement_type    -- Added as per Defect 1322      
       FROM  xx_cdh_mod4_sfdc_cust_stg a,
             xx_cdh_omx_bill_docs_stg  b,
             xx_cdh_omx_cust_info_stg  c
       WHERE a.process_flag IS NULL 
	     AND p_execution_date IS NULL
         AND a.aops_customer_number = b.aops_customer_number(+)
         AND a.batch_id = b.batch_id(+)
         AND a.aops_customer_number = c.aops_customer_number(+)
         AND a.batch_id = c.batch_id(+)
         AND a.aops_customer_number = NVL(p_aops_acct_number,a.aops_customer_number)
       );
   ld_execution_date            DATE;           
   lc_filehandle                UTL_FILE.file_type;
   lc_filename                  VARCHAR2 (200):= 'xxod_cdh_mod4_status_report';
   lc_file_name                 VARCHAR2 (200);
   lc_file                      VARCHAR2 (200):= '_' || TO_CHAR (SYSDATE, 'MMDDYYYY_HH24MISS');
   lc_mode                      VARCHAR2 (1) := 'W';
   lc_source_path               VARCHAR2 (200);
   lc_header_string             VARCHAR2 (4000);
   lc_string                    VARCHAR2 (32000);
   ln_total_records             NUMBER;
   ln_success_records           NUMBER;
   ln_failed_records            NUMBER; 
   lc_oracle_customer_name      VARCHAR2 (200);
   lr_config_details_rec        xx_fin_translatevalues%ROWTYPE;
   lc_process_type              VARCHAR2(200):= 'sfdc status report';
   ln_batch_id                  NUMBER;
   e_process_exception          EXCEPTION;
   e_cursor_exception           EXCEPTION;
   lc_subject                   VARCHAR2 (200);
   ln_cust_account_id           NUMBER;
   lc_oracle_account_number     VARCHAR2 (200);
   lr_payment_term_info         ra_terms%ROWTYPE;
   lr_bill_docs_info            xx_cdh_omx_bill_docs_stg%ROWTYPE ;         
   lc_billing_flag              VARCHAR2 (10);
   lc_delivery_method           VARCHAR2 (100);
   lc_error_msg                 VARCHAR2 (4000);
   lc_return_status             VARCHAR2 (100);      
   lc_status                    VARCHAR2 (1);
   lc_default_delivery_used     VARCHAR2 (1);
   lc_default_payterm_used      VARCHAR2 (1);
   --lc_utl_file_fopen            VARCHAR2 (2):= 'Y'; -- Commented as per Defect 37158
   lc_copy_file_complete        VARCHAR2 (100);
   lc_attach_text               VARCHAR2 (100); -- Added for Kitting Defect 37158
   lc_mail_subject              VARCHAR2 (100); -- Added for Kitting Defect 37158
   
   BEGIN
      lc_attach_text   := NULL; -- Added for Kitting Defect 37158
      lc_mail_subject  := NULL; -- Added for Kitting Defect 37158
      fnd_file.put_line(fnd_file.log,'Input parameters .....:');
      fnd_file.put_line(fnd_file.log,'p_execution_date: ' || p_execution_date);
      fnd_file.put_line(fnd_file.log,'p_debug_flag:' || p_debug_flag);
      fnd_file.put_line(fnd_file.log,'p_aops_acct_number:' || p_aops_acct_number);

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;
      
      IF p_execution_date IS NOT NULL
      THEN 
        ld_execution_date := FND_DATE.CANONICAL_TO_DATE(p_execution_date);
      ELSE
        ld_execution_date := NULL;
      END IF;
     
      ln_success_records:= 0;
      ln_failed_records := 0;
      ln_total_records  := 0;
      
      log_msg('Calling Get Config Details');   
      get_config_details (p_process_type       =>  lc_process_type,
                          p_config_details_rec =>  lr_config_details_rec,
                          p_return_status      =>  lc_return_status,
                          p_return_msg         =>  lc_error_msg
                         );
       
      log_msg('Get Config Details Return Status :'||lc_return_status);
      log_msg('Get Config Details Return Message :'||lc_error_msg);
                          
      -- Get the Source Directory Name      
      lc_source_path := lr_config_details_rec.target_value7; 
      IF lc_source_path IS  NULL
      THEN 
         RAISE e_process_exception;
      END IF;
      
      lc_file_name := lc_filename || lc_file || '.csv';
      
      -- Building a header string to spit out the the file to the specific output directory
      log_msg('Building header string');
      lc_header_string :=   'Date'
                         || ','
                         || 'AOPS Customer Number'
                         || ','
                         || 'Oracle Customer Number'
                         || ','
                         || 'Oracle Customer Name'
                         || ','
                         || 'OMX Customer Number'
                         || ','
                         || 'Billing Type'
                         || ','
                         || 'Split Flag'
                         || ','
                         || 'Active Consignee'
                         || ','
                         || 'Print Daily Flag'
                         || ','
                         || 'Summary Bill Flag'
                         || ','
                         || 'ODN Term'
                         || ','
                         || 'ODN Summary Bill Cycle'
                         || ','
                         || 'Print Expense Report'
                         || ','
                         || 'Print Invoice Report'
                         || ','
                         || 'Print Remittance Page'
                         || ','
                         || 'Sort By Consignee Expense Report'
                         || ','
                         || 'Sort By PO Expense Report'
                         || ','
                         || 'Sort By Cost Center Expense Report'
                         || ','
                         || 'Credit Limit'
                         || ','
                         || 'ODN Statement Cycle'  -- Added as per Defect 1322
                         || ','
                         || 'ODN Statement Type'   -- Added as per Defect 1322
                         || ','
                         || 'OD Payment Term'
                         || ','
                         || 'Delivery Method'
                         || ','
                         || 'Status'
                         || ','
                         || 'Exception Message';
						 
	--UTL File open	  
	  lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, lc_mode); -- Added as per Defect 37158
      UTL_FILE.put_line (lc_filehandle, lc_header_string); -- Added as per Defect 37158
      
      FOR cur_extract_rec IN cur_extract(p_execution_date      => ld_execution_date,
                                         p_aops_acct_number    => p_aops_acct_number)
      LOOP
        BEGIN
            ln_batch_id                 := NULL; 
            lc_oracle_account_number    := NULL;
            lc_oracle_customer_name     := NULL;
            ln_cust_account_id          := NULL;
            lc_error_msg                := NULL;
            lc_return_status            := NULL;       
            lr_bill_docs_info           := NULL;   
            lr_payment_term_info        := NULL;
            lc_billing_flag             := NULL;
            lc_delivery_method          := NULL;
            lc_default_delivery_used    := NULL;
            lc_default_payterm_used     := NULL;
            log_msg ('  ');
            log_msg('Processing the AOPS Customer Number :'||cur_extract_rec.aops_customer_number);
            -- Get the batch id             
            ln_batch_id := cur_extract_rec.batch_id;            
            -- Calling customer info procedure to get customer name and customer account id 
            log_msg('Calling get customer info ');                       
            get_customer_info (  p_aops_customer_number => cur_extract_rec.aops_customer_number,
                                 p_cust_account_id      => ln_cust_account_id,
                                 p_account_number       => lc_oracle_account_number,
                                 p_account_name         => lc_oracle_customer_name,
                                 p_return_msg           => lc_error_msg,
                                 p_return_status        => lc_return_status
                              );
                              
            log_msg('Get Customer Info return status :'||lc_return_status);
            log_msg('Get Customer Info return message :'||lc_error_msg);
            
            IF ln_cust_account_id IS NOT NULL AND cur_extract_rec.billing_type IN ('DI','IS')
            THEN
                -- Calling get billing documents info
                log_msg('Calling get bill docs info');
                lc_return_status :=get_billing_docs_info(p_aops_customer_number     => cur_extract_rec.aops_customer_number,
                                                          p_batch_id                 => cur_extract_rec.batch_id,
                                                          p_return_msg               => lc_error_msg,
                                                          p_bill_docs_info           => lr_bill_docs_info);
                  
                log_msg('Get Bill Docs Info Return Message ;'|| lc_error_msg);
                              
                --Calling get_payment_term_info
                IF lr_bill_docs_info.payment_term IS NOT NULL 
                THEN
               
                 IF lr_bill_docs_info.summary_bill_flag = 'N'
                  THEN
                     lc_billing_flag := lr_bill_docs_info.print_daily_flag;

                   ELSIF lr_bill_docs_info.summary_bill_flag <> 'N'
                    THEN
                       lc_billing_flag := lr_bill_docs_info.summary_bill_flag;
                       
                 END IF;
                 
                 -- Calling derive delivery method
                log_msg('Calling derive delivery method');
                lc_return_status := APPS.XX_CDH_OMX_BILL_DOCUMENTS_PKG.derive_delivery_method(p_billing_flag      => lc_billing_flag,
                                                                                              p_delivery_method   => lc_delivery_method,
                                                                                              p_default_used      => lc_default_delivery_used,
                                                                                              p_error_msg         => lc_error_msg);
                                    
                log_msg('Derive delivery method return message ;'|| lc_error_msg);
                log_msg('Delivery Method is :'|| lc_delivery_method); 
            
                END IF; 
            
            END IF;
            
            -- Building a exception string to spit out the the file to the specific output directory            
            lc_string :=   cur_extract_rec.creation_date
                        || ','
                        || cur_extract_rec.aops_customer_number
                        || ','
                        || lc_oracle_account_number
                        || ','
                        || lc_oracle_customer_name
                        || ','
                        || '='
                        || '"'
                        || cur_extract_rec.omx_customer_number
                        || '"'
                        || ','
                        || cur_extract_rec.billing_type
                        || ','
                        || cur_extract_rec.split_customer
                        || ','
                        || cur_extract_rec.active_consignee
                        || ','
                        || cur_extract_rec.print_daily_flag
                        || ','
                        || cur_extract_rec.summary_bill_flag
                        || ','
                        || cur_extract_rec.payment_term
                        || ','
                        || cur_extract_rec.summary_bill_cycle
                        || ','
                        || cur_extract_rec.print_exp_rep_flag
                        || ','
                        || cur_extract_rec.print_inv_detail_flag
                        || ','
                        || cur_extract_rec.print_remittance_page
                        || ','
                        || cur_extract_rec.sort_by_consignee_exp_rpt
                        || ','
                        || cur_extract_rec.sort_by_po_exp_rpt
                        || ','
                        || cur_extract_rec.sort_by_costcenter_exp_rpt
                        || ','
                        || cur_extract_rec.credit_limit
                        || ','
                        || cur_extract_rec.statement_cycle  -- Added as per Defect 1322
                        || ','
                        || cur_extract_rec.statement_type   -- Added as per Defect 1322
                        || ','
                        || cur_extract_rec.ods_payment_term
                        || ','
                        || lc_delivery_method
                        || ','
                        || cur_extract_rec.status
                        || ','
                        || REPLACE(REPLACE(cur_extract_rec.error_message,CHR(10),CHR(32)),',',' ');

            UTL_FILE.put_line (lc_filehandle, lc_string);
            
            ln_success_records:= ln_success_records + 1;
			
			-- Updating the process flag in staging table for processed records
			 UPDATE xx_cdh_mod4_sfdc_cust_stg
               SET Process_flag = 'Y',
                   last_update_date = gd_last_update_date,
                   last_updated_by = gn_last_updated_by
             WHERE record_id = cur_extract_rec.record_id 
               AND p_execution_date IS NULL;
        EXCEPTION
            WHEN UTL_FILE.INVALID_MODE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2; 
              RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
                   
            WHEN UTL_FILE.INVALID_PATH
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;  
              RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
                     
            WHEN UTL_FILE.INVALID_FILEHANDLE
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
              
            WHEN UTL_FILE.INVALID_OPERATION
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
                          
            WHEN UTL_FILE.WRITE_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20056, 'Write Error');
              
            WHEN UTL_FILE.INTERNAL_ERROR
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
              
            WHEN UTL_FILE.FILE_OPEN
            THEN
              UTL_FILE.FCLOSE_ALL;
              x_retcode := 2;
              RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
            WHEN OTHERS
            THEN            
               IF lc_error_msg IS NULL
               THEN  
                  lc_error_msg:= 'Error while processing record '|| cur_extract_rec.record_id ||SQLERRM;
               END IF;          
               log_msg(lc_error_msg);
               log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GENERATE_STATUS_REPORT',
                               p_error_msg         =>  lc_error_msg); 
                                   
            ln_failed_records:= ln_failed_records + 1;                                     
        END;
      ln_total_records := ln_total_records + 1;
      END LOOP;
      
      UTL_FILE.fclose (lc_filehandle);
      log_msg('  ');
      fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
      fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
      fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_total_records);
      
      IF  ln_success_records > 0
      THEN 
          lc_attach_text  := 'Attached are the SFDC status report for '||TO_CHAR(ln_batch_id);
          lc_mail_subject := lr_config_details_rec.target_value11 ||' '|| gc_date||' : Batch Id: '||TO_CHAR(ln_batch_id);
      ELSE
          lc_attach_text  := 'No records received from SFDC';
          lc_mail_subject := lr_config_details_rec.target_value11 ||' '|| gc_date;                    
      END IF;    
      
       log_msg('Calling move file');
        move_file  (p_file_name           => lc_file_name,
                    p_config_details_rec  => lr_config_details_rec,
                    p_sfdc_source         => 'N',
                    p_return_status       => lc_return_status,
                    p_return_msg          => lc_error_msg,
                    p_copy_file_complete  => lc_copy_file_complete
                   ) ;  
                        
         -- Call Send mail
      IF lc_return_status = gc_success
      THEN
            
        log_msg('Calling send mail');      
        send_mail(p_file_name          => lc_file_name,
                  p_attach_text        => lc_attach_text,
                  p_config_details_rec => lr_config_details_rec,
                  p_mail_subject       => lc_mail_subject,
                  p_copy_file_complete  => lc_copy_file_complete,
                  p_return_status      => lc_return_status,
                  p_return_msg         => lc_error_msg                                          
                 );  
                                         
         log_msg('send mail return status :'|| lc_return_status);    
         log_msg('send mail return message :' || lc_error_msg);
                                           
        -- Calling log_file procedure
         IF lc_return_status = gc_success
         THEN
            lc_status := 'C';
         ELSE
            lc_status := 'E';
         END IF;
                 
         fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
         log_file (p_success_records   => ln_success_records,
                   p_failed_records    => ln_failed_records,
                   p_batch_id          => ln_batch_id,
                   p_file_name         => lc_file_name,
                   p_status            => lc_status);  
                     
         ELSE 
          RAISE e_process_exception;
         END IF;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to process the program :'||SQLERRM;
         END IF;
         fnd_file.put_line(fnd_file.log,lc_error_msg);
         log_msg(lc_error_msg);
         log_exception ( p_error_location    =>  'XX_CDH_OMX_GEN_REPORTS_PKG.GENERATE_STATUS_REPORT',
                         p_error_msg         =>  lc_error_msg);
         x_retcode := 2;
         
   END generate_status_report;    
END XX_CDH_OMX_GEN_REPORTS_PKG;
/
show errors;