CREATE OR REPLACE PACKAGE xx_crm_wc_cust_inbound_pkg
--+=====================================================================+
--|      Office Depot - Project FIT                                     |
--|   Capgemini/Office Depot/Consulting Organization                    |
--+=====================================================================+
--|Name        :XX_CRM_WC_CUST_INBOUND_PKG                              |
--|RICE        :106313                                                  |
--|Description : This package is used for getting the data from         |
--|              webcollet and insert date into Oracle Stage tables     |
--|                                                                     |
--|                                                                     |
--|Change Record:                                                       |
--|==============                                                       |
--|Version    Date           Author                       Remarks       |
--|=======   ======        ====================          =========      |
--|1.00     28-Nov-2011   Balakrishna Bolikonda      Initial Version    |
--|1.1      22-May-2012   Jay Gupta              Defect 18387 - Add     |
--|                                             Request_id in LOG tables|
--+=====================================================================+
AS
   --Global variable declaration
   gc_module_name              fnd_application_tl.application_name%TYPE                       := 'XXCRM';
   gc_program_name             fnd_concurrent_programs_tl.USER_CONCURRENT_PROGRAM_NAME%TYPE   := 'OD: WC to Oracle CDH - Inbound - Customer Contacts and Collector Assignment Program';
   gc_program_short_name       fnd_concurrent_programs.concurrent_program_name%TYPE           := 'XX_CRM_WC_CUST_INBOUND_PKG';
   gn_last_updated_by          hz_cust_accounts.last_updated_by%TYPE                          := -1;
   gd_creation_date            hz_cust_accounts.creation_date%TYPE                            := SYSDATE;
   gn_last_update_login        hz_cust_accounts.last_update_login%TYPE                        := -1;
   gn_request_id               hz_cust_accounts.request_id%TYPE                               := FND_GLOBAL.CONC_REQUEST_ID; --V1.1 --  '-1';
   gn_program_application_id   hz_cust_accounts.program_application_id%TYPE                   := -1;
   gn_created_by               hz_cust_accounts.created_by%TYPE                               := -1;
   gd_last_update_date         hz_cust_accounts.last_update_date%TYPE                         := SYSDATE;
   gn_program_id               hz_cust_accounts.program_id%TYPE                               := 1;
   gc_error_debug              VARCHAR2 (200);
   gc_debug_flag               VARCHAR2 (2);
   gc_compute_stats            VARCHAR2 (2);
   gn_nextval                  NUMBER;

   --Table type declaration
   TYPE lt_file_names IS TABLE OF VARCHAR2 (100)
      INDEX BY BINARY_INTEGER;

--+=====================================================================+
--| Name       :  ins_int_log                                           |
--| Description:  This procedure is used to insert the file entries     |
--|               int log table                                         |
--| Parameters :  p_file_name                                           |
--|               p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE ins_int_log (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_file_name       IN       VARCHAR2
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );

--+=====================================================================+
--| Name       :  read_file_ins_int                                     |
--| Description:  This procedure is used to read the file from IN       |
--|               directory and to insert into custom interface table   |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
--   PROCEDURE read_file_ins_int (
--      p_errbuf          OUT      VARCHAR2
--     ,p_retcode         OUT      NUMBER
--     ,p_debug           IN       VARCHAR2
--     ,p_compute_stats   IN       VARCHAR2
--   );

--+=====================================================================+
--| Name       :  load_cint_extng_int                                   |
--| Description: This procedure is used Load data from custom interface |
--|               table into existing customer conversion interface     |
--|               tables                                                |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE load_cint_extng_int (
      p_errbuf          OUT      VARCHAR2
     ,p_retcode         OUT      NUMBER
     ,p_debug           IN       VARCHAR2
     ,p_compute_stats   IN       VARCHAR2
   );

--+=====================================================================+
--| Name       :  collector_errors                                      |
--| Description:  This procedure is used send the notification for      |
--|               Collector errors                                      |
--| Parameters :  p_collectors_dl_name                                  |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE collector_errors (
      p_errbuf               OUT      VARCHAR2
     ,p_retcode              OUT      NUMBER
    -- ,p_collectors_dl_name   IN       VARCHAR2
   );

--+=====================================================================+
--| Name       :  contact_errors                                        |
--| Description:  This procedure is used send the notification for      |
--|               Contact errors                                        |
--| Parameters :  p_contacts_dl_name                                    |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE contact_errors (
      p_errbuf             OUT      VARCHAR2
     ,p_retcode            OUT      NUMBER
    -- ,p_contacts_dl_name   IN       VARCHAR2
   );

--+=====================================================================+
--| Name       :  validate_data                                         |
--| Description:  This procedure is used to validate the data after     |
--|                processing all records, to check whether all records |
--|                are processed or not                                 |
--| Parameters :  p_debug                                               |
--|               p_compute_stats                                       |
--|                                                                     |
--| Returns :     p_errbuf                                              |
--|               p_retcode                                             |
--|                                                                     |
--+=====================================================================+
   PROCEDURE validate_data (
      p_errbuf    OUT      VARCHAR2
     ,p_retcode   OUT      NUMBER
     ,p_debug     IN       VARCHAR2
   );

      PROCEDURE copy_file (
	p_sourcepath IN VARCHAR2
	,p_destpath IN VARCHAR2
	);

--End of XX_CRM_WC_CUST_INBOUND_PKG package
END xx_crm_wc_cust_inbound_pkg;
/

SHOW errors;