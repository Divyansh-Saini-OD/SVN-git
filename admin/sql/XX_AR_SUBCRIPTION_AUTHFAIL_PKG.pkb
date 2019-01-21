SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ar_subcription_authfail_pkg
AS
-- +============================================================================================+
-- |  Office Depot                                                                              |
-- +============================================================================================+
-- |  Name:  XX_AR_SUBCRIPTION_AUTHFAIL_PKG                                                     |
-- |                                                                                            |
-- |  Description:  This package is to used to Email Payment Authorization Report to the        |
-- |                 Vendors defined in the Translation                                         |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05-SEP-2018  PUNIT_CG         Initial version  for Defect# NAIT-50736          |
-- +============================================================================================+

  gc_package_name        CONSTANT all_objects.object_name%TYPE   := 'xx_ar_subcription_authfail_pkg';
  gc_max_log_size        CONSTANT NUMBER                         := 2000;
  gb_debug                        BOOLEAN                        := FALSE;

/***********************************************
 *  Setter procedure for gb_debug global variable
 *  used for controlling debugging
 ***********************************************/

  PROCEDURE set_debug(p_debug_flag  IN  VARCHAR2)
  IS
  BEGIN
    IF (UPPER(p_debug_flag) IN('Y', 'YES', 'T', 'TRUE'))
    THEN
      gb_debug := TRUE;
    END IF;
  END set_debug;
  
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_debug is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/

  PROCEDURE logit(p_message  IN  VARCHAR2,
                  p_debug    IN  BOOLEAN DEFAULT FALSE)
  IS
    lc_message  VARCHAR2(2000) := NULL;
  BEGIN
     IF (gb_debug)
    THEN
      lc_message := SUBSTR(TO_CHAR(SYSTIMESTAMP, 'MM/DD/YYYY HH24:MI:SS.FF')
                           || ' => ' || p_message, 1, gc_max_log_size);
      IF (fnd_global.conc_request_id > 0)
      THEN
        fnd_file.put_line(fnd_file.LOG, lc_message);
      END IF;
    END IF;
  EXCEPTION
      WHEN OTHERS
      THEN
          NULL;
  END logit;

  PROCEDURE email_authfail_rpt_vendor(errbuff       OUT VARCHAR2,
                                      retcode       OUT VARCHAR2,
                                      p_as_of_date  IN VARCHAR2,
                                      p_debug_flag  IN  VARCHAR2,
                                      p_send_email  IN VARCHAR2)
  AS
    CURSOR c_subscr_vendors
    IS

      SELECT DISTINCT
             XFTV.target_value1 VENDOR_NUM,
             XFTV.target_value2 EMAIL_ADDRESS
      FROM   xx_fin_translatedefinition XFTD,
             xx_fin_translatevalues XFTV,
             ap_suppliers APS,
             ap_supplier_sites_all ASSA
      WHERE  XFTD.translation_name     = 'XX_AR_SUBSCR_VENDORS'
      AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active, SYSDATE + 1)
      AND    XFTD.enabled_flag         = 'Y'
      AND    XFTD.translate_id         = XFTV.translate_id
      AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active, SYSDATE + 1)
      AND    XFTV.enabled_flag         = 'Y'
      AND    LPAD(ASSA.vendor_site_code_alt,LENGTH(ASSA.vendor_site_code_alt)+1,'0') = XFTV.target_value1
      AND    APS.vendor_id             = ASSA.vendor_id;

    lc_appln_shortname_in  fnd_application.application_short_name%TYPE          := 'XXFIN';
    lc_program_in          fnd_concurrent_programs.concurrent_program_name%TYPE := 'XXARSCBILLAUTHFAIL';
    lc_description_in      fnd_concurrent_programs_tl.description%type          := 'OD: Subscription Billing Auth Failures Report';
    ln_request_id          fnd_concurrent_requests.request_id%TYPE;
    lb_layout              BOOLEAN;
    ln_xmlburst_reqid      fnd_concurrent_requests.request_id%TYPE;
    lc_phase               fnd_lookups.meaning%TYPE;
    lc_status              fnd_lookups.meaning%TYPE;
    lc_dev_phase           fnd_lookups.meaning%TYPE;
    lc_dev_status          fnd_lookups.meaning%TYPE;
    lc_message             VARCHAR2(100);
    lb_req_return_status   BOOLEAN;
    lc_send_email          VARCHAR2(1);
    lc_procedure_name      CONSTANT VARCHAR2(61)                                := gc_package_name || '.' || 'email_authfail_rpt_vendor';
    lc_as_of_date          VARCHAR2(50);

  BEGIN
    set_debug(p_debug_flag => p_debug_flag);
    lc_as_of_date     := p_as_of_date;
    
    logit(p_message => '---------------------------------------------------',
          p_debug   => TRUE);
    logit(p_message => 'Starting EMAIL_AUTHFAIL_RPT_VENDOR routine. ',
          p_debug   => TRUE);
    logit(p_message => '---------------------------------------------------',
          p_debug   => TRUE);
    
    lc_send_email        := p_send_email;
      
    FOR subscr_vendors_rec IN c_subscr_vendors
    LOOP
      /***********************************************************
      * LOOP Through the Unique Vendors present in the Translation
      ************************************************************/
      logit(p_message => '-----------------------------------------------',
            p_debug   => TRUE);
      logit(p_message => 'Submitting request for adding layout for the program : ' || lc_description_in || ' for vendor #: ' || subscr_vendors_rec.vendor_num,
            p_debug   => TRUE);
      logit(p_message      => '-----------------------------------------------',
            p_debug   => TRUE);
      /************************************************
      * Submitting Request to add layout to the program
      *************************************************/
      lb_layout :=     fnd_request.add_layout(template_appl_name => lc_appln_shortname_in,
                                              template_code      => lc_program_in,
                                              template_language  => 'en',
                                              template_territory => 'US',
                                              output_format      => 'EXCEL');
      logit(p_message      => '-----------------------------------------------',
            p_debug   => TRUE);
      logit(p_message => 'Submitting program: ' || lc_description_in || ' for vendor #: ' || subscr_vendors_rec.vendor_num,
            p_debug   => TRUE);
      logit(p_message      => '-----------------------------------------------',
            p_debug   => TRUE);
     /************************************************************************************************
      * Submitting Request to call the Subscriptions Auth Failure Report Child Program for each vendor
      ************************************************************************************************/
      ln_request_id := fnd_request.submit_request(application => lc_appln_shortname_in,
                                                  program     => lc_program_in,
                                                  description => lc_description_in,
                                                  start_time  => TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                                                  sub_request => FALSE,
                                                  argument1   => lc_as_of_date,
                                                  argument2   => subscr_vendors_rec.vendor_num,
                                                  argument3   => subscr_vendors_rec.email_address);
      COMMIT;
      IF ln_request_id = 0 
      THEN
        logit(p_message      => '-----------------------------------------------',
              p_debug   => TRUE);
        logit(p_message => 'ERROR in program: ' || lc_description_in || ' for vendor #: ' || subscr_vendors_rec.vendor_num||' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
              p_debug   => TRUE);
        logit(p_message      => '-----------------------------------------------',
              p_debug   => TRUE);
          
        errbuff        := 'Conc. Program  failed to submit :' || lc_description_in;
        retcode        := 2;
        ELSE
          IF (ln_request_id > 0 AND lc_send_email = 'Y')
          THEN
           LOOP
           /************************************************************************************************************************
           * Loop through to wait for the Subscriptions Auth Failure Report Program to finish before submitting the Bursting Program
           *************************************************************************************************************************/
           lb_req_return_status := fnd_concurrent.wait_for_request(request_id      => ln_request_id,
                                                                   interval        => 10,
                                                                   max_wait        => 1200,
                                                                   phase           => lc_phase,
                                                                   status          => lc_status,
                                                                   dev_phase       => lc_dev_phase,
                                                                   dev_status      => lc_dev_status,
                                                                   message         => lc_message);
           EXIT
             WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
           END LOOP;
           IF UPPER (lc_phase) = 'COMPLETED' AND UPPER (lc_status) = 'NORMAL' 
           THEN
             logit(p_message      => '-----------------------------------------------',
                   p_debug   => TRUE);
             logit(p_message => 'Program :' || lc_description_in || ' for vendor: ' ||subscr_vendors_rec.vendor_num || ' with request id: ' || ln_request_id || ' completed successfully ',
                   p_debug   => TRUE);
             logit(p_message      => '-----------------------------------------------',
                   p_debug   => TRUE);
              BEGIN
              /**************************************************************
               * Submitting XML Bursting Program to send email to the vendors
               *************************************************************/
              ln_xmlburst_reqid := fnd_request.submit_request(application   => 'XDO',
                                                              program       => 'XDOBURSTREP',
                                                              description   => NULL,
                                                              start_time    => SYSDATE,
                                                              sub_request   => FALSE,
                                                              argument1     => 'Y',
                                                              argument2     => ln_request_id,
                                                              argument3     => 'Y');
              logit(p_message => '-----------------------------------------------',
                    p_debug   => TRUE);
              logit(p_message => 'Program : XML Report Bursting  for vendor: ' ||subscr_vendors_rec.vendor_num || ' submitted with request id: ' || ln_xmlburst_reqid,
                    p_debug   => TRUE);
              logit(p_message      => '-----------------------------------------------',
                    p_debug   => TRUE);
              COMMIT;
              EXCEPTION
              WHEN OTHERS 
              THEN
                logit(p_message => '-----------------------------------------------',
                      p_debug   => TRUE);
                logit(p_message => 'ERROR in XML Report Bursting program: for vendor #: '|| subscr_vendors_rec.vendor_num||' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
                      p_debug   => TRUE);
                logit(p_message      => '-----------------------------------------------',
                      p_debug   => TRUE);
                errbuff := 'Exception while Submitting the XML Bursting Program :' || '-' ||SQLCODE||SQLERRM;
                retcode := 2;
              END;
           END IF;
         END IF;
       END IF;
    END LOOP;
  EXCEPTION
  WHEN OTHERS
  THEN
    logit(p_message => '-----------------------------------------------',
          p_debug   => TRUE);
    logit(p_message => 'Exception while Submitting the Subscription Auth Failures Report Program ' || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM,
          p_debug   => TRUE);
    logit(p_message => '-----------------------------------------------',
          p_debug   => TRUE);
    RAISE_APPLICATION_ERROR(-20101, 'PROCEDURE: ' || lc_procedure_name || ' SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);

  END email_authfail_rpt_vendor;
  
END xx_ar_subcription_authfail_pkg;
/
SHOW ERRORS;
EXIT;