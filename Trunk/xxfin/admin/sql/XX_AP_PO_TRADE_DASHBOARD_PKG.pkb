SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY xx_ap_po_trade_dashboard_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  xx_ap_po_trade_dashboard_pkg                                                          |
  -- |  RICE ID   :  E3522 AP Dashboard Report Package
  -- | Solution ID: 211.0 PO Inquiry
  -- |  Description:  Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11/16/2017   Jitendra Atale   Initial version                                  |
  -- +============================================================================================+
  l_Qty NUMBER :=0;
FUNCTION XX_AP_TRADE_GET_PO_DETAILS(
    p_po_header_id IN NUMBER,
    p_po_line_id   IN NUMBER DEFAULT NULL,
    p_type         IN VARCHAR2)
  RETURN VARCHAR2
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
  l_Recd_Qty       NUMBER :=0;
  L_TYPE           VARCHAR2(100) ;
  lv_inv_num       VARCHAR2(100) ;
  lv_inv_count     NUMBER :=0;
  lv_Receipt_num   VARCHAR2(100) ;
  lv_Receipt_Count NUMBER;
  lv_WO_Amt        NUMBER;
  lv_WO_Count      NUMBER;
  lv_WO_AMT_CHAR   VARCHAR2(100);
  lv_location      VARCHAR2(100) ;
  lv_lastreceiptdt VARCHAR2(100) ;
  lv_Unmatched_Qty NUMBER :=0;
BEGIN
  L_TYPE   := p_type ;
  IF L_TYPE = 'Qty' THEN
    BEGIN
      SELECT NVL(SUM(ail.quantity_invoiced),0)
      INTO l_Qty
      FROM ap_invoice_lines_all ail,
        ap_invoices_all ap
      WHERE ap.quick_po_header_id=p_po_header_id
      AND ap.cancelled_date     IS NULL
      AND ail.invoice_id         =ap.invoice_id
      AND ail.po_line_id         =p_po_line_id;
      RETURN TO_NUMBER(l_Qty);
    EXCEPTION
    WHEN OTHERS THEN
      RETURN TO_NUMBER(l_Qty);
    END;
  elsif L_TYPE   = 'INV_NUM' THEN
    lv_inv_count:=0;
    lv_inv_num  :=NULL;
    BEGIN
      SELECT MIN(ap.invoice_num),
        COUNT(ap.invoice_num)
      INTO lv_inv_num,
        lv_inv_count
      FROM ap_invoice_lines_all ail,
        ap_invoices_all ap
      WHERE ap.quick_po_header_id      =p_po_header_id
      AND ap.cancelled_date           IS NULL
      AND NVL(ail.quantity_invoiced,0) > 0
      AND ail.invoice_id               =ap.invoice_id
      AND ail.po_line_id               =p_po_line_id;
      IF lv_inv_count                  > 1 THEN
        lv_inv_num                    :=lv_inv_num||' '|| '+';
      END IF;
      RETURN lv_inv_num;
    EXCEPTION
    WHEN OTHERS THEN
      RETURN lv_inv_num;
    END;
  elsif L_TYPE       = 'REC_NUM' THEN
    lv_Receipt_Count:=0;
    lv_Receipt_num  :=NULL;
    BEGIN
      SELECT MIN(rsh.receipt_num),
        COUNT(rsh.receipt_num)
      INTO lv_Receipt_num,
        lv_Receipt_Count
      FROM rcv_shipment_lines rsl,
        rcv_shipment_headers rsh
      WHERE rsl.shipment_header_id = rsh.shipment_header_id
      AND rsl.po_line_id           = p_po_line_id
      ORDER BY rsh.Creation_date ASC;
      IF lv_Receipt_Count > 1 THEN
        lv_Receipt_num   :=lv_Receipt_num||' '|| '+';
      END IF;
      RETURN lv_Receipt_num;
    EXCEPTION
    WHEN OTHERS THEN
      RETURN lv_Receipt_num;
    END;
  elsif L_TYPE     = 'WO_AMT' THEN
    lv_WO_Count   :=0;
    lv_WO_AMT     :=NULL;
    lv_WO_AMT_CHAR:=NULL;
    BEGIN
      SELECT COUNT(mtr.reason_name),
        SUM(cwo.write_off_amount)
      INTO lv_WO_Count,
        lv_WO_AMT
      FROM cst_write_offs cwo,
        po_distributions_all pda,
        mtl_transaction_reasons mtr
      WHERE cwo.po_distribution_id =pda.po_distribution_id
      AND mtr.reason_id            = cwo.reason_id
      AND pda.po_header_id         = p_po_header_id
      AND pda.po_line_id           = p_po_line_id;
      lv_WO_AMT_CHAR              := TO_CHAR(lv_WO_AMT,'99,999,999,999,999.00');
      IF lv_WO_Count               > 1 THEN
        lv_WO_AMT_CHAR            :=lv_WO_AMT_CHAR||' '|| '+';
      END IF;
      RETURN lv_WO_AMT_CHAR;
    EXCEPTION
    WHEN OTHERS THEN
      RETURN lv_WO_AMT_CHAR;
    END;
  elsif L_TYPE = 'RECEIPTDATE' THEN
    BEGIN
      FOR i IN
      (SELECT nvl2(rsh.attribute1, To_Date(rsh.attribute1,'MM/DD/YY'),rt.transaction_date) rcep_date --  INTO lv_lastreceiptdt
      FROM rcv_transactions rt,
        rcv_shipment_headers rsh
      WHERE rt.po_header_id     =p_po_header_id
      AND rt.shipment_header_id = rsh.shipment_header_id
       ORDER BY rsh.receipt_num ASC
      )
      LOOP
    
        lv_lastreceiptdt := i.rcep_date;
      END LOOP;
   
      RETURN lv_lastreceiptdt;
    EXCEPTION
    WHEN OTHERS THEN
      RETURN lv_lastreceiptdt;
    END;
  END IF;
END XX_AP_TRADE_GET_PO_DETAILS;
-- +===================================================================+
-- | Name  : ap_trade_po_Inquiry_headers                               |
-- | Description     : This pipline fucntion will extract              |
-- |                   the PO headers                                  |
-- |                   records from base tables                        |
-- | Parameters      : p_date_from           IN                        |
-- |                   p_date_to             IN                        |
-- +===================================================================+
FUNCTION ap_trade_po_Inquiry_headers(
    p_date_from         DATE,
    p_date_to           DATE,
    p_po_header_id      NUMBER,
    p_vendor_id         NUMBER,
    p_vendor_site_id    NUMBER,
    p_Inventory_item_id NUMBER,
    p_location_id       NUMBER,
    p_status            VARCHAR2,
    p_org_id            NUMBER,
    p_Dropship          VARCHAR2,
    p_FrontDoor         VARCHAR2,
    p_Noncode           VARCHAR2,
    p_Consignment       VARCHAR2,
    p_trade             VARCHAR2,
    p_NewStore          VARCHAR2,
    p_Replenishment     VARCHAR2,
    p_directimport      VARCHAR2 )
  RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_db_ctt pipelined
IS
  CURSOR v1
  IS
    SELECT pha.po_header_id,
      pha.segment1 PO_Number,
      pha.Creation_date PO_Date,
      aps.vendor_name Supplier_Name,
      aps.segment1 Supplier_Number,
      apsa.vendor_site_code Supplier_Site,
      SUM(pll.quantity * pll.price_override) PO_Amount,
      SUM(pll.quantity) Order_Qty,
      SUM(pll.quantity_received) Receipt_Qty,
      SUM(pll.quantity - pll.quantity_received) Balance_Qty,
      xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( p_po_header_id=>pha.po_header_id , p_type=>'RECEIPTDATE') Last_Receipt,
      pha.ATTRIBUTE_CATEGORY PO_Type,
      apt.name Payment_term,
      pha.authorization_status Status,
      pha.org_id
    FROM
      ap_terms apt,
      ap_suppliers aps,
      ap_supplier_sites_all apsa,
      po_line_locations_all pll,
      po_lines_all pla,
      po_headers_all pha
    WHERE pha.creation_date BETWEEN NVL(p_date_from,pha.creation_date) AND NVL(p_date_to,pha.creation_date)
    AND pha.po_header_id       =NVL(p_po_header_id, pha.po_header_id)
    AND pla.po_header_id       =pha.po_header_id
    AND pla.item_id            =NVL(p_Inventory_item_id,pla.item_id)
    AND pll.po_line_id         =pla.po_line_id
    AND pll.ship_to_location_id=NVL(p_location_id,pll.ship_to_location_id)
    AND apsa.vendor_site_id    =pha.vendor_site_id
    AND apsa.vendor_site_id    =NVL(p_vendor_site_id,apsa.vendor_site_id)
    AND aps.vendor_id          =apsa.vendor_id
    AND aps.vendor_id          =NVL(p_vendor_id,aps.vendor_id)
    AND apt.term_id            =aps.terms_id
    AND (pha.ATTRIBUTE_CATEGORY LIKE DECODE(p_Dropship,'Y',(NVL2('DropShip%','DropShip%',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.ATTRIBUTE_CATEGORY LIKE DECODE(p_FrontDoor,'Y',(NVL2('FrontDoor%','FrontDoor%',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.ATTRIBUTE_CATEGORY =DECODE(p_Noncode,'Y',(NVL2('Non-Code','Non-Code',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.ATTRIBUTE_CATEGORY =DECODE(p_Consignment,'Y',(NVL2('Consignment','Consignment',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.ATTRIBUTE_CATEGORY =DECODE(p_trade,'Y',(NVL2('Trade','Trade',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.ATTRIBUTE_CATEGORY =DECODE(p_NewStore,'Y',(NVL2('New Store','New Store',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.attribute_category =DECODE(p_Replenishment,'Y',(NVL2('Replenishment','Replenishment',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.attribute_category =DECODE(p_directimport,'Y',(NVL2('Direct Import','Direct Import',pha.attribute_category)), (NVL2('X','X',pha.attribute_category)))
    OR pha.attribute_category =DECODE(p_Dropship
      ||p_FrontDoor
      ||p_Noncode
      ||p_Consignment
      ||p_trade
      ||p_NewStore
      ||p_Replenishment
      ||p_directimport,'NNNNNNNN',pha.attribute_category))
    AND pha.authorization_status =NVL(p_status,pha.authorization_status)
    AND pha.org_id               = NVL(p_org_id, pha.org_id)
    AND EXISTS
      (SELECT 1
      FROM XX_FIN_TRANSLATEVALUES TV,
        XX_FIN_TRANSLATEDEFINITION TD
      WHERE TD.TRANSLATION_NAME = 'XX_AP_TRADE_CATEGORIES'
      AND TV.TRANSLATE_ID       = TD.TRANSLATE_ID
      AND TV.ENABLED_FLAG       = 'Y'
      AND SYSDATE BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,SYSDATE)
      AND TV.TARGET_VALUE1 = NVL(apsa.ATTRIBUTE8,'X')
        ||''
      )
  GROUP BY pha.po_header_id,
    pha.segment1,
    pha.Creation_date,
    aps.vendor_name,
    aps.segment1,
    apsa.vendor_site_code,
    pha.attribute_category,
    apt.name,
    --    plc.displayed_field,
    pha.authorization_status,
    pha.org_id;
TYPE ap_po_trade_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_db INDEX BY PLS_INTEGER;
  l_ap_po_trade_db ap_po_trade_db_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors, -24381);
  n NUMBER := 0;
BEGIN
  IF l_ap_po_trade_db.count > 0 THEN
    l_ap_po_trade_db.delete;
  END IF;
  FOR i IN v1
  LOOP
    l_ap_po_trade_db(n).PO_header_id    := i.PO_header_id;
    l_ap_po_trade_db(n).PO_Number       := i.PO_Number;
    l_ap_po_trade_db(n).PO_Date         := i.PO_Date;
    l_ap_po_trade_db(n).Supplier_Name   := i.Supplier_Name;
    l_ap_po_trade_db(n).Supplier_Number := i.Supplier_Number;
    l_ap_po_trade_db(n).Supplier_Site   := i.Supplier_Site;
    l_ap_po_trade_db(n).PO_Amount       := i.PO_Amount;
    l_ap_po_trade_db(n).Order_Qty       := i.Order_Qty;
    l_ap_po_trade_db(n).Receipt_Qty     := i.Receipt_Qty;
    l_ap_po_trade_db(n).Balance_Qty     := i.Balance_Qty;
    l_ap_po_trade_db(n).Last_Receipt    := i.Last_Receipt;
    l_ap_po_trade_db(n).PO_Type         := i.PO_Type;
    l_ap_po_trade_db(n).Payment_term    := i.Payment_term;
    l_ap_po_trade_db(n).status          := i.status;
    l_ap_po_trade_db(n).org_id          := i.org_id;
    n                                   := n+1;
  END LOOP;
  -- END LOOP;
  IF l_ap_po_trade_db.count              = 0 THEN
    l_ap_po_trade_db(0).PO_header_id    := NULL;
    l_ap_po_trade_db(0).PO_Number       := NULL;
    l_ap_po_trade_db(0).PO_Date         := NULL;
    l_ap_po_trade_db(0).Supplier_Name   := NULL;
    l_ap_po_trade_db(n).Supplier_Number := NULL;
    l_ap_po_trade_db(0).Supplier_Site   := NULL;
    l_ap_po_trade_db(0).PO_Amount       := NULL;
    l_ap_po_trade_db(0).Order_Qty       := NULL;
    l_ap_po_trade_db(0).Receipt_Qty     := NULL;
    l_ap_po_trade_db(0).Balance_Qty     := NULL;
    l_ap_po_trade_db(0).Last_Receipt    := NULL;
    l_ap_po_trade_db(0).PO_Type         := NULL;
    l_ap_po_trade_db(0).Payment_term    := NULL;
    l_ap_po_trade_db(0).status          := NULL;
    l_ap_po_trade_db(0).org_id          := NULL;
  END IF;
  FOR i IN l_ap_po_trade_db.First .. l_ap_po_trade_db.last
  LOOP
    --dbms_output.put_line('Test '||l_chargeback_db(i).vendor_id);
    pipe row ( l_ap_po_trade_db(i) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || i || ' Array Index: ' || SQL%BULK_EXCEPTIONS(i).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) ) ;
  END LOOP;
END ap_trade_po_Inquiry_headers;
-- +===================================================================+
-- | Name  : ap_trade_po_Inquiry_details                               |
-- | Description     : This pipline fucntion will extract              |
-- |                   the PO details                                  |
-- |                   records from base tables                        |
-- | Parameters      : p_po_header_id           IN                     |
-- |                                                                   |
-- +===================================================================+
FUNCTION ap_trade_po_Inquiry_details(
    p_po_header_id NUMBER,
    p_PO_Num       VARCHAR2)
  RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_details_db_ctt pipelined
IS
  CURSOR v2
  IS
    SELECT pla.po_header_id,
      pla.po_line_id,
      pla.line_num Line_Number,
      msi.segment1 SKU,
      msi.description SKU_Description,
      mcat.segment3 Dept,
      pla.unit_meas_lookup_Code UOM,
      pla.quantity Quantity,
      pla.unit_price Unit_Price,
      (pla.quantity * pla.unit_price) Line_Amount,
      pla.vendor_product_num VPC,
      lpad(ltrim(SUBSTR(hrl.location_code,1,6),0),4,'0') Location,
      DECODE(pll.INSPECTION_REQUIRED_FLAG
      ||pll.RECEIPT_REQUIRED_FLAG,'NN','2-Way','NY','3-Way','YY','4-Way',NULL) Match_Level,
      pll.quantity_received Received_Qty,
      xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'Qty') Invoiced_Qty,
      xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'INV_NUM') Invoice_number,
      xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'REC_NUM') Receipt_number,
      DECODE(pll.INSPECTION_REQUIRED_FLAG
      ||pll.RECEIPT_REQUIRED_FLAG,'NY',pll.quantity_received-xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'Qty'), 'NN',pla.quantity-xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'Qty'),NULL) Unmatched_Qty,
      crs.PO_Balance Accrual_Amount,
      xx_ap_po_trade_dashboard_pkg.XX_AP_TRADE_GET_PO_DETAILS( pla.po_header_id , pla.po_line_id , 'WO_AMT') WrittenOff_Amount,
      --   sum(cwo.write_off_amount) WrittenOff_Amount,
      --  crs.Write_Off_Balance WrittenOff_Amount,
      (
      SELECT segment3
      FROM gl_code_combinations
      WHERE code_combination_id= pod.ACCRUAL_ACCOUNT_ID
      ) Accrual_Account,
    (SELECT segment3
    FROM gl_code_combinations
    WHERE code_combination_id= pod.VARIANCE_ACCOUNT_ID
    ) Variance_Account
  FROM cst_write_offs cwo,
    cst_reconciliation_summary crs,
    mtl_categories_b mcat,
    hr_locations_all hrl,
    mtl_system_items_b msi,
    po_distributions_all pod,
    po_line_locations_all pll,
    po_lines_all pla
  WHERE pla.po_header_id         =p_po_header_id
  AND pll.po_line_id             =pla.po_line_id
  AND pll.po_header_id           =pla.po_header_id
  AND pod.line_location_id       =pll.line_location_id
  AND pod.po_line_id             =pla.po_line_id
  AND msi.inventory_item_id      =pla.item_id
  AND msi.organization_id        =441
  AND hrl.location_id            =pll.ship_to_location_id
  AND mcat.category_id           =pla.category_id
  AND crs.po_distribution_id (+) =pod.PO_DISTRIBUTION_ID
  AND crs.accrual_account_id (+) =pod.ACCRUAL_ACCOUNT_ID
  AND cwo.po_distribution_id (+) = pod.po_distribution_id
  ORDER BY pla.line_num;
 
TYPE ap_po_trade_details_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_details_db INDEX BY PLS_INTEGER;
  l_ap_po_trade_details_db ap_po_trade_details_db_ctt;
  l_error_count_det NUMBER;
  ex_dml_errors_det EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors_det, -24381);
  n NUMBER := 0;
BEGIN
  IF l_ap_po_trade_details_db.count > 0 THEN
    l_ap_po_trade_details_db.delete;
  END IF;
  FOR j IN v2
  LOOP
    l_ap_po_trade_details_db(n).PO_header_id      := j.PO_header_id;
    l_ap_po_trade_details_db(n).PO_line_id        := j.PO_line_id;
    l_ap_po_trade_details_db(n).PO_Number         := p_PO_Num; --j.PO_Number;
    l_ap_po_trade_details_db(n).Line_Number       := j.Line_Number;
    l_ap_po_trade_details_db(n).SKU               := j.SKU;
    l_ap_po_trade_details_db(n).SKU_DESCRIPTION   := j.SKU_DESCRIPTION;
    l_ap_po_trade_details_db(n).Dept              := j.Dept;
    l_ap_po_trade_details_db(n).UOM               := j.UOM;
    l_ap_po_trade_details_db(n).QUANTITY          := j.QUANTITY;
    l_ap_po_trade_details_db(n).UNIT_PRICE        := j.UNIT_PRICE;
    l_ap_po_trade_details_db(n).Line_Amount       := j.Line_Amount;
    l_ap_po_trade_details_db(n).VPC               := j.VPC;
    l_ap_po_trade_details_db(n).Location          := j.Location;
    l_ap_po_trade_details_db(n).Match_Level       := j.Match_Level;
    l_ap_po_trade_details_db(n).Received_Qty      := j.Received_Qty;
    l_ap_po_trade_details_db(n).Invoiced_Qty      := j.Invoiced_Qty;
    l_ap_po_trade_details_db(n).Receipt_number    := j.Receipt_number;
    l_ap_po_trade_details_db(n).Invoice_number    := j.Invoice_number;
    l_ap_po_trade_details_db(n).Unmatched_Qty     := j.Unmatched_Qty;
    l_ap_po_trade_details_db(n).Accrual_Amount    := j.Accrual_Amount;
    l_ap_po_trade_details_db(n).WrittenOff_Amount := j.WrittenOff_Amount;
    l_ap_po_trade_details_db(n).Accrual_Account   := j.Accrual_Account;
    l_ap_po_trade_details_db(n).Variance_Account  := j.Variance_Account;
    n                                             := n+1;
  END LOOP;
  IF l_ap_po_trade_details_db.count                = 0 THEN
    l_ap_po_trade_details_db(0).PO_header_id      :=NULL;
    l_ap_po_trade_details_db(0).PO_line_id        :=NULL;
    l_ap_po_trade_details_db(0).PO_Number         :=NULL;
    l_ap_po_trade_details_db(0).Line_Number       :=NULL;
    l_ap_po_trade_details_db(0).SKU               :=NULL;
    l_ap_po_trade_details_db(0).SKU_DESCRIPTION   :=NULL;
    l_ap_po_trade_details_db(0).Dept              :=NULL;
    l_ap_po_trade_details_db(0).UOM               :=NULL;
    l_ap_po_trade_details_db(0).QUANTITY          :=NULL;
    l_ap_po_trade_details_db(0).UNIT_PRICE        :=NULL;
    l_ap_po_trade_details_db(0).Line_Amount       :=NULL;
    l_ap_po_trade_details_db(0).VPC               :=NULL;
    l_ap_po_trade_details_db(0).Location          :=NULL;
    l_ap_po_trade_details_db(0).Match_Level       :=NULL;
    l_ap_po_trade_details_db(0).Received_Qty      :=NULL;
    l_ap_po_trade_details_db(0).Invoiced_Qty      :=NULL;
    l_ap_po_trade_details_db(0).Receipt_number    :=NULL;
    l_ap_po_trade_details_db(0).Invoice_number    :=NULL;
    l_ap_po_trade_details_db(0).Unmatched_Qty     :=NULL;
    l_ap_po_trade_details_db(0).Accrual_Amount    :=NULL;
    l_ap_po_trade_details_db(0).WrittenOff_Amount :=NULL;
    l_ap_po_trade_details_db(0).Accrual_Account   :=NULL;
    l_ap_po_trade_details_db(0).Variance_Account  :=NULL;
  END IF;
  FOR j IN l_ap_po_trade_details_db.First .. l_ap_po_trade_details_db.last
  LOOP
    pipe row ( l_ap_po_trade_details_db(j) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors_det THEN
  l_error_count_det := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count_det);
  FOR j IN 1 .. l_error_count_det
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || j || ' Array Index: ' || SQL%BULK_EXCEPTIONS(j).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE) ) ;
  END LOOP;
END ap_trade_po_Inquiry_details;
-- +===================================================================+
-- | Name  : xx_ap_get_disp_receipts                                        |
-- | Description     : This pipline fucntion will extract              |
-- |                   the Receipt popup window                        |
-- |                                                                   |
-- | Parameters      : p_po_header_id           IN                     |
-- |                   p_po_line_id             IN                     |
-- +===================================================================+
FUNCTION xx_ap_get_disp_receipts(
    p_po_line_id NUMBER )
  RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_rec_db_ctt pipelined
IS
  CURSOR v3
  IS
    SELECT rsl.po_header_id,
      rsl.po_line_id,
      rsh.receipt_num Receipt_number,
      --  rsh.creation_date Receipt_Date,
      rt.transaction_date Receipt_Date,
      SUM(rsl.Quantity_Received) Qty
    FROM rcv_shipment_lines rsl,
      rcv_shipment_headers rsh,
      rcv_transactions rt
    WHERE rsl.shipment_header_id = rsh.shipment_header_id
      --  AND rsl.po_header_id         = 714183
    AND rsl.po_line_id        = p_po_line_id
    AND rt.transaction_type   ='RECEIVE'
    AND rt.shipment_header_id = rsh.shipment_header_id
    AND rt.shipment_line_id   = rsl.shipment_line_id
    GROUP BY rsl.po_header_id,
      rsl.po_line_id,
      rsh.receipt_num,
      rt.transaction_date
    ORDER BY rt.transaction_date ASC;
  
TYPE ap_po_trade_rec_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_rec_db INDEX BY PLS_INTEGER;
  l_ap_po_trade_rec_db ap_po_trade_rec_db_ctt;
  l_error_count_det NUMBER;
  ex_dml_errors_det EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors_det, -24381);
  n NUMBER := 0;
BEGIN
  IF l_ap_po_trade_rec_db.count > 0 THEN
    l_ap_po_trade_rec_db.delete;
  END IF;
  FOR k IN v3
  LOOP
    l_ap_po_trade_rec_db(n).PO_header_id   := k.PO_header_id;
    l_ap_po_trade_rec_db(n).PO_line_id     := k.PO_line_id;
    l_ap_po_trade_rec_db(n).Receipt_number := k.Receipt_number;
    l_ap_po_trade_rec_db(n).Receipt_Date   := k.Receipt_Date;
    l_ap_po_trade_rec_db(n).Qty            := k.Qty;
    n                                      := n+1;
  END LOOP;
  IF l_ap_po_trade_rec_db.count             = 0 THEN
    l_ap_po_trade_rec_db(0).PO_header_id   :=NULL;
    l_ap_po_trade_rec_db(0).PO_line_id     :=NULL;
    l_ap_po_trade_rec_db(0).Receipt_number :=NULL;
    l_ap_po_trade_rec_db(0).Receipt_Date   :=NULL;
    l_ap_po_trade_rec_db(0).Qty            :=NULL;
  END IF;
  FOR k IN l_ap_po_trade_rec_db.First .. l_ap_po_trade_rec_db.last
  LOOP
    --dbms_output.put_line('Test '||l_chargeback_db(i).vendor_id);
    pipe row ( l_ap_po_trade_rec_db(k) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors_det THEN
  l_error_count_det := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count_det);
  FOR k IN 1 .. l_error_count_det
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || k || ' Array Index: ' || SQL%BULK_EXCEPTIONS(k).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(k).ERROR_CODE) ) ;
  END LOOP;
END xx_ap_get_disp_receipts;
-- +===================================================================+
-- | Name  : xx_ap_get_disp_invoice                                        |
-- | Description     : This pipline fucntion will extract              |
-- |                   the Receipt popup window                        |
-- |                                                                   |
-- | Parameters      : p_po_header_id           IN                     |
-- |                   p_po_line_id             IN                     |
-- +===================================================================+
FUNCTION xx_ap_get_disp_invoice(
    p_po_header_id NUMBER,
    p_po_line_id   NUMBER )
  RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_inv_db_ctt pipelined
IS
  CURSOR v4
  IS
    SELECT po_header_id,
      po_line_id,
      creation_date,
      invoice_number,
      invoice_qty invoice_qty,
      invoice_price invoice_price,
      status
    FROM
      (SELECT ail.PO_header_id,
        ail.PO_line_id,
        ap.creation_date,
        AP.INVOICE_NUM Invoice_number,
        ail.Quantity_Invoiced Invoice_Qty,
        ail.unit_price Invoice_Price,
        get_inv_status(ap.invoice_id) Status
      FROM ap_invoice_lines_all ail,
        AP_InVOICES_ALL AP
      WHERE ap.quick_po_header_id      =p_po_header_id
      AND ap.cancelled_date           IS NULL
      AND NVL(ail.quantity_invoiced,0) > 0
      AND ail.invoice_id               =ap.invoice_id
      AND ail.po_line_id               =p_po_line_id
      );
TYPE ap_po_trade_inv_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_inv_db INDEX BY PLS_INTEGER;
  l_ap_po_trade_inv_db ap_po_trade_inv_db_ctt;
  l_error_count_det NUMBER;
  ex_dml_errors_det EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors_det, -24381);
  n NUMBER := 0;
BEGIN
  IF l_ap_po_trade_inv_db.count > 0 THEN
    l_ap_po_trade_inv_db.delete;
  END IF;
  FOR l IN v4
  LOOP
    l_ap_po_trade_inv_db(n).PO_header_id   := l.PO_header_id;
    l_ap_po_trade_inv_db(n).PO_line_id     := l.PO_line_id;
    l_ap_po_trade_inv_db(n).Invoice_number := l.Invoice_number;
    l_ap_po_trade_inv_db(n).Invoice_Qty    := l.Invoice_Qty;
    l_ap_po_trade_inv_db(n).Invoice_Price  := l.Invoice_Price;
    l_ap_po_trade_inv_db(n).Status         := l.Status;
    n                                      := n+1;
  END LOOP;
  -- END LOOP;
  IF l_ap_po_trade_inv_db.count             = 0 THEN
    l_ap_po_trade_inv_db(0).PO_header_id   :=NULL;
    l_ap_po_trade_inv_db(0).PO_line_id     :=NULL;
    l_ap_po_trade_inv_db(0).Invoice_number :=NULL;
    l_ap_po_trade_inv_db(0).Invoice_Qty    :=NULL;
    l_ap_po_trade_inv_db(0).Invoice_Price  :=NULL;
    l_ap_po_trade_inv_db(0).Status         :=NULL;
  END IF;
  FOR l IN l_ap_po_trade_inv_db.First .. l_ap_po_trade_inv_db.last
  LOOP
    pipe row ( l_ap_po_trade_inv_db(l) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors_det THEN
  l_error_count_det := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count_det);
  FOR l IN 1 .. l_error_count_det
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || l || ' Array Index: ' || SQL%BULK_EXCEPTIONS(l).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(l).ERROR_CODE) ) ;
  END LOOP;
END xx_ap_get_disp_invoice;
-- +===================================================================+
-- | Name  : xx_ap_get_disp_writeoff                                        |
-- | Description     : This pipline fucntion will extract              |
-- |                   the Receipt popup window                        |
-- |                                                                   |
-- | Parameters      : p_po_header_id           IN                     |
-- |                   p_po_line_id             IN                     |
-- +===================================================================+
FUNCTION xx_ap_get_disp_writeoff(
    p_po_header_id NUMBER,
    p_po_line_id   NUMBER )
  RETURN xx_ap_po_trade_dashboard_pkg.ap_po_trade_writeoff_db_ctt pipelined
IS
  CURSOR v5
  IS
    SELECT pda.po_header_id,
      pda.po_line_id,
      mtr.reason_name Reason_code,
      cwo.transaction_date Writeoff_Date,
      TO_CHAR(cwo.write_off_amount,'9999999,999,999,999.00') Amount
    FROM cst_write_offs cwo,
      po_distributions_all pda,
      mtl_transaction_reasons mtr
    WHERE cwo.po_distribution_id =pda.po_distribution_id
    AND mtr.reason_id            = cwo.reason_id
    AND pda.po_header_id         =p_po_header_id
    AND pda.po_line_id           =p_po_line_id;
TYPE ap_po_trade_writeoff_db_ctt
IS
  TABLE OF xx_ap_po_trade_dashboard_pkg.ap_po_trade_writeoff_db INDEX BY PLS_INTEGER;
  l_ap_po_trade_writeoff_db ap_po_trade_writeoff_db_ctt;
  l_error_count_det NUMBER;
  ex_dml_errors_det EXCEPTION;
  PRAGMA EXCEPTION_INIT(ex_dml_errors_det, -24381);
  n NUMBER := 0;
BEGIN
  IF l_ap_po_trade_writeoff_db.count > 0 THEN
    l_ap_po_trade_writeoff_db.delete;
  END IF;
  FOR m IN v5
  LOOP
    l_ap_po_trade_writeoff_db(n).PO_header_id  := m.PO_header_id;
    l_ap_po_trade_writeoff_db(n).PO_line_id    := m.PO_line_id;
    l_ap_po_trade_writeoff_db(n).Reason_code   := m.Reason_code;
    l_ap_po_trade_writeoff_db(n).Writeoff_Date := m.Writeoff_Date;
    l_ap_po_trade_writeoff_db(n).Amount        := m.Amount;
    n                                          := n+1;
  END LOOP;
  IF l_ap_po_trade_writeoff_db.count            = 0 THEN
    l_ap_po_trade_writeoff_db(0).PO_header_id  :=NULL;
    l_ap_po_trade_writeoff_db(0).PO_line_id    :=NULL;
    l_ap_po_trade_writeoff_db(0).Reason_code   :=NULL;
    l_ap_po_trade_writeoff_db(0).Writeoff_Date :=NULL;
    l_ap_po_trade_writeoff_db(0).Amount        :=NULL;
  END IF;
  FOR m IN l_ap_po_trade_writeoff_db.First .. l_ap_po_trade_writeoff_db.last
  LOOP
    pipe row ( l_ap_po_trade_writeoff_db(m) ) ;
  END LOOP;
  RETURN;
EXCEPTION
WHEN ex_dml_errors_det THEN
  l_error_count_det := SQL%BULK_EXCEPTIONS.count;
  DBMS_OUTPUT.put_line('Number of failures: ' || l_error_count_det);
  FOR m IN 1 .. l_error_count_det
  LOOP
    DBMS_OUTPUT.put_line ( 'Error: ' || m || ' Array Index: ' || SQL%BULK_EXCEPTIONS(m).error_index || ' Message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(m).ERROR_CODE) ) ;
  END LOOP;
END xx_ap_get_disp_writeoff;
-- +===================================================================+
-- | Name  : get_inv_status                                            |
-- | Description     : This pipline fucntion will extract              |
-- |                   invoice status                                  |
-- |                                                                   |
-- | Parameters      : p_invoice_id           IN                       |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_inv_status(
    p_invoice_id IN NUMBER)
  RETURN VARCHAR2
IS
  v_status VARCHAR2(1):='N';
BEGIN

xla_security_pkg.set_security_context(602);

  SELECT 'Y'
  INTO v_status
  FROM dual
  WHERE NOT EXISTS
    (SELECT 'x'
    FROM AP_HOLDS_ALL
    WHERE INVOICE_ID         =p_invoice_id
    AND RELEASE_LOOKUP_CODE IS NULL
    )
  AND EXISTS
    (SELECT 'x'
    FROM XLA_EVENTS XEV,
      XLA_TRANSACTION_ENTITIES XTE
    WHERE XTE.SOURCE_ID_INT_1=p_invoice_id
    AND XTE.APPLICATION_ID   = 200
    AND XTE.ENTITY_CODE      = 'AP_INVOICES'
    AND XEV.ENTITY_ID        = XTE.ENTITY_ID
    AND XEV.EVENT_TYPE_CODE LIKE '%VALIDATED%'
    );
  RETURN(v_status);
EXCEPTION
WHEN OTHERS THEN
  RETURN(v_status);
END get_inv_status;
------------------------------------------------------
-- AP Trade PO Inquiry
-- Solution ID:211
-- RICE_ID : E3522
------------------------------------------------------------
END xx_ap_po_trade_dashboard_pkg;

/
SHOW ERROR;