SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_XXAPCHBKAPDM_PKG

create or replace 
PACKAGE      XX_AP_XXAPCHBKAPDM_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_AP_XXAPCHBKAPDM_PKG.pks		               |
-- | Description :  Plsql package for XXAPCHBKAPDM Report              |
-- |                Created this package to avoid using dblinks in rdf |
-- | RICE ID     :  R1050                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       29-Apr-2013 Paddy Sanjeevi     Initial version           |
-- |                                         Defect 23208              |
-- |1.1       28-May-2013 Paddy Sanjeevi     Modified column mapping   |
--
-- |1.2       30-Aug-2017 Ragni Gupta        Changes for trade Payables project
-- +===================================================================+
AS


PROCEDURE G_Chargeback_layoutGroupFilter(p_vendor_site_id IN NUMBER,p_country_cd IN VARCHAR2, p_db_source IN VARCHAR2,
					 p_legacy_o OUT NUMBER,p_vendor_prefix_o OUT VARCHAR2);

FUNCTION CF_Voucher_numFormula(p_voucher_nbr IN VARCHAR2, p_db_source IN VARCHAR2) RETURN VARCHAR2;

FUNCTION CF_StyleFormula (p_country_cd IN VARCHAR2,p_sku IN NUMBER,p_vendor_site_id IN NUMBER, p_db_source IN VARCHAR2) RETURN VARCHAR2;

FUNCTION CF_Rec_DateFormula(p_ap_company IN VARCHAr2, p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN DATE;

FUNCTION CF_PO_NumberFormula(p_ap_company IN VARCHAr2, p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN VARCHAr2;

FUNCTION CF_legacy_loc_idFormula(p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN NUMBER;

FUNCTION CF_Legacy_Inv_numFormula(p_voucher_nbr IN VARCHAR2, p_invoice_num VARCHAR2, p_db_source IN VARCHAR2) RETURN VARCHAR2;

FUNCTION  CF_DeptFormula ( p_sku IN NUMBER, p_org_id IN NUMBER, p_db_source IN VARCHAR2 ) RETURN NUMBER;

FUNCTION  CF_DedcriptionFormula ( p_sku IN NUMBER, p_db_source IN VARCHAR2 ) RETURN VARCHAR2;

END;
/

SHOW ERRORS;