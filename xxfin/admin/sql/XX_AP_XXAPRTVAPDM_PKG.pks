SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE XX_AP_XXAPRTVAPDM_PKG
  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_AP_XXAPRTVAPDM_PKG.pkb                 |
  -- | Description :  Plsql package for XXAPRTVAPDM Report               |
  -- |                Created this package to avoid using dblinks in rdf |
  -- | RICE ID     :  R1050                                              |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |1.0       29-Apr-2013 Paddy Sanjeevi     Initial version           |
  -- |                                         Defect 23208              |
  -- |1.1       28-May-2013 Paddy Sanjeevi     Modified column mapping   |
  -- |1.2       31-May-2013 Paddy Sanjeevi     Modified to add cursor in
  -- |
  -- |                                         the procedure CF_voucher_num1
  -- |
  -- |1.3       28-Jun-2013 Paddy Sanjeevi     Added TRIM in cf_VendorProduct
  -- |
  -- |1.4       06-Jul-2013 Paddy Sanjeevi     Added TRIM in cf_legacy_inv_num
  -- |
  -- |1.5       06-Jul-2013 Paddy Sanjeevi     Added TRIM in
  -- CF_FreightBillFormula|
  -- |1.6       19-AUG-2017 Digamber S     Added p_source   column in all
  -- procedures and functions to resolve the data source Legacy or EBiz
  -- |1.7       12-APR-2018 Digamber S     Added new function before_report_trigger_c
  --                                       for new RTV APDM consolidation report
  -- +=========================================================================
AS
  FUNCTION get_inv_status(
      p_invoice_id NUMBER)
    RETURN VARCHAR2;
  PROCEDURE get_invoice_batch(
      p_batch_name VARCHAR2);
  PROCEDURE BEFORE_REPORT_TRIGGER_C(
      P_REQUEST_ID NUMBER,
      P_COUNTRY    VARCHAR2,
      --P_VENDOR_ID  NUMBER,
      P_RTV_NUMBER NUMBER,
      P_BATCH_NAME VARCHAR2);
  PROCEDURE BEFORE_REPORT_TRIGGER(
      p_request_id NUMBER,
      p_country    VARCHAR2,
      p_vendor_id  NUMBER,
      P_batch_name VARCHAR2);
  PROCEDURE G_RTV_layoutGroupFilter(
      p_source         IN VARCHAR2 ,
      p_vendor_site_id IN NUMBER ,
      p_country_cd     IN VARCHAR2 ,
      p_legacy_o OUT NUMBER ,
      p_vendor_prefix_o OUT VARCHAR2 );
  FUNCTION CF_worksheetnoFormula(
      p_source        IN VARCHAR2 ,
      p_rtv_nbr       IN NUMBER ,
      p_legacy_loc_id IN NUMBER ,
      p_sku           IN NUMBER ,
      p_invoice_nbr   IN VARCHAR2 )
    RETURN NUMBER;
  FUNCTION CF_voucher_num1Formula(
      p_source      IN VARCHAR2 ,
      p_voucher_nbr IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION CF_VendorProductFormula(
      p_source      IN VARCHAR2 ,
      p_country_cd  IN VARCHAR2 ,
      p_sku         IN NUMBER ,
      p_vendor_id   IN NUMBER,
      p_invoice_nbr IN VARCHAR2 )
    RETURN VARCHAR2;
  FUNCTION CF_rtv_nbrFormula(
      p_source      IN VARCHAR2 ,
      p_voucher_nbr IN VARCHAR2 ,
      p_ap_company  IN VARCHAR2 ,
      p_vendor      IN VARCHAR2 ,
      p_invoice_nbr IN VARCHAR2 )
    RETURN VARCHAR2;
  FUNCTION CF_legacy_loc_idFormula(
      p_source      IN VARCHAR2 ,
      p_voucher_nbr IN VARCHAR2 ,
      p_vendor      IN VARCHAR2 ,
      p_invoice_nbr IN VARCHAR2 )
    RETURN VARCHAR2;
  FUNCTION CF_legacy_inv_numFormula(
      p_source      IN VARCHAR2 ,
      p_voucher_nbr IN VARCHAR2 ,
      p_ap_company  IN VARCHAR2 ,
      p_vendor      IN VARCHAR2 ,
      p_invoice_nbr IN VARCHAR2 )
    RETURN VARCHAR2;
  FUNCTION CF_gstFormula(
      p_source         IN VARCHAR2 ,
      p_vendor_site_id IN NUMBER,
      p_country_cd     IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION CF_Freight_carrierFormula(
      p_source      IN VARCHAR2 ,
      p_carrier_id  IN NUMBER,
      p_invoice_nbr IN VARCHAR2)
    RETURN VARCHAR2;
  FUNCTION CF_DeptFormula(
      p_sku       IN NUMBER,
      p_vendor_id IN NUMBER)
    RETURN NUMBER;
  PROCEDURE CF_FreightBillFormula(
      p_source        IN VARCHAR2 ,
      p_voucher_nbr   IN VARCHAR2,
      p_invoice_nbr   IN VARCHAR2,
      p_rtv_nbr       IN NUMBER ,
      p_legacy_loc_id IN NUMBER ,
      p_carrier_id    IN NUMBER ,
      p_frightbill_o OUT VARCHAR2 );
  PROCEDURE CF_Disposition_Code(
      p_source         IN VARCHAR2 ,
      p_invoice_nbr    IN VARCHAR2,
      p_rtv_nbr        IN NUMBER ,
      p_legacy_loc_id  IN NUMBER ,
      p_vendor_site_id IN NUMBER ,
      p_country_cd     IN VARCHAR2 ,
      p_reason_cd_o OUT VARCHAR2 ,
      p_rga_nbr_o OUT VARCHAR2 ,
      p_carrier_id_o OUT NUMBER ,
      p_ship_name_o OUT VARCHAR2 ,
      p_ship_addr_line_1_o OUT VARCHAR2 ,
      p_ship_addr_line_2_o OUT VARCHAR2 ,
      p_ship_city_o OUT VARCHAR2 ,
      p_ship_state_o OUT VARCHAR2 ,
      p_ship_zip_o OUT VARCHAR2 ,
      p_ship_country_cd_o OUT VARCHAR2 ,
      p_cont_rga_flg_o OUT VARCHAR2 ,
      p_rtv_rga_o OUT VARCHAR2 ,
      p_fax_dd_wrksht_flg_o OUT VARCHAR2 ,
      p_cont_destroy_flg_o OUT VARCHAR2 ,
      P_RTV_DESTROY_RGA_O OUT VARCHAR2 );
TYPE RECORD_LEGACYDB2
IS
  RECORD
  (
    VOUCHER_NBR   VARCHAR2(100) ,
    PRODUCT_DESCR VARCHAR2(250) ,
    GROSS_AMT     NUMBER,
    rtv_quantity  NUMBER,
    SERIAL_NUMBER VARCHAR2(50) ,
    SKU           VARCHAR2(250),
    DEPARTMENT    VARCHAR2(50),
    AP_COMPANY    VARCHAR2(50));
TYPE RECORD_LEGACYDB2_CTT
IS
  TABLE OF XX_AP_XXAPRTVAPDM_PKG.RECORD_LEGACYDB2;
  FUNCTION XX_AP_LEGACYDB2(
      P_VENDOR_SITE_ID NUMBER)
    RETURN XX_AP_XXAPRTVAPDM_PKG.RECORD_LEGACYDB2_CTT pipelined;
END;
/

SHOW ERRORS;