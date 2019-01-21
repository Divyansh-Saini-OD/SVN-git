CREATE OR REPLACE PACKAGE xx_crm_cust_addr_extract_pkg
AS
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :XX_CRM_CUST_ADDR_EXTRACT_PKG                            |
--|RICE        :106313                                                  |
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
   gc_program_name             fnd_concurrent_programs_tl.USER_CONCURRENT_PROGRAM_NAME%TYPE   := 'OD: CRM Extract WC - Customer Addresses';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XX_CRM_CUST_ADDR_EXTRACT_PKG';
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
   gc_debug_flag               VARCHAR2 (2);
   gc_error_debug              VARCHAR2 (200);
   gc_compute_stats            VARCHAR2 (2);

-- +====================================================================+
-- |      Record Type Declaration                                       |
-- |                                                                    |
-- |   Name: Customer_master                                            |
-- +====================================================================+
   TYPE lr_customer_address IS RECORD (
      site_use_id                 hz_cust_site_uses_all.site_use_id%TYPE
     ,org_id                      hz_cust_acct_sites_all.org_id%TYPE
     ,cust_account_id             hz_cust_accounts.cust_account_id%TYPE
     ,address1                    hz_locations.address1%TYPE
     ,address2                    hz_locations.address2%TYPE
     ,address3                    hz_locations.address3%TYPE
     ,address4                    hz_locations.address4%TYPE
     ,postal_code                 hz_locations.postal_code%TYPE
     ,city                        hz_locations.city%TYPE
     ,state                       hz_locations.state%TYPE
     ,province                    hz_locations.province%TYPE
     ,country                     hz_locations.country%TYPE
     ,party_site_number           hz_party_sites.party_site_number%TYPE
     ,primary_flag                hz_cust_site_uses_all.primary_flag%TYPE
     ,SEQUENCE                    hz_party_sites.orig_system_reference%TYPE
     ,orig_system_reference       hz_party_sites.orig_system_reference%TYPE
     ,LOCATION                    hz_cust_site_uses_all.LOCATION%TYPE
     ,collector_number            ar_collectors.name%TYPE
     ,collector_name              ar_collectors.description%TYPE
     ,dunning_letters             hz_customer_profiles.dunning_letters%TYPE
     ,send_statements             hz_customer_profiles.send_statements%TYPE
     ,credit_limit_usd            hz_cust_profile_amts.overall_credit_limit%TYPE
     ,credit_limit_cad            hz_cust_profile_amts.overall_credit_limit%TYPE
     ,profile_class_name          hz_cust_profile_classes.NAME%TYPE
     ,consolidated_billing        hz_customer_profiles.cons_inv_flag%TYPE
     ,cons_billing_formats_type   hz_customer_profiles.cons_inv_type%TYPE
     ,bill_in_the_box             hz_cust_site_uses_all.attribute9%TYPE
     ,billing_currency            hz_cust_site_uses_all.attribute10%TYPE
     ,dunning_delivery            hz_cust_site_uses_all.attribute12%TYPE
     ,statement_delivery          hz_cust_site_uses_all.attribute18%TYPE
     ,taxware_entity_code         hz_cust_site_uses_all.attribute19%TYPE
     ,remit_to_sales_channel      hz_cust_site_uses_all.attribute25%TYPE
     ,edi_location                hz_cust_acct_sites_all.ece_tp_location_code%TYPE
     ,addressee                   hz_party_sites.addressee%TYPE
     ,identifying_address         hz_party_sites.identifying_address_flag%TYPE
     ,acct_site_status            hz_cust_acct_sites_all.status%TYPE
     ,site_use_status             hz_cust_site_uses_all.status%TYPE
     ,site_use_code               hz_cust_site_uses_all.site_use_code%TYPE
     ,last_updated_by             hz_cust_accounts.last_updated_by%TYPE
     ,creation_date               hz_cust_accounts.creation_date%TYPE
     ,request_id                  hz_cust_accounts.request_id%TYPE
     ,created_by                  hz_cust_accounts.created_by%TYPE
     ,last_update_date            hz_cust_accounts.last_update_date%TYPE
     ,program_id                  hz_cust_accounts.program_id%TYPE
   );

   --Table type declaration
   TYPE lt_cust_addr IS TABLE OF lr_customer_address;

   TYPE lt_req_id IS TABLE OF NUMBER
      INDEX BY BINARY_INTEGER;

   TYPE lt_file_names IS TABLE OF VARCHAR2 (200)
      INDEX BY BINARY_INTEGER;

--+=====================================================================+
--| Name       :  main                                                  |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_actiontype,                                         |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
--|                                                                     |
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

--End of XX_CRM_ADDR_EXTRACT_PKG package
END xx_crm_cust_addr_extract_pkg;
/

SHOW errors;