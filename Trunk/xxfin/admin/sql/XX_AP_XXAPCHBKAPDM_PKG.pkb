SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AP_XXAPCHBKAPDM_PKG
create or replace 
PACKAGE BODY      XX_AP_XXAPCHBKAPDM_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_AP_XXAPCHBKAPDM_PKG.pkb		               |
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
-- |1.2       10-Jul-2013 Paddy Sanjeevi     Added Trim in functions   |
-- |1.3       30-Aug-2017 Ragni Gupta        Modified functions to return
--                                           data based on DB source for|
--                                           Trade Payables project   |
-- +===================================================================+
AS

PROCEDURE G_Chargeback_layoutGroupFilter(p_vendor_site_id IN NUMBER,p_country_cd IN VARCHAR2, p_db_source IN VARCHAR2,
					 p_legacy_o OUT NUMBER,p_vendor_prefix_o OUT VARCHAR2)
IS

ln_legacy              NUMBER:=0;
lc_vendor_prefix       VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
    p_legacy_o:=0;
    p_vendor_prefix_o:=NULL;
  ELSE

    SELECT  1
           ,LTRIM(RTRIM(VM.vendor_prefix))
      INTO    ln_legacy
             ,lc_vendor_prefix
      FROM    od.venmst@legacydb2 VM
             ,od.ventrd@legacydb2 VT
      WHERE   VT.vendor_id = p_vendor_site_id
      AND     VT.master_vendor_id   = VM.master_vendor_id
      AND     VT.master_vendor_id   <> 0
      AND     SUBSTR(VT.country_cd,1,2) = p_country_cd;
  END IF;

    p_legacy_o:=ln_legacy;
    p_vendor_prefix_o:=lc_vendor_prefix;

EXCEPTION
  WHEN others THEN
    p_legacy_o:=0;
    p_vendor_prefix_o:=NULL;
END G_Chargeback_layoutGroupFilter;

FUNCTION CF_Voucher_numFormula(p_voucher_nbr IN VARCHAR2, p_db_source IN VARCHAR2) RETURN VARCHAR2
IS

lc_voucher_num  VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
    lc_voucher_num := p_voucher_nbr;
  ELSE
    SELECT LTRIM(RTRIM(voucher_nbr)) voucher_nbr
      INTO lc_voucher_num
      FROM OD.APAYHDR@legacydb2
     WHERE voucher_nbr   = p_voucher_nbr;
  END IF;

  RETURN lc_voucher_num;
EXCEPTION
  WHEN others THEN
    lc_voucher_num:=NULL;
    RETURN lc_voucher_num;

END CF_Voucher_numFormula;

FUNCTION CF_StyleFormula (p_country_cd IN VARCHAR2,p_sku IN NUMBER,p_vendor_site_id IN NUMBER, p_db_source IN VARCHAR2) RETURN VARCHAR2
IS

lc_vendor_product VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
    lc_vendor_product:=NULL;
  ELSE
     SELECT LTRIM(RTRIM(IV.vendor_product_cd))
       INTO lc_vendor_product
       FROM OD.itemven@legacydb2 IV
      WHERE IV.country_cd          = p_country_cd
        AND IV.sku                 = p_sku
        AND IV.vendor_id           = p_vendor_site_id;
  END IF;

  RETURN(lc_vendor_product);

EXCEPTION
  WHEN others THEN
    lc_vendor_product:=NULL;
    RETURN(lc_vendor_product);

END CF_StyleFormula;

FUNCTION CF_Rec_DateFormula(p_ap_company IN VARCHAr2, p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN DATE
IS

lc_Rcvr_nbr  VARCHAR2(50);
ld_Rec_Date DATE;
lc_Voucher_num VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
    BEGIN
        SELECT MAX(rsh.creation_date)
        INTO ld_rec_date
        FROM po_headers_all pha, po_lines_all pla, rcv_shipment_headers rsh, rcv_shipment_lines rsl,
             ap_invoices_all aia, ap_invoice_lines_all aila
        WHERE pha.po_header_id = pla.po_header_id
        AND pha.po_header_id = rsl.po_header_id
        AND rsl.shipment_header_id = rsh.shipment_header_id
        AND pla.po_line_id = aila.po_line_id
        AND aila.invoice_id= aia.invoice_id
        AND aia.invoice_id = p_invoice_id;
        EXCEPTION
        WHEN OTHERS THEN
          ld_rec_date:=NULL;
        END;
  ELSE
    BEGIN
      SELECT LTRIM(RTRIM(ca.rcvr_nbr))
        INTO lc_Rcvr_nbr
        FROM OD.chbkadj@legacydb2 CA
       WHERE CA.ap_company  = p_ap_company
         AND CA.voucher_nbr = p_Voucher_nbr
         AND ROWNUM=1;

       SELECT R.rcvr_dt
         INTO ld_Rec_Date
         FROM OD.rcvrhdr@legacydb2 R
        WHERE R.ap_company       = p_ap_company
          AND R.rcvr_nbr         = lc_Rcvr_nbr;
      EXCEPTION
        WHEN others THEN
          ld_rec_date:=NULL;
      END;

  END IF;
     RETURN ld_Rec_Date;
EXCEPTION
  WHEN others THEN
    ld_rec_date:=NULL;
    RETURN(ld_rec_date);
END CF_Rec_DateFormula;


FUNCTION CF_PO_NumberFormula(p_ap_company IN VARCHAr2, p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN VARCHAr2
IS

lc_Rcvr_nbr  VARCHAR2(50);
lc_PO_Number VARCHAR2(50);
lc_Voucher_num VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
        BEGIN
          SELECT distinct pha.segment1
          INTO lc_PO_Number
          FROM po_headers_all pha, po_lines_all pla, ap_invoices_all aia, ap_invoice_lines_all aila
          WHERE pha.po_header_id = pla.po_header_id
          AND pla.po_line_id = aila.po_line_id
          AND aila.invoice_id= aia.invoice_id
          AND aia.invoice_id = p_invoice_id;
        EXCEPTION
        WHEN OTHERS THEN
          lc_PO_Number:=NULL;
        END;
  ELSE
      BEGIN
        SELECT LTRIM(RTRIM(ca.rcvr_nbr))
          INTO lc_Rcvr_nbr
          FROM OD.chbkadj@legacydb2 CA
         WHERE CA.ap_company  = p_ap_company
           AND CA.voucher_nbr = p_Voucher_nbr
           AND ROWNUM=1;

        SELECT R.po_nbr
          INTO lc_PO_Number
          FROM OD.rcvrhdr@legacydb2 R
         WHERE R.ap_company       = p_ap_company
           AND R.rcvr_nbr         = lc_Rcvr_nbr;
      EXCEPTION
        WHEN OTHERS THEN
          lc_PO_Number:=NULL;
        END;
    END IF;

  RETURN(lc_PO_Number);
EXCEPTION
  WHEN others THEN
    lc_PO_Number:=NULL;
    RETURN(lc_PO_Number);
END CF_PO_NumberFormula;

FUNCTION CF_legacy_loc_idFormula(p_voucher_nbr IN VARCHAR2, p_invoice_id IN NUMBER, p_db_source IN VARCHAR2) RETURN NUMBER
IS

ln_loc_id NUMBER;

BEGIN
  IF p_db_Source = 'EBIZ' THEN

    BEGIN
     
      SELECT SUBSTR(hr.location_code,1,6)
      INTO ln_loc_id
      FROM hr_locations_all hr,ap_invoice_lines_all aila
      WHERE aila.invoice_id=p_invoice_id
      AND hr.location_id=aila.ship_to_location_id
      AND rownum<2;

    EXCEPTION
    WHEN others THEN
      ln_loc_id:=NULL;
    END;

  ELSE

    BEGIN
      SELECT loc_id
        INTO ln_loc_id
        FROM OD.APAYHDR@legacydb2
       WHERE voucher_nbr   = p_voucher_nbr;
    EXCEPTION
    WHEN others THEN
    ln_loc_id:=NULL;
    END;

  END IF;

  RETURN(ln_loc_id);
EXCEPTION
  WHEN others THEN
    ln_loc_id:=NULL;
    RETURN(ln_loc_id);
END CF_legacy_loc_idFormula;


FUNCTION CF_Legacy_Inv_numFormula(p_voucher_nbr IN VARCHAR2, p_invoice_num VARCHAR2, p_db_source IN VARCHAR2) RETURN VARCHAR2
IS

lc_inv_num VARCHAR2(52);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
    lc_inv_num := p_invoice_num;
  ELSE
    BEGIN
      SELECT LTRIM(RTRIM(invoice_nbr))
        INTO lc_inv_num
        FROM OD.APAYHDR@legacydb2
       WHERE voucher_nbr   = p_voucher_nbr;
      RETURN(lc_inv_num);
    EXCEPTION
      WHEN others THEN
        lc_inv_num:=NULL;
    END;
  END IF;

    RETURN(lc_inv_num);
END CF_Legacy_Inv_numFormula;

FUNCTION  CF_DeptFormula ( p_sku IN NUMBER, p_org_id IN NUMBER, p_db_source IN VARCHAR2 ) RETURN NUMBER
IS
ln_dept NUMBER;
BEGIN
  IF p_db_Source = 'EBIZ' THEN
    BEGIN
    SELECT distinct mc.segment3
    INTO ln_dept
      FROm mtl_item_categories mic, mtl_categories_b mc, mtl_system_items_b msib
      WHERE msib.inventory_item_id = mic.inventory_item_id
      AND mic.category_id = mc.category_id
      AND msib.segment1 = to_char(p_sku)
      AND msib.organization_id = p_org_id
      AND mc.segment3 IS NOT NULL;
    EXCEPTION
      WHEN others THEN
        ln_dept := NULL;
     END;
  ELSE
    BEGIN
      SELECT I.merch_dept_id
        INTO ln_dept
        FROM OD.item@legacydb2 I
       WHERE I.sku = p_sku;
    EXCEPTION
    WHEN others THEN
      ln_dept := NULL;
    END;
  END IF;
  RETURN(ln_dept);
EXCEPTION
  WHEN others THEN
    ln_dept := NULL;
    RETURN(ln_dept);
END CF_DeptFormula;


FUNCTION CF_DedcriptionFormula ( p_sku IN NUMBER, p_db_source IN VARCHAR2 ) RETURN VARCHAR2
IS

lc_description VARCHAR2(50);

BEGIN
  IF p_db_Source = 'EBIZ' THEN
      BEGIN
        SELECT description
        INTO lc_description
        FROM mtl_system_items_b msib
        WHERE segment1 = to_char(p_sku)
        AND organization_id = 441;
        EXCEPTION
          WHEN others THEN
            lc_description:= NULL;
      END;
  ELSE
    BEGIN
    SELECT LTRIM(RTRIM(I.descr))
      INTO lc_description
      FROM OD.item@legacydb2 I
     WHERE I.sku = p_sku;
      EXCEPTION
          WHEN others THEN
            lc_description:= NULL;
      END;
  END IF;

    RETURN(lc_description);

  EXCEPTION
    WHEN others THEN
      lc_description:=NULL;
    RETURN(lc_description);
END CF_DedcriptionFormula;

END XX_AP_XXAPCHBKAPDM_PKG;
/

SHOW ERRORS;