SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CUST_REL_SITE_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XXCDHCUSTRELATEMASTERS.pls                         |
-- | Description :  CDH Customer Account Relate Master Package Spec    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  27-Apr-2007 Ambarish Mukherjee Initial draft version     |
-- |Draft 1b  15-May-2007 Ambarish Mukherjee Modified to handle updates|
-- |Draft 1c  04-Jun-2007 Ambarish Mukherjee Modified to include limit |
-- |                                         clause in bulk fetch      |
-- +===================================================================+
AS

TYPE gt_cust_acct_rel_rec_type IS RECORD
      (  record_id                          xxod_hz_imp_accounts_stg.record_id%TYPE
        ,batch_id                           xxod_hz_imp_accounts_stg.batch_id%TYPE
        ,account_orig_system                xxod_hz_imp_accounts_stg.account_orig_system%TYPE
        ,account_orig_system_reference      xxod_hz_imp_accounts_stg.account_orig_system_reference%TYPE
        ,related_account_ref                xxod_hz_imp_accounts_stg.related_account_ref%TYPE
        ,related_acc_ref_f_bill_to_flag     xxod_hz_imp_accounts_stg.related_acc_ref_f_bill_to_flag%TYPE
        ,related_acc_ref_f_ship_to_flag     xxod_hz_imp_accounts_stg.related_acc_ref_f_ship_to_flag%TYPE
        ,related_acc_ref_b_bill_to_flag     xxod_hz_imp_accounts_stg.related_acc_ref_b_bill_to_flag%TYPE
        ,related_acc_ref_b_ship_to_flag     xxod_hz_imp_accounts_stg.related_acc_ref_b_ship_to_flag%TYPE
        ,created_by_module                  xxod_hz_imp_accounts_stg.created_by_module%TYPE
        ,program_application_id             xxod_hz_imp_accounts_stg.program_application_id%TYPE
      );
      
TYPE gt_upd_cust_site_use_rec_type IS RECORD
      (  record_id                          xxod_hz_imp_acct_site_uses_stg.record_id%TYPE
        ,batch_id                           xxod_hz_imp_acct_site_uses_stg.batch_id%TYPE
        ,acct_site_orig_system              xxod_hz_imp_acct_site_uses_stg.acct_site_orig_system%TYPE
        ,acct_site_orig_sys_reference       xxod_hz_imp_acct_site_uses_stg.acct_site_orig_sys_reference%TYPE
        ,site_use_code                      xxod_hz_imp_acct_site_uses_stg.site_use_code%TYPE
        ,bill_to_orig_system                xxod_hz_imp_acct_site_uses_stg.bill_to_orig_system%TYPE
        ,bill_to_acct_site_ref              xxod_hz_imp_acct_site_uses_stg.bill_to_acct_site_ref%TYPE
      );

PROCEDURE conv_master_main
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_batch_id_from                    IN  NUMBER,
         p_batch_id_to                      IN  NUMBER
      );

PROCEDURE submit_sub_requests
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_batch_id_from                    IN  NUMBER,
         p_batch_id_to                      IN  NUMBER
      );

PROCEDURE conv_child_main
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_batch_id                         IN  NUMBER
      );

PROCEDURE process_cust_acct_relate_batch
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_batch_id                         IN  NUMBER
      );

PROCEDURE process_cust_acct_relate
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_cust_acct_rel_rec                IN  gt_cust_acct_rel_rec_type
      );

PROCEDURE update_cust_site_use_batch
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_batch_id                         IN  NUMBER
      );
      
PROCEDURE update_cust_site_use
      (  x_errbuf                           OUT VARCHAR2,
         x_retcode                          OUT VARCHAR2,
         p_upd_cust_site_use_rec            IN  gt_upd_cust_site_use_rec_type
      );      

PROCEDURE log_exception
      (  p_record_control_id                IN NUMBER
        ,p_source_system_code               IN VARCHAR2
        ,p_procedure_name                   IN VARCHAR2
        ,p_staging_table_name               IN VARCHAR2
        ,p_staging_column_name              IN VARCHAR2
        ,p_staging_column_value             IN VARCHAR2
        ,p_source_system_ref                IN VARCHAR2
        ,p_batch_id                         IN NUMBER
        ,p_exception_log                    IN VARCHAR2
        ,p_oracle_error_code                IN VARCHAR2
        ,p_oracle_error_msg                 IN VARCHAR2
      );

PROCEDURE log_debug_msg
    (
         p_debug_msg              IN        VARCHAR2
    );
    
END XX_CDH_CUST_REL_SITE_PKG;
/
SHOW ERRORS;
EXIT;