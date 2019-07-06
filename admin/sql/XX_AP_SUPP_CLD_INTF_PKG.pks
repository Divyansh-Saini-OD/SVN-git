SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_ap_supp_cld_intf_pkg
AS
  -- +=========================================================================+
  -- |                  Office Depot - Project Simplify                        |
  -- |                  Office Depot                                           |
  -- +=========================================================================+
  -- | Name             : XX_AP_SUPP_CLD_INTF_PKG                              |
  -- | Description      : This plsql package has procedure of interfacing      |
  -- |                    supplier information from oracle fusion cloud to EBS |
  -- |                                                                         |
  -- |Change Record:                                                           |
  -- |===============                                                          |
  -- |Version    Date          Author            Remarks                       |
  -- |=======    ==========    =============     ==============================|
  -- |    1.0    14-MAY-2019   Priyam Parmar       Initial code                |
  -- +=========================================================================+
  
  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gn_request_id               NUMBER         := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  gc_step                     VARCHAR2 (100) := '';
  gc_ascii                    VARCHAR2(10);
  gc_errbuf                   VARCHAR2(300):=NULL;
  gn_retcode                  NUMBER       :=0;
  gn_process_status_inprocess NUMBER       := '2';
  gn_process_status_error     NUMBER       := '3';
  gn_process_status_validated NUMBER       := '4';
  gn_process_status_loaded    NUMBER := '5';
  gn_process_status_imp_fail  NUMBER :='6';
  gn_process_status_imported  NUMBER :='7';
  g_process_status_new        VARCHAR2 (10) := 'NEW';
  gc_transaction_source       VARCHAR2 (20) := 'INTERFACE';
  gc_debug                    VARCHAR2 (1)  := 'N';
  gc_success                  VARCHAR2 (1)  := fnd_api.g_ret_sts_success;
  gc_error                    VARCHAR2 (1)  := fnd_api.g_ret_sts_error;
  gn_error_cnt                NUMBER        := 0;
  gc_error_status_flag        VARCHAR2 (2)  := 'N';
  gc_error_site_status_flag   VARCHAR2 (2)  := 'N';
  gc_process_cont_status_flag VARCHAR2 (2)  := 'N';
  g_ins_bus_class             VARCHAR2 (1);
  gc_org_id hr_operating_units.organization_id%TYPE;
  gc_error_msg VARCHAR2(4000);

  --=================================================================
  -- Declaring Global Constants
  --=================================================================
  g_package_name        CONSTANT VARCHAR2 (50)            := 'XX_AP_SUPP_CLD_INTF_PKG';
  g_sup_table           CONSTANT VARCHAR2 (30)            := 'XX_AP_CLD_SUPPLIERS_STG';
  g_sup_site_cont_table CONSTANT VARCHAR2 (30)            := 'XX_AP_CLD_SUPP_SITES_STG';
  g_sup_cont_table      CONSTANT VARCHAR2 (30)            := 'XX_AP_CLD_SUPP_CONTACT_STG';
  g_sup_bank_table      CONSTANT VARCHAR2 (30)            := 'XX_AP_CLD_SUPP_BNKACT_STG';
  g_user_id             NUMBER                            := fnd_global.user_id;
  G_LOGIN_ID            NUMBER                            := FND_GLOBAL.LOGIN_ID;
  gc_site_country_code ap_supplier_sites_all.COUNTRY%TYPE := 'US';
  gc_process_error_flag VARCHAR2(1)                       := 'E';
  
  --=================================================================
  -- Declaring Table Types
  --=================================================================
TYPE sup_stg_tab IS 	 TABLE OF xx_ap_supplier_stg%ROWTYPE INDEX BY BINARY_INTEGER;
TYPE supsite_stg_tab IS  TABLE OF xx_ap_supp_site_contact_stg%ROWTYPE INDEX BY BINARY_INTEGER;
TYPE number_tab IS  	 TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE char_tab IS  		 TABLE OF VARCHAR2 (30) INDEX BY BINARY_INTEGER;
TYPE rowid_tab IS   	 TABLE OF ROWID INDEX BY BINARY_INTEGER;
  
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
  PROCEDURE main_prc_supplier( x_errbuf OUT NOCOPY  VARCHAR2 ,
							   x_retcode OUT NOCOPY NUMBER 
							 );
  
  PROCEDURE main_prc_supplier_site( x_errbuf OUT NOCOPY  VARCHAR2 ,
									x_retcode OUT NOCOPY NUMBER 
								  );
  
  PROCEDURE main_prc_supplier_contact(x_errbuf OUT NOCOPY  VARCHAR2 ,
									  x_retcode OUT NOCOPY NUMBER 
									 );

  PROCEDURE main_prc_supplier_bank(x_errbuf OUT NOCOPY  VARCHAR2 ,
								   x_retcode OUT NOCOPY NUMBER 
								  );

  PROCEDURE XX_AP_SUPP_CLD_INTF(x_errbuf OUT nocopy  VARCHAR2 ,
								x_retcode OUT nocopy NUMBER ,
								p_debug_level IN VARCHAR2
 							   );
END XX_AP_SUPP_CLD_INTF_PKG;

/
SHOW ERROR;