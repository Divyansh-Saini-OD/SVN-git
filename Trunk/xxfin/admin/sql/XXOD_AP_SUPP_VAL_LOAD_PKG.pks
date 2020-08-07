SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating Package  XXOD_AP_SUPP_VAL_LOAD_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XXAP_OFCMAX_SUPP_VAL_LOAD_PKG                        |
-- | Description      : This Program will do validations and load vendors to iface table from   |
-- |                    stagging table                                       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    14-JAN-2015   Madhu Bolli       Initial code                  |
-- |    1.1    14-JAN-2015   Amar Modium       Post Update procedures        |
-- |    1.2    02-Feb-2015   Madhu Bolli       Fixed the issues resulted in SIT |
-- +=========================================================================+

create or replace
PACKAGE  XXOD_AP_SUPP_VAL_LOAD_PKG AS

  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gn_request_id NUMBER         := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  gc_step       VARCHAR2 (100) := '';
  gc_ascii      VARCHAR2(10);
  gc_errbuf     VARCHAR2(300):=NULL;
  gn_retcode    NUMBER       :=0;
  gn_process_status_inprocess NUMBER        := '2';
  gn_process_status_error     NUMBER        := '3';
  gn_process_status_validated  NUMBER       := '35';
  --gn_process_status_processed  NUMBER       := '38';
  gn_process_status_loaded    NUMBER        := '4';
  g_process_status_new          VARCHAR2 (10) := 'NEW';
  gc_transaction_source       VARCHAR2 (20) := 'INTERFACE';
  gc_debug                    VARCHAR2 (1)  := 'N';
  gc_success                  VARCHAR2 (1)  := fnd_api.g_ret_sts_success;
  gc_error                    VARCHAR2 (1)  := fnd_api.g_ret_sts_error;
  gn_error_cnt                NUMBER        := 0;
  gc_error_status_flag        VARCHAR2 (2)  := 'N';
  gc_error_site_status_flag   VARCHAR2 (2)  := 'N';
  gc_process_cont_status_flag VARCHAR2 (2)  := 'N';
  
  g_ins_bus_class             VARCHAR2 (1);
  
  
  gc_org_id hr_operating_units.organization_id%Type;
  gc_error_msg                VARCHAR2(4000);
  --=================================================================
  -- Declaring Global Constants
  --=================================================================
  g_package_name        CONSTANT VARCHAR2 (50) := 'XXOD_AP_SUPP_VAL_LOAD_PKG';
  g_sup_table           CONSTANT VARCHAR2 (30) := 'XX_AP_SUPPLIER_STG';
  g_sup_site_cont_table CONSTANT VARCHAR2 (30) := 'XX_AP_SUPP_SITE_CONTACT_STG';
  g_user_id             NUMBER                 := fnd_global.user_id;
  g_login_id            NUMBER                 := fnd_global.login_id;
  
  gc_site_country_code        ap_supplier_sites_all.COUNTRY%TYPE := 'US';
  gc_process_error_flag       VARCHAR2(1)   := 'E';    
  --=================================================================
  -- Declaring Table Types
  --=================================================================
  TYPE sup_stg_tab
  IS
    TABLE OF xx_ap_supplier_stg%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE supsite_stg_tab
  IS
    TABLE OF xx_ap_supp_site_contact_stg%ROWTYPE INDEX BY BINARY_INTEGER;
  TYPE number_tab
  IS
    TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  TYPE char_tab
  IS
    TABLE OF VARCHAR2 (30) INDEX BY BINARY_INTEGER;
  TYPE rowid_tab
  IS
    TABLE OF ROWID INDEX BY BINARY_INTEGER;

    
--+============================================================================+
--| Name          : main                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Interface                                    |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |        
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
   PROCEDURE main_prc (
      x_errbuf                   OUT NOCOPY VARCHAR2
     ,x_retcode                  OUT NOCOPY NUMBER
     ,p_reset_flag               IN       VARCHAR2
     ,p_debug_level              IN       VARCHAR2
   );


  --+============================================================================+
  --| Name          : reset_stage_tables                                          |
  --| Description   : This procedure will delete all records from below 2 staging tables|
  --|                 XX_AP_SUPPLIER_STG and  XX_AP_SUPP_SITE_CONTACT_STG        |
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+                                    -
   PROCEDURE reset_stage_tables(x_ret_code OUT NUMBER
            ,x_return_status   OUT VARCHAR2
            ,x_err_buf OUT VARCHAR2
    );

  --+============================================================================+
  --| Name          : post_update_main_prc                                       |
  --| Description   : This procedure will do post update                         |
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+    
  PROCEDURE post_update_main_prc(x_errbuf   OUT NOCOPY VARCHAR2
                                ,x_retcode  OUT NOCOPY NUMBER);    

END XXOD_AP_SUPP_VAL_LOAD_PKG;
/
SHOW ERRORS;