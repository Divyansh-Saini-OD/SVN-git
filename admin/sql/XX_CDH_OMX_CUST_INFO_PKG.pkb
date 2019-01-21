create or replace PACKAGE BODY      xx_cdh_omx_cust_info_pkg
AS
-- +==============================================================================+
-- |                        Office Depot                                          |
-- +==============================================================================+
-- | Name  : xx_cdh_omx_cust_info_pkg                                             |
-- | Rice ID: C0702                                                               |
-- | Description      : This Program will extract all the Credit                  |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date          Author            Remarks                              |
-- |======= ===========  =============== =========================================|
-- | 1.0    02-MAR-2015   Abhi K          Initial draft version                   |
-- | 1.1    15-MAR-2015   Abhi K          Code review                             |
-- | 1.2    09-APR-2015   Abhi k          Add the logic to handle Statement Cycle |
-- | 1.3    19-JUN-2015   Manikant Kasu   Added Set_extended_attribute proc       |
-- | 1.4    16-JUL-2015   Havish Kasina   MOD5 Changes                            |
-- | 1.5    28-SEP-2015   Havish Kasina   changes done as per Defect 35970        |
-- +==============================================================================+
   -- Global Variable Declaration
   g_debug_flag           BOOLEAN;
   gc_success             VARCHAR2 (100)  := 'SUCCESS';
   gc_failure             VARCHAR2 (100)  := 'FAILURE';
   gd_last_update_date    DATE            := SYSDATE;
   gn_last_updated_by     NUMBER          := fnd_global.user_id;
   gd_creation_date       DATE            := SYSDATE;
   gn_created_by          NUMBER          := fnd_global.user_id;
   gn_last_update_login   NUMBER          := fnd_global.login_id;
   gn_request_id          NUMBER          := fnd_global.conc_request_id;
   gd_cycle_date          DATE            := SYSDATE;
   gc_error_loc           VARCHAR2 (2000) := NULL;

   PROCEDURE log_exception (
      p_error_location   IN   VARCHAR2,
      p_error_msg        IN   VARCHAR2
   )
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
      xx_com_error_log_pub.log_error
                           (p_return_code                 => fnd_api.g_ret_sts_error,
                            p_msg_count                   => 1,
                            p_application_name            => 'XXCRM',
                            p_program_type                => 'Custom Messages',
                            p_program_name                => 'XX_CDH_OMX_CUST_INFO_EXTRACT',
                            p_attribute15                 => 'XX_CDH_OMX_CUST_INFO_EXTRACT',
                            p_program_id                  => NULL,
                            p_module_name                 => 'MOD4A',
                            p_error_location              => p_error_location,
                            p_error_message_code          => NULL,
                            p_error_message               => p_error_msg,
                            p_error_message_severity      => 'MAJOR',
                            p_error_status                => 'ACTIVE',
                            p_created_by                  => ln_user_id,
                            p_last_updated_by             => ln_user_id,
                            p_last_update_login           => ln_login
                           );
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'Error while writting to the log ...' || SQLERRM
                           );
   END log_exception;

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

   PROCEDURE log_file (
      p_success_records   IN   NUMBER,
      p_faliure_records   IN   NUMBER,
      p_batch_id          IN   NUMBER,
      p_file_name         IN   VARCHAR2,
      p_status            IN   VARCHAR2
   )
   IS
/*===================================================================================+
| Name       : log_file                                                              |
| Description: This procedure is used to log  program name and total_records         |
|                                                                                    |
| Parameters : p_success_records     IN ->  success records                          |
|              p_batch_id            IN -> batch number                              |
+===================================================================================*/

--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg      VARCHAR2 (4000);
      lc_program_name   VARCHAR2 (200);
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
            lc_error_msg :=
                  'Concurrent Program Name not found for Request ID: '
               || gn_request_id;
            log_msg (lc_error_msg);
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.LOG_FILE',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            lc_error_msg :=
                  'Unable to fetch Concurrent Program name for Request ID :'
               || gn_request_id
               || ' '
               || SQLERRM;
            log_msg (lc_error_msg);
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.LOG_FILE',
                      p_error_msg           => lc_error_msg
                     );
      END;

      BEGIN
         INSERT INTO xx_cdh_omx_file_log_stg
                     (program_id, program_name, program_run_date, file_name,
                      success_records, failure_records, status,
                      request_id, cycle_date, batch_num, error_message,
                      creation_date, created_by, last_updated_by,
                      last_update_date, last_update_login
                     )
              VALUES (gn_request_id, lc_program_name, SYSDATE, p_file_name,
                      p_success_records, p_faliure_records, p_status,
                      gn_request_id, gd_cycle_date, p_batch_id, NULL,
                      gd_creation_date, gn_created_by, gn_last_updated_by,
                      gd_last_update_date, gn_last_update_login
                     );

         log_msg
            (   'Inserting records into xx_cdh_omx_file_log table for batch id: '
             || p_batch_id
            );
      EXCEPTION
         WHEN OTHERS
         THEN
            IF lc_error_msg IS NULL
            THEN
               lc_error_msg :=
                       'Unable to insert the records in log table' || SQLERRM;
            END IF;

            log_msg (lc_error_msg);
            log_exception
                    (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.LOG_TABLE',
                     p_error_msg           => lc_error_msg
                    );
      END;
   END log_file;

   PROCEDURE get_customer_profile_details (
      p_aops_account_number   IN       VARCHAR2,
      p_profile_rec           OUT      hz_customer_profiles%ROWTYPE,
      p_error_msg             OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : get_customer_profile_details (                            |
-- | Description     : get_customer_profile_details                    |
-- |                                                                   |
-- | Parameters      : p_aops_account_number                           |
-- +===================================================================+
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (4000);
   BEGIN
      lc_error_msg := NULL;
      log_msg ('Getting the customer profile details ..');

      SELECT hcp.*
        INTO p_profile_rec
        FROM hz_customer_profiles hcp, hz_cust_accounts hca
       WHERE hcp.cust_account_id = hca.cust_account_id
         AND site_use_id IS NULL
         AND hcp.status = 'A'
         AND hca.orig_system_reference =
                   LPAD (TO_CHAR (p_aops_account_number), 8, 0)
                || '-'
                || '00001-A0';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :=
                     'customer_profile_details Not Found : ';
         log_msg (lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_CUSTOMER_PROFILE_DETAILS',
             p_error_msg           => lc_error_msg
            );
      WHEN OTHERS
      THEN
      IF lc_error_msg is null then
         lc_error_msg :=
              'Unable to fetch customer_profile_details  :' || ' ' || SQLERRM;
      END IF;         
         log_msg (lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_CUSTOMER_PROFILE_DETAILS',
             p_error_msg           => lc_error_msg
            );
   END get_customer_profile_details;


   PROCEDURE get_cust_profile_amt_details (
      p_aops_account_number   IN       VARCHAR2,
      p_currency              IN       VARCHAR2,
      p_profile_amt_rec       OUT      hz_cust_profile_amts%ROWTYPE,
      p_error_msg             OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : get_customer_profile_amt_details (                        |
-- | Description     : get_customer_profile_details                    |
-- |                                                                   |
-- | Parameters      : p_aops_account_number                           |
-- +===================================================================+
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (4000);
   BEGIN
      lc_error_msg := NULL;
      log_msg ('Getting the customer Amt profile details for Currency :' || p_currency);

      SELECT hcpa.*
        INTO p_profile_amt_rec
        FROM hz_customer_profiles hcp, 
             hz_cust_accounts hca,
             hz_cust_profile_amts hcpa
       WHERE hcp.cust_account_id = hca.cust_account_id
         AND hcp.site_use_id IS NULL
         AND hcpa.cust_account_profile_id = hcp.cust_account_profile_id
         AND hcpa.currency_code           = p_currency
         AND hcp.status = 'A'
         AND hca.orig_system_reference =
                   LPAD (TO_CHAR (p_aops_account_number), 8, 0)
                || '-'
                || '00001-A0';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :=
                     'customer profile amt details Not Found : ';
         log_msg (lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_CUSTOMER_PROFILE_amt_DETAILS',
             p_error_msg           => lc_error_msg
            );
      WHEN OTHERS
      THEN
      IF lc_error_msg is null then
         lc_error_msg :=
              'Unable to fetch customer_profile_details  :' || ' ' || SQLERRM;
      END IF;         
         log_msg (lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_CUSTOMER_PROFILE_DETAILS',
             p_error_msg           => lc_error_msg
            );
   END get_cust_profile_amt_details;


   PROCEDURE update_credit (
      p_profile_amt_rec   IN       hz_customer_profile_v2pub.cust_profile_amt_rec_type,
      p_object_version_number IN OUT NUMBER,
      p_return_status     OUT      VARCHAR2,
      p_error_msg         OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : update_credit                                             |
-- | Description      This process creates the Profile amounts at      |
-- | customer account level                                            |
-- |                                                                   |
-- +===================================================================+

      --------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_init_msg_list           VARCHAR2 (1000) := FND_API.G_TRUE;
      lc_return_status           VARCHAR2 (1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2 (4000);
      lc_msg_text                VARCHAR2 (32000);
      l_errors_tbl               error_handler.error_tbl_type;
      e_process_exception        EXCEPTION;
   BEGIN
      lc_msg_text := NULL;
      lc_return_status := NULL;
      log_msg ('calling the update_cust_profile_amt using the API');
--      lc_init_msg_list := fnd_api.g_false;
      
      hz_customer_profile_v2pub.update_cust_profile_amt
                        (p_init_msg_list              => lc_init_msg_list,
                         p_cust_profile_amt_rec       => p_profile_amt_rec,
                         p_object_version_number      => p_object_version_number ,
                         x_return_status              => lc_return_status,
                         x_msg_count                  => ln_msg_count,
                         x_msg_data                   => lc_msg_data
                        );
                        
                        log_msg('ln_msg_count'|| ln_msg_count);
                        log_msg('lc_msg_data'||lc_msg_data);

      IF lc_return_status != fnd_api.g_ret_sts_success
      THEN
         IF ln_msg_count > 0
         THEN
           FOR i IN 1 .. FND_MSG_PUB.count_msg
           LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => 'F',
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            lc_msg_text := lc_msg_text||' '||lc_msg_data;
           END LOOP;
         ELSE
           lc_msg_text := lc_msg_data;  
         END IF;
         
         log_msg('HZ_CUSTOMER_PROFILE_V2PUB.UPDATE_CUST_PROFILE_AMT API returned Error.' );
         log_msg('Error:'||lc_msg_text);
         RAISE e_process_exception;
      END IF;

      log_msg
           ('HZ_CUSTOMER_PROFILE_V2PUB.UPDATE_CUST_PROFILE_AMT API successful');
      p_return_status := gc_success;
      p_error_msg := lc_msg_text;
      log_msg(' Commiting the Credit Changes ..');
      COMMIT;
   EXCEPTION      
      WHEN OTHERS
      THEN
        log_msg(' ROLLBACK the Credit Changes ..');
        ROLLBACK;
        IF lc_msg_text IS NULL
        THEN
          lc_msg_text := 'Unable to update_credit with API :' || ' ' || SQLERRM;
        END IF;   
         log_msg (lc_msg_text);
         log_exception
               (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.UPDATE_CREDIT',
                p_error_msg           => lc_msg_text
               );
         p_return_status := gc_failure;
         p_error_msg := lc_msg_text;
   END update_credit;

   PROCEDURE update_customer_profile (
      p_profile_rec            IN      hz_customer_profile_v2pub.customer_profile_rec_type,
      p_object_version_number  IN OUT  NUMBER,
      p_return_status          OUT     VARCHAR2,
      p_error_msg              OUT     VARCHAR2
   )
   IS
        -- +===================================================================+
        -- | Name  : update_customer_profile                                            |
        -- | Description     : The Purpose of the procedure is to update the   |
        --|  profile either at account level or Site level                     |
      -- |                                                                   |
     -- +===================================================================+

      --------------------------------
      -- Local Variable Declaration --
      --------------------------------
      lc_error_msg               VARCHAR2 (4000);
      lc_init_msg_list           VARCHAR2 (1000);
      lc_return_status           VARCHAR2 (1);
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2 (4000);
      lc_msg_text                VARCHAR2 (32000);
      l_errors_tbl               error_handler.error_tbl_type;
      e_process_exception        EXCEPTION;
   BEGIN
      lc_error_msg := NULL;
      lc_init_msg_list := NULL;
      log_msg ('calling the update_customer_profile using the API');
      lc_init_msg_list := fnd_api.g_false;
      hz_customer_profile_v2pub.update_customer_profile
                        (p_init_msg_list              => lc_init_msg_list,
                         p_customer_profile_rec       => p_profile_rec,
                         p_object_version_number      => p_object_version_number,
                         x_return_status              => lc_return_status,
                         x_msg_count                  => ln_msg_count,
                         x_msg_data                   => lc_msg_data
                        );
      log_msg (   'update_customer_profile : lc_return_status '
               || lc_return_status
              );

      IF lc_return_status != fnd_api.g_ret_sts_success
      THEN
         IF ln_msg_count > 0
         THEN
           FOR i IN 1 .. FND_MSG_PUB.count_msg
           LOOP
            fnd_msg_pub.get (p_msg_index       => i,
                             p_encoded         => 'F',
                             p_data            => lc_msg_data,
                             p_msg_index_out   => ln_msg_count);
            lc_msg_text := lc_msg_text||' '||lc_msg_data;
           END LOOP;
         ELSE
           lc_msg_text := lc_msg_data;  
         END IF;
         
         log_msg('HZ_CUSTOMER_PROFILE_V2PUB.UPDATE_CUST_PROFILE API returned Error.' );
         log_msg('Error:'||lc_msg_text);
         RAISE e_process_exception;
      END IF;


      log_msg
           ('HZ_CUSTOMER_PROFILE_V2PUB.UPDATE_CUSTOMER_PROFILE API successful');
      p_return_status := gc_success;
      
      log_msg(' Commiting the Customer profile Changes ..');
      COMMIT;

   EXCEPTION
      WHEN OTHERS
      THEN
        log_msg(' Rollback the Customer profile Changes ..');
        ROLLBACK;

            IF lc_msg_text IS NULL
            THEN
             lc_msg_text := 'unable to update_customer_profile :' || ' ' || SQLERRM;
             END IF;    
         
         log_msg (lc_msg_text);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.UPDATE_CUSTOMER_PROFILE',
             p_error_msg           => lc_msg_text
            );
         p_return_status := gc_failure;
         p_error_msg := lc_msg_text;
   END update_customer_profile;

-- +===================================================================+
-- | Name  : derive_billing_type                                       |
-- | Description     : This function returns the billing  type          |
-- |                                                                    |
-- |                                                                    |
-- | Parameters      :                                                  |
-- +===================================================================+
   FUNCTION derive_billing_type (
      p_cursor_rec     IN       xx_cdh_omx_cust_info_stg%ROWTYPE,
      p_billing_type   OUT      VARCHAR2,
      p_error_msg      OUT      VARCHAR2
   )
      RETURN VARCHAR2
   IS
 --------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (1000);
      lc_success     VARCHAR2 (10);
   BEGIN
      lc_success := NULL;
      log_msg ('deriving the billing type ..');
      lc_error_msg := NULL;
      p_error_msg := NULL;

      SELECT billing_type
        INTO p_billing_type
        FROM xx_cdh_mod4_sfdc_cust_stg
       WHERE aops_customer_number = p_cursor_rec.aops_customer_number;

      log_msg ('Billing Type : ' || p_billing_type);
  
      RETURN lc_success;
      log_msg ('lc_success : ' || lc_success);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :=
               'No Billing type found for customer :'
            || p_cursor_rec.aops_customer_number;
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.DERIVE_BILLING_TYPE',
             p_error_msg           => lc_error_msg
            );
         RETURN gc_failure;
         p_error_msg := lc_error_msg;
      WHEN OTHERS
      THEN
         lc_error_msg :=
                   'Unable to fetch Billing type details :' || ' ' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, p_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.DERIVE_BILLING_TYPE',
             p_error_msg           => lc_error_msg
            );
         RETURN gc_failure;
         p_error_msg := lc_error_msg;
   END derive_billing_type;

   FUNCTION check_customer_is_converted (
      p_acct_number   IN       xx_cdh_omx_cust_info_stg.customer_number%TYPE,
      p_converted      OUT      VARCHAR2,
      p_error_msg     OUT      VARCHAR2
   )
      RETURN VARCHAR2
   IS
-- +===================================================================+
-- | Name  : check_customer_is_converted                               |
-- | Description     : check_customer_is_converted                     |
-- |                                                                   |
-- | Parameters      :                                                 |
-- +===================================================================+

--------------------------------
-- Local Variable Declaration --
--------------------------------
      ln_cnt         NUMBER;
   BEGIN
      p_error_msg := NULL;
      log_msg ('check if the customer is converted');

      SELECT COUNT (1)
        INTO ln_cnt
        FROM hz_cust_acct_sites_all hcas,
             hz_cust_accounts hca,
             hz_cust_site_uses_all hcsu
       WHERE hcas.cust_account_id = hca.cust_account_id
         AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
         AND hcsu.site_use_code = 'SHIP_TO'
         AND hcsu.bill_to_site_use_id IS NULL
         AND hca.account_number = p_acct_number;

      IF ln_cnt > 0
      THEN
         p_converted := 'N';  -- Means not converted 
         p_error_msg  := 'Customer is not converted as Indirect';
      ELSE
         p_converted := 'Y';
      END IF;

      RETURN p_converted;
   EXCEPTION
      WHEN OTHERS
      THEN
         p_error_msg :=
               'Unable to fetch the count for check customer is converted :'
            || ln_cnt
            || ' '
            || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, p_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.CHECK_CUSTOMER_IS_CONVERTED',
             p_error_msg           => p_error_msg
            );
         p_converted := 'N';
         RETURN p_converted;
   END check_customer_is_converted;

   PROCEDURE dnb_rating (
      p_cursor_rec        IN       xx_cdh_omx_cust_info_stg%ROWTYPE,
      p_cust_account_id   IN       VARCHAR2,
      p_return_status     OUT      VARCHAR2,
      p_error_msg         OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : Update_profile                                            |
-- | Description     : The Purpose of the procedure is to update the   |
-- |  profile either at account level or Site level                    |
-- |                                                                   |
-- +===================================================================+

--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg               VARCHAR2 (4000);
      lc_init_msg_list           VARCHAR2 (256);
      lc_user_table              ego_user_attr_row_table:= ego_user_attr_row_table ();
      lc_data_table              ego_user_attr_data_table:= ego_user_attr_data_table ();
      lr_od_ext_attr_rec         xx_cdh_omx_bill_documents_pkg.xx_od_ext_attr_rec;
      lc_profile_id              VARCHAR2 (256);
      ln_object_version_number   NUMBER;
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2 (4000);
      lc_failed_row_id_list      VARCHAR2 (1000);
      lc_return_status           VARCHAR2 (1000);
      lc_errorcode               NUMBER;
      ln_cust_doc_id             NUMBER;
      lc_msg_text                VARCHAR2 (32000);
      l_errors_tbl               error_handler.error_tbl_type;
      e_process_exception        EXCEPTION;
      
   BEGIN
   
      FND_MSG_PUB.INITIALIZE;
      SELECT xx_cdh_cust_doc_id_s.NEXTVAL
        INTO ln_cust_doc_id
        FROM DUAL;

      lr_od_ext_attr_rec.attribute_group_code := 'OMX_DNB_RATING';
      lr_od_ext_attr_rec.record_id := p_cursor_rec.record_id;
      lr_od_ext_attr_rec.interface_entity_name := 'ACCOUNT';
      lr_od_ext_attr_rec.cust_acct_id := p_cust_account_id;
      lr_od_ext_attr_rec.c_ext_attr1 := p_cursor_rec.db_rating;
      lr_od_ext_attr_rec.n_ext_attr2 := ln_cust_doc_id;
      -- Call build extension table
      xx_cdh_omx_bill_documents_pkg.build_extension_table
                                     (p_user_row_table       => lc_user_table,
                                      p_user_data_table      => lc_data_table,
                                      p_ext_attribs_row      => lr_od_ext_attr_rec,
                                      p_return_status        => p_return_status,
                                      p_error_msg            => lc_error_msg
                                     );

      IF lc_user_table.COUNT > 0
      THEN
         log_msg ('User Table count..' || lc_user_table.COUNT);
      END IF;

      IF lc_data_table.COUNT > 0
      THEN
         log_msg ('Data Table count..' || lc_data_table.COUNT);
      END IF;
      
      log_msg('lc_error_msg ' ||''||lc_error_msg );

      log_msg ('calling process_account_record API..');
      -- Call below API to create the doc ..Which internally calls the
      xx_cdh_hz_extensibility_pub.process_account_record
                  (p_api_version                => xx_cdh_cust_exten_attri_pkg.g_api_version,
                   p_cust_account_id            => p_cust_account_id,
                   p_attributes_row_table       => lc_user_table,
                   p_attributes_data_table      => lc_data_table,
                   p_log_errors                 => fnd_api.g_false,
                   x_failed_row_id_list         => lc_failed_row_id_list,
                   x_return_status              => lc_return_status,
                   x_errorcode                  => lc_errorcode,
                   x_msg_count                  => ln_msg_count,
                   x_msg_data                   => lc_msg_data
                  );
                  
      log_msg ('process_account_record :'||''||lc_return_status );  
    
    IF lc_return_status != FND_API.G_RET_STS_SUCCESS
    THEN
     IF ln_msg_count > 0
     THEN
        ERROR_HANDLER.Get_Message_List(l_errors_tbl);
        FOR i IN 1..l_errors_tbl.COUNT
        LOOP
          lc_msg_text := lc_msg_text||' '||l_errors_tbl(i).message_text;
        END LOOP;
     ELSE
        lc_msg_text := lc_msg_data;
      END IF;

      p_error_msg := lc_msg_text;

      log_msg('XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API returned Error.');
      RAISE e_process_exception;
    END IF;
       

      log_msg
           ('HZ_CUSTOMER_PROFILE_V2PUB.PROCESS_ACCOUNT_RECORD API successful');
      p_return_status := gc_success;
      
      log_msg('Commiting the DNB Rating changes ..');
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
        log_msg(' Commiting the DB rating Changes ..');
        ROLLBACK;
         
        IF lc_msg_text is null then
         lc_msg_text := 'Unable to get dnb rating :' || ' ' || SQLERRM;
        END IF;  
         log_msg (lc_msg_text);
         log_exception
                  (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.dnb_rating',
                   p_error_msg           => lc_msg_text
                  );
         p_return_status := gc_failure;
         p_error_msg := lc_msg_text;
   END dnb_rating;


-- +===================================================================+
-- | Name            : set_extended_attribute                          |
-- | Description     : The Purpose of the procedure is to update the   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE set_extended_attribute (
      p_cursor_rec        IN       xx_cdh_omx_cust_info_stg%ROWTYPE,
      p_cust_account_id   IN       VARCHAR2,
      P_group_code        IN       VARCHAR2,
      p_return_status     OUT      VARCHAR2,
      p_error_msg         OUT      VARCHAR2
      )
   IS

--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg               VARCHAR2 (4000) := NULL;
      lc_init_msg_list           VARCHAR2 (256);
      lc_user_table              ego_user_attr_row_table:= ego_user_attr_row_table ();
      lc_data_table              ego_user_attr_data_table:= ego_user_attr_data_table ();
      lr_od_ext_attr_rec         xx_cdh_omx_bill_documents_pkg.xx_od_ext_attr_rec;
      lc_profile_id              VARCHAR2 (256);
      ln_object_version_number   NUMBER;
      ln_msg_count               NUMBER;
      lc_msg_data                VARCHAR2 (4000);
      lc_failed_row_id_list      VARCHAR2 (1000);
      lc_return_status           VARCHAR2 (1000);
      lc_errorcode               NUMBER;
      ln_cust_doc_id             NUMBER;
      lc_msg_text                VARCHAR2 (32000);
      l_errors_tbl               error_handler.error_tbl_type;
      e_process_exception        EXCEPTION;
      
   BEGIN
      
      FND_MSG_PUB.INITIALIZE;
      SELECT xx_cdh_cust_doc_id_s.NEXTVAL
        INTO ln_cust_doc_id
        FROM DUAL;

      lr_od_ext_attr_rec.attribute_group_code := p_group_code;
      lr_od_ext_attr_rec.record_id := p_cursor_rec.record_id;
      lr_od_ext_attr_rec.interface_entity_name := 'ACCOUNT';
      lr_od_ext_attr_rec.cust_acct_id := p_cust_account_id;
      lr_od_ext_attr_rec.c_ext_attr1 := 'Y';
      lr_od_ext_attr_rec.n_ext_attr2 := ln_cust_doc_id;
      -- Call build extension table
      xx_cdh_omx_bill_documents_pkg.build_extension_table
                                     ( p_user_row_table       => lc_user_table,
                                       p_user_data_table      => lc_data_table,
                                       p_ext_attribs_row      => lr_od_ext_attr_rec,
                                       p_return_status        => p_return_status,
                                       p_error_msg            => lc_error_msg
                                     );

      IF lc_user_table.COUNT > 0
      THEN
         log_msg ('User Table count..' || lc_user_table.COUNT);
      END IF;

      IF lc_data_table.COUNT > 0
      THEN
         log_msg ('Data Table count..' || lc_data_table.COUNT);
      END IF;
      
      log_msg('lc_error_msg ' ||''||lc_error_msg );

      log_msg ('calling process_account_record API..');
      -- Call below API to create the doc ..Which internally calls the
      xx_cdh_hz_extensibility_pub.process_account_record
                  (p_api_version                => xx_cdh_cust_exten_attri_pkg.g_api_version,
                   p_cust_account_id            => p_cust_account_id,
                   p_attributes_row_table       => lc_user_table,
                   p_attributes_data_table      => lc_data_table,
                   p_log_errors                 => fnd_api.g_false,
                   x_failed_row_id_list         => lc_failed_row_id_list,
                   x_return_status              => lc_return_status,
                   x_errorcode                  => lc_errorcode,
                   x_msg_count                  => ln_msg_count,
                   x_msg_data                   => lc_msg_data
                  );
                  
      log_msg ('process_account_record :'||''||lc_return_status );  
    
    IF lc_return_status != FND_API.G_RET_STS_SUCCESS
    THEN
     IF ln_msg_count > 0
     THEN
        ERROR_HANDLER.Get_Message_List(l_errors_tbl);
        FOR i IN 1..l_errors_tbl.COUNT
        LOOP
          lc_msg_text := lc_msg_text||' '||l_errors_tbl(i).message_text;
        END LOOP;
     ELSE
        lc_msg_text := lc_msg_data;
      END IF;

      p_error_msg := lc_msg_text;

      log_msg('XX_HZ_EXTENSIBILITY_PUB.Process_Account_Record API returned Error.');
      RAISE e_process_exception;
    END IF;
       
      log_msg('HZ_CUSTOMER_PROFILE_V2PUB.PROCESS_ACCOUNT_RECORD API successful');
      p_return_status := gc_success;
      
      log_msg('Commiting the Extended Attribute changes ..');
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
        log_msg(' Commiting the Extended Attribute Changes ..');
        ROLLBACK;
         
        IF lc_msg_text is null then
         lc_msg_text := 'Unable to get Extended Attribute :' || ' ' || SQLERRM;
        END IF;  
         log_msg (lc_msg_text);
         log_exception
                  (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.set_extended_attribute',
                   p_error_msg           => lc_msg_text
                  );
         p_return_status := gc_failure;
         p_error_msg := lc_msg_text;
   END set_extended_attribute;

-- +====================================================================+
-- | Name       : GET_INTERFACE_SETTINGS                                |
-- |                                                                    |
-- | Description: This procedure will retrieve all of the source values |
-- |              from the XXOD_WEBCOLLECT_INTERFACE translation        |
-- |              definition, and print them to the log file            |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+
   PROCEDURE get_interface_settings (
      p_process_type       IN       VARCHAR2,
      p_translation_info   OUT      xx_fin_translatevalues%ROWTYPE,
      p_error_msg          OUT      VARCHAR2
   )
   IS
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (4000);
   BEGIN
      lc_error_msg := NULL;

--========================================================================
-- Retreiving Translation Definition Values
--========================================================================
      SELECT xftv.*
        INTO p_translation_info
        FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name = 'XXOD_OMX_MOD4_INTERFACE'
         AND xftv.source_value1 = p_process_type
         AND SYSDATE BETWEEN xftv.start_date_active
                         AND NVL (xftv.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN xftd.start_date_active
                         AND NVL (xftd.end_date_active, SYSDATE + 1)
         AND xftv.enabled_flag = 'Y'
         AND xftd.enabled_flag = 'Y';

      log_msg ('Email              :' || p_translation_info.target_value4);
      log_msg ('Source_Path        :' || p_translation_info.target_value7);
      log_msg ('Destination_Path   :' || p_translation_info.target_value8);
      log_msg ('Archive File Path  :' || p_translation_info.target_value9);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :=
             'No Translation info found for process type :' || p_process_type;
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_INTERFACE_SETTINGS',
             p_error_msg           => lc_error_msg
            );
         p_error_msg := lc_error_msg;
      WHEN OTHERS
      THEN
         lc_error_msg :=
                   'Unable to fetch Billing type details :' || ' ' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, p_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_INTERFACE_SETTINGS',
             p_error_msg           => lc_error_msg
            );
         p_error_msg := lc_error_msg;
   END get_interface_settings;

-- +====================================================================+
-- | Name       : GET_STATEMENT_cYCLE                                   |
-- |                                                                    |
-- | Description: This procedure will retrieve all of the source values |
-- |              from the XXOD_MOD4_OMX_SMENT_CYCLE translation        |
-- |              definition, and print them to the log file            |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+
   PROCEDURE get_statement_cycle (
      p_translation_name   IN       VARCHAR2,
      p_statement_type     IN       VARCHAR2,
      p_translation_info   OUT      xx_fin_translatevalues%ROWTYPE,
      p_error_msg          OUT      VARCHAR2
   )
   IS
--------------------------------
-- Local Variable Declaration --
--------------------------------
      lc_error_msg   VARCHAR2 (4000);
   BEGIN
      lc_error_msg := NULL;

--========================================================================
-- Retreiving Translation Definition Values
--========================================================================
      SELECT xftv.*
        INTO p_translation_info
        FROM xx_fin_translatevalues xftv, xx_fin_translatedefinition xftd
       WHERE xftv.translate_id = xftd.translate_id
         AND xftd.translation_name = p_translation_name   
         AND xftv.source_value1 = p_statement_type     
         AND SYSDATE BETWEEN xftv.start_date_active
                         AND NVL (xftv.end_date_active, SYSDATE + 1)
         AND SYSDATE BETWEEN xftd.start_date_active
                         AND NVL (xftd.end_date_active, SYSDATE + 1)
         AND xftv.enabled_flag = 'Y'
         AND xftd.enabled_flag = 'Y';

      log_msg ('ODN Statement Type :' || p_translation_info.source_value1);
      log_msg ('Statement Cycle    :' || p_translation_info.target_value1);

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         lc_error_msg :=
             'No Translation info found for ODN Statement Type :' || p_statement_type ;    
         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_STATEMENT_cYCLE',
             p_error_msg           => lc_error_msg
            );
         p_error_msg := lc_error_msg;
      WHEN OTHERS
      THEN
         lc_error_msg :=
                   'Unable to fetch info from the Translation :' || ' ' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, p_error_msg);
         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GET_STATEMENT_cYCLE',
             p_error_msg           => lc_error_msg
            );
         p_error_msg := lc_error_msg;
   END get_statement_cycle;

   /*=====================================================================================+
    | Name       : Update xx_cdh_omx_cust_info_stg for each record_id if it is completed |
    |                OR Errored Out.                                                       |
    | Description: This procedure is update the status                                    |
    |                                                                                     |
    | Parameters : none                                                                   |
    |                                                                                     |
    | Returns    : none                                                                   |
    +=====================================================================================*/
   PROCEDURE update_cust_info_stg (
      p_status         IN       VARCHAR2,
      p_process_flag   IN       VARCHAR2,
      p_record_id      IN       NUMBER,
      p_error_msg      IN OUT   VARCHAR2
   )
   IS
   BEGIN
      log_msg ('updating status .....');

      UPDATE xx_cdh_omx_cust_info_stg
         SET status = p_status,
             process_flag = p_process_flag,
             error_message = p_error_msg,
             last_update_date = SYSDATE
       WHERE record_id = p_record_id ;

      log_msg ('Number of Rows updated :' || SQL%ROWCOUNT);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF p_error_msg IS NULL
         THEN
            p_error_msg :=
                  'Error while updating the status xx_cdh_omx_cust_info_stg '
               || SQLERRM;
         END IF;

         log_exception
            (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.UPDATE_CUST_INFO_STG',
             p_error_msg           => p_error_msg
            );
   END update_cust_info_stg;

   PROCEDURE send_mail (
      p_file_name       IN       VARCHAR2,
      p_sourcepath      IN       VARCHAR2,
      p_destpath        IN       VARCHAR2,
      p_archpath        IN       VARCHAR2,
      p_sender_email    IN       Varchar2,
      p_receipts_email  IN       VARCHAR2,
      p_email_subject   IN       VARCHAR2,
      p_email_body      IN       VARCHAR2,
      p_return_status   OUT      VARCHAR2,
      p_return_msg      OUT      VARCHAR2
   )
   IS
-- +===================================================================+
-- | Name  : send_mail                                                   |
-- | Description     : The send_mail  procedure copies the outbound file to |
-- |                   the required directoy , archivesr and also email's..|
-- |                                                                   |
-- | Parameters      : p_file_name     -> file name
-- |                   p_return_status -> return status                |
-- |                   p_return_msg    -> return message               |
-- +===================================================================+
      lc_conn                        UTL_SMTP.connection;
      lc_sourcepath                  VARCHAR2 (4000);
      lc_destpath                    VARCHAR2 (4000);
      lc_archpath                    VARCHAR2 (4000);
      ln_copy_conc_request_id        NUMBER;
      lb_complete                    BOOLEAN;
      lc_phase                       VARCHAR2 (500);
      lc_status                      VARCHAR2 (500);
      lc_dev_phase                   VARCHAR2 (100);
      lc_dev_status                  VARCHAR2 (500);
      lc_message                     VARCHAR2 (500);
      lc_error_msg                   VARCHAR2 (4000);
      lc_date                        VARCHAR2 (500)  := TO_CHAR (SYSDATE, 'MM/DD/YYYY');
      e_process_exception   EXCEPTION;
   BEGIN
      lc_error_msg  := NULL;
      lc_conn       := NULL;
      lc_sourcepath := NULL;
      lc_destpath   := NULL;
      lc_archpath   := NULL;
      ln_copy_conc_request_id   := NULL;
      lb_complete    := NULL;
      lc_phase       := NULL;
      lc_status      := NULL;
      lc_dev_phase   := NULL;
      lc_dev_status  := NULL;
      lc_message     := NULL;

           BEGIN
         SELECT directory_path
           INTO lc_sourcepath
           FROM all_directories
          WHERE directory_name = p_sourcepath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Source Directory path not found'
                              );
            lc_error_msg := 'Source Directory path not found';
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            fnd_file.put_line (fnd_file.LOG,
                                  'Unable to fetch Source Directory path'
                               || SQLERRM
                              );
            lc_error_msg := 'Unable to fetch SourceDirectory path' || SQLERRM;
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
      END;

      
      BEGIN
         SELECT directory_path
           INTO lc_destpath
           FROM all_directories
          WHERE directory_name = p_destpath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Email Destination Directory path not found'
                              );
            lc_error_msg := 'Email Destination Directory path not found';
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                       (fnd_file.LOG,
                           'Unable to fetch Email Destination Directory path'
                        || SQLERRM
                       );
            lc_error_msg :=
                 'Unable to fetch Email Destination Directory path' || SQLERRM;
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
      END;
      
      
        BEGIN
         SELECT directory_path
           INTO lc_archpath
           FROM all_directories
          WHERE directory_name = p_archpath;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            fnd_file.put_line (fnd_file.LOG,
                               'Archive Directory path not found'
                              );
            lc_error_msg := 'Archive Destination Directory path not found';
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
         WHEN OTHERS
         THEN
            fnd_file.put_line
                       (fnd_file.LOG,
                           'Unable to fetch Archive Directory path'
                        || SQLERRM
                       );
            lc_error_msg :=
                 'Unable to fetch Archive Directory path' || SQLERRM;
            log_exception
                     (p_error_location      => 'XX_CDH_OMX_CONTACTS_PKG.SEND_MAIL',
                      p_error_msg           => lc_error_msg
                     );
      END;
      


      IF (lc_sourcepath IS NOT NULL)
      THEN
         lc_sourcepath := lc_sourcepath || '/' || p_file_name;
         lc_destpath :=  lc_destpath || '/' || p_file_name;
         lc_archpath := lc_archpath;
         fnd_file.put_line (fnd_file.LOG, 'source path :' || lc_sourcepath);
         fnd_file.put_line (fnd_file.LOG, 'destination path :' || lc_destpath);
         fnd_file.put_line (fnd_file.LOG, 'archive path  :' || lc_archpath);
         ln_copy_conc_request_id :=
            fnd_request.submit_request (application      => 'XXFIN',
                                        program          => 'XXCOMFILCOPY',
                                        description      => NULL,
                                        start_time       => NULL,
                                        sub_request      => FALSE,
                                        argument1        => lc_sourcepath,
                                        argument2        => lc_destpath,
                                        argument3        => NULL,
                                        argument4        => NULL,
                                        argument5        => 'Y',
                                        argument6        => lc_archpath,
                                        argument7        => NULL,
                                        argument8        => NULL,
                                        argument9        => NULL,
                                        argument10       => NULL,
                                        argument11       => NULL,
                                        argument12       => NULL,
                                        argument13       => NULL
                                       );

         IF ln_copy_conc_request_id > 0
         THEN
            COMMIT;
            lb_complete :=
               fnd_concurrent.wait_for_request
                                      (request_id      => ln_copy_conc_request_id,
                                       INTERVAL        => 30,
                                       max_wait        => 0   -- out arguments
                                                           ,
                                       phase           => lc_phase,
                                       status          => lc_status,
                                       dev_phase       => lc_dev_phase,
                                       dev_status      => lc_dev_status,
                                       MESSAGE         => lc_message
                                      );
         ELSE
            lc_error_msg :='fnd_concurrent.wait_for_request Faliure' || ' ' || SQLERRM;
            RAISE e_process_exception;
         END IF;

         log_msg ('lc_dev_phase: ' || lc_dev_phase);
         
      IF UPPER (lc_dev_phase) IN ('COMPLETE')
         THEN
            lc_conn :=  xx_pa_pb_mail.begin_mail
                             (sender             => p_sender_email,
                              recipients         => p_receipts_email,
                              cc_recipients      => NULL,
                              subject            => p_email_subject|| ' '|| lc_date,
                              mime_type          => xx_pa_pb_mail.multipart_mime_type
                             );
            xx_pa_pb_mail.xx_attach_excel (lc_conn, p_file_name);
            xx_pa_pb_mail.end_attachment (conn => lc_conn);
            xx_pa_pb_mail.attach_text (conn => lc_conn, DATA => p_email_body);
            xx_pa_pb_mail.end_mail (conn => lc_conn);
         ELSE
            lc_error_msg := 'lc_dev_phase is not complete' || '  ' || SQLERRM;
            RAISE e_process_exception;
         END IF;

         p_return_status := gc_success;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to email the file'||'  '|| SQLERRM;
         END IF;

         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
                    (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.SEND_MAIL',
                     p_error_msg           => lc_error_msg
                    );                    
         p_return_status := gc_failure;
         p_return_msg := lc_error_msg;
   END send_mail
   ;
   PROCEDURE generate_exception_report (
      x_retcode     OUT NOCOPY   NUMBER,
      x_errbuf      OUT NOCOPY   VARCHAR2,
      p_error_msg   OUT          VARCHAR2
   )
   IS
      -- local variable declaration
      lc_filehandle          UTL_FILE.file_type;
      lc_filename            VARCHAR2 (500);
      lc_file_name           VARCHAR2 (500);
      lc_file                VARCHAR2 (500):= '_' || TO_CHAR (SYSDATE, 'MMDDYYYY');
      lc_mode                VARCHAR2 (1)                     := 'W';
      ln_failed_records      NUMBER;
      ln_records_processed   NUMBER;
      lc_string              VARCHAR2 (32000);
      lc_header_string       VARCHAR2 (4000);
      lc_success             VARCHAR2 (200);
      lc_error_msg           VARCHAR2 (4000);
      lc_source_path_name    VARCHAR2 (200);
      lc_return_status       VARCHAR2 (500);
      lc_name                VARCHAR2 (1000);
      lc_sender_email        VARCHAR2(4000);
      lc_email               VARCHAR2 (4000);
      lc_file_path           VARCHAR2 (500);
      lc_ftp_file_path       VARCHAR2 (500);
      lc_arch_file_path      VARCHAR2 (500);
      lc_debug               VARCHAR2 (20);
      lc_utl_file_fopen      VARCHAR2(1) := 'Y';
      lc_translation_info    xx_fin_translatevalues%ROWTYPE;
	  
--Statement exception report
      CURSOR cur_st_exp_rpt
      IS
         SELECT    stg.aops_customer_number,
                   stg.customer_number,
                   stg.omx_account_number,
                   stg.statement_type,
                   stg.error_message,
                   hca.account_name,
                   stg1.split_customer
           FROM    xx_cdh_omx_cust_info_stg stg,
                   hz_cust_accounts hca,
                   xx_cdh_mod4_sfdc_cust_stg stg1
          WHERE    stg.status = 'E'
            AND    TRUNC (stg.last_update_date) = TRUNC (SYSDATE)
            AND    hca.orig_system_reference = LPAD (stg.aops_customer_number, 8, 0) || '-'|| '00001-A0'
            AND    hca.orig_system_reference = LPAD (stg1.aops_customer_number, 8, 0) || '-'|| '00001-A0'
            AND   (stg.statement_type IS NOT NULL AND stg.statement_type NOT IN ('1','2','3'));

--Credit Limit and DNB exception report
      CURSOR cur_dnb_exp_rpt
      IS
         SELECT   stg.aops_customer_number,
                  stg.customer_number,
                  stg.credit_limit,
                  stg.db_rating,
                  stg.omx_account_number,
				          stg.error_message,
				          hca.account_name,
				          stg1.split_customer
           FROM   xx_cdh_omx_cust_info_stg stg,
		              hz_cust_accounts hca,
				          xx_cdh_mod4_sfdc_cust_stg stg1
          WHERE   stg.status = 'E'
            AND   hca.orig_system_reference = LPAD (stg.aops_customer_number, 8, 0) || '-'|| '00001-A0'
			      AND   hca.orig_system_reference = LPAD (stg1.aops_customer_number, 8, 0) || '-'|| '00001-A0'
            AND   TRUNC (stg.last_update_date) = TRUNC (SYSDATE)
            AND   (1 = 1 OR stg.process_flag = 'E')
            AND   (stg.statement_type IS NULL OR stg.statement_type IN ('1','2','3'));
   BEGIN
 ---------------------------------------------------------------------------------------------
--Statement exception report
 ---------------------------------------------------------------------------------------------
      BEGIN
       
         lc_file_name := NULL;
         ln_records_processed := 0;
         ln_failed_records := 0;
         lc_utl_file_fopen := 'Y';
         lc_email := NULL;
         lc_sender_email := NULL;
         lc_file_path := NULL;
         lc_ftp_file_path := NULL;
         lc_arch_file_path := NULL;
         lc_header_string := NULL;
         lc_translation_info := NULL;

---------------------------------------------------------------------------------------------
---- Building a header string to spit out the the file to the specific output directory
---------------------------------------------------------------------------------------------
         lc_header_string :=
               'AOPS Account Number'
            || ','
            || 'Oracle Account Number'
            || ','
            || 'OD North Account Number'
            || ','
            || 'Account Name'
            || ','
			      || 'Split Flag' -- Added as per Version 1.4, MOD5 Changes
            || ','
            || 'Statement type from ODN' 
            || ','
            || 'Error Message';

         FOR cur_st_exp_rpt_rec IN cur_st_exp_rpt
         LOOP
            BEGIN
              log_msg ('Getting data for Statement exception report');
               lc_string := NULL;
			   
               log_msg ('Statement exception report..');
  -------------------------------------------------------------------------
 -- UTL_FILE.fopen
-------------------------------------------------------------------------
            IF lc_utl_file_fopen = 'Y'
            THEN
            
        get_interface_settings (p_process_type          => 'Customer Info Statement',
                                 p_translation_info      => lc_translation_info,
                                 p_error_msg             => lc_error_msg
                                );
         lc_sender_email :=lc_translation_info.target_value10;                        
         lc_email := lc_translation_info.target_value4;
         lc_file_path := lc_translation_info.target_value7;
         lc_ftp_file_path := lc_translation_info.target_value8;
         lc_arch_file_path := lc_translation_info.target_value9;
         lc_file_name :=  'xxod_omx_statement_info_exception'|| lc_file || '.csv';
             lc_filehandle :=
               UTL_FILE.fopen (lc_file_path, lc_file_name, lc_mode);
               UTL_FILE.put_line (lc_filehandle, lc_header_string);
               lc_utl_file_fopen := 'N';
            END IF;   
			
---------------------------------------------------------------------------------------------
  ---- Building a exception string to spit out the the file to the specific output directory
---------------------------------------------------------------------------------------------
               lc_string :=
                     cur_st_exp_rpt_rec.aops_customer_number
                  || ','
                  || cur_st_exp_rpt_rec.customer_number
                  || ','
                  || cur_st_exp_rpt_rec.omx_account_number
                  || ','
                  || cur_st_exp_rpt_rec.account_name
                  || ','
				          || cur_st_exp_rpt_rec.split_customer
                  || ','
                  || cur_st_exp_rpt_rec.statement_type
                  || ','
                  || cur_st_exp_rpt_rec.error_message;
               UTL_FILE.put_line (lc_filehandle, lc_string);
---------------------------------------------------------------------------------------------

               --Count Successful records loaded into the exception file
--------------------------------------------------------------------------
               ln_records_processed := ln_records_processed + 1;
           EXCEPTION       
            WHEN UTL_FILE.invalid_mode
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20052, 'Invalid Mode');
            WHEN UTL_FILE.internal_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20053, 'Internal Error');
            WHEN UTL_FILE.invalid_operation
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20054, 'Invalid Operation');
            WHEN UTL_FILE.invalid_filehandle
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20055, 'Invalid Filehandle');
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20056, 'Write Error');
            WHEN OTHERS
            THEN
               lc_error_msg :=
                  'Unable to fetch date to send_mail error:' || ' '
                  || SQLERRM;
               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GENERATE_EXCEPTION_REPORT',
                   p_error_msg           => lc_error_msg
                  );
            END;
         END LOOP;

         UTL_FILE.fclose (lc_filehandle);
          
    IF ln_records_processed  >= 1     THEN 
------------------------------------------------------------------
-- Calling  ftp_file to copy the file to the OMX FTP Directory  --
------------------------------------------------------------------
         lc_return_status := NULL;
         lc_error_msg := NULL;
-----------------------
--Send email procedure
-----------------------
         log_msg ('Calling  procedure email_file');
         send_mail
            (p_file_name          => lc_file_name,
             p_sourcepath         => lc_file_path,
             p_destpath           => lc_ftp_file_path,
             p_archpath           => lc_arch_file_path,
             p_sender_email       => lc_sender_email,
             p_receipts_email     => lc_email,
             p_email_subject      => 'Statement Exception Report',
             p_email_body         => 'The attached file contains Customer Info Statement Exception Report',
             p_return_status      => lc_return_status,
             p_return_msg         => lc_error_msg
            );
             log_msg ('Statement exception report Completed');
    END IF;         
 EXCEPTION
         WHEN OTHERS
         THEN
            IF lc_error_msg IS NULL
            THEN
               lc_error_msg := 'Unable to fetch data  :' || ' ' || SQLERRM;
            END IF;

            fnd_file.put_line (fnd_file.LOG, lc_error_msg);
            log_exception
               (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GENERATE_EXCEPTION_REPORT',
                p_error_msg           => lc_error_msg
               );
               
                log_msg ('Statement exception report exception');
      END;
-------------------------------------------------------------------------------------------------------
----------------------------------End Statement exception report--------------------------------
-------------------------------------------------------------------------------------------------------
-- Credit Limit and DNB exception report
-------------------------------------------------------------------------------------------------------
      BEGIN
         lc_file_name := NULL;
         ln_records_processed := 0;
         ln_failed_records := 0;
         lc_email := NULL;
         lc_sender_email := NULL;
         lc_file_path := NULL;
         lc_ftp_file_path := NULL;
         lc_arch_file_path := NULL;
         lc_header_string := NULL;
         lc_translation_info := NULL;         
         lc_file_name := 'xxod_omx_credit_info_exception'||lc_file||'.csv';
--------------------------------------------------------------------------------------------------         
         ---- Building a header string to spit out the the file to the specific output directory
--------------------------------------------------------------------------------------------------         
         lc_header_string :=
               'AOPS Account Number'
            || ','
            || 'Oracle Account Number'
            || ','
            || 'OD North Account Number'
            || ','
            || 'Account Name'
            || ','
			      || 'Split Flag'
            || ','
            || 'credit limit from ODN'
            || ','
            || 'DNB Rating'
            || ','
            || 'Exception message';
		
		
		 get_interface_settings (p_process_type          => 'Customer Info Credits',
                                 p_translation_info      => lc_translation_info,
                                 p_error_msg             => lc_error_msg
                                );
         lc_sender_email :=lc_translation_info.target_value10;                           
         lc_email := lc_translation_info.target_value4;
         lc_file_path := lc_translation_info.target_value7;
         lc_ftp_file_path := lc_translation_info.target_value8;
         lc_arch_file_path := lc_translation_info.target_value9;    

         -------------------------------------------------------------------------
          -- UTL_FILE.fopen
         -------------------------------------------------------------------------		 
         lc_filehandle :=
                UTL_FILE.fopen (lc_file_path, lc_file_name, lc_mode);
                UTL_FILE.put_line (lc_filehandle, lc_header_string);

         FOR cur_dnb_exp_rpt_rec IN cur_dnb_exp_rpt
         LOOP
            BEGIN
               lc_string := NULL;
               log_msg ('Credit Limit and DNB exception report..');

         -------------------------------------------------------------------------------------------                       
          ---- Building a exception string to spit out the the file to the specific output directory
         -------------------------------------------------------------------------------------------- 
               lc_string :=
                     cur_dnb_exp_rpt_rec.aops_customer_number
                  || ','
                  || cur_dnb_exp_rpt_rec.customer_number
                  || ','
                  || cur_dnb_exp_rpt_rec.omx_account_number
                  || ','
                  || cur_dnb_exp_rpt_rec.account_name
                  || ','
				          || cur_dnb_exp_rpt_rec.split_customer -- Added for MOD5 Changes
				          || ','
                  || cur_dnb_exp_rpt_rec.credit_limit
                  || ','
                  || cur_dnb_exp_rpt_rec.db_rating
                  || ',' 
                  || cur_dnb_exp_rpt_rec.error_message;
               UTL_FILE.put_line (lc_filehandle, lc_string);
--------------------------------------------------------------------------
--Count Successful records loaded into the exception file
--------------------------------------------------------------------------
               ln_records_processed := ln_records_processed + 1;
            EXCEPTION       
            WHEN UTL_FILE.invalid_mode
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20052, 'Invalid Mode');
            WHEN UTL_FILE.internal_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20053, 'Internal Error');
            WHEN UTL_FILE.invalid_operation
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20054, 'Invalid Operation');
            WHEN UTL_FILE.invalid_filehandle
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20055, 'Invalid Filehandle');
            WHEN UTL_FILE.write_error
            THEN
               UTL_FILE.fclose_all;
               x_retcode := 2;
               raise_application_error (-20056, 'Write Error');
            WHEN OTHERS
            THEN
               lc_error_msg :=
                  'Unable to fetch date to send_mail error:' || ' '
                  || SQLERRM;
               fnd_file.put_line (fnd_file.LOG, lc_error_msg);
               log_exception
                  (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GENERATE_EXCEPTION_REPORT',
                   p_error_msg           => lc_error_msg
                  );
            END;
         END LOOP;

         UTL_FILE.fclose (lc_filehandle);      
                  
     ------------------------------------------------------------------
      -- Calling  ftp_file to copy the file to the OMX FTP Directory  --
     ------------------------------------------------------------------
         lc_return_status := NULL;
         lc_error_msg := NULL;
        
         log_msg ('file_name :'||lc_file_name );
     -----------------------
      --Send email procedure
     -----------------------
         log_msg ('Calling  procedure send email');
        send_mail
            (p_file_name          => lc_file_name,
             p_sourcepath         => lc_file_path,
             p_destpath           => lc_ftp_file_path,
             p_archpath           => lc_arch_file_path,
             p_sender_email       => lc_sender_email,
             p_receipts_email     => lc_email,
             p_email_subject      => 'Credit Limit and DNB Rating Exception Report',
             p_email_body         => 'The attached file contains Customer Info Credit Limit and DNB Rating Exception Report',
             p_return_status      => lc_return_status,
             p_return_msg         => lc_error_msg
            );
			
      EXCEPTION
         WHEN OTHERS
         THEN
            IF lc_error_msg IS NULL
            THEN
               lc_error_msg :=
                     'Unable to fetch data from credit exception Report:'
                  || ' '
                  || SQLERRM;
            END IF;

            fnd_file.put_line (fnd_file.LOG, lc_error_msg);
            log_exception
               (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.GENERATE_EXCEPTION_REPORT',
                p_error_msg           => lc_error_msg
               );
      END;
   END generate_exception_report;
   
   PROCEDURE process_customer_info (
         x_retcode     OUT NOCOPY   NUMBER,
      x_errbuf      OUT NOCOPY   VARCHAR2,
      p_return_status             OUT      VARCHAR2,
      p_return_msg                OUT      VARCHAR2,
      p_status                    IN       VARCHAR2,
      p_aops_acct_number          IN       VARCHAR2,
      p_default_statement_cycle   IN       VARCHAR2,
      p_default_card_limit        IN       VARCHAR2
   )
   IS
      -- local variable declaration
      lc_statement_cycle_id          VARCHAR2 (100);
      ln_statement_cycle_id          NUMBER;
      lc_error_msg                   VARCHAR2 (4000);  
      lc_final_error_msg             VARCHAR2 (4000);
      lc_credit_error_msg            VARCHAR2 (4000);
      lc_profile_error_msg           VARCHAR2 (4000);
      lc_cust_error_msg              VARCHAR2 (4000);
      lc_site_error_msg              VARCHAR2 (4000);
      lc_dnb_error_msg               VARCHAR2 (4000);
      lc_error_exists                VARCHAR2(1) := 'N';
      lc_process_flag                VARCHAR2(1) := 'N';
      lc_status                      VARCHAR2(1) := 'N';
      lc_return_message              VARCHAR2 (2000);
      lc_return_status               VARCHAR2 (200);
      lc_direct_customer             VARCHAR2 (100);
      lc_cust_convered               VARCHAR2 (100);
      ln_object_version_number       NUMBER;
      ln_failed_records              NUMBER;
      ln_records_processed           NUMBER;
      ln_batch_id                    NUMBER;
      lc_statement_cycle             VARCHAR2(20);
      lc_profile_rec                 hz_customer_profiles%ROWTYPE;
      lc_profile_amt_rec             hz_cust_profile_amts%ROWTYPE;
      lc_billing_type                xx_cdh_mod4_sfdc_cust_stg.billing_type%TYPE;
      lc_converted                   VARCHAR2 (10);
      lr_od_ext_attr_rec             xx_cdh_omx_bill_documents_pkg.xx_od_ext_attr_rec;
      lr_cust_profile_amt_rec_type   hz_customer_profile_v2pub.cust_profile_amt_rec_type;
      lc_customer_profile_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
      lr_cust_pcursor_rec_type       xx_cdh_omx_cust_info_stg%ROWTYPE;
      lc_translation_info            xx_fin_translatevalues%ROWTYPE;
      e_process_exception            EXCEPTION;

      CURSOR cur_cust_info
      IS
         SELECT   *
             FROM xx_cdh_omx_cust_info_stg a
            WHERE 1 = 1
              AND status = NVL (p_status, 'N')
              AND aops_customer_number =
                                NVL (p_aops_acct_number, aops_customer_number)
         ORDER BY batch_id;
   BEGIN

      ln_records_processed := 0;
      ln_failed_records := 0;
            
      FOR cur_cust_rec IN cur_cust_info
      LOOP
         BEGIN
           lc_error_msg         := NULL;
           lc_final_error_msg   := NULL;
           lc_credit_error_msg  := NULL;
           lc_profile_error_msg := NULL;
           lc_cust_error_msg    := NULL;
           lc_site_error_msg    := NULL;
           lc_dnb_error_msg     := NULL;
           lc_return_status     := NULL;
           lr_od_ext_attr_rec   := NULL;
           lc_profile_rec       := NULL;
           lr_od_ext_attr_rec   := NULL;
           lc_status            := NULL;
           lc_process_flag      := 'N';
           lc_error_exists      := 'N';
           lc_billing_type      := NULL;
           ln_object_version_number := NULL;
		   lc_translation_info  := NULL;
           
            log_msg('********************************************************************************');

           log_msg ('Processing record_id ....' || cur_cust_rec.record_id ||' For Customer Number '|| cur_cust_rec.aops_customer_number);

            -- Get profile details
            log_msg ('Calling customer profile details procedure..');

            get_customer_profile_details
                 (p_aops_account_number      => cur_cust_rec.aops_customer_number,
                  p_profile_rec              => lc_profile_rec,
                  p_error_msg                => lc_error_msg
                 );
            log_msg('Cust profile account id :'|| lc_profile_rec.cust_account_profile_id);
            log_msg('Cust account id :'|| lc_profile_rec.cust_account_id);


            IF lc_error_msg IS NOT NULL
            THEN
               RAISE e_process_exception;
            END IF;
            
            -------------------------------------------------------------------------------------
            --- This process updates the Profile amounts at customer account level.
            -------------------------------------------------------------------------------------

            IF lc_profile_rec.cust_account_profile_id IS NOT NULL
            THEN
               IF NVL (cur_cust_rec.credit_limit, 0) > 0
               THEN
                 log_msg('Credit Limit :'||cur_cust_rec.credit_limit);

                 get_cust_profile_amt_details(p_aops_account_number   => cur_cust_rec.aops_customer_number,
                                              p_currency              => 'USD',
                                              p_profile_amt_rec       => lc_profile_amt_rec,
                                              p_error_msg             => lc_error_msg);
              
                 lr_cust_profile_amt_rec_type                          := NULL;
                 ln_object_version_number                              := lc_profile_amt_rec.object_version_number;
                 lr_cust_profile_amt_rec_type.cust_account_profile_id  := lc_profile_amt_rec.cust_account_profile_id;
                 lr_cust_profile_amt_rec_type.cust_acct_profile_amt_id := lc_profile_amt_rec.cust_acct_profile_amt_id;
                 lr_cust_profile_amt_rec_type.currency_code            := 'USD';
                 lr_cust_profile_amt_rec_type.trx_credit_limit         := cur_cust_rec.credit_limit;
                 lr_cust_profile_amt_rec_type.overall_credit_limit     := cur_cust_rec.credit_limit;
                 lr_cust_profile_amt_rec_type.cust_account_id          := lc_profile_rec.cust_account_id;

                 log_msg ('updating the profile amount for USD');

                 update_credit
                          (p_profile_amt_rec       => lr_cust_profile_amt_rec_type,
                           p_object_version_number => ln_object_version_number,
                           p_return_status         => lc_return_status,
                           p_error_msg             => lc_credit_error_msg
                          );

                 IF lc_return_status = gc_failure
                 THEN 
                   lc_error_exists := 'Y';
                   lc_process_flag := 'E';
                   log_msg( 'Credit Error msg '||' '||lc_credit_error_msg);                    
                 END IF;

                  IF lc_return_status = gc_success
                  THEN
                     log_msg( 'update_credit procedure Returned Success');
                     log_msg ('updating the profile amount for CAD');


                     lc_profile_amt_rec := NULL;

                     get_cust_profile_amt_details(p_aops_account_number   => cur_cust_rec.aops_customer_number,
                                                  p_currency              => 'CAD',
                                                  p_profile_amt_rec       => lc_profile_amt_rec,
                                                  p_error_msg             => lc_error_msg);

                     lr_cust_profile_amt_rec_type := NULL;
                     ln_object_version_number                               := lc_profile_amt_rec.object_version_number;
                     lr_cust_profile_amt_rec_type.cust_account_profile_id   := lc_profile_amt_rec.cust_account_profile_id;
                     lr_cust_profile_amt_rec_type.cust_acct_profile_amt_id  := lc_profile_amt_rec.cust_acct_profile_amt_id;
                     lr_cust_profile_amt_rec_type.currency_code             := 'CAD';
                     lr_cust_profile_amt_rec_type.trx_credit_limit          := p_default_card_limit; 
                     lr_cust_profile_amt_rec_type.overall_credit_limit      := p_default_card_limit;
                     lr_cust_profile_amt_rec_type.cust_account_id           := lc_profile_rec.cust_account_id;

                     update_credit
                          (p_profile_amt_rec      => lr_cust_profile_amt_rec_type,
                           p_object_version_number => ln_object_version_number,
                           p_return_status        => lc_return_status,
                           p_error_msg            => lc_credit_error_msg
                          );


                     IF lc_return_status =gc_failure
                     THEN
                       lc_error_exists := 'Y';
                       lc_process_flag := 'E';
                       IF lc_credit_error_msg is null then
                       log_msg( 'Credit Error msg for CAD' ||' '||lc_credit_error_msg); 
                       END IF;
                     END IF;
                  ELSE
                     lc_credit_error_msg := 'updating the profile amount for CAD failed as update_credit limit API falied';
                     log_msg( 'Credit Error msg for CAD' ||' '||lc_credit_error_msg); 
                     lc_error_exists := 'Y';
                     lc_process_flag := 'E';
                  END IF;
               ELSE 
                 lc_error_exists := 'Y';
                 lc_credit_error_msg := 'Credit Limit is either zero or Blank '|| cur_cust_rec.credit_limit ;   
               END IF;
            END IF;

            -------------------------------------------------------------------------------------
            --  DNB Rating
            --  This process updates the DNB rating in the extended attributes table
            --  for attribute group “DNB_RATING” and group type “Account
            ------------------------------------------------------------------------------------- 
   
            log_msg('setting DNB Rating ');
            log_msg('DNB Rating flag:'|| cur_cust_rec.db_rating);

            IF cur_cust_rec.db_rating IS NOT NULL
            THEN
              lc_return_status := NULL;
  
              dnb_rating(p_cursor_rec           => cur_cust_rec,
                         p_cust_account_id      => lc_profile_rec.cust_account_id,
                         p_return_status        => lc_return_status,
                         p_error_msg            => lc_dnb_error_msg
                        );
              log_msg ('dnb_lc_return_status :'|| lc_return_status );
              IF lc_return_status = gc_failure
              THEN
                lc_error_exists := 'Y';
                lc_process_flag := 'E';
                log_msg( 'DNB Error msg' ||' '||lc_dnb_error_msg); 
               END IF;
            END IF;
            
            -------------------------------------------------------------------------------------
            ---Statement Cycle Check for 0 or 1 or 2 or 3
            ---Call update_customer_profile Procedure
            -- donot update the process flag to E for Statement cycle.
             -------------------------------------------------------------------------------------

            log_msg('Checking statement type  ');
            log_msg ( 'Statement type :'|| cur_cust_rec.statement_type);
            IF  (cur_cust_rec.db_rating_date  is not null or cur_cust_rec.statement_cycle is not null )
            then
            lc_customer_profile_rec                         := NULL;
            lc_customer_profile_rec.cust_account_profile_id := lc_profile_rec.cust_account_profile_id;
            lc_customer_profile_rec.cust_account_id         := lc_profile_rec.cust_account_id;
            lc_customer_profile_rec.last_credit_review_date := cur_cust_rec.db_rating_date;  -- check the date format 
          IF cur_cust_rec.statement_cycle is not null 
          then
            IF (   cur_cust_rec.statement_type IS NULL
                OR cur_cust_rec.statement_type IN ('1','2','3')
               )
            THEN
			
			     --------------------------------------------------------------------------
                 -- Calling get_statement_cycle for STATEMENT_CYCLE_ID 
                 --------------------------------------------------------------------------
                 log_msg ('Getting translation value for statement_cycle..');
                 get_statement_cycle (p_translation_name          => 'XXOD_MOD4_OMX_SMENT_CYCLE',
				                      p_statement_type            => NVL(cur_cust_rec.statement_type,'DEFAULT'),
                                      p_translation_info          => lc_translation_info,
                                      p_error_msg                 => lc_error_msg
                                      );
									       
                 IF lc_translation_info.target_value1 IS NOT NULL
                 THEN
                    SELECT arsc.statement_cycle_id
                      INTO ln_statement_cycle_id
                      FROM ar_statement_cycles arsc
                     WHERE 1 = 1
                       AND arsc.NAME = lc_translation_info.target_value1
                    ;
                 END IF;
				 
               lc_customer_profile_rec.send_statements    := 'Y';
               lc_customer_profile_rec.statement_cycle_id := ln_statement_cycle_id ; --p_default_statement_cycle;
               
               -------------------------------------------------------------------------------------
               --  Set Extended Attirute
               --  This process updates the extended attributes table
               --  
               ------------------------------------------------------------------------------------- 
   
               log_msg('setting extended attribute ');
               IF cur_cust_rec.statement_type = '2'
               THEN
                 lc_return_status := NULL;
                 set_extended_attribute ( p_cursor_rec           => cur_cust_rec,
                                          p_cust_account_id      => lc_profile_rec.cust_account_id,
                                          p_group_code           => 'STATEMENTS_AT_SHIP_TO',
                                          p_return_status        => lc_return_status,
                                          p_error_msg            => lc_cust_error_msg
                                        );
                 log_msg ('set_extended_attribute lc_return_status :'|| lc_return_status );
                 IF lc_return_status = gc_failure
                 THEN
                   lc_error_exists := 'Y';
                   lc_process_flag := 'E';
                   log_msg( 'set_extended_attribute Error msg' ||' '||lc_cust_error_msg); 
                  END IF;
               END IF;
            
            ELSE
              lc_error_exists := 'Y';
              lc_cust_error_msg := 'Statement type is '||cur_cust_rec.statement_type ;
              log_msg ( lc_cust_error_msg);
              
            END IF;
           END IF; 
            log_msg( 'calling the update_customer_profile procedure to update the profile at acct level');

            update_customer_profile (p_profile_rec            => lc_customer_profile_rec,
                                     p_object_version_number  => lc_profile_rec.object_version_number,
                                     p_return_status          => lc_return_status,
                                     p_error_msg              => lc_profile_error_msg
                                    );

            IF lc_return_status = gc_failure
            THEN
             log_msg( 'lc_profile_error_msg :'|| lc_profile_error_msg);
             lc_error_exists := 'Y';
            END IF;
          END IF;
            -------------------------------------------------------------------------------------
            --- If Statement Cycle Check is equal to 3
            ---Call update_customer_profile Procedure
            -------------------------------------------------------------------------------------

            IF cur_cust_rec.statement_type = '3'
            THEN
            
              log_msg('Processing site level for Statement type 3 records ..');
              log_msg ('calling the derive_billing_type function' );

              lc_direct_customer :=  derive_billing_type (p_cursor_rec        => cur_cust_rec,
                                                          p_billing_type      => lc_billing_type,
                                                          p_error_msg         => lc_error_msg);

              log_msg('Billing Type :'|| lc_billing_type);
              
               IF lc_billing_type IS NULL 
               THEN 
                lc_error_exists := 'Y';
                lc_error_msg := 'Invalid Billing type';
               END IF;  

            
              IF lc_billing_type = 'IS' -- means indirect customer
              THEN

                log_msg('calling the check_customer_is_converted');

                lc_cust_convered :=  check_customer_is_converted(p_acct_number      => cur_cust_rec.customer_number,
                                                                 p_converted         => lc_converted,
                                                                 p_error_msg        => lc_error_msg);
                                                                 
                log_msg('Customer Converted :'|| lc_converted );                                                                 

                IF lc_cust_convered = 'N'
                THEN
                   lc_error_exists := 'Y';
                END IF;
              END IF;
              
              IF (lc_billing_type = 'DI' or lc_converted = 'Y')
              THEN
              IF  (cur_cust_rec.db_rating_date  is not null or cur_cust_rec.statement_cycle is not null) then
                log_msg ('get all the bill to profiles..');
 
                FOR cur_site_rec IN (SELECT hcp.cust_account_profile_id,
                                            hcp.site_use_id,
                                            hcp.object_version_number
                                       FROM hz_cust_acct_sites_all hcs,
                                            hz_cust_site_uses_all hcsa,
                                            hz_customer_profiles hcp,
                                            hz_cust_accounts hca
                                      WHERE site_use_code = 'BILL_TO'
                                        AND hcp.cust_account_id = hca.cust_account_id
                                        AND hcp.site_use_id = hcsa.site_use_id
                                        AND hcsa.cust_acct_site_id = hcs.cust_acct_site_id
                                        AND hcp.status = 'A'
                                        AND hca.orig_system_reference =  LPAD (TO_CHAR (cur_cust_rec.aops_customer_number),8,0)|| '-'|| '00001-A0')

                LOOP
                  BEGIN

                    log_msg(' Setting for Bill to acct profile id :'|| cur_site_rec.cust_account_profile_id);
                    log_msg(' site use id :'|| cur_site_rec.site_use_id);

                    lc_customer_profile_rec                                 := NULL;
                    lc_customer_profile_rec.cust_account_profile_id         := cur_site_rec.cust_account_profile_id;
                    lc_customer_profile_rec.cust_account_id                 := lc_profile_rec.cust_account_id;
                    lc_customer_profile_rec.site_use_id                     := cur_site_rec.site_use_id;
                    lc_customer_profile_rec.last_credit_review_date         := cur_cust_rec.db_rating_date;  -- check the date format 
                    
                    IF cur_cust_rec.statement_cycle is not null then
                    lc_customer_profile_rec.send_statements                 := 'Y';
                    lc_customer_profile_rec.statement_cycle_id              := ln_statement_cycle_id; --p_default_statement_cycle;
                    END IF;                                 
                    log_msg( 'Calling update customer profile API');                           

                    update_customer_profile
                                   (p_profile_rec            => lc_customer_profile_rec,
                                    p_object_version_number  => cur_site_rec.object_version_number,
                                    p_return_status          => lc_return_status,
                                    p_error_msg              => lc_site_error_msg
                                   );

                    IF lc_return_status = gc_failure
                    THEN 
                      log_msg('Site error msg:'|| lc_site_error_msg);
                      RAISE e_process_exception;
                    END IF;
                  EXCEPTION
                    WHEN OTHERS
                    THEN
                      IF lc_site_error_msg IS NULL 
                      THEN
                        lc_site_error_msg := ('Error while updating the Site level profile '||' '|| SQLERRM);  
                      END IF;
                      lc_error_exists   := 'Y';
                  END;
                END LOOP;
                END IF;
              END IF;
            END IF; -- statement type

            --------------------------------------------------------------------------------------
            -- call update status procedure
            --------------------------------------------------------------------------------------
            
            log_msg('Lc Error exists :'|| lc_error_exists);

            IF lc_error_exists = 'Y'
            THEN 
              lc_status            := 'E';
              lc_final_error_msg   :=  SUBSTR(lc_credit_error_msg || ' '|| lc_dnb_error_msg||'  '||lc_cust_error_msg||' '||
                                              lc_profile_error_msg ||' '|| lc_site_error_msg||' '||lc_error_msg,1,4000);
              ln_failed_records := ln_failed_records + 1;
            ELSE
              lc_status := 'C';

              ln_records_processed    := ln_records_processed +1 ;
            END IF;
            
            log_msg('Final Error Msg:'|| lc_final_error_msg);

            update_cust_info_stg (p_status            => lc_status,
                                  p_process_flag      => lc_process_flag,
                                  p_record_id         => cur_cust_rec.record_id,
                                  p_error_msg         => lc_final_error_msg
                                 );

            log_msg (' Commit the record ...');
           
            ln_batch_id := cur_cust_rec.batch_id;
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
              ROLLBACK;
              IF lc_error_msg IS NULL
              THEN
                lc_error_msg := 'Error while processing record' || SQLERRM;
              END IF;

              fnd_file.put_line (fnd_file.LOG, lc_error_msg);
              log_exception
                  (p_error_location      => 'XX_CDH_OMX_CUST_INFO_PKG.PROCESS_CUSTOMER_INFO',
                   p_error_msg           => lc_error_msg
                  );
               update_cust_info_stg (p_status            => 'E',
                                     p_process_flag      => 'N',
                                     p_record_id         => cur_cust_rec.record_id,
                                     p_error_msg         => lc_error_msg
                                    );
               ln_failed_records := ln_failed_records + 1;
              
         END;
                            
      END LOOP;
      
      log_msg ('END LOOP ..');
       IF ln_failed_records >= 0 then

            log_msg ('Calling Process generate_exception_report ..');
           
            generate_exception_report (x_retcode        => x_retcode,
                                       x_errbuf         => x_errbuf,
                                       p_error_msg      => lc_error_msg
                                      );
         END IF; 
      
      ------------------------------
      -- calling log_table procedure
      -----------------------------
      log_msg ('Calling  procedure log msg');
      log_file (p_success_records      => ln_records_processed,
                p_faliure_records      => ln_failed_records,
                p_batch_id             => ln_batch_id,
                p_file_name            => NULL,
                p_status               => 'C'
               );

   EXCEPTION 
     WHEN OTHERS 
     THEN 
       log_msg('Error while processing customer info '|| SQLERRM);
   END process_customer_info;

   ----------------------------------------------------------
   ----Main Program
   ----------------------------------------------------------
   PROCEDURE EXTRACT (
      x_retcode                   OUT NOCOPY      NUMBER,
      x_errbuf                    OUT NOCOPY      VARCHAR2,
      p_status                    IN              VARCHAR2,
      p_debug_flag                IN              VARCHAR2,
      p_aops_acct_number          IN              xx_cdh_omx_cust_info_stg.aops_customer_number%TYPE,
      p_default_statement_cycle   IN              xx_cdh_omx_cust_info_stg.statement_cycle%TYPE,
      p_default_credit_limit      IN              NUMBER
   )
   IS
      lc_error_msg       VARCHAR2 (4000);
      lc_return_status   VARCHAR2 (10);
-- +===================================================================+
-- | Name  : extract                                                   |
-- | Description     : The extract is the main                         |
-- |                   procedure that will extract the records         |
-- |                   and write them into the output file             |
-- |                                                                   |
-- | Parameters      : x_retcode           OUT                         |
-- |                   x_errbuf            OUT                         |
-- |                   p_debug_flag        IN -> Debug Flag            |
-- |                   p_status            IN -> Record status         |
-- +===================================================================+
   BEGIN

      IF (p_debug_flag = 'Y')
      THEN
         g_debug_flag := TRUE;
      ELSE
         g_debug_flag := FALSE;
      END IF;
      
      
           fnd_file.put_line
         (fnd_file.LOG,
          '********************************************************************************'
         );
      fnd_file.put_line (fnd_file.LOG, 'Input parameters .....:');
      fnd_file.put_line (fnd_file.LOG, 'p_debug_flag: ' || p_debug_flag);
      fnd_file.put_line (fnd_file.LOG, 'p_status:' || p_status);
      fnd_file.put_line (fnd_file.LOG,'p_default_statement_cycle :'||p_default_statement_cycle);
      fnd_file.put_line (fnd_file.LOG,'p_default_credit_limit :'||p_default_credit_limit);
       fnd_file.put_line
         (fnd_file.LOG,
          '********************************************************************************'
         );

      log_msg ('Calling Process bill Process_customer_info ..');
      process_customer_info

                      ( x_retcode                      => x_retcode,
                        x_errbuf                       => x_errbuf,
                        p_return_status                => lc_return_status,
                        p_return_msg                   => lc_return_status,
                        p_status                       => p_status,
                        p_aops_acct_number             => p_aops_acct_number,
                        p_default_statement_cycle      => p_default_statement_cycle,
                        p_default_card_limit           => p_default_credit_limit
                      );
      COMMIT;
      
      --Generate_Exception_report;
   EXCEPTION
      WHEN OTHERS
      THEN
        ROLLBACK;
         IF lc_error_msg IS NULL
         THEN
            lc_error_msg := 'Unable to process ' || SQLERRM;
         END IF;

         fnd_file.put_line (fnd_file.LOG, lc_error_msg);
         log_exception
                      (p_error_location      => 'xx_cdh_omx_cust_info_pkg.EXTRACT',
                       p_error_msg           => lc_error_msg
                      );
         x_retcode := 2;
         COMMIT;
   END EXTRACT;
END xx_cdh_omx_cust_info_pkg;
/
SHOW ERRORS;