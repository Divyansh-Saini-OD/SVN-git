CREATE OR REPLACE PACKAGE xx_crm_cust_slsas_extract_pkg
AS
  --+=====================================================================+
  --|      Office Depot - Project FIT                                     |
  --|   Capgemini/Office Depot/Consulting Organization                    |
  --+=====================================================================+
  --|Name        : XX_CRM_CUST_SLSAS_EXTRACT_PKG                          |
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
  --|                                                                     |
  --|                                                                     |
  --+=====================================================================+
   
   --Global variable declaration
   gc_module_name              fnd_application_tl.application_name%TYPE                     := 'XXCRM';
   gc_program_name             fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE := 'OD: CRM Extract WC - Sales Person Assignment';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE         := 'XX_CRM_CUST_SLSAS_EXTRACT_PKG';
   gn_last_updated_by          hz_cust_accounts.last_updated_by%TYPE                        := -1;
   gd_creation_date            hz_cust_accounts.creation_date%TYPE                          := SYSDATE;
   gn_last_update_login        hz_cust_accounts.last_update_login%TYPE                      := -1;
   gn_request_id               hz_cust_accounts.request_id%TYPE                             := -1;
   gn_program_application_id   hz_cust_accounts.program_application_id%TYPE                 := -1;
   gn_created_by               hz_cust_accounts.created_by%TYPE                             := -1;
   gd_last_update_date         hz_cust_accounts.last_update_date%TYPE                       := SYSDATE;
   gn_program_id               hz_cust_accounts.program_id%TYPE                             := 1;
   gn_nextval                  NUMBER;
   gn_count                    NUMBER;
   gc_filename                 VARCHAR2 (200);
   gc_debug_flag               VARCHAR2 (2);
   gc_error_debug              VARCHAR2 (200);
   gc_compute_stats            VARCHAR2 (2);

-- +====================================================================+
-- |   Record Type Declaration                                          |
-- |                                                                    |
-- |   Name: Customer_master                                            |
-- +====================================================================+
   TYPE lr_customer_salesperson IS RECORD (
       cust_account_id           hz_cust_accounts.cust_account_id%TYPE 
      ,salesrep_number           jtf_rs_role_relations.attribute15%TYPE
      ,salesrep_name             jtf_rs_resource_extns.source_name%TYPE
      ,rep_email_address         jtf_rs_resource_extns.source_email%TYPE
      ,dsm_name                  xxtps_group_mbr_info_mv.c_resource_name%TYPE
      ,dsm_email_address         xxtps_group_mbr_info_mv.c_source_email%TYPE
      ,orig_system_reference     hz_cust_acct_sites_all.orig_system_reference%TYPE
      ,salesrep_id               jtf_rs_salesreps.salesrep_id%TYPE
      ,last_updated_by           hz_cust_accounts.last_updated_by%TYPE
      ,creation_date             hz_cust_accounts.creation_date%TYPE
      ,request_id                hz_cust_accounts.request_id%TYPE
      ,created_by                hz_cust_accounts.created_by%TYPE
      ,last_update_date          hz_cust_accounts.last_update_date%TYPE
      ,program_id                hz_cust_accounts.program_id%TYPE
   );

   --Table type declaration
   TYPE lt_cust_salesperson IS TABLE OF lr_customer_salesperson;
   
   TYPE lt_req_id IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE lt_file_names IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;   
   
--+=====================================================================+
--| Name       :  main                                                  |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_actiontype                                          |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
--|                                                                     |
--|                                                                     |
--|                                                                     |
--| Returns :   x_return_message                                        |
--|             x_return_code                                           |
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
PROCEDURE extract_stagedata
  (
     p_errbuf        OUT VARCHAR2
    ,p_retcode       OUT NUMBER
    ,p_debug_flag    IN  VARCHAR2
    ,p_compute_stats IN  VARCHAR2
  );

END xx_crm_cust_slsas_extract_pkg;
/
SHOW errors;