SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE XX_AP_TR_UI_ACTION_PKG

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE APPS.XX_AP_TR_UI_ACTION_PKG AUTHID CURRENT_USER
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_TR_UI_ACTION_PKG.pks                               |
-- | Description :  Plsql package for Invoice UI Actions                     |
-- | RICE ID     :  E3522_OD Trade Match Foundation                          |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       12-Aug-2017 Paddy Sanjeevi     Initial version                 |
-- |1.1       29-Sep-2017 Naveen Patha       added new function              |
-- |                                         xx_chbk_reprocess_action        |
-- |1.2       27-Oct-2017 Paddy Sanjeevi     Added xx_insert_new_holds       |
-- |1.3        7-Dec-2017 Paddy Sanjeevi     Added get_freight_chargeback    |
-- |1.4       21-Dec-2017 Naveen Patha       Modified xx_call_chbk_act       |
-- |1.5       03-Jan-2018 Paddy Sanjeevi     Added xx_purge_errors           |
-- |1.6       10-Jan-2018 Naveen Patha       Added xx_apps_initialize        |
-- |1.7       18-Apr-2018 Paddy Sanjeevi     Added get_po_uom                |
-- |1.8       18-Jul-2018 Chandra            Added global variables          |
-- |                                         for defect #NAIT-41954          |
-- +=========================================================================+
AS

FUNCTION get_po_item_desc(p_po_line_id IN NUMBER) RETURN VARCHAR2;

FUNCTION get_po_uom(p_po_line_id IN NUMBER) RETURN VARCHAR2;


PROCEDURE xx_apps_initialize(p_user_id NUMBER,
                             p_resp_id NUMBER,
							 p_resp_app_id NUMBER);

PROCEDURE xx_purge_errors(x_errbuf         OUT NOCOPY  VARCHAR2 ,
                          x_retcode         OUT NOCOPY VARCHAR2 
                         );

PROCEDURE xx_release_template_holds(
                                    x_errbuf         OUT NOCOPY  VARCHAR2 ,
                                    x_retcode         OUT NOCOPY VARCHAR2 ,
                                    p_source         IN  VARCHAR2,
                                                                        p_invoice_id IN NUMBER
                                   );

FUNCTION xx_no_chbk_no_split(p_invoice_id NUMBER) RETURN VARCHAR2;

FUNCTION get_freight_chargeback(p_vendor_site_id IN NUMBER,p_org_id IN NUMBER)
RETURN VARCHAR2;
                                   
PROCEDURE xx_freight_upd(p_invoice_id IN NUMBER);                                   
                                   
PROCEDURE xx_del_line(p_invoice_id IN NUMBER, p_line_seq_id IN NUMBER);

PROCEDURE xx_nrc_rc_upd(p_invoice_id IN NUMBER);

PROCEDURE xx_upd_reason_code(p_invoice_id IN NUMBER,p_inv_total IN NUMBER);

PROCEDURE xx_get_total(p_invoice_id IN NUMBER,
                       p_line_total    OUT NUMBER,
                       p_rc_total    OUT NUMBER
                      );

FUNCTION get_uom(p_item_id IN NUMBER) RETURN VARCHAR2;

PROCEDURE xx_chbk_action ( x_errbuf       OUT NOCOPY VARCHAR2
                          ,x_retcode      OUT NOCOPY VARCHAR2
                          ,p_invoice_id   IN  NUMBER
                          ,p_org_id           NUMBER
                          );
/*PROCEDURE xx_chbk_reprocess_action ( x_errbuf       OUT NOCOPY VARCHAR2
                          ,x_retcode      OUT NOCOPY VARCHAR2                          
                          );*/
                          
/*PROCEDURE xx_chbk_error_report ( x_errbuf          OUT NOCOPY VARCHAR2
                                  ,x_retcode         OUT NOCOPY VARCHAR2);*/

FUNCTION xx_call_chbk_act( p_invoice_id IN  NUMBER, p_org_id NUMBER) RETURN NUMBER;
                            
FUNCTION xx_release_hold(p_invoice_id IN NUMBER,p_org_id IN NUMBER)
RETURN VARCHAR2;                            

FUNCTION xx_submit_inv_validation(p_invoice_id IN NUMBER,
                                  p_org_id IN NUMBER)
RETURN NUMBER;

FUNCTION xx_cancel_invoice(p_invoice_id IN NUMBER) 
RETURN VARCHAR2;

FUNCTION XX_CREATE_INVOICE(P_INVOICE_ID NUMBER,p_chbk_flag IN VARCHAR2) 
RETURN VARCHAR2;

PROCEDURE xx_upd_invoice_num(p_invoice_id IN NUMBER);

FUNCTION XX_UI_INVOICE_CANCEL(p_invoice_id IN NUMBER) 
RETURN VARCHAR2;

PROCEDURE xx_upd_invoice_chargeback(p_invoice_id IN VARCHAR2,
                                    p_org_id IN VARCHAR2);

FUNCTION get_misc_account(p_invoice_id IN NUMBER,
                          p_line_no IN NUMBER,
                          p_reason_cd IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION xx_create_chargeback(p_invoice_id NUMBER,
                              p_org_id IN NUMBER)
RETURN VARCHAR2;

FUNCTION get_unbilled_qty(p_po_header_id IN NUMBER,
                          p_po_line_id IN NUMBER, 
                          p_item_id IN NUMBER,
                          p_invoice_id IN NUMBER)
RETURN NUMBER;

FUNCTION get_assigned_user(p_invoice_id IN NUMBER,
                           p_user_id IN NUMBER)
RETURN VARCHAR2;

PROCEDURE unassign_user(p_invoice_id IN NUMBER);

FUNCTION check_hold_exists(p_invoice_id IN NUMBER,p_line_location_id IN NUMBER)
RETURN VARCHAR2;

FUNCTION get_shipment_num(p_po_line_id IN NUMBER)
RETURN NUMBER;

PROCEDURE xx_send_uierror_report ( x_errbuf       OUT NOCOPY VARCHAR2
                                  ,x_retcode      OUT NOCOPY VARCHAR2
                                 );

FUNCTION get_charge_acct(p_po_line_id IN NUMBER)
RETURN VARCHAR2;

FUNCTION get_freight_acct(p_invoice_id NUMBER ,p_line_number IN NUMBER)
RETURN VARCHAR2;

FUNCTION xx_insert_custom_invoice_table(p_invoice_id IN VARCHAR2,
                                        p_user_id IN  VARCHAR2,
                                        p_user_name  IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION xx_insert_new_holds(p_invoice_id IN VARCHAR2) RETURN VARCHAR2;

-- to be removed later
--PROCEDURE xx_upd_invoice_num(p_invoice_id IN NUMBER);
  -- Start : -- 1.8 #Added by Chandra for defect #NAIT-41954
  gcn_invoice_id        NUMBER; 
  gin_invoice_id        NUMBER;
  -- End : -- 1.8 #Added by Chandra for defect #NAIT-41954
END;    
/
SHOW ERRORS;