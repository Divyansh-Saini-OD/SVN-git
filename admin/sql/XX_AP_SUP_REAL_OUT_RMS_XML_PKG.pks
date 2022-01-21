SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_INV_TRADE_DASHBOARD_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE


create or replace 
PACKAGE XX_AP_SUP_REAL_OUT_RMS_XML_PKG
AS
  -- +============================================================================================+
  --   Office Depot - Project Simplify
  --
  -- +============================================================================================+
  --   Name        : XX_AP_SUP_REAL_OUT_RMS_XML_PKG
  --   RICE ID     : I0380 Supplier_TDM_Realtime_Datalink_Outbound_Interface
  --   Solution ID :
  --   Description : IDMS Outbound Integration For RMS in XML format
  --   Change Record
  -- +============================================================================================+
  --  Version     Date         Author           Remarks
  --  =========   ===========  =============    ===============================================
  --  1.0         15-Nov-17    Sunil Kalal       Initial version
  -- +============================================================================================+
  ------------------------------------------------------------
  ------------------------------------------------------------
  retcode varchar2(10) :=0;
  PROCEDURE xx_ap_sup_addr_type_id_update(
      errbuf out varchar2,
      retcode OUT VARCHAR2 );
  PROCEDURE xx_ap_supp_traits_id_update(
      errbuf out varchar2,
      retcode OUT VARCHAR2 );
  PROCEDURE xx_ap_supp_addl_attri_sqlldr(
      errbuf OUT VARCHAR2,
      retcode OUT VARCHAR2 );
  FUNCTION xx_ap_addr_update_allowed(
      p_address_type_id NUMBER)
    RETURN VARCHAR2;
  PROCEDURE xx_ap_supp_rms_update_telex(
      v_vendor_site_id IN NUMBER,
      v_error_message OUT VARCHAR2);
  PROCEDURE xx_ap_supp_out_track(
      v_transaction_id       IN NUMBER,
      v_globalvendor_id      IN NUMBER ,
      v_name                 IN VARCHAR2,
      v_vendor_site_id       IN NUMBER,
      v_vendor_site_code     IN VARCHAR2,
      v_site_orgid           IN NUMBER ,
      v_user_id              IN VARCHAR2,
      v_user_name            IN VARCHAR2,
      v_xml_output           IN CLOB,
      v_request_id           IN NUMBER,
      v_response_status_code IN VARCHAR2,
      v_response_reason      IN VARCHAR2,
      v_error_message OUT VARCHAR2 );
  PROCEDURE xx_ap_supp_real_out_rms_xml(
      errbuf OUT VARCHAR2,
      retcode OUT VARCHAR2 );
END XX_AP_SUP_REAL_OUT_RMS_XML_PKG;
/
show error

