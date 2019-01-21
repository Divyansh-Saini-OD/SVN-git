CREATE OR REPLACE PACKAGE xx_crm_cust_elg_pkg
AS
--+===============================================================================+
--|      Office Depot - Project FIT                                               |
--|   Capgemini/Office Depot/Consulting Organization                              |
--+===============================================================================+
--|Name        :XX_CRM_CUST_ELG_PKG                                               |
--| BR #       :106313                                                            |
--|Description :This Package is for identifying eligble customers                 |
--|                                                                               |
--|            The Package Procedure will perform the following steps             |
--|                                                                               |
--|             1. Identify eligible customers based on business rules which are  |
--|                 a. All Active Account Billing Customers                       |
--|                 b. Customers with open Balance exluding internal              |
--|                 c. Parent Customers in hierarchy irrespective of status       |
--|                                                                               |
--|             2. Insert data into customer eligbility table                     |
--|                                                                               |
--|             3. Find records that have been updated since last run date.       |
--|                                                                               |
--|Change Record:                                                                 |
--|==============                                                                 |
--|Version    Date           Author                       Remarks                 |
--|=======   ======        ====================          =========                |
--|1.00     30-Aug-2011   Balakrishna Bolikonda      Initial Version              |
--+===============================================================================+

   --Global variable  declaration
   gd_last_update_date     hz_cust_accounts.last_update_date%TYPE                 := SYSDATE;
   gn_last_updated_by      hz_cust_accounts.last_updated_by%TYPE                  := NVL (fnd_profile.VALUE ('USER_ID'), -1);
   gd_creation_date        hz_cust_accounts.creation_date%TYPE                    := SYSDATE;
   gn_created_by           hz_cust_accounts.created_by%TYPE                       := NVL (fnd_profile.VALUE ('USER_ID'), -1);
   gn_request_id           hz_cust_accounts.request_id%TYPE                       := NVL (fnd_profile.VALUE ('REQUEST_ID'), -1);
   gn_program_id           hz_cust_accounts.program_id%TYPE                       := NVL (fnd_profile.VALUE ('PROGRAM_ID'), -1);
   gc_program_type         xx_com_error_log.program_type%TYPE                     := 'CONCURRENT PROGRAM';
   gc_program_name         xx_com_error_log.program_name%TYPE                     := 'OD: CRM Identify WC - Customer Eligibility';
   gc_program_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE   := 'XX_CRM_CUST_ELG_PKG';
   gc_module_name          xx_com_error_log.module_name%TYPE                      := 'XXCRM';
   gc_error_debug          VARCHAR2 (400)                                         := NULL;
   gc_debug_flag           VARCHAR2 (1);
   gc_compute_stats        VARCHAR2 (1);
   gn_nextval              NUMBER;

-- +==============================================================================+
-- |      Record Type Declaration                                                 |
-- |                                                                              |
-- |   Name: Record type for Eligible Customers                                   |
-- +===============================================================================+
   TYPE lr_cust_elg IS RECORD (
      party_id                hz_parties.party_id%TYPE
     ,cust_account_id         hz_cust_accounts.cust_account_id%TYPE
     ,account_number          hz_cust_accounts.account_number%TYPE
     ,int_source              VARCHAR2 (2)
     ,extraction_date         DATE
     ,cust_mast_head_ext      VARCHAR2 (1)
     ,cust_addr_ext           VARCHAR2 (1)
     ,cust_cont_ext           VARCHAR2 (1)
     ,cust_hier_ext           VARCHAR2 (1)
     ,sls_per_ext             VARCHAR2 (1)
     ,ar_converted_flag       VARCHAR2 (1)
     ,ar_conv_from_date_full  DATE
     ,ar_conv_from_to_full    DATE
     ,notes_processed_to_wc   VARCHAR2 (1)
     ,last_update_date        hz_cust_accounts.last_update_date%TYPE
     ,last_updated_by         hz_cust_accounts.last_updated_by%TYPE
     ,creation_date           hz_cust_accounts.creation_date%TYPE
     ,created_by              hz_cust_accounts.created_by%TYPE
     ,request_id              hz_cust_accounts.request_id%TYPE
     ,program_id              hz_cust_accounts.program_id%TYPE
   );

   TYPE lt_cust_elg IS TABLE OF lr_cust_elg;

--+=====================================================================+
--| Name       : main                                                   |
--| Description:                                                        |
--|                                                                     |
--| Parameters :  p_action_type                                         |
--|               p_last_run_date                                       |
--|               p_to_run_date                                         |
--|               p_sample_count                                        |
--|               p_debug_flag                                          |
--|               p_compute_stats                                       |
--|               p_batch_limit                                         |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE main (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_action_type     IN       VARCHAR2
     ,p_debug_flag      IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );

-- +====================================================================+
-- |   To find active AB customers                                      |
-- +====================================================================+
   PROCEDURE find_active_ab_cust (
      p_batch_limit    IN       NUMBER
     ,p_sample_count   IN       NUMBER
     ,p_retcode        OUT      NUMBER
   );

-- +===============================================================================+
-- | To find customers that have open balance excluding internal customers         |
-- +===============================================================================+
   PROCEDURE find_open_balance (
      p_batch_limit    IN       NUMBER
     ,p_sample_count   IN       NUMBER
     ,p_retcode        OUT      NUMBER
   );

-- +===============================================================================+
-- | To find new Account Billing Customers that have been added                    |
-- +===============================================================================+
   PROCEDURE find_new_AB (
      p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_retcode         OUT      NUMBER
   );

-- +===============================================================================+
-- | To find Active Parents for the hierarchy                                      |
-- +===============================================================================+
   PROCEDURE find_cust_hierarchy (
      p_last_run_date   IN       VARCHAR2
     ,p_to_run_date     IN       VARCHAR2
     ,p_batch_limit     IN       NUMBER
     ,p_sample_count    IN       NUMBER
     ,p_action          IN       VARCHAR2
     ,p_retcode         OUT      NUMBER
   );

-- +===============================================================================+
-- | To get the from and to dates from log table                                   |
-- +===============================================================================+
   PROCEDURE from_to_date (
      p_from_date   OUT   VARCHAR2
     ,p_to_date     OUT   VARCHAR2
     ,p_retcode     OUT   NUMBER
   );

PROCEDURE sp_daily_cdh_report (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
   );

END xx_crm_cust_elg_pkg;
/

SHOW ERROR