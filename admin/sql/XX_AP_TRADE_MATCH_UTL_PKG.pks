create or replace PACKAGE      XX_AP_TRADE_MATCH_UTL_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_TRADE_MATCH_UTL_PKG.pks                            |
-- | Description :  AP Trade Match Util Package                              |
-- | RICE ID   :  E3522_OD Trade Match Foundation                            |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       30-MAY-2017 Paddy Sanjeevi     Initial version                 |
-- |1.1       12-Dec-2017 Paddy Sanjeevi     Added xx_qty_hold_amt function  |
-- |1.2       27-Dec-2017 Paddy Sanjeevi     Modified xx_qty_hold_amt        |
-- +=========================================================================+
AS

FUNCTION xx_qty_hold_amt(p_invoice_id in number,p_line_number IN NUMBER) RETURN NUMBER;
FUNCTION xx_price_hold_amt(p_invoice_id in number,p_line_number IN NUMBER) RETURN NUMBER;

PROCEDURE xx_ap_update_due_date(p_invoice_id IN NUMBER, p_terms_date IN date,p_terms_id IN number); 

PROCEDURE xx_ap_update_pay_method(p_invoice_id IN NUMBER, p_pay_method IN VARCHAR2);

PROCEDURE xx_ap_update_pay_group(p_invoice_id IN NUMBER, p_pay_group IN VARCHAR2);

FUNCTION xx_primary_vendor_name(p_vend_site_id IN NUMBER) RETURN VARCHAR2;

FUNCTION xx_ap_freight_invoice(p_invoice_id NUMBER) RETURN VARCHAR2;

PROCEDURE xx_ap_release_hold(p_invoice_id IN NUMBER, p_qty_rel_code IN VARCHAR2, p_price_rel_code IN VARCHAR2);

PROCEDURE xx_ap_update_pay_due_date(p_invoice_id IN NUMBER, p_due_date IN date);

procedure xx_upd_invoice_released(invoice_in IN XX_AP_TR_INV_ARRAY);

procedure xx_upd_vendorassistant(site_id IN XX_AP_TR_INV_ARRAY);

procedure xx_upd_paymentterms( invoice_in in XX_AP_TR_INV_ARRAY);

procedure xx_upd_mass_releasehold(invoice_in IN XX_AP_TR_INV_ARRAY);
    
FUNCTION xx_get_vendor_assistant(p_code in varchar2) Return varchar2;

function xxod_tdmatch_quantity(p_invoice_id in number) return number;

function xxod_tdmatch_price(p_invoice_id in number) return number;


END;
/
SHOW ERRORS;
