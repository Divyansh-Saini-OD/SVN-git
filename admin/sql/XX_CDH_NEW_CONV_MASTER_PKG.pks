SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_NEW_CONV_MASTER_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_NEW_CONV_MASTER_PKG.pls                     |
-- | Description :  CDH Customer Conversion Master Package Spec        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  25-Oct-2011 Sreedhar Mohan     Initial draft version     |
-- +===================================================================+
AS

g_bulk_fetch_limit NUMBER := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),10000);

PROCEDURE conv_master_main
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_from_ebs_batch_id   IN  NUMBER,
         p_to_ebs_batch_id     IN  NUMBER,
         p_submit_bulk         IN  VARCHAR2,
         p_create_cust_acct    IN  VARCHAR2,
         p_create_contact      IN  VARCHAR2,
         p_create_cust_prof    IN  VARCHAR2,
         p_create_bank_paymeth IN  VARCHAR2,
         p_create_ext_attrib   IN  VARCHAR2,
         p_import_run_option   IN  VARCHAR2, -- Bulk Import Parameter
         p_run_batch_dedup     IN  VARCHAR2, -- Bulk Import Parameter
         p_batch_dedup_rule    IN  VARCHAR2, -- Bulk Import Parameter
         p_action_duplicates   IN  VARCHAR2, -- Bulk Import Parameter
         p_run_addr_val        IN  VARCHAR2, -- Bulk Import Parameter
         p_run_reg_dedup       IN  VARCHAR2, -- Bulk Import Parameter
         p_reg_dedup_rule      IN  VARCHAR2, -- Bulk Import Parameter
         p_generate_fuzzy_key  IN  VARCHAR2  -- Bulk Import Parameter
      );
      
PROCEDURE submit_sub_requests 
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_batch_id_from       IN  NUMBER,
         p_batch_id_to         IN  NUMBER,
         p_submit_bulk         IN  VARCHAR2,
         p_create_cust_acct    IN  VARCHAR2,
         p_create_contact      IN  VARCHAR2,
         p_create_cust_prof    IN  VARCHAR2,
         p_create_bank_paymeth IN  VARCHAR2,
         p_create_ext_attrib   IN  VARCHAR2,
         p_import_run_option   IN  VARCHAR2,
         p_run_batch_dedup     IN  VARCHAR2,
         p_batch_dedup_rule    IN  VARCHAR2,
         p_action_duplicates   IN  VARCHAR2,
         p_run_addr_val        IN  VARCHAR2,
         p_run_reg_dedup       IN  VARCHAR2,
         p_reg_dedup_rule      IN  VARCHAR2,
         p_generate_fuzzy_key  IN  VARCHAR2
      );
      
PROCEDURE conv_child_main
      (  x_errbuf              OUT VARCHAR2,
         x_retcode             OUT VARCHAR2,
         p_submit_bulk         IN  VARCHAR2,
         p_create_cust_acct    IN  VARCHAR2,
         p_create_contact      IN  VARCHAR2,
         p_create_cust_prof    IN  VARCHAR2,
         p_create_bank_paymeth IN  VARCHAR2,
         p_create_ext_attrib   IN  VARCHAR2, 
         p_batch_id            IN  NUMBER,
         p_import_run_option   IN  VARCHAR2, -- Bulk Import Parameter
         p_run_batch_dedup     IN  VARCHAR2, -- Bulk Import Parameter
         p_batch_dedup_rule    IN  VARCHAR2, -- Bulk Import Parameter
         p_action_duplicates   IN  VARCHAR2, -- Bulk Import Parameter
         p_run_addr_val        IN  VARCHAR2, -- Bulk Import Parameter
         p_run_reg_dedup       IN  VARCHAR2, -- Bulk Import Parameter
         p_reg_dedup_rule      IN  VARCHAR2, -- Bulk Import Parameter
         p_generate_fuzzy_key  IN  VARCHAR2  -- Bulk Import Parameter
      );
      
PROCEDURE get_osr_owner_table_id
      (  p_orig_system         IN  hz_orig_sys_references.orig_system%TYPE,
         p_orig_sys_reference  IN  hz_orig_sys_references.orig_system_reference%TYPE,
         p_owner_table_name    IN  hz_orig_sys_references.owner_table_name%TYPE,
         x_owner_table_id     OUT  hz_orig_sys_references.owner_table_id%TYPE,
         x_retcode            OUT  NUMBER, 
         x_errbuf             OUT  VARCHAR2
      );
      
      
FUNCTION get_hz_imp_g_miss_char 
      (  p_column_value VARCHAR2 )
RETURN VARCHAR2;

FUNCTION get_hz_imp_g_miss_num  
      (  p_column_value VARCHAR2 )
RETURN NUMBER;

FUNCTION get_hz_imp_g_miss_date
      (  p_column_value VARCHAR2 )
RETURN DATE;

PROCEDURE write_conc_log_message
      ( p_message    IN VARCHAR2);
      
FUNCTION trim_input_msg
      ( p_message   IN  VARCHAR2)
RETURN VARCHAR2;

PROCEDURE submit_conv_request_set
      ( x_errbuf                 OUT VARCHAR2,
        x_retcode                OUT VARCHAR2,
        p_ebs_batch_id           IN  NUMBER,
        p_submit_update          IN  VARCHAR2, 
        p_sbmt_load_INT_to_STG   IN  VARCHAR2, 
        p_submit_bulk            IN  VARCHAR2,
        p_process_party_rel      IN  VARCHAR2, 
        p_process_accounts       IN  VARCHAR2,
        p_process_acct_sites     IN  VARCHAR2,
        p_process_acct_site_uses IN  VARCHAR2,
        p_process_contacts       IN  VARCHAR2,
        p_process_contact_points IN  VARCHAR2,
        p_process_profiles       IN  VARCHAR2,
        p_process_bank           IN  VARCHAR2,
        p_process_ext_attrib     IN  VARCHAR2,
        p_import_run_option      IN  VARCHAR2,
        p_run_batch_dedup        IN  VARCHAR2,
        p_batch_dedup_rule       IN  VARCHAR2,
        p_action_duplicates      IN  VARCHAR2,
        p_run_addr_val           IN  VARCHAR2,
        p_run_reg_dedup          IN  VARCHAR2,
        p_reg_dedup_rule         IN  VARCHAR2,
        p_gen_fuz_key            IN  VARCHAR2
      );

PROCEDURE activate_bulk_batch
      ( x_errbuf              OUT VARCHAR2,
        x_retcode             OUT VARCHAR2,
        p_bulk_batch_id       IN  NUMBER
      );
      
PROCEDURE generate_bulk_batch
      ( x_errbuf              OUT VARCHAR2,
        x_retcode             OUT VARCHAR2,
        p_batch_name          IN  VARCHAR2,
        p_description         IN  VARCHAR2,
        p_original_system     IN  VARCHAR2,
        p_est_no_of_records   IN  VARCHAR2
      );    
      
PROCEDURE submit_tca_bulk_wrapper
      ( x_errbuf              OUT VARCHAR2,
        x_retcode             OUT VARCHAR2,
        p_submit_bulk         IN  VARCHAR2,
        p_batch_id            IN  VARCHAR2,
        p_import_run_option   IN  VARCHAR2, -- Bulk Import Parameter
        p_run_batch_dedup     IN  VARCHAR2, -- Bulk Import Parameter
        p_batch_dedup_rule    IN  VARCHAR2, -- Bulk Import Parameter
        p_action_duplicates   IN  VARCHAR2, -- Bulk Import Parameter
        p_run_addr_val        IN  VARCHAR2, -- Bulk Import Parameter
        p_run_reg_dedup       IN  VARCHAR2, -- Bulk Import Parameter
        p_reg_dedup_rule      IN  VARCHAR2, -- Bulk Import Parameter
        p_generate_fuzzy_key  IN  VARCHAR2  -- Bulk Import Parameter
      ); 
      
PROCEDURE submit_cdh_aops_master
      ( x_errbuf                 OUT VARCHAR2,
        x_retcode                OUT VARCHAR2,
        p_from_ebs_batch_id      IN  NUMBER,
        p_to_ebs_batch_id        IN  NUMBER,
        p_submit_update          IN  VARCHAR2, 
        p_sbmt_load_INT_to_STG   IN  VARCHAR2, 
        p_submit_bulk            IN  VARCHAR2,
        p_process_party_rel      IN  VARCHAR2, 
        p_process_accounts       IN  VARCHAR2,
        p_process_acct_sites     IN  VARCHAR2,
        p_process_acct_site_uses IN  VARCHAR2,
        p_process_contacts       IN  VARCHAR2,
        p_process_contact_points IN  VARCHAR2,
        p_process_profiles       IN  VARCHAR2,
        p_process_bank           IN  VARCHAR2,
        p_process_ext_attrib     IN  VARCHAR2,
        p_import_run_option      IN  VARCHAR2,
        p_run_batch_dedup        IN  VARCHAR2,
        p_batch_dedup_rule       IN  VARCHAR2,
        p_action_duplicates      IN  VARCHAR2,
        p_run_addr_val           IN  VARCHAR2,
        p_run_reg_dedup          IN  VARCHAR2,
        p_reg_dedup_rule         IN  VARCHAR2,
        p_gen_fuz_key            IN  VARCHAR2
      );
      
PROCEDURE seamless_aops_conversion
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_batch_type             IN  VARCHAR2,
       p_submit_update          IN  VARCHAR2,
       p_sbmt_load_INT_to_STG   IN  VARCHAR2,
       p_submit_bulk            IN  VARCHAR2,
       p_process_party_rel      IN  VARCHAR2,
       p_process_accounts       IN  VARCHAR2,
       p_process_acct_sites     IN  VARCHAR2,
       p_process_acct_site_uses IN  VARCHAR2,
       p_process_contacts       IN  VARCHAR2,
       p_process_contact_points IN  VARCHAR2,
       p_process_profiles       IN  VARCHAR2,
       p_process_bank           IN  VARCHAR2,
       p_process_ext_attrib     IN  VARCHAR2,
       p_import_run_option      IN  VARCHAR2,
       p_run_batch_dedup        IN  VARCHAR2,
       p_batch_dedup_rule       IN  VARCHAR2,
       p_action_duplicates      IN  VARCHAR2,
       p_run_addr_val           IN  VARCHAR2,
       p_run_reg_dedup          IN  VARCHAR2,
       p_reg_dedup_rule         IN  VARCHAR2,
       p_gen_fuz_key            IN  VARCHAR2
   );
   
PROCEDURE seamless_conv_other_sources
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_sbmt_load_INT_to_STG   IN  VARCHAR2,
       p_submit_bulk            IN  VARCHAR2,
       p_process_party_rel      IN  VARCHAR2,
       p_process_accounts       IN  VARCHAR2,
       p_process_acct_sites     IN  VARCHAR2,
       p_process_acct_site_uses IN  VARCHAR2,
       p_process_contacts       IN  VARCHAR2,
       p_process_contact_points IN  VARCHAR2,
       p_process_profiles       IN  VARCHAR2,
       p_process_bank           IN  VARCHAR2,
       p_process_ext_attrib     IN  VARCHAR2,
       p_import_run_option      IN  VARCHAR2,
       p_run_batch_dedup        IN  VARCHAR2,
       p_batch_dedup_rule       IN  VARCHAR2,
       p_action_duplicates      IN  VARCHAR2,
       p_run_addr_val           IN  VARCHAR2,
       p_run_reg_dedup          IN  VARCHAR2,
       p_reg_dedup_rule         IN  VARCHAR2,
       p_gen_fuz_key            IN  VARCHAR2
   );   
      
      
END XX_CDH_NEW_CONV_MASTER_PKG;
/
SHOW ERRORS;
