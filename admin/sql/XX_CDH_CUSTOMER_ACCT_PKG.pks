SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_CUSTOMER_ACCT_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                 Oracle NAIO Consulting Organization                                     |
-- +=========================================================================================+
-- | Name        : XX_CDH_CUSTOMER_ACCT_PKG                                                  |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   19-Apr-2007     Prakash Sowriraj     Initial draft version                    |
-- |Draft 1b   15-May-2007     Prakash Sowriraj     Modified to include update part          |
-- |Draft 1c   19-Jul-2007     Ambarish Mukherjee   Modified to have different programs for  |
-- |                                                Accounts, Account Sites, Acct Site Uses  |
-- |Draft 1d   27-Aug-2007     Ambarish Mukherjee   Multi-threaded for Account Site Uses     | 
-- +=========================================================================================+

AS

-- +===================================================================+
-- | Name        : process_accounts                                    |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_accounts  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2 
   );
   
-- +===================================================================+
-- | Name        : process_account_sites                               |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_account_sites  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2
   );
   
PROCEDURE process_account_sites_worker  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_worker_id    IN      NUMBER
   );   
   
-- +===================================================================+
-- | Name        : process_account_site_uses                           |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: CDH Customer Account Conversion'       |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE process_account_site_uses  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_process_yn   IN      VARCHAR2
   );
   
PROCEDURE process_acc_site_uses_worker  
   (   x_errbuf       OUT     VARCHAR2
      ,x_retcode      OUT     VARCHAR2
      ,p_batch_id     IN      NUMBER
      ,p_worker_id    IN      NUMBER
   );   

-- +===================================================================+
-- | Name        : account_main                                        |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program                                             |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE account_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
    );


-- +===================================================================+
-- | Name        : create_account                                      |
-- | Description : Procedure to create a new customer account          |
-- |                                                                   |
-- | Parameters  : l_hz_imp_accounts_stg                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account
    (
         L_HZ_IMP_ACCOUNTS_STG      IN      XXOD_HZ_IMP_ACCOUNTS_STG%ROWTYPE
        ,x_cust_account_id          OUT     NUMBER
        ,x_acct_return_status       OUT     VARCHAR
    );


-- +===================================================================+
-- | Name        : create_account_site                                 |
-- | Description : Procedure to create a new customer account site     |
-- |                                                                   |
-- | Parameters  : l_hz_imp_acct_sites_stg,p_cust_account_id           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account_site
    (
         l_hz_imp_acct_sites_stg    IN      XXOD_HZ_IMP_ACCT_SITES_STG%ROWTYPE
        ,x_acct_site_id             OUT     NUMBER
        ,x_acct_site_return_status  OUT     VARCHAR
    );



-- +===================================================================+
-- | Name        : create_account_site_use                             |
-- | Description : Procedure to create a new site use                  |
-- |                                                                   |
-- | Parameters  : l_hz_imp_acct_site_uses_stg                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_account_site_use
    (
         l_hz_imp_acct_site_uses_stg    IN      XXOD_HZ_IMP_ACCT_SITE_USES_STG%ROWTYPE
        ,x_site_use_id                  OUT     NUMBER
        ,x_site_use_return_status       OUT     VARCHAR
    );


-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description : Proecdure to log messages                           |
-- |                                                                   |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (  p_debug_msg     IN  VARCHAR2 );



-- +===================================================================+
-- | Name        : validate_date_value                                 |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  : p_date                                              |
-- |                                                                   |
-- +===================================================================+
FUNCTION validate_date_value
    ( p_date    IN  VARCHAR2 ) 

RETURN BOOLEAN;


-- +===================================================================+
-- | Name        : validate_flex_value                                 |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  : p_flex_value_set_name,p_flex_value                  |
-- |                                                                   |
-- +===================================================================+
FUNCTION validate_flex_value
    (
         p_flex_value_set_name    IN    VARCHAR2
        ,p_flex_value             IN    VARCHAR2
    ) 

RETURN BOOLEAN;



-- +===================================================================+
-- | Name        : is_account_exists                                   |
-- | Description : Function to checks whether customer account         |
-- |               already exists or not                               |
-- | Parameters  : p_acct_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_account_exists
    (
         p_acct_orig_sys_ref    IN  VARCHAR2
        ,p_acct_orig_sys        IN  VARCHAR2
    ) 

RETURN NUMBER;



-- +===================================================================+
-- | Name        : is_acct_site_exists                                 |
-- | Description : Function to check whether customer account site     |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_exists
    (
         p_site_orig_sys_ref   IN   VARCHAR2
        ,p_site_orig_sys       IN   VARCHAR2
    ) 

RETURN NUMBER;



-- +===================================================================+
-- | Name        : is_acct_site_use_exists                             |
-- | Description : Function to check whether customer account site use |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_use_exists
    (
         p_site_orig_sys_ref    IN  VARCHAR2
        ,p_orig_sys             IN  VARCHAR2
        ,p_site_code            IN  VARCHAR2
    ) 

RETURN NUMBER;


-- +===================================================================+
-- | Name        : bill_to_use_id_val                                  |
-- | Description : Funtion to get bill_to_use_id                       |
-- |                                                                   |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION bill_to_use_id_val
    (
         p_bill_to_orig_sys         IN  VARCHAR2
        ,p_bill_to_orig_add_ref     IN  VARCHAR2
    )

RETURN NUMBER;


-- +===================================================================+
-- | Name        : orig_sys_val                                        |
-- |                                                                   |
-- | Description : Function checks whether the p_orig_sys is a valid   |
-- |               reference key of HZ_ORIG_SYSTEM_B table             |
-- | Parameters  : p_orig_sys                                          |
-- |                                                                   |
-- +===================================================================+ 
FUNCTION orig_sys_val
    ( p_orig_sys    IN   VARCHAR2) 

RETURN NUMBER;



-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |               conversion common elements tables.                  |
-- |                                                                   |
-- | Parameters  : p_conversion_id,p_record_control_id,                |
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
PROCEDURE log_exception
    (
         p_conversion_id            IN  NUMBER
        ,p_record_control_id        IN  NUMBER
        ,p_source_system_code       IN  VARCHAR2
        ,p_source_system_ref        IN  VARCHAR2
        ,p_procedure_name           IN  VARCHAR2
        ,p_staging_table_name       IN  VARCHAR2
        ,p_staging_column_name      IN  VARCHAR2
        ,p_staging_column_value     IN  VARCHAR2
        ,p_batch_id                 IN  NUMBER
        ,p_exception_log            IN  VARCHAR2
        ,p_oracle_error_code        IN  VARCHAR2
        ,p_oracle_error_msg         IN  VARCHAR2
);
            
-- +===================================================================+
-- | Name        : ar_lookup_val                                       |
-- | Description : This procedure checks whether the lookup value      |
-- |               exists in AR_LOOKUPS table or not                   |
-- |                                                                   |
-- | Parameters  : p_lookup_type,p_lookup_code                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION ar_lookup_val
    (
         p_lookup_type     IN VARCHAR2
        ,p_lookup_code     IN VARCHAR2
    ) 

RETURN BOOLEAN;


END XX_CDH_CUSTOMER_ACCT_PKG;
/
SHOW ERRORS;