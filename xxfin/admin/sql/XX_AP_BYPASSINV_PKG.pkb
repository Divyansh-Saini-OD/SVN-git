SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


create or replace 
PACKAGE BODY XX_AP_BYPASSINV_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_BYPASSINV_PKG                                                              |
  -- |  RICE ID   :  R7039                                                                        |
  -- |  Description:  PAckage will be used to execute before_report which will set email information
  --                  ,certain functions to get depot.sku,mfg_Code UOM information and           |
  --                  and after_report will submit XML bursting for Bypass Invoice Report         |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/13/2017   Ragni Gupta       Initial version                                  |
  -- +============================================================================================+
FUNCTION beforeReport
  RETURN BOOLEAN
IS
  L_EMAIL_SUBJECT     VARCHAR2(250);
  L_EMAIL_CONTENT     VARCHAR2(500);
  L_DISTRIBUTION_LIST VARCHAR2(500);
BEGIN
  XX_AP_XML_BURSTING_PKG.Get_email_detail( 'XXAPBYPASSINV' , G_SMTP_SERVER, G_EMAIL_SUBJECT, G_EMAIL_CONTENT, G_DISTRIBUTION_LIST) ;
  /*BEGIN
    SELECT COUNT(*)
    INTO G_REC_COUNT
    FROM ap_invoices_interface aii,
      po_headers_all pha,
      ap_suppliers asp,
      ap_supplier_sites_all assa,
      hr_locations_all hla,
	  AP_INTERFACE_REJECTIONS AIR
    WHERE 1 = 1
	AND (aii.po_number like 'E%'
	OR (air.parent_table ='AP_INVOICES_INTERFACE' and air.reject_lookup_code ='INVALID PO NUM'))
	AND aii.SOURCE            = 'US_OD_TRADE_EDI'
    AND aii.status             <> 'PROCESSED'
    AND pha.segment1            =aii.po_number
    AND asp.vendor_id           = aii.vendor_id
    AND asp.vendor_id           = assa.vendor_id
    AND assa.vendor_site_id     = aii.vendor_site_id
    AND pha.ship_to_location_id = hla.location_id
    AND TRUNC(aii.creation_date) BETWEEN fnd_date.canonical_to_date(P_START_DATE) AND fnd_date.canonical_to_date(P_END_DATE);
  EXCEPTION
  WHEN OTHERS THEN
    G_REC_COUNT :=0;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'G_REC_COUNT ' || G_REC_COUNT);
  END;*/
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in before_report function '||SQLERRM );
END beforeReport;
FUNCTION GET_MFG_CODE(
    p_po_num   VARCHAR2,
    p_line_num NUMBER)
  RETURN VARCHAR2
IS
  lv_mfg_code VARCHAR2(30);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside get mfg code function');
  SELECT ood.organization_code
  INTO lv_mfg_code
  FROM po_headers_all pha,
    po_lines_all pll,
    po_line_locations_all plla,
    org_organization_definitions ood
  WHERE 1                 =1
  AND pha.segment1        = p_po_num
  AND pll.line_num        = p_line_num
  AND pha.po_header_id    = pll.po_header_id
  AND plla.po_header_id   = pll.po_header_id
  AND plla.po_line_id     = pll.po_line_id
  AND ood.organization_id = plla.ship_to_organization_id;
  RETURN lv_mfg_code;
EXCEPTION
WHEN OTHERS THEN
  lv_mfg_code := NULL;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_BYPASSINV_PKG.GET_MFG_CODE:- ' || sqlerrm);
  RETURN NULL;
END GET_MFG_CODE;
FUNCTION GET_SKU(
    p_po_num   VARCHAR2,
    p_line_num NUMBER,
    p_item_id  NUMBER)
  RETURN VARCHAR2
IS
  lv_sku VARCHAR2(30);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside get sku function');
  IF p_item_id IS NOT NULL THEN
    SELECT segment1
    INTO lv_sku
    FROM mtl_system_items_b
    WHERE inventory_item_id = p_item_id
    AND rownum              =1;
  ELSE
    SELECT msi.segment1
    INTO lv_sku
    FROM po_headers_all pha,
      po_lines_all pll,
      po_line_locations_all plla,
      mtl_system_items_b msi
    WHERE 1                   =1
    AND pha.segment1          = p_po_num
    AND pll.line_num          = p_line_num
    AND pha.po_header_id      = pll.po_header_id
    AND plla.po_header_id     = pll.po_header_id
    AND plla.po_line_id       = pll.po_line_id
    AND msi.inventory_item_id = pll.item_id
    AND msi.organization_id   = plla.ship_to_organization_id;
  END IF;
  RETURN lv_sku;
EXCEPTION
WHEN OTHERS THEN
  lv_sku := NULL;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_BYPASSINV_PKG.GET_SKU:- ' || sqlerrm);
  RETURN NULL;
END GET_SKU;
FUNCTION GET_DEPT(
    p_item_id  NUMBER,
    p_org_id   NUMBER,
    p_po_num   VARCHAR2,
    p_line_num NUMBER)
  RETURN NUMBER
IS
  ln_dept NUMBER;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside get dept function');
  IF p_org_id IS NULL AND p_item_id IS NULL THEN
    SELECT DISTINCT mc.segment3
    INTO ln_dept
    FROM po_headers_all pha,
      po_lines_all pll,
      po_line_locations_all plla,
      mtl_system_items_b msi,
      mtl_item_categories mic,
      mtl_categories_b mc
    WHERE 1                   =1
    AND msi.inventory_item_id = mic.inventory_item_id
    AND mic.category_id       = mc.category_id
    AND pha.segment1          = p_po_num
    AND pll.line_num          = p_line_num
    AND pha.po_header_id      = pll.po_header_id
    AND plla.po_header_id     = pll.po_header_id
    AND plla.po_line_id       = pll.po_line_id
    AND msi.inventory_item_id = pll.item_id
    AND msi.organization_id   = plla.ship_to_organization_id
    AND mc.segment3          IS NOT NULL;
  ELSE
    SELECT DISTINCT mc.segment3
    INTO ln_dept
    FROM mtl_item_categories mic,
      mtl_categories_b mc,
      mtl_system_items_b msib
    WHERE msib.inventory_item_id = mic.inventory_item_id
    AND mic.category_id          = mc.category_id
    AND msib.inventory_item_id   = p_item_id
    AND msib.organization_id     = p_org_id
    AND mc.segment3             IS NOT NULL;
  END IF;
  RETURN ln_dept;
EXCEPTION
WHEN OTHERS THEN
  ln_dept := NULL;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_BYPASSINV_PKG.GET_DEPT:- ' || sqlerrm);
  RETURN NULL;
END GET_DEPT;
FUNCTION GET_UOM(
    p_po_num   VARCHAR2,
    p_line_num NUMBER)
  RETURN VARCHAR2
IS
  lv_uom_code VARCHAR2(30);
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'inside get UOM function');
  SELECT pll.unit_meas_lookup_Code
  INTO lv_uom_code
  FROM po_headers_all pha,
    po_lines_all pll,
    po_line_locations_all plla
  WHERE 1               =1
  AND pha.segment1      = p_po_num
  AND pll.line_num      = p_line_num
  AND pha.po_header_id  = pll.po_header_id
  AND plla.po_header_id = pll.po_header_id
  AND plla.po_line_id   = pll.po_line_id;
  RETURN lv_uom_code;
EXCEPTION
WHEN OTHERS THEN
  lv_uom_code := NULL;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'ERROR at XX_AP_BYPASSINV_PKG.GET_UOM:- ' || sqlerrm);
  RETURN NULL;
END GET_UOM;
FUNCTION afterReport
  RETURN BOOLEAN
IS
  l_request_id NUMBER;
  l_file_size  NUMBER;
BEGIN
  P_CONC_REQUEST_ID        := FND_GLOBAL.CONC_REQUEST_ID;
  
      --P_DISTRIBUTION_LIST := 'ragni.gupta1@officedepot.com; Rajesh.Gupta@officedepot.com';
      fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
      l_request_id := FND_REQUEST.SUBMIT_REQUEST('XDO', 'XDOBURSTREP', NULL, NULL, FALSE, 'Y', P_CONC_REQUEST_ID, 'Y');
      Fnd_File.PUT_LINE(Fnd_File.LOG, 'After submitting bursting ');
      COMMIT;
    
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Exception in after_report function '||SQLERRM );
END afterReport;
END;
/

SHOW ERRORS;