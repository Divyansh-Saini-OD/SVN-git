CREATE OR REPLACE PACKAGE xx_crm_cust_head_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_HEAD_EXTRACT_PKG                           |
--|RICE        : 106313                                                 |
--|Description :This Package is used for insert data into staging       |
--|             table and fetch data from staging table to flat file    |
--|                                                                     |
--|            The STAGING Procedure will perform the following steps   |
--|                                                                     |
--|             1.It will fetch the records into staging table. The     |
--|               data will be either full or incremental               |
--|                                                                     |
--|             EXTRACT STAGING procedure will perform the following    |
--|                steps                                                |
--|                                                                     |
--|              1.It will fetch the staging table data to flat file    |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version    |
--|                                                                     |
--|                                                                     |
--+=====================================================================+

   --Global variable declaration
   gc_module_name              fnd_application_tl.application_name%TYPE                       := 'XXCRM';
   gc_program_name             fnd_concurrent_programs_tl.USER_CONCURRENT_PROGRAM_NAME%TYPE   := 'OD: CRM Extract WC - Customer Master Header';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XX_CRM_CUST_HEAD_EXTRACT_PKG';
   gn_last_updated_by          hz_cust_accounts.last_updated_by%TYPE                          := -1;
   gd_creation_date            hz_cust_accounts.creation_date%TYPE                            := SYSDATE;
   gn_last_update_login        hz_cust_accounts.last_update_login%TYPE                        := -1;
   gn_request_id               hz_cust_accounts.request_id%TYPE                               := -1;
   gn_program_application_id   hz_cust_accounts.program_application_id%TYPE                   := -1;
   gn_created_by               hz_cust_accounts.created_by%TYPE                               := -1;
   gd_last_update_date         hz_cust_accounts.last_update_date%TYPE                         := SYSDATE;
   gn_program_id               hz_cust_accounts.program_id%TYPE                               := 1;
   gn_nextval                  NUMBER;
   gn_count                    NUMBER;
   gc_filename                 VARCHAR2 (200);
   gc_error_debug              VARCHAR2 (200);
   gc_debug_flag               VARCHAR2 (1);
   gc_compute_stats            VARCHAR2 (1);

-- +====================================================================+
-- |   Record Type Declaration                                          |
-- |                                                                    |
-- |   Name: Customer_master                                            |
-- +====================================================================+
   TYPE lr_customer_master IS RECORD (
      cust_account_id                 hz_cust_accounts.cust_account_id%TYPE
     ,customer_number                 hz_cust_accounts.account_number%TYPE
     ,organization_number             hz_parties.party_number%TYPE
     ,customer_number_aops            hz_cust_accounts.orig_system_reference%TYPE
     ,customer_name                   hz_cust_accounts.account_name%TYPE
     ,status                          hz_cust_accounts.status%TYPE
     ,customer_type                   hz_cust_accounts.attribute18%TYPE
     ,customer_class_code             hz_cust_accounts.customer_class_code%TYPE
     ,sales_channel_code              hz_cust_accounts.sales_channel_code%TYPE
     ,sic_code                        hz_parties.sic_code%TYPE
     ,cust_category_code              ar_lookups.meaning%TYPE
     ,duns_number                     hz_parties.duns_number_c%TYPE
     ,sic_code_type                   hz_parties.sic_code_type%TYPE
     ,collector_number                ar_collectors.NAME%TYPE
     ,collector_name                  ar_collectors.description%TYPE
     ,credit_checking                 hz_customer_profiles.attribute3%TYPE
     ,credit_rating                   hz_customer_profiles.credit_rating%TYPE
     ,account_established_date        hz_cust_accounts.attribute6%TYPE
     ,account_credit_limit_usd        hz_cust_profile_amts.overall_credit_limit%TYPE
     ,account_credit_limit_cad        hz_cust_profile_amts.overall_credit_limit%TYPE
     ,order_credit_limit_usd          hz_cust_profile_amts.trx_credit_limit%TYPE
     ,order_credit_limit_cad          hz_cust_profile_amts.trx_credit_limit%TYPE
     ,credit_classification           ar_lookups.meaning%TYPE
     ,exposure_analysis_segment       hz_customer_profiles.account_status%TYPE
     ,risk_code                       hz_customer_profiles.risk_code%TYPE
     ,source_of_creation_for_credit   hz_cust_accounts.attribute19%TYPE
     ,po                              hz_cust_accounts.attribute2%TYPE
     ,release                         hz_cust_accounts.attribute4%TYPE
     ,cost_center                     hz_cust_accounts.attribute9%TYPE
     ,desktop                         hz_cust_accounts.attribute11%TYPE
     ,po_value                        hz_cust_accounts.attribute1%TYPE
     ,release_value                   hz_cust_accounts.attribute3%TYPE
     ,cost_center_value               hz_cust_accounts.attribute5%TYPE
     ,desktop_value                   hz_cust_accounts.attribute10%TYPE
     ,last_updated_by                 hz_cust_accounts.last_updated_by%TYPE
     ,creation_date                   hz_cust_accounts.creation_date%TYPE
     ,request_id                      hz_cust_accounts.request_id%TYPE
     ,created_by                      hz_cust_accounts.created_by%TYPE
     ,last_update_date                hz_cust_accounts.last_update_date%TYPE
     ,program_id                      hz_cust_accounts.program_id%TYPE
     ,omx_account_number              hz_cust_accounts.orig_system_reference%TYPE
     ,billdocs_delivery_method        xx_cdh_cust_acct_ext_b.c_ext_attr3%TYPE
   );

   --Table type declaration
   TYPE lt_cust_master IS TABLE OF lr_customer_master;

   TYPE lt_req_id IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE lt_file_names IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;

--+=====================================================================+
--| Name       : main                                                   |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_action_type                                         |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
--|                                                                     |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );

--+==================================================================+
--|Name        :extract_stagedata                                    |
--|Description :This procedure is used to fetch the staging table    |
--|             data to flat file                                    |
--|                                                                  |
--|                                                                  |
--|Parameters :                                                      |
--|               p_debug_flag                                       |
--|               p_compute_stats                                    |
--|Returns    :   p_errbuf                                           |
--|               p_retcode                                          |
--|                                                                  |
--|                                                                  |
--+==================================================================+
   PROCEDURE extract_stagedata (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );

   PROCEDURE insert_incrdata_child (
      x_errbuf OUT nocopy  VARCHAR2,
      x_retcode OUT nocopy VARCHAR2,
      in_low          NUMBER,
      in_high         NUMBER
   );


END xx_crm_cust_head_extract_pkg;
/

SHOW errors;
