CREATE OR REPLACE PACKAGE XX_AP_SUA_PMNT_INTF_PKG
AS
  -- +=========================================================================+
  -- |                  Office Depot - Project Simplify                        |
  -- |                  Office Depot                                           |
  -- +=========================================================================+
  -- | Name             : XX_AP_SUA_PMNT_INTF_PKG                              |
  -- | Description      : This plsql package has procedure processing          |
  -- |                    SUA Payments to JPM                                  |
  -- |                                                                         |
  -- |Change Record:                                                           |
  -- |===============                                                          |
  -- |Version    Date          Author            Remarks                       |
  -- |=======  ==========    =============     ==============================  |
  -- | 1.0      25-JAN-2021   Paddy Sanjeevi    Initial code                   |
  -- | 1.1      03-FEB-2021   Mayur Palsokar    Modified submit_payment_process|
  -- | 1.2      03-FEB-2021   Manjush D H       Added load_recon_data          |
  -- | 1.3      12-FEB-2021   Mayur Palsokar    Added process_recon_data       |
  -- +=========================================================================+
  
  --=================================================================
  -- Declaring Global variables
  --=================================================================
  gn_request_id   NUMBER       := NVL(FND_GLOBAL.CONC_REQUEST_ID,-1);
  gc_errbuf       VARCHAR2(300):=NULL;
  gn_retcode      NUMBER       :=0;
  gc_error_msg    VARCHAR2(4000);
  gc_package_name VARCHAR2(50):= 'XX_AP_SUA_PMNT_INTF_PKG';
  gc_debug        VARCHAR2(5);
  
  PROCEDURE submit_payment_process(
      p_errbuf        IN OUT VARCHAR2 ,
      p_retcode       IN OUT NUMBER ,
      p_template_name IN VARCHAR2 ,
      p_payment_date  IN VARCHAR2 ,
      p_pay_from_date IN VARCHAR2 ,
      p_pay_thru_date IN VARCHAR2 );
	  
  PROCEDURE load_recon_data(
      p_file_name    VARCHAR2,
      p_debug_flag   VARCHAR2,
      p_request_id   NUMBER,
      p_user_id      NUMBER );
	  
  PROCEDURE process_recon_data(
      p_errbuf  IN OUT VARCHAR2 ,
      p_retcode IN OUT NUMBER );
	  
END XX_AP_SUA_PMNT_INTF_PKG;
/
show errors;
exit;