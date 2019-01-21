create or replace 
PACKAGE XX_CDH_CUSTOMER_PROFILE_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |                Oracle NAIO Consulting Organization                                      |
-- +=========================================================================================+
-- | Name        : XX_CDH_CUSTOMER_PROFILE_PKG                                               |
-- | Description : Custom package to create/update customer profile and profile amount       |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   12-Apr-2007     Prakash Sowriraj     Initial draft version                    |
-- |Draft 1b   15-May-2007     Prakash Sowriraj     Modified to include update part          |
-- |1.0        10-Dec-2013     Shubhashree R        Changes for defect 26170.                |
-- |                                                Added procedure update_profile_override_terms. |
-- |                                                                                         |
-- +=========================================================================================+

AS

-- +===================================================================+
-- | Name        : profile_main                                        |
-- |                                                                   |
-- | Description : The main procedure to be invoked from the           |
-- |               concurrent program                                  |
-- |                                                                   |
-- | Parameters  : p_batch_id                                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE profile_main
    (
         x_errbuf       OUT     VARCHAR2
        ,x_retcode      OUT     VARCHAR2
        ,p_batch_id     IN      NUMBER
        ,p_process_yn   IN      VARCHAR2
    );


-- +===================================================================+
-- | Name        : create_profile                                      |
-- |                                                                   |
-- | Description : Procdedure to create a new customer profile         |
-- |                                                                   |
-- | Parameters  : l_hz_imp_acct_prof_stg                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_profile
    (
         l_hz_imp_acct_prof_stg     IN      XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE
        ,x_cust_acct_prof_id        OUT     NUMBER
        ,x_prof_return_status       OUT     VARCHAR2
    );


-- +===================================================================+
-- | Name        : create_profile_amount                               |
-- |                                                                   |
-- | Description : Procdedure to create a new customer profile amount  |
-- |                                                                   |
-- | Parameters  : l_hz_imp_prof_amt_stg                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_profile_amount
    (
         l_hz_imp_prof_amt_stg      IN      XXOD_HZ_IMP_ACCOUNT_PROF_STG%ROWTYPE
        ,x_prof_amt_id              OUT     NUMBER
        ,x_prof_amt_return_status   OUT     VARCHAR2
    );



-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- |                                                                   |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (
        p_debug_msg     IN      VARCHAR2
    );



-- +===================================================================+
-- | Name        : is_customer_profile_exists                          |
-- |                                                                   |
-- | Description : Function checks whether customer profile already    |
-- |               exists or not                                       |
-- |                                                                   |
-- | Parameters  : p_cust_account_id                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_customer_profile_exists
    (
        p_cust_account_id   IN      NUMBER

    )   RETURN NUMBER;

-- +===================================================================+
-- | Name        : is_profile_amt_exists                               |
-- |                                                                   |
-- | Description : Function checks whether customer profile amount     |
-- |               already exists or not                               |
-- |                                                                   |
-- | Parameters  : p_cust_acct_prof_id , p_currency_code               |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_profile_amt_exists
    (
         p_cust_acct_prof_id    IN      NUMBER
        ,p_currency_code        IN      VARCHAR

    )   RETURN NUMBER;


-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |                conversion common elements tables.                 |
-- |                                                                   |
-- | Parameters :  p_conversion_id,p_record_control_id,p_procedure_name|
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
-- | Name        : get_party_id                                        |
-- |                                                                   |
-- | Description : Function to get party_id from p_cust_account_id     |
-- |                                                                   |
-- | Parameters  : p_cust_account_id                                   |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_party_id
    (
        p_cust_account_id   IN      NUMBER

    )   RETURN NUMBER;

-- +===================================================================+
-- | Name        : orig_sys_val                                        |
-- |                                                                   |
-- | Description : Function checks whether the p_orig_sys is a valid   |
-- |               reference key of HZ_ORIG_SYSTEM_B table             |
-- | Parameters  : p_orig_sys                                          |
-- |                                                                   |
-- +===================================================================+
FUNCTION orig_sys_val
    (
         p_orig_sys     IN      VARCHAR2

    )   RETURN NUMBER;


-- +===================================================================+
-- | Name        : get_profile_class_id                                |
-- |                                                                   |
-- | Description : Procedure to get profile_class_id from              |
-- |               p_profile_class_name passed                         |
-- | Parameters  : p_profile_class_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_profile_class_id
    (
         p_profile_class_name   IN      VARCHAR2
        ,x_profile_class_id     OUT     NUMBER
        ,x_ret_status           OUT     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_standard_terms                                  |
-- |                                                                   |
-- | Description : Procedure to get standard_terms from                |
-- |               p_standard_term_name passed                         |
-- | Parameters  : p_standard_term_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_standard_terms
    (
         p_standard_term_name   IN      VARCHAR2
        ,x_standard_terms       OUT     NUMBER
        ,x_ret_status           OUT     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_dunning_letter_set_id                           |
-- |                                                                   |
-- | Description : Procedure to get dunning_letter_set_id from         |
-- |               p_dunning_letter_set_name passed                    |
-- | Parameters  : p_dunning_letter_set_name                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_dunning_letter_set_id
    (
         p_dunning_letter_set_name  IN      VARCHAR2
        ,x_dunning_letter_set_id    OUT     NUMBER
        ,x_ret_dun_letter_status    OUT     VARCHAR2
    );


-- +===================================================================+
-- | Name        : get_statement_cycle_id                              |
-- |                                                                   |
-- | Description : Procedure to get statement_cycle_id from            |
-- |               p_statement_cycle_name passed                       |
-- | Parameters  : p_statement_cycle_name                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_statement_cycle_id
    (
         p_statement_cycle_name     IN      VARCHAR2
        ,x_statement_cycle_id       OUT     NUMBER
        ,x_ret_statement_status     OUT     VARCHAR2
    );


-- +===================================================================+
-- | Name        : get_autocash_hierarchy_id                           |
-- |                                                                   |
-- | Description : Procedure to get autocash_hierarchy_id from         |
-- |               p_autocash_hierarchy_name passed                    |
-- | Parameters  : p_autocash_hierarchy_name                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_autocash_hierarchy_id
    (
         p_autocash_hierarchy_name      IN      VARCHAR2
        ,x_autocash_hierarchy_id        OUT     NUMBER
        ,x_autocash_hierarchy_status    OUT     VARCHAR2
    );


-- +===================================================================+
-- | Name        : get_grouping_rule_id                                |
-- |                                                                   |
-- | Description : Procedure to get grouping_rule_id from              |
-- |               p_grouping_rule_name passed                         |
-- | Parameters  : p_grouping_rule_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_grouping_rule_id
    (
         p_grouping_rule_name       IN      VARCHAR2
        ,x_grouping_rule_id         OUT     NUMBER
        ,x_grouping_rule_status     OUT     VARCHAR2
    );


-- +===================================================================+
-- | Name        : get_hierarchy_id_for_adr                            |
-- |                                                                   |
-- | Description : Procedure to get hierarchy_id_for_adr from          |
-- |               p_hierarchy_name_adr passed                         |
-- | Parameters  : p_hierarchy_name_adr                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_hierarchy_id_for_adr
    (
         p_hierarchy_name_adr       IN      VARCHAR2
        ,x_hierarchy_id_for_adr     OUT     NUMBER
        ,x_hierarchy_status         OUT     VARCHAR2
    );

-- +===================================================================+
-- | Name        : get_collector_id                                    |
-- |                                                                   |
-- | Description : Procedure to get collector_id from                  |
-- |               p_collector_name passed                             |
-- | Parameters  : p_collector_name                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE get_collector_id
    (
         p_collector_name       IN      VARCHAR2
        ,x_collector_id         OUT     NUMBER
        ,x_ret_status           OUT     VARCHAR2
    );

PROCEDURE update_profile_override_terms
    (
         custAcctId              IN      NUMBER
         ,p_override_terms           IN      VARCHAR2
        ,x_prof_return_status    OUT     VARCHAR2
    );
END XX_CDH_CUSTOMER_PROFILE_PKG;
/
SHOW ERRORS;