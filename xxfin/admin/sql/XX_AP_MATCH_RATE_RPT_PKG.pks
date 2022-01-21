SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE xx_ap_match_rate_rpt_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name      :  xx_ap_match_rate_rpt_pkg                                                          |
  -- |  RICE ID   :  E3523 AP Match Rate Dashboard                                            |
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:   
  -- |  Rice Id: E3523
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-dec-2017   Priyam P       Initial version
  -- |  1.1         19-APR-2018   Digamber Somvanshi Code changed for DEFECT NAIT-37732
  ---|  1.2         24-May-18       Priyam Parmar   Code changed for Defect NAIT-29696
  ---|  1.3         10-JUN-18     Priyam Parmar     Code change for Performance tunning.
  -- +============================================================================================+
TYPE match_rate_db
IS
  Record
  (
    CRITERIA            VARCHAR2(50),
    RUN_DATE            DATE,
    TOTAL_INV_CNT       NUMBER,
    TOTAL_SYS_MATCH_CNT NUMBER,
    match_rate          NUMBER);
TYPE match_rate_db_ctt
IS
  TABLE OF xx_ap_match_rate_rpt_pkg.match_rate_db;
  FUNCTION xx_ap_match_rate_rpt_pipe(
      p_date_from  DATE ,
      P_DATE_TO    DATE ,
      P_PO_TYPE    VARCHAR2,
      P_MATCH_TYPE VARCHAR2,
      P_OU_NAME    VARCHAR2)
    RETURN XX_AP_MATCH_RATE_RPT_PKG.MATCH_RATE_DB_CTT PIPELINED;
  PROCEDURE XX_AP_INSERT_INV_MATCH_DETAIL(
      ERRBUF OUT VARCHAR2,
      RETCODE OUT VARCHAR2,
      p_date DATE);
  PROCEDURE XX_AP_INSERT_INV_MATCH_SUMMARY(
      p_date DATE);
  PROCEDURE xx_ap_release_by(
      p_invoice_id IN NUMBER,
      p_invoice_creation_date DATE,
      p_invoice_num           VARCHAR2,
      p_vendor_id             NUMBER,
      p_vendor_site_id        NUMBER,
      p_match_criteria  IN VARCHAR2,
      p_validation_flag IN VARCHAR2,
      p_appsmgr         IN NUMBER,
      p_svc_esp_fin     IN NUMBER,
      p_svc_esp_vps     IN NUMBER,
      p_rel_by OUT VARCHAR2,
      p_rel_date OUT DATE,
      p_hold_last_update_date out date,
      p_hold_last_updated_by OUT VARCHAR2,
      p_hold_count out number );
  PROCEDURE xx_ap_upd_inv_detail_firstpass(
      p_date in date);
      
   procedure xx_ap_upd_inv_detail_truematch(
      p_date in date);
  procedure xx_ap_upd_matched_by_firstpass(
      p_date in date);
    procedure xx_ap_upd_matched_by_truematch(
      p_date IN DATE);    
-- P_DATE DATE
  /* FUNCTION get_matched_by(
  p_invoice_id NUMBER)
  RETURN VARCHAR2;
  FUNCTION get_release_date(
      p_invoice_id NUMBER)
    return date;*/

END xx_ap_match_rate_rpt_pkg;

/
SHOW ERROR;