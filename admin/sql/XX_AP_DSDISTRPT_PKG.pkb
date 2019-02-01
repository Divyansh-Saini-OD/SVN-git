SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
  
WHENEVER SQLERROR CONTINUE; 
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE BODY xx_ap_dsdistrpt_pkg IS
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

  -- +============================================================================================+
  -- |  Name  : beforereport                                                                      |
  -- |  Description: Before Report trigger function which will derive email details               |
  -- =============================================================================================|
    FUNCTION beforereport RETURN BOOLEAN
        IS
    BEGIN
        xx_ap_xml_bursting_pkg.get_email_detail ('XXAPDSDISTRPT', g_smtp_server, g_email_subject, g_email_content, g_distribution_list);
        RETURN true;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.log, 'ERROR at XX_AP_DSDISTRPT_PKG.beforeReport:- '
            || sqlerrm);
    END beforereport;

  -- +============================================================================================+
  -- |  Name  : afterreport                                                                       |
  -- |  Description: After Report trigger function which submit bursting concurrent program       |
  -- =============================================================================================|

    FUNCTION afterreport RETURN BOOLEAN IS
        l_request_id   NUMBER;
    BEGIN
        p_conc_request_id   := fnd_global.conc_request_id;
        fnd_file.put_line (fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
        l_request_id        := fnd_request.submit_request ('XDO', 'XDOBURSTREP', NULL, NULL, false, 'Y', p_conc_request_id, 'Y');

        fnd_file.put_line (fnd_file.log, 'Completed ');
        COMMIT;
        return (true);
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.log, 'Unable to submit burst request '
            || sqlerrm);
    END afterreport;

END xx_ap_dsdistrpt_pkg;
/

SHOW ERRORS;