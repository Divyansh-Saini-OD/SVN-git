SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating FUNCTION XX_AP_GET_PO_DETAILS

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
create or replace 
FUNCTION XX_AP_GET_PO_DETAILS(
      p_po_header_id IN NUMBER,
      p_po_line_id   IN NUMBER DEFAULT NULL,
      p_type         IN VARCHAR2)
    RETURN VARCHAR
    -- +============================================================================================+
    -- |  Office Depot - Project Simplify                                                           |
    -- |                                                                                            |
    -- +============================================================================================+
    -- |  Name  :  XX_AP_GET_PO_DETAILS                                                          |
    -- |  RICE ID   :  E3522 AP Dashboard Report Package
    -- | Solution ID: 211.0 PO Inquiry
    -- |  Description:  Function to get Quantity Invoices, Invoice Number, Receipt Number,Location  |
    -- |  Change Record:                                                                            |
    -- +============================================================================================+
    -- | Version     Date         Author           Remarks                                          |
    -- | =========   ===========  =============    ===============================================  |
    -- | 1.0         11/28/2017   Jitendra Atale   Initial version                                  |
    -- +============================================================================================+
  IS
  l_Qty            NUMBER :=0;
  L_TYPE           VARCHAR2(100) ;
  lv_inv_num       VARCHAR2(100) ;
  lv_inv_count     NUMBER :=0;
  lv_Receipt_num   VARCHAR2(100) ;
  lv_Receipt_Count NUMBER;
  lv_location      VARCHAR2(100) ;
  lv_status        VARCHAR2(100) ;
  lv_Unmatched_Qty NUMBER :=0;
  BEGIN
    L_TYPE   := p_type ;
    IF L_TYPE = 'Qty' THEN
     BEGIN
      SELECT NVL(SUM(aid.quantity_invoiced),0)
      INTO l_Qty
      FROM apps.ap_invoice_distributions_all aid,
        apps.po_headers_all pha,
        apps.po_distributions_all pda
      WHERE 1                    =1
      AND pha.po_header_id       = pda.po_header_id
      AND aid.po_distribution_id = pda.po_distribution_id
      AND pha.po_header_id       = p_po_header_id --pla.po_header_id
      AND pda.po_line_id         = p_po_line_id ; --pla.po_line_id;
      RETURN TO_NUMBER(l_Qty);
      EXCEPTION WHEN OTHERS THEN
        RETURN TO_NUMBER(l_Qty);
    END;
    elsif L_TYPE = 'INV_NUM' THEN
    lv_inv_count:=0;
    lv_inv_num:=NULL;
    BEGIN
      SELECT MIN(AP.INVOICE_NUm),count(AP.INVOICE_NUm)
      INTO lv_inv_num,lv_inv_count
      FROM apps.ap_invoice_distributions_all aid,
        APPS.AP_InVOICES_ALL AP ,
        apps.po_headers_all pha,
        apps.po_distributions_all pda
      WHERE 1                    =1
      AND pha.po_header_id       = pda.po_header_id
      AND aid.po_distribution_id = pda.po_distribution_id
      AND pha.po_header_id       = p_po_header_id
      AND pda.po_line_id         = p_po_line_id
      AND AP.INVOICE_ID          = aid.INVOICE_ID
      ORDER BY AP.Creation_date ASC;
      
      IF lv_inv_count > 1 THEN
        lv_inv_num:=lv_inv_num||' '|| '+';
      END IF;
      RETURN lv_inv_num;
       EXCEPTION WHEN OTHERS THEN
        RETURN lv_inv_num;
    END;
    elsif L_TYPE = 'REC_NUM' THEN
    lv_Receipt_Count:=0;
    lv_Receipt_num:=NULL;
     BEGIN
      SELECT MIN(rsh.receipt_num),count(rsh.receipt_num)
      INTO lv_Receipt_num,lv_Receipt_Count
      FROM apps.rcv_shipment_lines rsl,
        apps.rcv_shipment_headers rsh
      WHERE rsl.shipment_header_id = rsh.shipment_header_id
      AND rsl.po_line_id           = p_po_line_id
      ORDER BY rsh.Creation_date ASC;
     
       IF lv_Receipt_Count > 1 THEN
        lv_Receipt_num:=lv_Receipt_num||' '|| '+';
      END IF;
       RETURN lv_Receipt_num;
      
       EXCEPTION WHEN OTHERS THEN
        RETURN lv_Receipt_num;
    END;
    elsif L_TYPE = 'LOC' THEN
     BEGIN
      SELECT ltrim(SUBSTR(hru.name,1,6),0)
      INTO lv_location
      FROM hr_organization_units hru,
        po_headers_all pha,
        po_lines_all pla
      WHERE hru.location_id     = pha.ship_to_location_id
      ANd pha.po_header_id=pla.po_header_id
      AND pha.po_header_id      =p_po_header_id
      AND pla.po_line_id        =p_po_line_id
      AND rownum                =1;
      RETURN lv_location;
        EXCEPTION WHEN OTHERS THEN
        RETURN lv_location;
    END;
    elsif L_TYPE = 'STATUS' THEN  
    BEGIN
      select plc.displayed_field
      into lv_status
      from apps.po_lookup_codes plc,po_headers_all pha
      where plc.lookup_type='DOCUMENT STATE'
      and pha.po_header_id=p_po_header_id
      AND plc.lookup_code=nvl(pha.authorization_status,'INCOMPLETE');
      RETURN lv_status;
         EXCEPTION WHEN OTHERS THEN
        RETURN lv_status;
    END;
    elsif L_TYPE = 'UQTY' THEN  
    BEGIN
      
      SELECT NVL(SUM(aid.quantity_invoiced),0)
      INTO l_Qty
      FROM apps.ap_invoice_distributions_all aid,
        apps.po_headers_all pha,
        apps.po_distributions_all pda
      WHERE 1                    =1
      AND pha.po_header_id       = pda.po_header_id
      AND aid.po_distribution_id = pda.po_distribution_id
      AND pha.po_header_id       = p_po_header_id --pla.po_header_id
      AND pda.po_line_id         = p_po_line_id ; --pla.po_line_id;
   
      SELECT DECODE(pll.INSPECTION_REQUIRED_FLAG||pll.RECEIPT_REQUIRED_FLAG,'NY',pll.quantity_received-l_Qty,'NN',pla.quantity-l_Qty,NULL)
      INTO lv_Unmatched_Qty
      FROM apps.po_headers_all pha,
           apps.po_lines_all pla,
           apps.po_line_locations_all pll
      WHERE 1=1
      AND pha.po_header_id      =pla.po_header_id
      AND pha.po_header_id                =pll.po_header_id
      AND pla.po_line_id                  =pll.po_line_id
      AND pha.po_header_id                = p_po_header_id
      AND pla.po_line_id                  =p_po_line_id;
      
      
      RETURN lv_Unmatched_Qty;
         EXCEPTION WHEN OTHERS THEN
        RETURN lv_Unmatched_Qty;
    END;
    END IF;
------------------------------------------------------
-- AP Trade – PO Inquiry
-- Solution ID:211
-- RICE_ID : E3522
------------------------------------------------------------
END XX_AP_GET_PO_DETAILS;
/

SHOW ERRORS
  