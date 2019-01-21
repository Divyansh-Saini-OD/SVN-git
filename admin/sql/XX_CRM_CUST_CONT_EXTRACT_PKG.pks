create or replace 
PACKAGE xx_crm_cust_cont_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        : XX_CRM_CUST_CONT_EXTRACT_PKG                           |
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
   gc_program_name             fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE   := 'OD: CRM Extract WC - Customer Contacts and Contact Points';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XX_CRM_CUST_CONT_EXTRACT_PKG';
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
   gc_debug_flag               VARCHAR2 (2);
   gc_compute_stats            VARCHAR2 (2);

-- +====================================================================+
-- |   Record Type Declaration                                          |
-- |                                                                    |
-- |   Name: Customer_master                                            |
-- +====================================================================+
   TYPE lr_customer_contacts IS RECORD (
      cont_osr                hz_org_contacts.orig_system_reference%type
     ,cust_account_id         hz_cust_accounts.cust_account_id%TYPE
     ,site_use_id             hz_cust_site_uses_all.site_use_id%TYPE
     ,contact_number          hz_org_contacts.contact_number%TYPE
     ,last_name               hz_parties.person_last_name%TYPE
     ,first_name              hz_parties.person_first_name%TYPE
     ,job_title               hz_org_contacts.job_title%TYPE
     ,email_address           hz_parties.email_address%TYPE
     ,cont_point_purpose      hz_contact_points.contact_point_purpose%TYPE
     ,cont_point_primary_flag hz_cust_account_roles.primary_flag%TYPE
     ,contact_role_primary_flag  hz_contact_points.primary_flag%TYPE
     ,contact_point_type     hz_contact_points.contact_point_type%TYPE
     ,phone_line_type        hz_contact_points.phone_line_type%TYPE
     ,country_code           hz_contact_points.phone_country_code%TYPE
     ,area_code              hz_contact_points.phone_area_code%TYPE
     ,phone_number           hz_contact_points.phone_number%TYPE
     ,extension              hz_contact_points.phone_extension%TYPE
     ,site_osr               HZ_CUST_ACCT_SITES_ALL.orig_system_reference%type
     ,cont_point_osr         hz_contact_points.orig_system_reference%type
     ,last_updated_by        hz_cust_accounts.last_updated_by%TYPE
     ,creation_date          hz_cust_accounts.creation_date%TYPE
     ,request_id             hz_cust_accounts.request_id%TYPE
     ,created_by             hz_cust_accounts.created_by%TYPE
     ,last_update_date       hz_cust_accounts.last_update_date%TYPE
     ,program_id             hz_cust_accounts.program_id%TYPE
   );

   --Table type declaration
   TYPE lt_cust_contacts IS TABLE OF lr_customer_contacts;

   TYPE lt_req_id IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE lt_file_names IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;

--+=====================================================================+
--| Name       : main                                                   |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_actiontype                                          |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
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
   PROCEDURE extract_stagedata (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );
   
    PROCEDURE insert_incrdata_child (
      p_errbuf    OUT NOCOPY      VARCHAR2,
      p_retcode   OUT NOCOPY      VARCHAR2,
      p_in_low    IN              NUMBER,
      p_in_high   IN              NUMBER
   );
   
   
END xx_crm_cust_cont_extract_pkg;
/
show errors;