SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE XX_AP_IBY_PMNT_BATCH_PKG
AS
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                            Providge                                      |
  -- +==========================================================================+
  -- | Name             :    XX_AP_IBY_PMNT_BATCH_PKG                           |
  -- | Description      :    Package for AP Open Invoice Conversion             |
  -- | RICE ID          :    E1283                                              |
  -- |                                                                          |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version   Date         Author              Remarks                        |
  -- |=======   ===========  ================    ========================       |
  -- | 1.0      22-Jul-2013  Paddy Sanjeevi      Initial  
  --|  1.1      19-Mar-2018  Priyam Parmar     Changed for cut off date 
  -- +==========================================================================+
  PROCEDURE submit_eft_PROCESS(
      p_errbuf        IN OUT VARCHAR2 ,
      p_retcode       IN OUT NUMBER ,
      p_checkrun_id   IN NUMBER ,
      p_template_name IN VARCHAR2 ,
      p_payment_date  IN VARCHAR2 ,
      p_pay_thru_date IN VARCHAR2 ,
      p_pay_from_date IN VARCHAR2 ,
      p_email_id      IN VARCHAR2 ,
      p_output_format IN VARCHAR2 );
  PROCEDURE submit_ach_PROCESS(
      p_errbuf        IN OUT VARCHAR2 ,
      p_retcode       IN OUT NUMBER ,
      p_checkrun_id   IN NUMBER ,
      p_template_name IN VARCHAR2 ,
      p_payment_date  IN VARCHAR2 ,
      p_pay_thru_date IN VARCHAR2 ,
      p_pay_from_date IN VARCHAR2 );
  PROCEDURE submit_payment_PROCESS(
      p_errbuf        IN OUT VARCHAR2 ,
      p_retcode       IN OUT NUMBER ,
      p_checkrun_id   IN NUMBER ,
      p_template_name IN VARCHAR2 ,
      p_payment_date  IN VARCHAR2 ,
      p_pay_thru_date IN VARCHAR2 ,
      p_pay_from_date IN VARCHAR2 );
  PROCEDURE SUBMIT_APDM_REPORTS(
      x_error_buff OUT VARCHAR2 ,
      x_ret_code OUT NUMBER );
  PROCEDURE AP_TDM_FORMAT(
      x_ret_code OUT NUMBER);
  PROCEDURE SUBMIT_RTV_REPORTS(
      x_error_buff OUT VARCHAR2 ,
      X_RET_CODE OUT number );
  PROCEDURE submit_rtv_cons_reports(
      x_error_buff OUT VARCHAR2 ,
      x_ret_code out number);  
   ------Function added for cut off date
   
    FUNCTION CUTOFF_DATE_ELIGIBLE RETURN date;
END XX_AP_IBY_PMNT_BATCH_PKG;

/

SHOW ERROR