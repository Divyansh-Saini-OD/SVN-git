CREATE OR REPLACE PACKAGE BODY APPS.XX_CDH_OMX_PURGE_PKG
AS
-- +================================================================================================+
-- |                        Office Depot                                                            |
-- +================================================================================================+
-- | Name  : XX_CDH_OMX_PURGE_PKG                                                                   |
-- | Rice ID: C0700                                                                                 |
-- | Description      : This package is used to purge all the successful records over p_purge_days  |
-- |                    (default--> 30 days) from the staging tables                                |
-- |                                                                                                |
-- |Change Record:                                                                                  |
-- |===============                                                                                 |
-- |Version Date        Author            Remarks                                                   |
-- |======= =========== =============== ============================================================|
-- |1.0     04-MAR-2015 Havish Kasina   Initial draft version                                       |
-- |2.0     12-MAR-2015 Havish Kasina   Code Review Changes                                         |
-- +================================================================================================+


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

         fnd_file.put_line (fnd_file.LOG, p_string);

   END log_msg;

      
   PROCEDURE log_exception (p_error_location   IN VARCHAR2,
                            p_error_msg        IN VARCHAR2)
   AS     
   
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
      
   ln_login_id  NUMBER := fnd_global.login_id;
   ln_user_id   NUMBER := fnd_global.user_id;
   BEGIN
   
      XX_COM_ERROR_LOG_PUB.log_error (
         p_return_code              => FND_API.G_RET_STS_ERROR,
         p_msg_count                => 1,
         p_application_name         => 'XXCRM',
         p_program_type             => 'Custom Messages',
         p_program_name             => 'XX_CDH_OMX_PURGE',
         p_attribute15              => 'XX_CDH_OMX_PURGE',
         p_program_id               => NULL,
         p_module_name              => 'MOD4A',
         p_error_location           => p_error_location,
         p_error_message_code       => NULL,
         p_error_message            => p_error_msg,
         p_error_message_severity   => 'MAJOR',
         p_error_status             => 'ACTIVE',
         p_created_by               => ln_user_id,
         p_last_updated_by          => ln_user_id,
         p_last_update_login        => ln_login_id);
         
   EXCEPTION
   
      WHEN OTHERS
      THEN
      log_msg('Error while writing to the log ...' || SQLERRM);
      
   END log_exception;

   
   PROCEDURE data_purge(x_retcode              OUT       NUMBER,
                        x_errbuf               OUT       VARCHAR2,
                        p_purge_days           IN        NUMBER)
   IS
   -- +=====================================================================================+
   -- | Name  : data_purge                                                                  |
   -- | Description     : This procedure is to purge the successful data for 30 days        |
   -- |                   in the staging tables                                             |
   -- |                                                                                     |
   -- | Parameters      : x_retcode         OUT                                             |
   -- |                   x_errbuf          OUT                                             |
   -- |                   p_purge_days      IN -> Number of days ( Default--> 30 days)      |
   -- +=====================================================================================+

   lc_error_msg          VARCHAR2(2000);
   e_process_exception   EXCEPTION;

   BEGIN

     -- Delete the records from the xx_cdh_mod4_sfdc_cust_stg table

     DELETE FROM xx_cdh_mod4_sfdc_cust_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);
            
     fnd_file.put_line(fnd_file.log,'Number of records deleted from SFDC staging table :'||SQL%ROWCOUNT);


     -- Delete the records from the xx_cdh_omx_bill_docs_stg table

     DELETE FROM xx_cdh_omx_bill_docs_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);
            
     fnd_file.put_line(fnd_file.log,'Number of records deleted from Ebill documents staging table :'||SQL%ROWCOUNT);


     -- Delete the records from the xx_cdh_omx_ebill_contacts_stg table

     DELETE FROM xx_cdh_omx_ebill_contacts_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);

     fnd_file.put_line(fnd_file.log,'Number of records deleted from Ebill contacts staging table :'||SQL%ROWCOUNT);
         
     -- Delete the records from the xx_cdh_omx_addr_exceptions_stg table

     DELETE FROM xx_cdh_omx_addr_exceptions_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);

     fnd_file.put_line(fnd_file.log,'Number of records deleted from Address exceptions staging table :'||SQL%ROWCOUNT);
     
     -- Delete the records from the xx_cdh_omx_ap_contacts_stg table

     DELETE FROM xx_cdh_omx_ap_contacts_stg
     WHERE status = 'C'
       AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);

     fnd_file.put_line(fnd_file.log,'Number of records deleted from AP contacts staging table :'||SQL%ROWCOUNT);
     
     -- Delete the records from the xx_cdh_omx_dunning_stg table

     DELETE FROM xx_cdh_omx_dunning_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);
        
     fnd_file.put_line(fnd_file.log,'Number of records deleted from Dunning staging table :'||SQL%ROWCOUNT);

     -- Delete the records from the xx_cdh_omx_cust_info_stg table

         DELETE FROM xx_cdh_omx_cust_info_stg
          WHERE status = 'C'
            AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);
     
     fnd_file.put_line(fnd_file.log,'Number of records deleted from Credit limit staging table :'||SQL%ROWCOUNT);

     -- Delete the records from the xx_cdh_omx_file_log_stg table

     DELETE FROM xx_cdh_omx_file_log_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);

     fnd_file.put_line(fnd_file.log,'Number of records deleted from Log table :'||SQL%ROWCOUNT);

     -- Delete the records from the xx_cdh_omx_reconcile_count_stg table

     DELETE FROM xx_cdh_omx_reconcile_count_stg
      WHERE status = 'C'
        AND TRUNC(creation_date) < TRUNC(SYSDATE-p_purge_days);

     fnd_file.put_line(fnd_file.log,'Number of records deleted from Reconcile count staging table :'||SQL%ROWCOUNT);
     
   COMMIT;

   EXCEPTION
      WHEN OTHERS
      THEN
         lc_error_msg:= 'Unable to purge the records from the staging tables......'||SQLERRM;
         fnd_file.put_line(fnd_file.log,lc_error_msg);
         log_exception (p_error_location   => 'XX_CDH_OMX_PURGE_PKG.DATA_PURGE',
                        p_error_msg        => lc_error_msg);
         x_retcode := 2;
         ROLLBACK;
         
   END data_purge;

END XX_CDH_OMX_PURGE_PKG;
/
SHOW ERRORS;