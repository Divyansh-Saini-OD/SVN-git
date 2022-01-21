create or replace PACKAGE body xx_ap_trade_rct_inq_pkg
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name        : xx_ap_trade_rct_inq_pkg                                                     |
  -- |  RICE ID     : E3523
  -- |  Solution ID : 218 AP Trade – Receipt Detail Inquiry                                       |
  -- |  Description : Dash board Query are build using pipeline Function for performance          |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-Nov-17   Priyam Parmar    Initial version
  -- | 1.1         27-APR-18   Priyam Parmar     Code change for performance tunning in PRDGB in get_data_tmp and beforereport
  -- | 1.2         11-Oct-18   Atul Khard        Changed Receipt Date column display value        |
  -- |                                           from rst.transaction_date to rsh.attribute1 for  |
  -- |                                           NAIT-61741                                       |
  -- | 1.3         25-Aug-2021 Mayur Palsokar   Modified XXAPRECEITPDETINQ_WRAPPER for NAIT-167419|
  -- +============================================================================================+
  -- +===================================================================+
  -- | Name            : xx_ap_trade_rct_inquiry                         |
  -- | Description     : This pipline function will extract              |
  -- |                   details for invoice matched receipts
  --    and receipts which doesnot have invoices to match.               |
  -- |                                                                   |
  -- | Parameters      : p_date_from           IN                        |
  -- |                   p_date_to             IN
  -- |                   P_PERIOD_FROM         IN
  -- |                   P_Period_to           IN
  -- |                   P_INVOICE_NUM         IN
  -- |                   P_RECEIPT_NUM         IN
  -- |                   P_PO_NUM              IN
  -- +===================================================================+
FUNCTION xx_ap_trade_rct_inquiry(
    p_date_from DATE ,
    p_date_to   DATE ,
    -- P_PERIOD_FROM VARCHAR2,
    --- P_PERIOD_TO   VARCHAR2,
    /*P_INVOICE_NUM VARCHAR2,
    P_RECEIPT_NUM VARCHAR2,
    P_PO_NUM      VARCHAR2,*/
    p_invoice_id        NUMBER,
    p_receipt_id        NUMBER,
    p_po_header_id      NUMBER,
    p_inventory_item_id NUMBER,
    p_supplier_site_id  NUMBER,
    p_vendor_id         NUMBER,
    p_user_id           NUMBER)
  RETURN xx_ap_trade_rct_inq_pkg.ap_trade_rct_det_ctt pipelined
IS
  CURSOR rct_inq (p_dt_from DATE,p_dt_to DATE)
  IS
    SELECT-- DISTINCT
      rcp.receipt_num,
      rcp.rcp_date,
      rcp.shipment_header_id,
      rcp.po_header_id,
      rcp.po_line_id,
      t.invoice_num,
      rcp.supplier_num,
      rcp.supplier_name,
      rcp.supplier_site,
      rcp.po,
      rcp.po_line_num,
      rcp.sku,
      rcp.location,
      rcp.uom,
      rcp.rec_line_num,
      rcp.receipt_line_amt,
      rcp.unit_price,
      rcp.po_qty,
      rcp.rcp_qty,
      rcp.receipt_qty,
      rcp.quantity_shipped,
      t.po tpo ,
      t.po_line_id tpo_line_id,
      t.receipt_num treceipt_num,
      t.receipt_qty treceipt_qty,---SAME AS RCP_QTY FOR RECEIPT CORRECTION
      t.unit_price tunit_price,
      xx_ap_trade_rct_inq_pkg.f_inv_number(t.po,t.po_line_id,t.receipt_num,p_user_id) inv_num_fifo,
      t.inv_val tinv_val,
      rcp.transaction_date,
      rcp.attribute1,
      rcp.item_id,
      rcp.vendor_site_id
    FROM xx_ap_receipt_po_temp_218 rcp,
      xx_ap_po_recinv_dashb_gtemp t
    WHERE 1 =1
    AND rcp.rcp_date BETWEEN to_date(TO_CHAR(p_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND rcp.po_vendor_id       =NVL(p_vendor_id, rcp.po_vendor_id)
    AND rcp.shipment_header_id = NVL(p_receipt_id,rcp.shipment_header_id)
    AND rcp.po_header_id       = NVL(p_po_header_id,rcp.po_header_id)
    AND NVL(t.invoice_id,1)    = NVL(p_invoice_id,NVL(t.invoice_id,1) )
    AND rcp.user_id            =p_user_id
    AND rcp.item_id            = NVL(p_inventory_item_id,rcp.item_id)
    AND rcp.vendor_site_id     =NVL(p_supplier_site_id,rcp.vendor_site_id)
    AND rcp.po_header_id       =t.po_header_id(+)
    AND rcp.po_line_id         =t.po_line_id(+)
    AND rcp.receipt_num        =t.receipt_num (+)
    AND rcp.user_id            =t.user_id(+)
    AND t.request_id          IS NULL
    AND rcp.request_id        IS NULL
    ORDER BY rcp.rcp_date DESC,
      rcp.receipt_num ,
      rec_line_num;
type ap_trade_rct_det_ctt
IS
  TABLE OF xx_ap_trade_rct_inq_pkg.ap_trade_rct_det INDEX BY pls_integer;
  l_ap_trade_rct_det ap_trade_rct_det_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  pragma exception_init(ex_dml_errors, -24381);
  n            NUMBER := 0;
  l_start_date DATE;
  l_end_date   DATE;
  v_inv_qtty   NUMBER :=0;
  --- V_RECEIPT_QTY  NUMBER;
  v_inv_num_fifo VARCHAR2(20);
  v_uninv_qtty   NUMBER      :=0;
  v_rct_age      NUMBER      :=NULL;
  v_sign         NUMBER      :=0;
  v_flag         VARCHAR2(5) := 'Y';
  v_rec_amt      NUMBER      :=0;
  v_uninv_amt    NUMBER      :=0;
BEGIN
  IF ( p_date_from IS NOT NULL AND p_date_to IS NOT NULL ) THEN
    l_start_date   := p_date_from;
    l_end_date     := p_date_to;
  END IF;
  IF p_receipt_id IS NOT NULL THEN
    BEGIN
      SELECT MIN(rcp_date),
        MAX(rcp_date)
      INTO l_start_date,
        l_end_date
      FROM xx_ap_receipt_po_temp_218 t
      WHERE t.user_id   =p_user_id
      AND t.request_id IS NULL;
      ---  select max(RCP_DATE) into L_END_DATE from XX_AP_RECEIPT_PO_TEMP_218 T ;
    EXCEPTION
    WHEN OTHERS THEN
      l_start_date:=sysdate+1;
      l_end_date  :=l_start_date;
    END ;
  END IF;
  --- IF P_PO_NUM IS NOT NULL THEN
  IF p_po_header_id IS NOT NULL THEN
    BEGIN
      SELECT MIN(rcp_date),
        MAX(rcp_date)
      INTO l_start_date,
        l_end_date
      FROM xx_ap_po_recinv_dashb_gtemp t
      WHERE t.user_id   =p_user_id
      AND t.request_id IS NULL;
    EXCEPTION
    WHEN OTHERS THEN
      l_start_date:=sysdate+1;
      l_end_date  :=l_start_date;
    END ;
  END IF;
  ---  IF P_INVOICE_NUM IS NOT NULL THEN
  IF p_invoice_id IS NOT NULL THEN
    SELECT MIN(rcp_date),
      MAX(rcp_date)
    INTO l_start_date,
      l_end_date
    FROM xx_ap_po_recinv_dashb_gtemp t
    WHERE t.user_id   =p_user_id
    AND t.request_id IS NULL;
  END IF;
  IF l_ap_trade_rct_det.count > 0 THEN
    l_ap_trade_rct_det.delete;
  END IF;
  FOR i IN rct_inq (l_start_date,l_end_date)
  LOOP
    v_inv_qtty   := 0 ;
    v_uninv_qtty :=0;
    BEGIN
      SELECT NVL(xx_ap_trade_rct_inq_pkg.f_inv_qtty( i.tpo,i.tpo_line_id,i.treceipt_num,p_user_id),0)
      INTO v_inv_qtty
      FROM dual;
      IF v_inv_qtty  =0 THEN
        v_uninv_qtty:=i.rcp_qty;--I.RECEIPT_QTY;
        v_uninv_amt := ROUND( i.rcp_qty *i.unit_price,2);
      ELSE
        v_uninv_qtty:=i.treceipt_qty -v_inv_qtty;
        v_uninv_amt :=(i.rcp_qty     -v_inv_qtty)*i.tunit_price;
      END IF;
      ------LOGIC FOR RECEIPT AGE--------
      v_sign         :=i.rcp_qty-v_inv_qtty;
      IF SIGN (v_sign)=1 THEN
        v_rct_age    :=ROUND(sysdate-(NVL(i.attribute1,TRUNC(i.transaction_date))));
      ELSE
        v_rct_age:=NULL;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      v_inv_qtty  :=0;
      v_uninv_qtty:=0;
      v_uninv_amt :=0;
      v_sign      :=0;
      v_rct_age   :=0;
    END ;
    l_ap_trade_rct_det(n).receipt_num      := i.receipt_num;
    l_ap_trade_rct_det(n).rcp_date         := NVL(i.attribute1,TRUNC(i.transaction_date));--I.RCP_DATE;
    l_ap_trade_rct_det(n).supplier_num     := i.supplier_num;
    l_ap_trade_rct_det(n).supplier_name    := i.supplier_name;
    l_ap_trade_rct_det(n).supplier_site    := i.supplier_site;
    l_ap_trade_rct_det(n).po               := i.po;
    l_ap_trade_rct_det(n).po_line_num      := i.po_line_num;
    l_ap_trade_rct_det(n).sku              := i.sku;
    l_ap_trade_rct_det(n).location         := i.location;
    l_ap_trade_rct_det(n).uom              := i.uom;
    l_ap_trade_rct_det(n).rec_line_num     := i.rec_line_num;
    l_ap_trade_rct_det(n).receipt_line_amt := i.receipt_line_amt;
    l_ap_trade_rct_det(n).po_qty           := i.po_qty;
    l_ap_trade_rct_det(n).rcp_qty          := i.rcp_qty;
    l_ap_trade_rct_det(n).invoice_num      := i.invoice_num;
    l_ap_trade_rct_det(n).inv_qtty         := v_inv_qtty;
    l_ap_trade_rct_det(n).inv_num_fifo     := i.inv_num_fifo;
    l_ap_trade_rct_det(n).uninv_qtty       := v_uninv_qtty;
    l_ap_trade_rct_det(n).uninv_amt        := v_uninv_amt;
    l_ap_trade_rct_det(n).rct_age          := v_rct_age;
    l_ap_trade_rct_det(n).unit_price       := i.unit_price;
    -----ADDED 17 JAN 2018
    l_ap_trade_rct_det(n).item_id        :=i.item_id;
    l_ap_trade_rct_det(n).vendor_site_id :=i.vendor_site_id;
    l_ap_trade_rct_det(n).po_line_id     := i.po_line_id;
    l_ap_trade_rct_det(n).inv_val        := i.tinv_val;
    n                                    := n+1;
  END LOOP;
  IF l_ap_trade_rct_det.count > 0 THEN
    FOR i IN l_ap_trade_rct_det.first .. l_ap_trade_rct_det.last
    LOOP
      pipe row ( l_ap_trade_rct_det(i) ) ;
    END LOOP;
  END IF;
  -- COMMIT;
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := sql%bulk_exceptions.count;
  dbms_output.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    dbms_output.put_line ( 'Error: ' || i || ' Array Index: ' || sql%bulk_exceptions(i).error_index || ' Message: ' || sqlerrm(-sql%bulk_exceptions(i).error_code) ) ;
  END LOOP;
END xx_ap_trade_rct_inquiry;
-- +===================================================================+
-- | Name  : F_INV_QTTY                                                                    |
-- | Description     : Function to get_inv_status                                           |
-- |
--
-- |                                                                                       |
-- | Parameters      : p_invoice_id       IN
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
    FROM ap_holds_all
    WHERE invoice_id         =p_invoice_id
    AND release_lookup_code IS NULL
    )
  AND EXISTS
    (SELECT 'x'
    FROM xla_events xev,
      xla_transaction_entities xte
    WHERE xte.source_id_int_1=p_invoice_id
    AND xte.application_id   = 200
    AND xte.entity_code      = 'AP_INVOICES'
    AND xev.entity_id        = xte.entity_id
    AND xev.event_type_code LIKE '%VALIDATED%'
    );
  RETURN(v_status);
EXCEPTION
WHEN OTHERS THEN
  RETURN(v_status);
END get_inv_status;
-- +===================================================================+
-- | Name  : F_INV_QTTY                                                                    |
-- | Description     : Function to get invoice applied quantity from Temp table            |
-- |
--
-- |                                                                                       |
-- | Parameters      : P_PO_NUM       IN
-- |                   P_PO_LINE_ID   IN
-- |                   P_RECEIPT_NUM  IN
-- +===================================================================+
FUNCTION f_inv_qtty(
    p_po_num      VARCHAR2,
    p_po_line_id  NUMBER,
    p_receipt_num VARCHAR2,
    p_user_id     NUMBER)
  RETURN NUMBER
IS
  v_inv_applied_amt NUMBER :=0;
BEGIN
  SELECT SUM (inv_applied_amt)
  INTO v_inv_applied_amt
  FROM xx_ap_po_recinv_dashb_gtemp
  WHERE po        = p_po_num
  AND po_line_id  =p_po_line_id
  AND receipt_num =p_receipt_num
  AND user_id     =p_user_id
  AND request_id IS NULL;
  RETURN NVL(v_inv_applied_amt,0);
EXCEPTION
WHEN no_data_found THEN
  v_inv_applied_amt:=0;
  RETURN v_inv_applied_amt;
END f_inv_qtty;
-- +===================================================================+
-- | Name  : F_INV_QTTY                                                                    |
-- | Description     : Function to get invoice applied quantity from Temp table            |
-- |
--
-- |                                                                                       |
-- | Parameters      : P_PO_NUM       IN
-- |                   P_PO_LINE_ID   IN
-- |                   P_RECEIPT_NUM  IN
-- +===================================================================+
FUNCTION f_inv_qtty_request(
    p_po_num      VARCHAR2,
    p_po_line_id  NUMBER,
    p_receipt_num VARCHAR2,
    p_user_id     NUMBER,
    p_request_id  NUMBER)
  RETURN NUMBER
IS
  v_inv_applied_amt NUMBER :=0;
BEGIN
  SELECT SUM (inv_applied_amt)
  INTO v_inv_applied_amt
  FROM xx_ap_po_recinv_dashb_gtemp
  WHERE po       = p_po_num
  AND po_line_id =p_po_line_id
  AND receipt_num=p_receipt_num
  AND user_id    =p_user_id
  AND request_id =p_request_id;
  RETURN NVL(v_inv_applied_amt,0);
EXCEPTION
WHEN no_data_found THEN
  v_inv_applied_amt:=0;
  RETURN v_inv_applied_amt;
END f_inv_qtty_request;
-- +===================================================================+
-- | Name  : F_INV_number                                                                    |
-- | Description     : Function to get first invoice matched (FIFO invoice)                  |
-- |
--
-- |                                                                                         |
-- | Parameters      : P_PO_NUM       IN
-- |                   P_PO_LINE_ID   IN
-- |                   P_RECEIPT_NUM  IN
-- +===================================================================+
FUNCTION f_inv_number(
    p_po_num      VARCHAR2,
    p_po_line_id  NUMBER,
    p_receipt_num VARCHAR2,
    p_user_id     NUMBER )
  RETURN VARCHAR2
IS
  v_inv_number VARCHAR2(20);
  v_count      NUMBER;
BEGIN
  SELECT COUNT (invoice_num),
    MIN (invoice_num)
  INTO v_count,
    v_inv_number
  FROM xx_ap_po_recinv_dashb_gtemp
  WHERE po        = p_po_num
  AND po_line_id  =p_po_line_id
  AND receipt_num =p_receipt_num
  AND user_id     =p_user_id
  AND request_id IS NULL;
  IF v_count      >1 THEN
    RETURN v_inv_number ||'+';
  ELSE
    RETURN v_inv_number;
  END IF;
EXCEPTION
WHEN no_data_found THEN
  v_inv_number:='XXX';
  RETURN v_inv_number;
END f_inv_number;
FUNCTION f_inv_number_request(
    p_po_num      VARCHAR2,
    p_po_line_id  NUMBER,
    p_receipt_num VARCHAR2,
    p_user_id     NUMBER,
    p_request_id  NUMBER )
  RETURN VARCHAR2
IS
  v_inv_number VARCHAR2(20);
  v_count      NUMBER;
BEGIN
  SELECT COUNT (invoice_num),
    MIN (invoice_num)
  INTO v_count,
    v_inv_number
  FROM xx_ap_po_recinv_dashb_gtemp
  WHERE po       = p_po_num
  AND po_line_id =p_po_line_id
  AND receipt_num=p_receipt_num
  AND user_id    =p_user_id
  AND request_id =p_request_id;
  IF v_count     >1 THEN
    RETURN v_inv_number ||'+';
  ELSE
    RETURN v_inv_number;
  END IF;
EXCEPTION
WHEN no_data_found THEN
  v_inv_number:='XXX';
  RETURN v_inv_number;
END f_inv_number_request;
-- +===================================================================+
-- | Name  : Get_data_temp                                                                    |
-- | Description     : Function to populate temp table with FIFO invoice details              |
-- |
--
-- |                                                                                          |
-- | Parameters      : p_date_from           IN                                               |
-- |                   p_date_to             IN
-- |                   P_PERIOD_FROM         IN
-- |                   P_Period_to           IN
-- |                   P_INVOICE_NUM         IN
-- |                   P_RECEIPT_NUM         IN
-- |                   P_PO_NUM              IN
-- +===================================================================+
PROCEDURE get_data_temp(
    p_date_from         DATE ,
    p_date_to           DATE ,
    p_user_id           NUMBER,
    p_invoice_id        NUMBER,
    p_receipt_id        NUMBER,
    p_po_header_id      NUMBER,
    p_inventory_item_id NUMBER,
    p_supplier_site_id  NUMBER,
    p_vendor_id         NUMBER,
    p_result OUT VARCHAR2,
    p_error OUT VARCHAR2)
IS
  pragma autonomous_transaction;
  CURSOR c_rcpt (p_dt_from DATE,p_dt_to DATE,v_header_id NUMBER)
  IS
    -----paddy's Query
    SELECT pha.segment1 po,
      pla.po_line_id po_line_id,
      pla.line_num po_line_num,
      pla.quantity po_qty,
      SUBSTR(hrl.location_code,1,6) location,
      rsl.unit_of_measure uom,
      pla.unit_price,
      -- RSL.QUANTITY_SHIPPED QUANTITY_SHIPPED,
      ROUND(rsl.quantity_received * pla.unit_price,2) receipt_line_amt,
      rsl.line_num rec_line_num,
      --XX_AP_TRADE_RCT_INQ_PKG.GET_SKU(PLA.ITEM_ID) SKU,
      msi.segment1 sku,
      aps.segment1 supplier_num,
      aps.vendor_id,
      aps.vendor_name supplier_name,
      ast.vendor_site_code supplier_site,
      pla.item_id,
      ast.vendor_site_id,
      rsl.quantity_shipped receipt_qty,
      pha.po_header_id po_header_id,
      NVL(to_date(rsh.attribute1,'MM/DD/YY'),rst.transaction_date) rcp_date,--rst.transaction_date rcp_date, --changed for NAIT-61741
      ---rsh.CREATION_DATE RCP_DATE,CHANGED FOR Receipt Date is the Transaction Date and not Creation Date.
      rsh.receipt_num,
      rsh.shipment_header_id receipt_id,
      --- Rst.QUANTITY RCP_QTY,
      rsl.quantity_received rcp_qty,--changed for receipt Correction
      to_date(rsh.attribute1,'MM/DD/YY') attribute1,
      rst.transaction_date
    FROM hr_locations_all hrl,
      mtl_system_items_b msi,
      ap_suppliers aps,
      ap_supplier_sites_all ast,
      po_lines_all pla,
      po_headers_all pha,
      rcv_shipment_lines rsl,
      rcv_shipment_headers rsh,
      rcv_transactions rst
    WHERE rst.transaction_date BETWEEN to_date(TO_CHAR(p_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(p_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND rst.po_header_id      =NVL(v_header_id,rst.po_header_id)
    AND rst.transaction_type  ='RECEIVE'
    AND rsl.shipment_header_id=rst.shipment_header_id
    AND rsl.shipment_line_id  =rst.shipment_line_id
    AND rsl.item_id           =NVL(p_inventory_item_id,rsl.item_id)
      -----Added by priyam as it was missing from original Query-start -----
      --- AND rsl.po_header_id       =NVL(p_po_header_id,rsl.po_header_id)
      ----------end----------------------------------------------
    AND rsh.shipment_header_id       =rsl.shipment_header_id
    AND rsh.vendor_id                =NVL(p_vendor_id,rsh.vendor_id)
    AND rsh.vendor_site_id           =NVL(p_supplier_site_id,rsh.vendor_site_id)
    AND pha.po_header_id             =rsl.po_header_id
    AND pla.po_header_id             =pha.po_header_id
    AND pla.po_line_id               =rsl.po_line_id
    AND ast.vendor_site_id           =pha.vendor_site_id
    AND aps.vendor_id                =ast.vendor_id
    AND hrl.inventory_organization_id=rsl.to_organization_id
    AND msi.inventory_item_id        =rsl.item_id
    AND msi.organization_id+0        =441
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ast.attribute8
        ||''
      )
  ORDER BY pha.segment1 ,
    pha.po_header_id ,
    pla.po_line_id,
    rsh.creation_date,
    rsh.receipt_num;

  CURSOR c_inv( v_po_header_id NUMBER, v_po_line_id NUMBER)
  IS
    SELECT a.invoice_num,
      a.invoice_id,
      a.inv_date,
      a.inv_qty,
      a.po_header_id,
      a.po_line_id,
      xx_ap_trade_rct_inq_pkg.get_inv_status(a.invoice_id) val_status
    FROM
      (SELECT aia.invoice_num,
        aia.invoice_id,
        aia.creation_date inv_date,
        aila.po_header_id,
        aila.po_line_id,
        SUM(aila.quantity_invoiced) inv_qty
      FROM ap_invoice_lines_all aila,
        ap_invoices_all aia
      WHERE aia.quick_po_header_id=v_po_header_id
      AND aila.invoice_id         =aia.invoice_id
      AND aila.po_line_id         =v_po_line_id
      AND aila.quantity_invoiced  > 0
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ap_po_recinv_dashb_gtemp t
        WHERE t.po_header_id = aila.po_header_id
        AND aila.po_line_id  = t.po_line_id
        AND t.invoice_num    = aia.invoice_num
        AND t.inv_rem_qty   <= 0
        AND t.user_id        =p_user_id
        AND t.request_id    IS NULL
        )
    GROUP BY aia.invoice_num,
      aia.invoice_id,
      aia.creation_date,
      aila.po_header_id,
      aila.po_line_id
      ) a
    ORDER BY a.inv_date,
      a.invoice_num;

    l_reciept_num        VARCHAR2(100) := 'X';
    l_rec_rem_qty        NUMBER        := 0;
    l_inv_rem_qty        NUMBER        := 0;
    l_inv_appl_qty       NUMBER        := 0;
    l_rcpt_consumed_flag VARCHAR2(1)   := 'N';
    l_inv_consumed_flag  VARCHAR2(1)   := 'N';
    v_inv_qty_rem        NUMBER        :=0 ;
    v_val_status         VARCHAR2(1);
    v_user_id            NUMBER;
    v_invoice_fifo_num   NUMBER :=0;
    l_start_date         DATE;
    l_end_date           DATE;
    l_header_id          NUMBER;
    v_po_header_id       NUMBER;
    v_data_218           NUMBER:=0;
    v_data_gtemp         NUMBER:=0;
  BEGIN
    v_user_id :=p_user_id;
    DELETE
    FROM xx_ap_po_recinv_dashb_gtemp
    WHERE user_id   =v_user_id
    AND request_id IS NULL;
    DELETE
    FROM xx_ap_receipt_po_temp_218
    WHERE user_id   =v_user_id
    AND request_id IS NULL;
    COMMIT;
    BEGIN
      IF p_receipt_id IS NOT NULL THEN
        BEGIN
          SELECT b.po_header_id
          INTO v_po_header_id
          FROM rcv_shipment_headers a,
            rcv_transactions b
          WHERE a.shipment_header_id =p_receipt_id
          AND a.shipment_header_id   =b.shipment_header_id
          AND b.transaction_type     ='RECEIVE'
          AND rownum                 <2---Changes suggested by paddy
          AND EXISTS
            (SELECT 'x'
            FROM ap_supplier_sites_all site
            WHERE site.vendor_site_id=a.vendor_site_id
            AND EXISTS
              (SELECT 'x'
              FROM xx_fin_translatevalues tv,
                xx_fin_translatedefinition td
              WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
              AND tv.translate_id       = td.translate_id
              AND tv.enabled_flag       = 'Y'
              AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
              AND tv.target_value1 = site.attribute8
                ||''
              )
            );
        EXCEPTION
        WHEN OTHERS THEN
          v_po_header_id:=NULL;---Changes suggested by paddy
          p_result      :='E';
          p_error       := SUBSTR(sqlerrm, 1, 200);
        END ;
      END IF;
      IF p_po_header_id IS NOT NULL THEN
        v_po_header_id  :=p_po_header_id;
      END IF;
      ---IF P_PO_NUM IS NOT NULL THEN
      IF v_po_header_id IS NOT NULL THEN
        BEGIN
          SELECT MIN(rst.transaction_date)-1,
            MAX(rst.transaction_date)     +1,
            rst.po_header_id
          INTO l_start_date,
            l_end_date,
            l_header_id
          FROM rcv_shipment_headers rsh,
            rcv_transactions rst
          WHERE 1                   =1
          AND rst.po_header_id      = v_po_header_id
          AND rst.shipment_header_id=rsh.shipment_header_id
          AND rst.transaction_type  ='RECEIVE'
          GROUP BY rst.po_header_id;
        EXCEPTION
        WHEN OTHERS THEN
          l_start_date:=sysdate+1;
          l_end_date  :=l_start_date;
        END ;
      END IF;
      -----Changes suggested by paddy
      IF p_invoice_id IS NOT NULL THEN
        BEGIN
          SELECT NVL(po_header_id,quick_po_header_id)
          INTO v_po_header_id
          FROM ap_supplier_sites_all b,
            ap_invoices_all a
          WHERE a.invoice_id  =p_invoice_id
          AND b.vendor_site_id=a.vendor_site_id+0
          AND EXISTS
            (SELECT 'x'
            FROM xx_fin_translatevalues tv,
              xx_fin_translatedefinition td
            WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
            AND tv.translate_id       = td.translate_id
            AND tv.enabled_flag       = 'Y'
            AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
            AND tv.target_value1 = b.attribute8
              ||''
            );
        EXCEPTION
        WHEN OTHERS THEN
          v_po_header_id:=NULL;
        END;
        IF v_po_header_id IS NOT NULL THEN
          BEGIN
            SELECT MIN(rst.transaction_date)-1,
              MAX(rst.transaction_date)     +1,
              rst.po_header_id
            INTO l_start_date,
              l_end_date,
              l_header_id
            FROM rcv_shipment_headers rsh,
              rcv_transactions rst
            WHERE 1                   =1
            AND rst.po_header_id      = v_po_header_id
            AND rst.shipment_header_id=rsh.shipment_header_id
            AND rst.transaction_type  ='RECEIVE'
            GROUP BY rst.po_header_id;
          EXCEPTION
          WHEN OTHERS THEN
            l_start_date:=sysdate+1;
            l_end_date  :=l_start_date;
          END ;
        END IF;
      END IF;
      IF ( p_date_from IS NOT NULL AND p_date_to IS NOT NULL ) THEN
        l_start_date   := p_date_from;
        l_end_date     := p_date_to;
      END IF;
    END;
    FOR i IN c_rcpt (l_start_date,l_end_date,l_header_id)
    LOOP
      BEGIN
        INSERT
        INTO xx_ap_receipt_po_temp_218
          (
            po ,
            po_line_id ,
            po_line_num ,
            po_unit_price ,
            po_qty ,
            location ,
            uom ,
            unit_price ,
            quantity_shipped ,
            receipt_line_amt ,
            rec_line_num ,
            sku ,
            supplier_num ,
            supplier_name ,
            supplier_site ,
            receipt_qty ,
            po_header_id ,---PO_NUM
            rcp_date ,
            receipt_num ,
            shipment_header_id ,---RECEIPT_ID
            rcp_qty ,
            transaction_date,
            attribute1,
            user_id ,
            po_vendor_id,   ---SUPPLIER NAME
            item_id,        ---SKU
            vendor_site_id,----SUPPLIER SITE
            request_id
          )
          VALUES
          (
            i.po ,
            i.po_line_id ,
            i.po_line_num ,
            i.unit_price ,
            i.po_qty ,
            i.location ,
            i.uom ,
            i.unit_price ,
            i.rcp_qty ,
            i.receipt_line_amt ,
            i.rec_line_num ,
            i.sku ,
            i.supplier_num ,
            i.supplier_name ,
            i.supplier_site ,
            i.receipt_qty ,--rsl
            i.po_header_id ,
            i.rcp_date ,
            i.receipt_num ,
            i.receipt_id ,
            i.rcp_qty ,---rsl
            i.transaction_date,
            i.attribute1,
            p_user_id ,
            i.vendor_id,
            i.item_id,
            i.vendor_site_id,
            NULL
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        p_result :='E';
        p_error  := SUBSTR(sqlerrm, 1, 200);
      END;
      l_rec_rem_qty     := i.rcp_qty ;
      l_inv_rem_qty     :=0;
      l_inv_appl_qty    := 0;
      v_invoice_fifo_num:=1;
      FOR j IN c_inv
      (
        i.po_header_id,i.po_line_id
      )
      LOOP
        IF l_rec_rem_qty > 0 THEN
          BEGIN
            SELECT SUM(t1.inv_rem_qty)
            INTO v_inv_qty_rem
            FROM xx_ap_po_recinv_dashb_gtemp t1
            WHERE 1           =1
            AND t1.receipt_id =
              (SELECT MAX(t.receipt_id)
              FROM xx_ap_po_recinv_dashb_gtemp t
              WHERE t1.invoice_num  =t.invoice_num
              AND t.invoice_num     =j.invoice_num
              AND t.rcpt_remain_qty = 0
              AND t.user_id         =p_user_id
              AND t.request_id     IS NULL
              )
            AND t1.invoice_num =j.invoice_num
            AND t1.user_id     =p_user_id
            AND t1.request_id IS NULL;
          EXCEPTION
          WHEN no_data_found THEN
            v_inv_qty_rem:=0;
          END ;
          IF v_inv_qty_rem >0 THEN
            l_rec_rem_qty := l_rec_rem_qty - v_inv_qty_rem;
          ELSE
            l_rec_rem_qty := l_rec_rem_qty - j.inv_qty;
          END IF;
          IF l_rec_rem_qty <= 0 THEN
            l_inv_rem_qty  := -1 * l_rec_rem_qty;
            l_rec_rem_qty  := 0;
          ELSE
            l_inv_rem_qty :=0;
          END IF;
          IF v_inv_qty_rem  >0 THEN
            l_inv_appl_qty :=v_inv_qty_rem - l_inv_rem_qty;
          ELSE
            l_inv_appl_qty := j.inv_qty - l_inv_rem_qty;
          END IF;
          INSERT
          INTO xx_ap_po_recinv_dashb_gtemp
            (
              po,
              po_line_id,
              po_header_id,
              rcp_date,
              receipt_num,
              receipt_id,
              rcp_qty,
              inv_date,
              invoice_num,
              inv_qty,
              rcpt_remain_qty,
              inv_rem_qty,
              inv_applied_amt,
              rcpt_consumed_flag,
              inv_consumed_flag,
              v_inv_qty_rem,
              inv_val,
              po_line_num,
              po_qty,
              location,
              uom,
              unit_price,
              quantity_shipped,
              receipt_line_amt,
              rec_line_num,
              sku,
              supplier_num,
              supplier_name,
              supplier_site,
              user_id,
              invoice_fifo_num ,
              receipt_qty,
              creation_date ,
              po_vendor_id,
              item_id,
              vendor_site_id,
              invoice_id,
              request_id
            )
            VALUES
            (
              i.po,
              i.po_line_id,
              i.po_header_id,
              i.rcp_date,
              i.receipt_num,
              i.receipt_id,
              i.rcp_qty,
              j.inv_date,
              j.invoice_num,
              j.inv_qty,
              l_rec_rem_qty,
              l_inv_rem_qty,
              l_inv_appl_qty,
              l_rcpt_consumed_flag,
              l_inv_consumed_flag,
              v_inv_qty_rem,
              j.val_status,
              --- V_VAL_STATUS,
              i.po_line_num,
              i.po_qty,
              i.location,
              i.uom,
              i.unit_price,
              i.rcp_qty ,
              i.receipt_line_amt,
              i.rec_line_num,
              i.sku,
              i.supplier_num,
              i.supplier_name,
              i.supplier_site,
              v_user_id,
              v_invoice_fifo_num,
              i.rcp_qty,
              --- I.RECEIPT_QTY,--rsl changed for receipt correction
              sysdate ,
              i.vendor_id,
              i.item_id,
              i.vendor_site_id,
              j.invoice_id,
              NULL
            );
          v_invoice_fifo_num:=0;
          COMMIT;
        END IF;
      END LOOP;
    END LOOP;
    ------------------Code added to restrict success status when no data is present for User search
    BEGIN
      SELECT NVL(COUNT(po_header_id),0)
      INTO v_data_gtemp
      FROM xx_ap_po_recinv_dashb_gtemp
      WHERE user_id   =p_user_id
      AND request_id IS NULL;
      SELECT NVL(COUNT(po_header_id),0)
      INTO v_data_218
      FROM xx_ap_receipt_po_temp_218
      WHERE user_id   =p_user_id
      AND request_id IS NULL;
      IF v_data_gtemp > 0 OR v_data_218 > 0 THEN
        p_result     :='S';
      ELSE
        p_result :='E';
        p_error  :='No data inserted in Temp';
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      p_result :='E';
      p_error  := SUBSTR(sqlerrm, 1, 200);
    END ;
    --P_RESULT     :='S';
    ---------
  EXCEPTION
  WHEN OTHERS THEN
    p_result :='E';
    p_error  := SUBSTR(sqlerrm, 1, 200);
  END get_data_temp;
FUNCTION get_sku(
    p_po_item_id NUMBER )
  RETURN VARCHAR2
IS
  v_sku VARCHAR2(100);
BEGIN
  /*(SELECT MSIB.SEGMENT1
  INTO V_SKU
  FROM MTL_SYSTEM_ITEMS_B MSIB
  WHERE MSIB.INVENTORY_ITEM_ID=P_PO_ITEM_ID
  AND MSIB.ORGANIZATION_ID+0  =441;*/
  SELECT
    /*+ INDEX(msi MTL_SYSTEM_ITEMS_B_N1) */
    msib.segment1
  INTO v_sku
  FROM mtl_system_items_b msib
  WHERE msib.organization_id +0        =441
  AND msib.inventory_item_id           =p_po_item_id
  AND NVL(enabled_flag,'Y')            = 'Y'
  AND NVL(end_date_active,sysdate +1 ) > sysdate ;
  RETURN v_sku;
EXCEPTION
WHEN OTHERS THEN
  v_sku:=NULL;
  RETURN v_sku;
END get_sku;

PROCEDURE xxapreceitpdetinq_wrapper(
    p_date_from         DATE ,
    p_date_to           DATE ,
    p_invoice_id        NUMBER,
    p_receipt_id        NUMBER,
    p_po_header_id      NUMBER,
    p_inventory_item_id NUMBER,
    p_supplier_site_id  NUMBER,
    p_vendor_id         NUMBER,
    p_user_id        NUMBER,
    p_request_id OUT NUMBER)
IS
  ln_request_id  NUMBER(15);
  lb_layout      BOOLEAN;
  lb_req_status  BOOLEAN;
  lc_status_code VARCHAR2(10);
  lc_phase       VARCHAR2(50);
  lc_status      VARCHAR2(50);
  lc_devphase    VARCHAR2(50);
  lc_devstatus   VARCHAR2(50);
  lc_message     VARCHAR2(50);
  l_resp_id      NUMBER;
  l_resp_appl_id NUMBER;
  l_user_id      NUMBER;
  --- lb_print_option      BOOLEAN;
BEGIN
  BEGIN
    SELECT application_id,
      responsibility_id
    INTO l_resp_appl_id,
      l_resp_id
    FROM fnd_responsibility_tl
    WHERE responsibility_name ='OD (US) AP Batch Jobs';
    SELECT user_id
    INTO l_user_id
    FROM fnd_user
	-- WHERE user_name=TO_CHAR(p_user_id);  -- Commented for NAIT-167419
	WHERE (user_name=TO_CHAR(p_user_id) OR user_name=LPAD(TO_CHAR(p_user_id),6,'0'));     -- Added for NAIT-16741
  EXCEPTION
  WHEN OTHERS THEN
    l_resp_appl_id:=0;
    l_resp_id     :=0;
    l_user_id     :=0;
  END;
  ---fnd_global.apps_initialize(3820959,52296,200);
  fnd_global.apps_initialize(l_user_id,l_resp_id,l_resp_appl_id);
  fnd_file.put_line(fnd_file.log,'USER ID'|| l_user_id);
  fnd_file.put_line(fnd_file.log,'Responsibility ID'|| l_resp_id);
  fnd_file.put_line(fnd_file.log,'Responsibility Application ID'|| l_resp_appl_id);
  lb_layout     := fnd_request.add_layout( 'XXFIN' ,'XXAPRECEITPDETINQ' ,'en' ,'US' ,'EXCEL' );
  ln_request_id := fnd_request.submit_request (application => 'XXFIN' , program => 'XXAPRECEITPDETINQ' , description => NULL , sub_request => false , argument1 => TO_CHAR(fnd_date.canonical_to_date(TO_CHAR(p_date_from,'YYYY-MON-DD')),'YY-MON-DD')--FND_DATE.CANONICAL_TO_DATE(P_DATE_FROM)--TO_DATE(P_DATE_FROM,'DD-MON-YYYY')---'YYYY/MM/DD HH24:MI:SS'
  , argument2 => TO_CHAR(fnd_date.canonical_to_date(TO_CHAR(p_date_to,'YYYY-MON-DD')),'YY-MON-DD')                                                                                                                                                    --FND_DATE.CANONICAL_TO_DATE(P_DATE_TO)---TO_DATE(P_DATE_TO,'DD-MON-YYYY')
  , argument3 => p_invoice_id , argument4 => p_receipt_id , argument5 => p_po_header_id , argument6 => p_inventory_item_id , argument7 => p_supplier_site_id , argument8 => p_vendor_id , argument9 => p_user_id );
  COMMIT;
  IF ln_request_id <> 0 THEN
    p_request_id   :=ln_request_id;
  ELSE
    p_request_id:=0;
    ---- FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.output,'EXCEPTION : ' || sqlerrm);
END xxapreceitpdetinq_wrapper;
FUNCTION beforereport
  RETURN BOOLEAN
IS
  pragma autonomous_transaction;
  CURSOR c_rcpt (v_dt_from DATE,v_dt_to DATE,v_header_id NUMBER)
  IS
    -----paddy's Query
    SELECT pha.segment1 po,
      pla.po_line_id po_line_id,
      pla.line_num po_line_num,
      pla.quantity po_qty,
      SUBSTR(hrl.location_code,1,6) location,
      rsl.unit_of_measure uom,
      pla.unit_price,
      ----RSL.QUANTITY_SHIPPED QUANTITY_SHIPPED,
      ROUND(rsl.quantity_received*pla.unit_price,2) receipt_line_amt,
      rsl.line_num rec_line_num,
      --XX_AP_TRADE_RCT_INQ_PKG.GET_SKU(PLA.ITEM_ID) SKU,
      msi.segment1 sku,
      aps.segment1 supplier_num,
      aps.vendor_id,
      aps.vendor_name supplier_name,
      ast.vendor_site_code supplier_site,
      pla.item_id,
      ast.vendor_site_id,
      rsl.quantity_shipped receipt_qty,
      pha.po_header_id po_header_id,
      rst.transaction_date rcp_date,
      ---rsh.CREATION_DATE RCP_DATE,CHANGED FOR Receipt Date is the Transaction Date and not Creation Date.
      rsh.receipt_num,
      rsh.shipment_header_id receipt_id,
      --- Rst.QUANTITY RCP_QTY,
      rsl.quantity_received rcp_qty,--changed for receipt Correction
      to_date(rsh.attribute1,'MM/DD/YY') attribute1,
      rst.transaction_date
    FROM hr_locations_all hrl,
      mtl_system_items_b msi,
      ap_suppliers aps,
      ap_supplier_sites_all ast,
      po_lines_all pla,
      po_headers_all pha,
      rcv_shipment_lines rsl,
      rcv_shipment_headers rsh,
      rcv_transactions rst
    WHERE rst.transaction_date BETWEEN to_date(TO_CHAR(v_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(v_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND rst.po_header_id      =NVL(v_header_id,rst.po_header_id)
    AND rst.transaction_type  ='RECEIVE'
    AND rsl.shipment_header_id=rst.shipment_header_id
    AND rsl.shipment_line_id  =rst.shipment_line_id
    AND rsl.item_id           =NVL(g_inventory_item_id,rsl.item_id)
      --AND rsl.po_header_id       =NVL(g_po_header_id,rsl.po_header_id)
    AND rsh.shipment_header_id       =rsl.shipment_header_id
    AND rsh.vendor_id                =NVL(g_vendor_id,rsh.vendor_id)
    AND rsh.vendor_site_id           =NVL(g_supplier_site_id,rsh.vendor_site_id)
    AND pha.po_header_id             =rsl.po_header_id
    AND pla.po_header_id             =pha.po_header_id
    AND pla.po_line_id               =rsl.po_line_id
    AND ast.vendor_site_id           =pha.vendor_site_id
    AND aps.vendor_id                =ast.vendor_id
    AND hrl.inventory_organization_id=rsl.to_organization_id
    AND msi.inventory_item_id        =rsl.item_id
    AND msi.organization_id+0        =441
    AND EXISTS
      (SELECT 1
      FROM xx_fin_translatevalues tv,
        xx_fin_translatedefinition td
      WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
      AND tv.translate_id       = td.translate_id
      AND tv.enabled_flag       = 'Y'
      AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
      AND tv.target_value1 = ast.attribute8
        ||''
      )
  ORDER BY pha.segment1 ,
    pha.po_header_id ,
    pla.po_line_id,
    rsh.creation_date,
    rsh.receipt_num;

  CURSOR c_inv( v_po_header_id NUMBER, v_po_line_id NUMBER)
  IS
    SELECT a.invoice_num,
      a.invoice_id,
      a.inv_date,
      a.inv_qty,
      a.po_header_id,
      a.po_line_id,
      xx_ap_trade_rct_inq_pkg.get_inv_status(a.invoice_id) val_status
    FROM
      (SELECT aia.invoice_num,
        aia.invoice_id,
        aia.creation_date inv_date,
        aila.po_header_id,
        aila.po_line_id,
        SUM(aila.quantity_invoiced) inv_qty
      FROM ap_invoice_lines_all aila,
        ap_invoices_all aia
      WHERE aia.quick_po_header_id=v_po_header_id
      AND aila.invoice_id         =aia.invoice_id
      AND aila.po_line_id         =v_po_line_id
      AND aila.quantity_invoiced  > 0
      AND NOT EXISTS
        (SELECT 1
        FROM xx_ap_po_recinv_dashb_gtemp t
        WHERE t.po_header_id = aila.po_header_id
        AND aila.po_line_id  = t.po_line_id
        AND t.invoice_num    = aia.invoice_num
        AND t.inv_rem_qty   <= 0
        AND t.user_id        =g_user_id
        AND t.request_id     =fnd_global.conc_request_id
        )
    GROUP BY aia.invoice_num,
      aia.invoice_id,
      aia.creation_date,
      aila.po_header_id,
      aila.po_line_id
      ) a
    ORDER BY a.inv_date,
      a.invoice_num;

    l_reciept_num        VARCHAR2(100) := 'X';
    l_rec_rem_qty        NUMBER        := 0;
    l_inv_rem_qty        NUMBER        := 0;
    l_inv_appl_qty       NUMBER        := 0;
    l_rcpt_consumed_flag VARCHAR2(1)   := 'N';
    l_inv_consumed_flag  VARCHAR2(1)   := 'N';
    v_inv_qty_rem        NUMBER        :=0 ;
    v_val_status         VARCHAR2(1);
    v_user_id            NUMBER;
    v_invoice_fifo_num   NUMBER :=0;
    l_start_date         DATE;
    l_end_date           DATE;
    l_header_id          NUMBER;
    v_po_header_id       NUMBER;
  BEGIN
    v_user_id :=g_user_id;
    -- delete from xx_ap_po_recinv_dashb_gtemp where user_id=v_user_id and request_id is not null;
    --- DELETE FROM XX_AP_RECEIPT_PO_TEMP_218 WHERE USER_ID=V_USER_ID AND REQUEST_ID IS NOT NULL;
    COMMIT;
    BEGIN
      IF g_receipt_id IS NOT NULL THEN
        BEGIN
          SELECT b.po_header_id
          INTO v_po_header_id
          FROM rcv_shipment_headers a,
            rcv_transactions b
          WHERE a.shipment_header_id =g_receipt_id
          AND a.shipment_header_id   =b.shipment_header_id
          AND b.transaction_type     ='RECEIVE'
          AND rownum                 <2---Changes suggested by paddy
          AND EXISTS
            (SELECT 'x'
            FROM ap_supplier_sites_all site
            WHERE site.vendor_site_id=a.vendor_site_id
            AND EXISTS
              (SELECT 'x'
              FROM xx_fin_translatevalues tv,
                xx_fin_translatedefinition td
              WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
              AND tv.translate_id       = td.translate_id
              AND tv.enabled_flag       = 'Y'
              AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
              AND tv.target_value1 = site.attribute8
                ||''
              )
            );
        EXCEPTION
        WHEN OTHERS THEN
          v_po_header_id:=NULL;---Changes suggested by paddy
          --G_RESULT      :='E';
          --- G_ERROR       := SUBSTR(SQLERRM, 1, 200);
        END ;
      END IF;
      IF g_po_header_id IS NOT NULL THEN
        v_po_header_id  :=g_po_header_id;
      END IF;
      ---IF P_PO_NUM IS NOT NULL THEN
      IF v_po_header_id IS NOT NULL THEN
        BEGIN
          SELECT MIN(rst.transaction_date)-1,
            MAX(rst.transaction_date)     +1,
            rst.po_header_id
          INTO l_start_date,
            l_end_date,
            l_header_id
          FROM rcv_shipment_headers rsh,
            rcv_transactions rst
          WHERE 1                   =1
          AND rst.po_header_id      = v_po_header_id
          AND rst.shipment_header_id=rsh.shipment_header_id
          AND rst.transaction_type  ='RECEIVE'
          GROUP BY rst.po_header_id;
        EXCEPTION
        WHEN OTHERS THEN
          l_start_date:=sysdate+1;
          l_end_date  :=l_start_date;
        END ;
      END IF;
      -----Changes suggested by paddy
      IF g_invoice_id IS NOT NULL THEN
        BEGIN
          SELECT NVL(po_header_id,quick_po_header_id)
          INTO v_po_header_id
          FROM ap_supplier_sites_all b,
            ap_invoices_all a
          WHERE a.invoice_id  =g_invoice_id
          AND b.vendor_site_id=a.vendor_site_id+0
          AND EXISTS
            (SELECT 'x'
            FROM xx_fin_translatevalues tv,
              xx_fin_translatedefinition td
            WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'
            AND tv.translate_id       = td.translate_id
            AND tv.enabled_flag       = 'Y'
            AND sysdate BETWEEN tv.start_date_active AND NVL(tv.end_date_active,sysdate)
            AND tv.target_value1 = b.attribute8
              ||''
            );
        EXCEPTION
        WHEN OTHERS THEN
          v_po_header_id:=NULL;
        END;
        IF v_po_header_id IS NOT NULL THEN
          BEGIN
            SELECT MIN(rst.transaction_date)-1,
              MAX(rst.transaction_date)     +1,
              rst.po_header_id
            INTO l_start_date,
              l_end_date,
              l_header_id
            FROM rcv_shipment_headers rsh,
              rcv_transactions rst
            WHERE 1                   =1
            AND rst.po_header_id      = v_po_header_id
            AND rst.shipment_header_id=rsh.shipment_header_id
            AND rst.transaction_type  ='RECEIVE'
            GROUP BY rst.po_header_id;
          EXCEPTION
          WHEN OTHERS THEN
            l_start_date:=sysdate+1;
            l_end_date  :=l_start_date;
          END ;
        END IF;
      END IF;
      IF ( g_date_from IS NOT NULL AND g_date_to IS NOT NULL ) THEN
        l_start_date   := g_date_from;---TO_DATE(G_DATE_FROM,'YYYY/MM/DD HH24:MI:SS');
        l_end_date     := g_date_to; ----to_date(G_DATE_TO,'YYYY/MM/DD HH24:MI:SS');
      END IF;
    END;
    FOR i IN c_rcpt (l_start_date,l_end_date,l_header_id)
    LOOP
      BEGIN
        INSERT
        INTO xx_ap_receipt_po_temp_218
          (
            po ,
            po_line_id ,
            po_line_num ,
            po_unit_price ,
            po_qty ,
            location ,
            uom ,
            unit_price ,
            quantity_shipped ,
            receipt_line_amt ,
            rec_line_num ,
            sku ,
            supplier_num ,
            supplier_name ,
            supplier_site ,
            receipt_qty ,
            po_header_id ,---PO_NUM
            rcp_date ,
            receipt_num ,
            shipment_header_id ,---RECEIPT_ID
            rcp_qty ,
            transaction_date,
            attribute1,
            user_id ,
            po_vendor_id,   ---SUPPLIER NAME
            item_id,        ---SKU
            vendor_site_id,----SUPPLIER SITE
            request_id
          )
          VALUES
          (
            i.po ,
            i.po_line_id ,
            i.po_line_num ,
            i.unit_price ,
            i.po_qty ,
            i.location ,
            i.uom ,
            i.unit_price ,
            i.rcp_qty ,
            i.receipt_line_amt ,
            i.rec_line_num ,
            i.sku ,
            i.supplier_num ,
            i.supplier_name ,
            i.supplier_site ,
            i.receipt_qty ,--rsl
            i.po_header_id ,
            i.rcp_date ,
            i.receipt_num ,
            i.receipt_id ,
            i.rcp_qty ,---rst
            i.transaction_date,
            i.attribute1,
            g_user_id ,
            i.vendor_id,
            i.item_id,
            i.vendor_site_id,
            fnd_global.conc_request_id
          );
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        fnd_file.put_line(fnd_file.log, 'ERROR at xx_ap_trade_rct_inq_pkg.beforeReport during insertion XX_AP_RECEIPT_PO_TEMP_218:- ' || sqlerrm);
      END;
      l_rec_rem_qty     := i.rcp_qty ;
      l_inv_rem_qty     :=0;
      l_inv_appl_qty    := 0;
      v_invoice_fifo_num:=1;
      FOR j IN c_inv
      (
        i.po_header_id,i.po_line_id
      )
      LOOP
        IF l_rec_rem_qty > 0 THEN
          BEGIN
            SELECT SUM(t1.inv_rem_qty)
            INTO v_inv_qty_rem
            FROM xx_ap_po_recinv_dashb_gtemp t1
            WHERE 1           =1
            AND t1.receipt_id =
              (SELECT MAX(t.receipt_id)
              FROM xx_ap_po_recinv_dashb_gtemp t
              WHERE t1.invoice_num  =t.invoice_num
              AND t.invoice_num     =j.invoice_num
              AND t.rcpt_remain_qty = 0
              AND t.user_id         =g_user_id
              AND t.request_id      = fnd_global.conc_request_id
              )
            AND t1.invoice_num =j.invoice_num
            AND t1.user_id     =g_user_id
            AND t1.request_id  = fnd_global.conc_request_id;
          EXCEPTION
          WHEN no_data_found THEN
            v_inv_qty_rem:=0;
          END ;
          IF v_inv_qty_rem >0 THEN
            l_rec_rem_qty := l_rec_rem_qty - v_inv_qty_rem;
          ELSE
            l_rec_rem_qty := l_rec_rem_qty - j.inv_qty;
          END IF;
          IF l_rec_rem_qty <= 0 THEN
            l_inv_rem_qty  := -1 * l_rec_rem_qty;
            l_rec_rem_qty  := 0;
          ELSE
            l_inv_rem_qty :=0;
          END IF;
          IF v_inv_qty_rem  >0 THEN
            l_inv_appl_qty :=v_inv_qty_rem - l_inv_rem_qty;
          ELSE
            l_inv_appl_qty := j.inv_qty - l_inv_rem_qty;
          END IF;
          INSERT
          INTO xx_ap_po_recinv_dashb_gtemp
            (
              po,
              po_line_id,
              po_header_id,
              rcp_date,
              receipt_num,
              receipt_id,
              rcp_qty,
              inv_date,
              invoice_num,
              inv_qty,
              rcpt_remain_qty,
              inv_rem_qty,
              inv_applied_amt,
              rcpt_consumed_flag,
              inv_consumed_flag,
              v_inv_qty_rem,
              inv_val,
              po_line_num,
              po_qty,
              location,
              uom,
              unit_price,
              quantity_shipped,
              receipt_line_amt,
              rec_line_num,
              sku,
              supplier_num,
              supplier_name,
              supplier_site,
              user_id,
              invoice_fifo_num ,
              receipt_qty,
              creation_date ,
              po_vendor_id,
              item_id,
              vendor_site_id,
              invoice_id,
              request_id
            )
            VALUES
            (
              i.po,
              i.po_line_id,
              i.po_header_id,
              i.rcp_date,
              i.receipt_num,
              i.receipt_id,
              i.rcp_qty,
              j.inv_date,
              j.invoice_num,
              j.inv_qty,
              l_rec_rem_qty,
              l_inv_rem_qty,
              l_inv_appl_qty,
              l_rcpt_consumed_flag,
              l_inv_consumed_flag,
              v_inv_qty_rem,
              j.val_status,
              --- V_VAL_STATUS,
              i.po_line_num,
              i.po_qty,
              i.location,
              i.uom,
              i.unit_price,
              i.rcp_qty,
              i.receipt_line_amt,
              i.rec_line_num,
              i.sku,
              i.supplier_num,
              i.supplier_name,
              i.supplier_site,
              v_user_id,
              v_invoice_fifo_num,
              i.rcp_qty,
              --- I.RECEIPT_QTY,--rsl changed for receipt correction
              sysdate ,
              i.vendor_id,
              i.item_id,
              i.vendor_site_id,
              j.invoice_id,
              fnd_global.conc_request_id
            );
          v_invoice_fifo_num:=0;
          COMMIT;
        END IF;
      END LOOP;
    END LOOP;
    --- G_RESULT :='S';
    RETURN true;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'ERROR atxx_ap_trade_rct_inq_pkg.beforeReport during insertion XX_AP_PO_RECINV_DASHB_GTEMP:- ' || sqlerrm);
    --- G_RESULT :='E';
    --- G_ERROR  := SUBSTR(SQLERRM, 1, 200);
    RETURN false;
  END beforereport;
FUNCTION xx_ap_trade_rct_inquiry_xml
  RETURN xx_ap_trade_rct_inq_pkg.ap_trade_rct_det_ctt pipelined
IS
  CURSOR rct_inq (g_dt_from DATE,g_dt_to DATE)
  IS
    SELECT-- DISTINCT
      rcp.receipt_num,
      rcp.rcp_date,
      rcp.shipment_header_id,
      rcp.po_header_id,
      rcp.po_line_id,
      t.invoice_num,
      rcp.supplier_num,
      rcp.supplier_name,
      rcp.supplier_site,
      rcp.po,
      rcp.po_line_num,
      rcp.sku,
      rcp.location,
      rcp.uom,
      rcp.rec_line_num,
      rcp.receipt_line_amt,
      rcp.unit_price,
      rcp.po_qty,
      rcp.rcp_qty,
      rcp.receipt_qty,
      rcp.quantity_shipped,
      t.po tpo ,
      t.po_line_id tpo_line_id,
      t.receipt_num treceipt_num,
      t.receipt_qty treceipt_qty,
      t.unit_price tunit_price,
      xx_ap_trade_rct_inq_pkg.f_inv_number_request(t.po,t.po_line_id,t.receipt_num,g_user_id,fnd_global.conc_request_id) inv_num_fifo,
      t.inv_qty,
      t.inv_applied_amt tinv_applied_amt,
      t.inv_val tinv_val,
      rcp.transaction_date,
      rcp.attribute1,
      rcp.item_id,
      rcp.vendor_site_id
    FROM xx_ap_receipt_po_temp_218 rcp,
      xx_ap_po_recinv_dashb_gtemp t
    WHERE 1 =1
    AND rcp.rcp_date BETWEEN to_date(TO_CHAR(g_dt_from)
      ||' 00:00:00','DD-MON-RR HH24:MI:SS')
    AND to_date(TO_CHAR(g_dt_to)
      ||' 23:59:59','DD-MON-RR HH24:MI:SS')
    AND rcp.po_vendor_id       =NVL(g_vendor_id, rcp.po_vendor_id)
    AND rcp.shipment_header_id = NVL(g_receipt_id,rcp.shipment_header_id)
    AND rcp.po_header_id       = NVL(g_po_header_id,rcp.po_header_id)
    AND NVL(t.invoice_id,1)    = NVL(g_invoice_id,NVL(t.invoice_id,1) )
    AND rcp.user_id            =g_user_id
    AND rcp.item_id            = NVL(g_inventory_item_id,rcp.item_id)
    AND rcp.vendor_site_id     =NVL(g_supplier_site_id,rcp.vendor_site_id)
    AND rcp.po_header_id       =t.po_header_id(+)
    AND rcp.po_line_id         =t.po_line_id(+)
    AND rcp.receipt_num        =t.receipt_num (+)
    AND rcp.user_id            =t.user_id(+)
    AND rcp.request_id         =t.request_id(+)
    AND rcp.request_id         = fnd_global.conc_request_id
    ORDER BY rcp.rcp_date DESC,
      rcp.receipt_num ,
      rec_line_num;
type ap_trade_rct_det_ctt
IS
  TABLE OF xx_ap_trade_rct_inq_pkg.ap_trade_rct_det INDEX BY pls_integer;
  l_ap_trade_rct_det ap_trade_rct_det_ctt;
  l_error_count NUMBER;
  ex_dml_errors EXCEPTION;
  pragma exception_init(ex_dml_errors, -24381);
  n            NUMBER := 0;
  l_start_date DATE;
  l_end_date   DATE;
  v_inv_qtty   NUMBER :=0;
  --- V_RECEIPT_QTY  NUMBER;
  v_inv_num_fifo VARCHAR2(20);
  v_uninv_qtty   NUMBER      :=0;
  v_rct_age      NUMBER      :=NULL;
  v_sign         NUMBER      :=0;
  v_flag         VARCHAR2(5) := 'Y';
  v_rec_amt      NUMBER      :=0;
  v_uninv_amt    NUMBER      :=0;
  v_receipt_num  NUMBER      :=0;
  v_sku          NUMBER      :=0;
  v_po_line_num  NUMBER      :=0;
BEGIN
  IF ( g_date_from IS NOT NULL AND g_date_to IS NOT NULL ) THEN
    l_start_date   := g_date_from;---TO_DATE(G_DATE_FROM,'YYYY/MM/DD HH24:MI:SS');
    l_end_date     := g_date_to;  ---TO_DATE(G_DATE_TO,'YYYY/MM/DD HH24:MI:SS');
  END IF;
  IF l_ap_trade_rct_det.count > 0 THEN
    l_ap_trade_rct_det.delete;
  END IF;
  FOR i IN rct_inq (l_start_date,l_end_date)
  LOOP
    v_inv_qtty   := 0 ;
    v_uninv_qtty :=0;
    BEGIN
      SELECT NVL(xx_ap_trade_rct_inq_pkg.f_inv_qtty_request( i.tpo,i.tpo_line_id,i.treceipt_num,g_user_id, fnd_global.conc_request_id),0)
      INTO v_inv_qtty
      FROM dual;
      IF v_inv_qtty  =0 THEN
        v_uninv_qtty:=i.rcp_qty;
        v_uninv_amt := ROUND( i.rcp_qty *i.unit_price,2);
      ELSE
        v_uninv_qtty:=i.treceipt_qty -v_inv_qtty;
        v_uninv_amt :=(i.rcp_qty     -v_inv_qtty)*i.tunit_price;
      END IF;
      ------LOGIC FOR RECEIPT AGE--------
      v_sign         :=i.rcp_qty-v_inv_qtty;
      IF SIGN (v_sign)=1 THEN
        v_rct_age    :=ROUND(sysdate-(NVL(i.attribute1,TRUNC(i.transaction_date))));
      ELSE
        v_rct_age:=NULL;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      v_inv_qtty  :=0;
      v_uninv_qtty:=0;
      v_uninv_amt :=0;
      v_sign      :=0;
      v_rct_age   :=0;
    END ;
    IF ((i.receipt_num                        = v_receipt_num AND i.sku != v_sku AND i.po_line_num != v_po_line_num) OR (i.receipt_num = v_receipt_num AND i.sku = v_sku AND i.po_line_num != v_po_line_num) OR (i.receipt_num = v_receipt_num AND i.sku != v_sku AND i.po_line_num = v_po_line_num) OR (i.receipt_num != v_receipt_num)) THEN
      v_receipt_num                          := i.receipt_num;
      v_sku                                  := i.sku;
      v_po_line_num                          := i.po_line_num;
      l_ap_trade_rct_det(n).receipt_num      := i.receipt_num;
      l_ap_trade_rct_det(n).rcp_date         := NVL(i.attribute1,TRUNC(i.transaction_date));--I.RCP_DATE;
      l_ap_trade_rct_det(n).supplier_num     := i.supplier_num;
      l_ap_trade_rct_det(n).supplier_name    := i.supplier_name;
      l_ap_trade_rct_det(n).supplier_site    := i.supplier_site;
      l_ap_trade_rct_det(n).po               := i.po;
      l_ap_trade_rct_det(n).po_line_num      := i.po_line_num;
      l_ap_trade_rct_det(n).sku              := i.sku;
      l_ap_trade_rct_det(n).location         := i.location;
      l_ap_trade_rct_det(n).uom              := i.uom;
      l_ap_trade_rct_det(n).rec_line_num     := i.rec_line_num;
      l_ap_trade_rct_det(n).receipt_line_amt := i.receipt_line_amt;
      l_ap_trade_rct_det(n).po_qty           := i.po_qty;
      l_ap_trade_rct_det(n).rcp_qty          := i.rcp_qty;
      l_ap_trade_rct_det(n).invoice_num      := i.invoice_num;
      l_ap_trade_rct_det(n).inv_qtty         := i.tinv_applied_amt; ---V_INV_QTTY;--CHANGED FOR XML OITPUT
      l_ap_trade_rct_det(n).inv_num_fifo     := i.inv_num_fifo;
      l_ap_trade_rct_det(n).uninv_qtty       := v_uninv_qtty;
      l_ap_trade_rct_det(n).uninv_amt        := v_uninv_amt;
      l_ap_trade_rct_det(n).rct_age          := v_rct_age;
      l_ap_trade_rct_det(n).unit_price       := i.unit_price;
      l_ap_trade_rct_det(n).item_id          :=i.item_id;
      l_ap_trade_rct_det(n).vendor_site_id   :=i.vendor_site_id;
      l_ap_trade_rct_det(n).po_line_id       := i.po_line_id;
      l_ap_trade_rct_det(n).inv_val          := i.tinv_val;
    ELSE
      l_ap_trade_rct_det(n).receipt_num      := i.receipt_num;
      l_ap_trade_rct_det(n).rcp_date         := NVL(i.attribute1,TRUNC(i.transaction_date));--I.RCP_DATE;
      l_ap_trade_rct_det(n).supplier_num     := i.supplier_num;
      l_ap_trade_rct_det(n).supplier_name    := i.supplier_name;
      l_ap_trade_rct_det(n).supplier_site    := i.supplier_site;
      l_ap_trade_rct_det(n).po               := i.po;
      l_ap_trade_rct_det(n).po_line_num      := i.po_line_num;
      l_ap_trade_rct_det(n).sku              := i.sku;
      l_ap_trade_rct_det(n).location         := i.location;
      l_ap_trade_rct_det(n).uom              := i.uom;
      l_ap_trade_rct_det(n).rec_line_num     := i.rec_line_num;
      l_ap_trade_rct_det(n).receipt_line_amt := NULL;
      l_ap_trade_rct_det(n).po_qty           := NULL;
      l_ap_trade_rct_det(n).rcp_qty          := NULL;
      l_ap_trade_rct_det(n).invoice_num      := i.invoice_num;
      l_ap_trade_rct_det(n).inv_qtty         := i.tinv_applied_amt; ---V_INV_QTTY;--CHANGED FOR XML OITPUT
      l_ap_trade_rct_det(n).inv_num_fifo     := i.inv_num_fifo;
      l_ap_trade_rct_det(n).uninv_qtty       := NULL;
      l_ap_trade_rct_det(n).uninv_amt        := NULL;
      l_ap_trade_rct_det(n).rct_age          := NULL;
      l_ap_trade_rct_det(n).unit_price       := i.unit_price;
      l_ap_trade_rct_det(n).item_id          :=i.item_id;
      l_ap_trade_rct_det(n).vendor_site_id   :=i.vendor_site_id;
      l_ap_trade_rct_det(n).po_line_id       := i.po_line_id;
      l_ap_trade_rct_det(n).inv_val          := i.tinv_val;
    END IF;
    n := n+1;
  END LOOP;
  IF l_ap_trade_rct_det.count > 0 THEN
    FOR i IN l_ap_trade_rct_det.first .. l_ap_trade_rct_det.last
    LOOP
      pipe row ( l_ap_trade_rct_det(i) ) ;
    END LOOP;
  END IF;
  -- COMMIT;
  RETURN;
EXCEPTION
WHEN ex_dml_errors THEN
  l_error_count := sql%bulk_exceptions.count;
  dbms_output.put_line('Number of failures: ' || l_error_count);
  FOR i IN 1 .. l_error_count
  LOOP
    dbms_output.put_line ( 'Error: ' || i || ' Array Index: ' || sql%bulk_exceptions(i).error_index || ' Message: ' || sqlerrm(-sql%bulk_exceptions(i).error_code) ) ;
  END LOOP;
END xx_ap_trade_rct_inquiry_xml;
FUNCTION afterreport
  RETURN BOOLEAN
IS
BEGIN
  DELETE
  FROM xx_ap_po_recinv_dashb_gtemp
  WHERE request_id =fnd_global.conc_request_id;
  DELETE
  FROM xx_ap_receipt_po_temp_218
  WHERE request_id =fnd_global.conc_request_id;
  RETURN true;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'ERROR atxx_ap_trade_rct_inq_pkg.AfterReport' || sqlerrm);
  --- G_RESULT :='E';
  --- G_ERROR  := SUBSTR(SQLERRM, 1, 200);
  RETURN false;
END afterreport;
END xx_ap_trade_rct_inq_pkg;
/
SHOW ERRORS;