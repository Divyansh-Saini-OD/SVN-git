SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE; 
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE xx_ap_dsdistrpt_pkg IS
  -- +============================================================================================|
  -- |  Office Depot                                                                              |
  -- +============================================================================================|
  -- |  Name:  XX_AP_DSDISTRPT_PKG                                                                |
  -- |                                                                                            |
  -- |  Description: Package for OD: AP Dropship Distributions Report                             |
  -- |  RICE ID   : R7049 Dropship Distributions Report                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================|
  -- | Version     Date         Author               Remarks                                      |
  -- | =========   ===========  =============        =============================================|
  -- | 1.0         28-JAN-2019  Naveen Srinivasa     Initial Version                              |
  -- +============================================================================================|

    FUNCTION beforereport RETURN BOOLEAN;

    FUNCTION afterreport RETURN BOOLEAN;

    PROCEDURE extract_data (
        x_errbuf            OUT NOCOPY VARCHAR2
      , x_retcode           OUT NOCOPY NUMBER
      , p_period            IN VARCHAR2
    );    
    
    g_smtp_server         VARCHAR2 (250);
    g_distribution_list   VARCHAR2 (500);
    g_email_subject       VARCHAR2 (250);
    g_email_content       VARCHAR2 (500);
    p_conc_request_id     NUMBER;
    p_vendor_site_id      VARCHAR2(250);
    p_period_from         VARCHAR2(250);
    p_period_to           VARCHAR2(250);
    p_gl_date_from        VARCHAR2(250);
    p_gl_date_to          VARCHAR2(250);
    p_from_clause         VARCHAR2(4000);
    p_where_clause        VARCHAR2(4000);
END xx_ap_dsdistrpt_pkg;
/

SHOW ERRORS;