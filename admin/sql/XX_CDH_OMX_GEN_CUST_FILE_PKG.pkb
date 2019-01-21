CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_OMX_GEN_CUST_FILE_PKG
AS
-- +=================================================================================+
-- |                        Office Depot                                             |
-- +=================================================================================+
-- | Name  : XX_CDH_OMX_GEN_CUST_FILE_PKG                                            |
-- | Rice ID: C0700                                                                  |
-- | Description      : This program will extracts the records from the              |
-- |                    xx_cdh_mod4_sfdc_cust_stg table and generate the .txt file   |
-- |                                                                                 |
-- |Change Record:                                                                   |
-- |===============                                                                  |
-- |Version Date        Author            Remarks                                    |
-- |======= =========== =============== =============================================|
-- |1.0     13-FEB-2015 Havish Kasina   Initial draft version                        |
-- |2.0     06-MAR-2015 Havish Kasina   Code review changes                          |
-- |3.0     29-JUN-2015 Havish Kasina   MOD5 changes                                 |
-- |4.0     03-SEP-2015 Havish Kasina   Changes added as per Defects 1686 and 1689   |
-- |5.0     19-OCT-2015 Havish Kasina   Removed the apps schema in the existing code |
-- +=================================================================================+

--------------------------------
-- Global Variable Declaration --
--------------------------------
   gd_last_update_date    DATE           := SYSDATE;
   gn_last_updated_by     NUMBER         := fnd_global.user_id;
   gd_creation_date       DATE           := SYSDATE;
   gn_created_by          NUMBER         := fnd_global.user_id;
   gn_last_update_login   NUMBER         := fnd_global.login_id;
   gn_request_id          NUMBER         := fnd_global.conc_request_id;
   gd_cycle_date          DATE           := SYSDATE;
   gc_success             VARCHAR2(1)    := 'S';
   gc_failure             VARCHAR2(1)    := 'F';

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
   
      XX_COM_ERROR_LOG_PUB.log_error (
         p_return_code              => FND_API.G_RET_STS_ERROR,
         p_msg_count                => 1,
         p_application_name         => 'XXCRM',
         p_program_type             => 'Custom Messages',
         p_program_name             => 'XX_CDH_OMX_GEN_CUST_FILE',
         p_attribute15              => 'XX_CDH_OMX_GEN_CUST_FILE',
         p_program_id               => NULL,
         p_module_name              => 'MOD4A',
         p_error_location           => p_error_location,
         p_error_message_code       => NULL,
         p_error_message            => p_error_msg,
         p_error_message_severity   => 'MAJOR',
         p_error_status             => 'ACTIVE',
         p_created_by               => ln_user_id,
         p_last_updated_by          => ln_user_id,
         p_last_update_login        => ln_login);
         
   EXCEPTION
   
      WHEN OTHERS
      THEN
      log_msg('Error while writing to the log ...' || SQLERRM);
                            
   END log_exception;

   
-- Check Customer Exists in Oracle 

   PROCEDURE check_customer_exists (
      p_aops_cust_number            IN     xx_cdh_mod4_sfdc_cust_stg.aops_customer_number%TYPE,
      p_oracle_customer_number      OUT    hz_cust_accounts.account_number%TYPE,
      p_return_msg                  OUT    VARCHAR2,
      p_return_status               OUT    VARCHAR2)
   IS
   -- +=======================================================================+
   -- | Name  : check_customer_exists                                         |
   -- | Description     : The check_customer_exists function checks           |
   -- |                  whether the customer exists or not                   |
   -- |                                                                       |
   -- | Parameters : p_aops_cust_number         IN  -> AOPS customer number   |
   -- |              p_oracle_customer_number   OUT -> Oracle customer number |
   -- |              p_return_status            OUT -> return status          |
   -- |              p_return_msg               OUT -> return message         |
   -- +=======================================================================+

  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
   lc_error_msg     VARCHAR2 (4000):= NULL;
   
   BEGIN

      SELECT hca.account_number
        INTO p_oracle_customer_number
        FROM hz_cust_accounts hca
       WHERE hca.orig_system_reference = LPAD (TO_CHAR (p_aops_cust_number), 8, 0)|| '-'|| '00001-A0'
         AND hca.status = 'A'
         ;

      log_msg ('Oracle Customer Customer :'|| p_oracle_customer_number|| ' found for AOPS Customer Number :'|| p_aops_cust_number);      
      p_return_msg:= NULL;
      p_return_status:= gc_success;
      
   EXCEPTION
   
      WHEN NO_DATA_FOUND
      THEN
          lc_error_msg :='Customer does not exist';
          log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.CHECK_CUSTOMER_EXISTS',
                         p_error_msg        => lc_error_msg);             
          p_oracle_customer_number := NULL;
          p_return_msg:= lc_error_msg;
          p_return_status:= gc_failure;

      WHEN OTHERS
      THEN
                       
          IF lc_error_msg is NULL 
          THEN 
             lc_error_msg :='Unable to fetch Oracle Customer number for AOPS Customer Number :'|| p_aops_cust_number|| ' '|| SQLERRM;
          END IF;
          
          log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.CHECK_CUSTOMER_EXISTS',
                         p_error_msg        => lc_error_msg);
          p_oracle_customer_number := NULL;
          p_return_msg:= lc_error_msg;
          p_return_status:= gc_failure;         
   END;

--update the status in staging table

  PROCEDURE update_status(p_record_id           IN     NUMBER,
                          p_status              IN     VARCHAR2,
                          p_error_message       IN OUT VARCHAR2)
  IS  
  -- +=======================================================================+
  -- | Name  : update_status                                                 |
  -- | Description: This is to update the status in staging table            |
  -- |                                                                       |
  -- | Parameters : p_record_id         IN    -> Record Id                   |
  -- |              p_status            IN    -> Status in staging table     |
  -- |              p_error_message    IN OUT -> Error Message               |
  -- +=======================================================================+
   BEGIN

     UPDATE xx_cdh_mod4_sfdc_cust_stg
     SET status           = p_status,
         error_message    = p_error_message,
         last_update_date = gd_last_update_date,
         last_updated_by  = gn_last_updated_by
      WHERE record_id     = p_record_id
        AND status         = 'N';
    
  EXCEPTION
    WHEN OTHERS
    THEN
      IF p_error_message IS NULL
      THEN
        p_error_message := 'Error while updating the status  '|| SQLERRM ;
      END IF;
      
      log_msg (p_error_message);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.UPDATE_STATUS',
                     p_error_msg        => p_error_message);
  END update_status;

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
      -------------------------------------------------------------------
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

         log_msg('Inserted records into log table for batch id: '|| p_batch_id);         
            
   EXCEPTION   
      WHEN OTHERS
      THEN
      IF lc_error_msg is NULL 
      THEN
         lc_error_msg :='Unable to insert the records in log table' || SQLERRM;
      END IF;
      
      log_msg(lc_error_msg);
      log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.LOG_FILE',
                     p_error_msg        => lc_error_msg);                     
   END log_file;
   
-- Get Config details

   PROCEDURE get_config_details (
                                 p_process_type       IN    VARCHAR2,
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
   -- | Parameters      : p_process_type         IN  -> Process Type                 |
   -- |                   p_config_details_rec   OUT -> Config Details               |
   -- |                   p_return_status        OUT -> Return Status ('E' or 'S')  |
   -- |                   p_return_msg           OUT  -> Return Message              |
   -- +==============================================================================+  
   -- Declaration of Local Variables 
   lc_translation_name        xx_fin_translatedefinition.translation_name%TYPE := 'XXOD_OMX_MOD4_INTERFACE';
   lc_error_msg               VARCHAR2(4000):= NULL;
       
   BEGIN
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
         log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.GET_CONFIG_DETAILS',
                        p_error_msg        => lc_error_msg);
          p_return_status      := gc_failure;
          p_return_msg         := lc_error_msg;
          p_config_details_rec := NULL; 
                 
      WHEN OTHERS THEN
          IF lc_error_msg IS NULL
          THEN
             lc_error_msg:= 'Interface (Process Type) could not be retrieved: '||p_process_type||SQLERRM;
          END IF;
          log_msg(lc_error_msg);
          log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.GET_CONFIG_DETAILS',
                         p_error_msg        => lc_error_msg);
          p_return_status := gc_failure;
          p_return_msg    := lc_error_msg;
          p_config_details_rec := NULL;
      
   END get_config_details;

-- Move the outbound file from Source to Destination   
   PROCEDURE ftp_file (p_file_name          IN     VARCHAR2,
                       p_config_details_rec IN     xx_fin_translatevalues%ROWTYPE,
                       p_return_status      OUT    VARCHAR2,
                       p_return_msg         OUT    VARCHAR2
                      )
   IS
   -- +=================================================================================+
   -- | Name  :ftp_file                                                                 |
   -- | Description : This procedure picks the outbound file from source directory and  |
   -- |               sends the file to destination directory.                          |
   -- |                                                                                 |
   -- | Parameters  :     p_file_name           IN  -> file name                        |
   -- |                   p_return_status       OUT -> return status                    |
   -- |                   p_return_msg          OUT -> return message                   |
   -- |                   p_config_details_rec IN   -> Configuration Details            |
   -- +=================================================================================+
   
   -- Local Variable Declaration   
   lc_sourcepath             VARCHAR2 (200);
   lc_destpath               VARCHAR2 (200);
   lc_archivepath            VARCHAR2 (200);
   lc_email                  VARCHAR2 (200);
   lc_error_msg              VARCHAR2 (4000):= NULL;
   e_error_exception         EXCEPTION;
   ln_copy_conc_request_id   NUMBER;

   BEGIN   
      -- Get the Source Path
      log_msg('Get the Source Path');      
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
      log_msg('Get the Destination Path');
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
         
      -- Get the Archive Path
      log_msg('Get the Archive Path');
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
             log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.FTP_FILE',
                          p_error_msg        => lc_error_msg);                                                      
           WHEN OTHERS
           THEN
             lc_error_msg :='Unable to fetch Archive Directory path' || SQLERRM;
             log_msg(lc_error_msg);
             log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.FTP_FILE',
                            p_error_msg        => lc_error_msg);                           
         END; 
                      
      -- Config Details 
         lc_sourcepath  := lc_sourcepath || '/' || p_file_name;
         lc_destpath    := lc_destpath || '/omx/' || p_file_name;
         lc_archivepath := lc_archivepath;
         
         fnd_file.put_line(fnd_file.log,'File Name is ....'||p_file_name);
         fnd_file.put_line(fnd_file.log,'Source Directory Name is....'||p_config_details_rec.target_value7);
         fnd_file.put_line(fnd_file.log,'Source Directory Path is....'||lc_sourcepath);
         fnd_file.put_line(fnd_file.log,'Destination Directory Name is....'||p_config_details_rec.target_value8);
         fnd_file.put_line(fnd_file.log,'Destination Directory Path is....'||lc_destpath);
         fnd_file.put_line(fnd_file.log,'Archive Directory Name is...'||p_config_details_rec.target_value9);
         fnd_file.put_line(fnd_file.log,'Archive Directory Path is....'||lc_archivepath);
       
      -- Calling File Copy Program
         ln_copy_conc_request_id := fnd_request.submit_request (application   => 'XXFIN',
                                                                program       => 'XXCOMFILCOPY',
                                                                description   => NULL,
                                                                start_time    => NULL,
                                                                sub_request   => FALSE,
                                                                argument1     => lc_sourcepath,
                                                                argument2     => lc_destpath,
                                                                argument3     => NULL,
                                                                argument4     => NULL,
                                                                argument5     => NULL,
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
            fnd_file.put_line(fnd_file.log,'Able to FTP the file');         
         ELSE
            lc_error_msg:= 'Unable to launch File Copy Program ';
            RAISE e_error_exception;                                                              
         END IF;

         p_return_status := gc_success;
         p_return_msg    := NULL;
                  
   EXCEPTION           
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
         lc_error_msg := 'Unable to FTP the file' || SQLERRM;
         END IF;
         log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.FTP_FILE',
                        p_error_msg        => lc_error_msg);
         p_return_msg   := lc_error_msg;
         p_return_status:= gc_failure;
   END ftp_file;

-- Main Extract
  PROCEDURE EXTRACT (x_retcode              OUT NOCOPY    NUMBER,
                     x_errbuf               OUT NOCOPY    VARCHAR2,
                     p_status               IN            VARCHAR2,
                     p_debug_flag           IN            VARCHAR2,
                     p_aops_customer_number IN            VARCHAR2)
  IS
  -- +==========================================================================+
  -- | Name  : extract                                                          |
  -- | Description     : The extract is the main                                |
  -- |                   procedure that will extract the records                |
  -- |                   and write them into the output file                    |
  -- |                                                                          |
  -- | Parameters      : x_retcode           OUT                                |
  -- |                   x_errbuf            OUT                                |
  -- |                   p_debug_flag        IN -> Debug Flag                   |
  -- |                   p_status                   IN -> Record status         |
  -- |                   p_aops_customer_number     IN -> AOPS Customer Number  |
  -- +==========================================================================+

  --------------------------------
  -- Local Variable Declaration --
  --------------------------------
  lc_error_msg                VARCHAR2 (4000);
  lc_return_status            VARCHAR2 (5);
  lc_filehandle               UTL_FILE.file_type;
  lc_file_name                VARCHAR2 (200) := 'xxod_cdh_mod4_ods_cust.txt'; 
  lc_mode                     VARCHAR2 (1) := 'W';
  lc_oracle_customer_number   hz_cust_accounts.account_number%TYPE;
  ln_batch_count              NUMBER;
  ln_new_batch                NUMBER;  
  ln_batch                    NUMBER;  
  ln_rec_count                NUMBER := 0;
  ln_success_records          NUMBER;
  ln_failed_records           NUMBER;
  lc_string                   VARCHAR2 (2000);
  e_process_exception         EXCEPTION;
  e_cursor_exception          EXCEPTION;
  lr_config_details_rec       xx_fin_translatevalues%ROWTYPE;
  lc_process_type             VARCHAR2(200):= 'MOD4 Customers File';
  lc_source_path              VARCHAR2(200);
  lc_status                   VARCHAR2(1);
  lc_omx_customer             VARCHAR2(40);
  lc_credit_limit_flag        VARCHAR2(1);
  ln_ship_to_count            NUMBER;
  lc_bill_to_consignee        VARCHAR2(40);
  ln_address_key_count        NUMBER;
  lc_party_site_consginee_num VARCHAR2(40);
  
  CURSOR cur_extract(p_aops_customer_number IN xx_cdh_mod4_sfdc_cust_stg.aops_customer_number%TYPE,
                     p_status               IN xx_cdh_mod4_sfdc_cust_stg.status%TYPE)
  IS
    SELECT *
      FROM xx_cdh_mod4_sfdc_cust_stg
     WHERE 1 = 1 
       AND status  =  NVL(p_status,'N')
       AND aops_customer_number = NVL(p_aops_customer_number,aops_customer_number)
     ORDER BY batch_id;
     
  -- Added as per Version 3.0, MOD5 Changes
  CURSOR cur_party_sites(p_party_id IN xx_cdh_mod4_sfdc_cust_stg.party_id%TYPE)
  IS
    SELECT hps.orig_system_reference consignee_num
      FROM hz_parties hp,
           hz_party_sites hps,
           hz_cust_acct_sites_all hcsa
     WHERE hp.party_id =  hps.party_id
       AND hcsa.party_site_id = hps.party_site_id
       AND hps.status = 'A'
       AND hps.party_id = p_party_id;
	   
  -- End of adding changes as per Version 3.0, MOD5 Changes
         
   BEGIN
      fnd_file.put_line (fnd_file.log,'Input parameters .....:');
      fnd_file.put_line (fnd_file.log,'p_debug_flag: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.log,'p_status:' || p_status);
      fnd_file.put_line (fnd_file.log,'p_aops_customer_number :'||p_aops_customer_number);
      
      IF (p_debug_flag = 'Y')
      THEN              
         g_debug_flag := TRUE;                 
      ELSE              
         g_debug_flag := FALSE;                 
      END IF;
            
      ln_success_records    := 0;
      ln_failed_records     := 0;
      ln_rec_count          := 0;
      lc_status             := NULL;
      lr_config_details_rec := NULL;
      ln_batch_count        := NULL;
      ln_new_batch          := NULL;
      lc_source_path        := NULL;
      lc_string             := NULL;
      lc_error_msg          := NULL;
      lc_return_status      := NULL;
	    lc_bill_to_consignee  := NULL;
	    lc_party_site_consginee_num := NULL;
	  BEGIN          
         -- Updating the status to 'E' in staging table if the customer is a Split Customer and having Billing Types "AE" and "IC"
         log_msg('Updating the status to E in staging table if the customer is a Split Customer');
             
         UPDATE xx_cdh_mod4_sfdc_cust_stg
            SET status           = 'E',
			    error_message    = 'Split account with "AE" or "IC" needs to be processed manually',
                last_update_date = gd_last_update_date,
                last_updated_by  = gn_last_updated_by
          WHERE billing_type     IN  ('AE','IC')
            AND split_customer   =   'Y'
            AND status           =   'N';

         fnd_file.put_line(fnd_file.log,'Number of records updated in the staging table if the customer is a split customer and having Billing Types "AE" and "IC":'|| SQL%ROWCOUNT);
         COMMIT;
             
      EXCEPTION          
         WHEN OTHERS
         THEN
           lc_error_msg :='Unable to update staging table if the Customer is a Split Customer and having Billing Types "AE" and "IC"'|| SQLERRM;
           log_msg (lc_error_msg);
           log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.EXTRACT',
                          p_error_msg        => lc_error_msg);             
      END;
      
      -- Calling  Get Config Details
      log_msg('Calling  Get Config Details');
      get_config_details (p_process_type       =>  lc_process_type,
                          p_config_details_rec =>  lr_config_details_rec,
                          p_return_status      =>  lc_return_status,
                          p_return_msg         =>  lc_error_msg
                          );
                                
      -- Get the Source Directory Name      
       lc_source_path := lr_config_details_rec.target_value7; 
               
         IF lc_source_path IS  NOT NULL
          THEN 
          --To get the distinct batch count          
            BEGIN                      
               log_msg('To get the distinct batch count');
               
               SELECT COUNT (DISTINCT NVL(batch_id,0))
                 INTO ln_batch_count
                 FROM xx_cdh_mod4_sfdc_cust_stg
                WHERE 1 = 1 
                  AND status = 'N';
                  
               log_msg('Distinct batch count is :'||ln_batch_count);
                         
            EXCEPTION                      
               WHEN OTHERS 
               THEN                         
                  lc_error_msg:= 'Unable to get the distinct batch count from the staging table '||SQLERRM;
               RAISE e_process_exception;
            END;
                  
          --To get the next batch_id if count(distinct batch_id) > 1
            IF ( (ln_batch_count > 1) OR (ln_batch_count = 0))
            THEN                  
               ln_new_batch := xxod_omx_mod4_batch_id_s.NEXTVAL;                     
            END IF;

          -- Update the batch_id with the new batch_id          
            IF (ln_batch_count > 1)
            THEN
               BEGIN  
                  log_msg('Updating the staging table with new batch id');
                                                        
                  UPDATE xx_cdh_mod4_sfdc_cust_stg
                     SET batch_id = ln_new_batch
                   WHERE 1 = 1 
                     AND status = 'N';
                                
                  fnd_file.put_line(fnd_file.log,'Number of records updated with new batch '||ln_new_batch|| ' are :'||SQL%ROWCOUNT);
                  COMMIT;
                         
               EXCEPTION                         
                  WHEN OTHERS
                  THEN                            
                    lc_error_msg:= 'Unable to update the batch id with new batch id in staging table '||SQLERRM;                              
                    RAISE e_process_exception;                          
               END;
                         
            END IF;
                  
            lc_filehandle := UTL_FILE.fopen (lc_source_path, lc_file_name, lc_mode);

          -- Checking if total record count =0 then write only new batch id in the file
          --  else build a string with the customer information
            IF (ln_batch_count = 0)
            THEN              
              lc_string := LPAD (ln_new_batch, 6, 0);

              UTL_FILE.put_line (lc_filehandle, lc_string);
                               
            ELSE
              -- Updating the staging table with new batch id when batch id is NULL
              UPDATE xx_cdh_mod4_sfdc_cust_stg
              SET batch_id = xxod_omx_mod4_batch_id_s.NEXTVAL
              WHERE 1 = 1 
                AND status = 'N' 
                AND batch_id IS NULL;
                     
               FOR cur_extract_rec IN cur_extract(p_aops_customer_number => p_aops_customer_number,
                                                  p_status => p_status)
               LOOP
                  BEGIN
                     lc_error_msg                 := NULL;
                     lc_return_status             := NULL;
                     lc_string                    := NULL;
                     lc_oracle_customer_number    := NULL;
		     lc_omx_customer              := NULL;
                     lc_credit_limit_flag         := NULL;
                     ln_ship_to_count             := 0;
		     lc_bill_to_consignee         := NULL;
                     ln_address_key_count         := 0;
                     lc_party_site_consginee_num  := NULL;
                     
                     log_msg (' ');
					 
                     log_msg ('Get the Oracle Customer Number for AOPS Number :'||cur_extract_rec.aops_customer_number);
                     check_customer_exists (p_aops_cust_number         => cur_extract_rec.aops_customer_number,
                                            p_oracle_customer_number   => lc_oracle_customer_number,
                                            p_return_msg               => lc_error_msg,
                                            p_return_status            => lc_return_status);

                     IF lc_return_status <> gc_success
                     THEN
                        RAISE e_cursor_exception;
                     END IF;

                     ln_batch := cur_extract_rec.batch_id;
					 
                     -- Added as per Version 3.0, MOD5 Changes
					 
		     IF cur_extract_rec.split_customer = 'Y'
                     THEN
                       lc_omx_customer := SUBSTR(cur_extract_rec.omx_customer_number,1,7);

			 IF cur_extract_rec.billing_type = 'IS'
                         THEN
			    lc_credit_limit_flag := 'N';
						    
                         ELSIF cur_extract_rec.billing_type = 'DI'
			 THEN
			    SELECT COUNT(hcas.orig_system_Reference)
			      INTO ln_ship_to_count
			      FROM hz_cust_acct_sites_all hcas,
                                   hz_cust_accounts       hca,
				   hz_cust_site_uses_all  hcsua
			     WHERE hcas.cust_account_id   =   hca.cust_account_id
			       AND hcas.cust_acct_site_id =   hcsua.cust_acct_site_id
                               AND hcas.status            =   'A'
                               AND hca.status             =   'A'
			       AND hcsua.status           =   'A'
			       AND hcsua.site_use_code    =   'SHIP_TO'
			       AND hca.account_number     =   lc_oracle_customer_number;

                           -- Added the logic as per Defect 1689
									 
			    IF ln_ship_to_count > 2 
                            THEN
				lc_credit_limit_flag := 'N';
			    ELSE 
                                SELECT COUNT( DISTINCT hl.address_key)
  				  INTO ln_address_key_count
  				  FROM hz_parties hp,
       				  hz_party_sites hps,
       				  hz_locations hl,
       				  hz_cust_accounts_all hca,
                                  hz_cust_acct_sites_all hcsa,
       				  hz_cust_site_uses_all hcsu
 			         WHERE hp.party_id            =    hps.party_id
   			      	   AND hps.location_id        =    hl.location_id
                                   AND hp.party_id            =    hca.party_id
                                   AND hcsa.party_site_id     =    hps.party_site_id
                                   AND hcsu.cust_acct_site_id =    hcsa.cust_acct_site_id
                                   AND hca.cust_account_id    =    hcsa.cust_account_id
                                   AND hcsa.status            =   'A'
                                   AND hca.status             =   'A'
	                           AND hcsu.status            =   'A'  
                                   AND hps.status             =   'A'
                                   AND hp.status              =   'A'
                                   AND hcsu.site_use_code     =   'SHIP_TO'
                                   AND hca.account_number     =   lc_oracle_customer_number;

                                   IF ln_address_key_count > 1
                                   THEN
                                        lc_credit_limit_flag := 'N'; 
                                   ELSE
                                        lc_credit_limit_flag := 'Y'; 
                                   END IF;
              END IF;
                        ELSE
                           lc_credit_limit_flag := 'Y'; 							
			END IF;     
							  							  
                    ELSE
                      lc_omx_customer := cur_extract_rec.omx_customer_number;
                      lc_credit_limit_flag := 'Y'; 
                    END IF;

               log_msg('Credit Limit Flag : '||lc_credit_limit_flag );
       -- Added the logic as per Defect 1686
        
	  -- Retrieving the Bill To Consignee Value
	    IF cur_extract_rec.bill_to_consignee = cur_extract_rec.omx_customer_number
            THEN 
                lc_bill_to_consignee := NULL;
            ELSE
                SELECT SUBSTR(cur_extract_rec.bill_to_consignee,
                              LENGTH(lc_omx_customer)+1,
                              DECODE(INSTR(cur_extract_rec.bill_to_consignee,'-OMX'),0,LENGTH(cur_extract_rec.bill_to_consignee)-LENGTH(lc_omx_customer),INSTR(cur_extract_rec.bill_to_consignee,'-OMX')-(LENGTH(lc_omx_customer)+1)))
                  INTO lc_bill_to_consignee
                  FROM DUAL;
            END IF;

           log_msg('Bill to Consignee : '||lc_bill_to_consignee); 
      -- End of changes as per Defect 1686
					     
        IF cur_extract_rec.billing_type = 'IS'
        THEN
                      
           FOR cur_party_sites_rec IN cur_party_sites(p_party_id => cur_extract_rec.party_id)
           LOOP
             lc_party_site_consginee_num := NULL;
           BEGIN
            -- Added the logic as per Defect 1686
 
             -- Retrieving Party Site Consignee Number
              IF INSTR(cur_party_sites_rec.consignee_num,'OMX00') > 0 
              THEN
                 lc_party_site_consginee_num := NULL;
              ELSE
                 log_msg('Consignee Number :'||cur_party_sites_rec.consignee_num ||'OMX Customer :'||lc_omx_customer);
                 SELECT SUBSTR(cur_party_sites_rec.consignee_num,
                              LENGTH(lc_omx_customer)+1,
                              DECODE(INSTR(cur_party_sites_rec.consignee_num,'-OMX'),0,LENGTH(cur_party_sites_rec.consignee_num)-LENGTH(lc_omx_customer),INSTR(cur_party_sites_rec.consignee_num,'-OMX')-(LENGTH(lc_omx_customer)+1)))
                  INTO lc_party_site_consginee_num 
                  FROM DUAL;
              END IF;

              log_msg('Party Site Consignee Num : '||lc_party_site_consginee_num); 
             -- End of changes as per Defect 1686                  
             -- Building a exception string to spit out the the file to the specific output directory
             lc_string:=   LPAD (NVL(cur_extract_rec.batch_id,0),6, 0)
                         ||LPAD (NVL(lc_oracle_customer_number,0),10, 0)
                         ||LPAD (NVL(cur_extract_rec.aops_customer_number,0),8,0)
                         ||LPAD (NVL(lc_omx_customer,0),7,0)
                         ||LPAD (NVL(cur_extract_rec.billing_type,0),2,0)
                         ||cur_extract_rec.split_customer
                         ||RPAD (NVL(lc_bill_to_consignee,' '),6,' ')
                         ||RPAD (NVL(lc_party_site_consginee_num ,' '),6,' ')
			 ||lc_credit_limit_flag
                         ;
		UTL_FILE.put_line (lc_filehandle, lc_string);
              EXCEPTION
              WHEN OTHERS 
              THEN
                 lc_error_msg := 'Unable to build the string for Indirect Customer';
                 log_msg(lc_error_msg);
                 RAISE e_cursor_exception;
            END;
            END LOOP;
       ELSE
            -- Building a exception string to spit out the the file to the specific output directory
            lc_string:=   LPAD (NVL(cur_extract_rec.batch_id,0),6, 0)
                        ||LPAD (NVL(lc_oracle_customer_number,0),10, 0)
                        ||LPAD (NVL(cur_extract_rec.aops_customer_number,0),8,0)
                        ||LPAD (NVL(lc_omx_customer,0),7,0)
                        ||LPAD (NVL(cur_extract_rec.billing_type,0),2,0)
                        ||cur_extract_rec.split_customer
                        ||RPAD (NVL(lc_bill_to_consignee,' '),6,' ')
                        ||RPAD (NVL(lc_bill_to_consignee,' '),6,' ')
                        ||lc_credit_limit_flag
                       ;
              UTL_FILE.put_line (lc_filehandle, lc_string);
				
        END IF;
                     
                       
       log_msg('Calling update_status to update the status to I in the staging table');
       update_status( p_record_id     => cur_extract_rec.record_id,
                      p_status        => 'I',
                      p_error_message => lc_error_msg
                    ); 
                                                                 
       ln_success_records := ln_success_records + 1;                           
       log_msg('Commit the changes ..');      
       COMMIT;
                               
    EXCEPTION
       WHEN e_cursor_exception 
       THEN 
         IF lc_error_msg is NULL 
         THEN 
             lc_error_msg :='Customer Not Exists for AOPS Customer Number '||cur_extract_rec.aops_customer_number;
         END IF;
                       
         log_msg('Updating the error message -'|| lc_error_msg);              
         update_status( p_record_id     => cur_extract_rec.record_id,
                        p_status        => 'N',
                        p_error_message => lc_error_msg
                      );
         --log_msg(lc_error_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.EXTRACT',
                        p_error_msg        => lc_error_msg);
                                      
         ln_failed_records := ln_failed_records + 1;
         log_msg('Commit the changes ..');      
         COMMIT;
                                
      WHEN OTHERS
      THEN                               
         log_msg('Calling update_status to update the status to E in the staging table');              
         update_status( p_record_id     => cur_extract_rec.record_id,
                        p_status        => 'E',
                        p_error_message => lc_error_msg
                      );                                             
        IF lc_error_msg is NULL 
        THEN 
           lc_error_msg :='Error while processing record '|| cur_extract_rec.record_id ||SQLERRM;
        END IF;
                       
        fnd_file.put_line(fnd_file.log,lc_error_msg);
        log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.EXTRACT',
                       p_error_msg        => lc_error_msg);
                                      
        ln_failed_records := ln_failed_records + 1;
        log_msg('Commit the error log changes ..');
        COMMIT;
      END;

     ln_rec_count := ln_rec_count + 1;
                        
    END LOOP;
               
  fnd_file.put_line (fnd_file.log,'Total number of successful records ..' || ln_success_records);
  fnd_file.put_line (fnd_file.log,'Total number of failed records ...' || ln_failed_records);
  fnd_file.put_line (fnd_file.log,'Total Record Count ...........' || ln_rec_count);
              
              -- If record count = Failed records count then write just new batch id in the file

     IF (ln_rec_count = ln_failed_records)
     THEN     
         ln_new_batch := XXOD_OMX_MOD4_batch_ID_S.NEXTVAL;
         log_msg('Creating file with Dummy batch id :'|| ln_new_batch); 
         lc_string := LPAD (ln_new_batch, 6, 0);

         UTL_FILE.put_line (lc_filehandle, lc_string);                            
      END IF;
               
     END IF;

       UTL_FILE.fclose (lc_filehandle);

    ELSE 
                 
     RAISE e_process_exception;          
   END IF;
         
     
      
      ------------------------------------------------------------------
      -- Calling  ftp_file to copy the file to the OMX FTP Directory  --
      ------------------------------------------------------------------
      fnd_file.put_line (fnd_file.log,'Calling ftp_file to copy the file to the OMX FTP Directory');      
      ftp_file (p_file_name          =>  lc_file_name,
                p_config_details_rec =>  lr_config_details_rec,
                p_return_status      =>  lc_return_status,
                p_return_msg         =>  lc_error_msg
               );
--Checking move file return status
      IF lc_return_status = gc_success
      THEN
       -- Calling log_file procedure
         fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
         log_file (p_success_records   => ln_success_records,
                   p_failed_records    => ln_failed_records,
                   p_batch_id          => NVL (ln_batch, ln_new_batch),
                   p_file_name         => lc_file_name,
                   p_status            => 'C');
         ELSE
       -- Calling log_file procedure
         fnd_file.put_line (fnd_file.log,'Calling log file for tracking purpose');
         log_file (p_success_records   => ln_success_records,
                   p_failed_records    => ln_failed_records,
                   p_batch_id          => NVL (ln_batch, ln_new_batch),
                   p_file_name         => lc_file_name,
                   p_status            => 'E'); 
            
        RAISE e_process_exception;   
         END IF; 
                  
      fnd_file.put_line(fnd_file.log,'Successfully Inserted records into log table');         
   COMMIT;
      
   EXCEPTION   
      WHEN UTL_FILE.INVALID_MODE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
        x_retcode := 2;      
      WHEN UTL_FILE.INVALID_PATH
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
        x_retcode := 2;         
      WHEN UTL_FILE.INVALID_FILEHANDLE
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
        x_retcode := 2;
      WHEN UTL_FILE.INVALID_OPERATION
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
        x_retcode := 2;            
      WHEN UTL_FILE.WRITE_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20056, 'Write Error');
        x_retcode := 2;
      WHEN UTL_FILE.INTERNAL_ERROR
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
        x_retcode := 2;
      WHEN UTL_FILE.FILE_OPEN
      THEN
        UTL_FILE.FCLOSE_ALL;
        RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
        x_retcode := 2;   
      WHEN OTHERS
      THEN      
        IF lc_error_msg IS NULL
        THEN         
          lc_error_msg := 'Unable to process ' || SQLERRM;         
        END IF;
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       log_exception (p_error_location   => 'XX_CDH_OMX_GEN_CUST_FILE_PKG.EXTRACT',
                      p_error_msg        => lc_error_msg);
       x_retcode := 2;
       ROLLBACK;         
   END extract;
   
END XX_CDH_OMX_GEN_CUST_FILE_PKG;
/
SHOW ERRORS;

