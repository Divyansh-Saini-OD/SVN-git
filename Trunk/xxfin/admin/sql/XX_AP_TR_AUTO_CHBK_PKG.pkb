CREATE OR REPLACE
PACKAGE BODY XX_AP_TR_AUTO_CHBK_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  XX_AP_TR_AUTO_CHBK_PKG                                                           |
  -- |  RICE ID   :  E3522_OD Trade Match Foundation                                              |
  -- |  Description:  Plsql package for Auto Chargeback                                           |
  -- |                                                                                            |
  -- |                                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         05/08/2017   Avinash Baddam   Initial version                                  |
  -- | 1.1         07/22/2017   Naveen Patha     Modified to check multi invoices                 |
  -- | 1.1         10/12/2017   Naveen Patha     Modified to skip invoices if po price is zero    |
  -- | 1.2         11/14/2017   Paddy Sanjeevi   Added Invoice source parameter                   |
  -- | 1.3         10/12/2017   Naveen Patha     Modified description                             |
  -- | 1.4         01/04/2018   Paddy Sanjeevi   Modified to removed reason code while insert     |
  -- | 1.5         01/11/2018   Paddy Sanjeevi   Added terms_date in invoice interface            |
  -- | 1.6         01/18/2018   Naveen Patha     Round amount                                     |
  -- | 1.7         01/30/2018   Naveen Patha     Added org_id parameter                           |
  -- | 1.8         02/26/2018   Paddy Sanjeevi   Added check for custom holds exists              |
  -- | 1.9         03/15/2018   Paddy Sanjeevi   Modified to populate attribute10 for header      |
  -- | 2.9         06/27/2018   Vivek Kumar      Defect#45000 Commented Accounting_date and       |
  -- |                                           gl_date from AP_INVOICES_INTERFACE Table         |
  -- |                                           so that gl_date and accounting date will         |
  -- |                                           be populated as null value                       |
  -- | 3.0         08/24/2018   Ragni Gupta      Added logic to handle multiple invoices          |
  --                                             for NAIT-50192                                   |
  -- | 3.1         08/29/2018   Ragni Gupta      Added logic to handle the scenario where
  --            available qty is 0
  -- | 3.2         09/11/2018   Ragni Gupta      Modified logic to restrict program from exiting, if
  --            any of the tolerance is found
  -- | 3.3         09/19/2018    Ragni Gupta     Modified code to calculate unbilled qty
  -- | 3.4         09/24/2018    Ragni Gupta     Modified code to handle OD Max freight hold and release it
  -- | 3.5         10/15/2018    Ragni Gupta     Modified description  for 2-way invoice from AvlPOQ to PQ
  -- | 3.6         11/05/2018    Ragni Gupta     As per Business asked on 31-Oct, below changes:
  --                                             Qty Variance - multiplication of Inv price instead of PO price
  --                                             Price Variance - if multiple invoices single variance, multiply with billed qty otherwise avl po qty
  -- +============================================================================================+
  gc_debug VARCHAR2(2);
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
  -- +============================================================================================+
  -- |  Name        : Log Exception                                                                |
  -- |  Description : The log_exception procedure logs all exceptions                              |
  -- |  Parameters  :  N/A                                                                         |
  -- |  Returns     :                                                                              |
  -- =============================================================================================|
PROCEDURE log_exception(
    p_program_name   IN VARCHAR2 ,
    p_error_location IN VARCHAR2 ,
    p_error_msg      IN VARCHAR2)
IS
  ln_login   NUMBER := FND_GLOBAL.LOGIN_ID;
  ln_user_id NUMBER := FND_GLOBAL.USER_ID;
BEGIN
  XX_COM_ERROR_LOG_PUB.log_error( p_return_code => FND_API.G_RET_STS_ERROR ,p_msg_count => 1 ,p_application_name => 'XXFIN' ,p_program_type => 'Custom Messages' ,p_program_name => p_program_name ,p_attribute15 => p_program_name ,p_program_id => NULL ,p_module_name => 'PO' ,p_error_location => p_error_location ,p_error_message_code => NULL ,p_error_message => p_error_msg ,p_error_message_severity => 'MAJOR' ,p_error_status => 'ACTIVE' ,p_created_by => ln_user_id ,p_last_updated_by => ln_user_id ,p_last_update_login => ln_login );
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while writting to the log ...'|| SQLERRM);
END log_exception;
-- +====================================================================================+
-- | Name        :  print_debug_msg                                                       |
-- | Description :  Procedure used to log based on gb_debug value or if p_force is TRUE.  |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  N/A                                                                   |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  --  IF (gc_debug  = 'Y' OR p_force) THEN
  lc_Message := P_Message;
  fnd_file.put_line (fnd_file.log, lc_Message);
  --IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
  --  dbms_output.put_line (lc_message);
  --END IF;
  --  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
-- +====================================================================================+
-- | Name        :  print_out_msg                                                         |
-- | Description :  Procedure used to out the text to the concurrent program.             |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  N/A                                                                   |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  --IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
  --  dbms_output.put_line (lc_message);
  --END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;
--Changes for NAIT-50192
-- +======================================================================================+
-- | Name        :  get_unapproved_qty                                                 |
-- | Description :  Function used to get qty for unapproved invoices                      |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  po_header_id, p_item_id, p_invoice_id, po_line_id                     |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION get_unapproved_qty(
    p_po_header_id IN NUMBER,
    p_item_id      IN NUMBER,
    p_invoice_id   IN NUMBER,
    p_po_line_id   IN NUMBER)
  RETURN NUMBER
IS
  CURSOR C2
  IS
    SELECT a.invoice_num,
      a.invoice_id,
      a.vendor_id,
      a.vendor_site_id,
      b.line_number,
      b.inventory_item_id,
      ph.segment1,
      b.quantity_invoiced
    FROM po_headers_all ph,
      ap_invoices_all a,
      ap_invoice_lines_all b
    WHERE b.po_header_id    = p_po_header_id
    AND b.inventory_item_id = p_item_id
    AND b.po_line_id        =p_po_line_id
    AND b.invoice_id       <>p_invoice_id
    AND a.invoice_id        =b.invoice_id
    AND a.invoice_num NOT LIKE '%ODDBUIA%'
    AND ph.po_header_id=a.quick_po_header_id
    AND 'APPROVED'    <> AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.INVOICE_ID, a.INVOICE_AMOUNT, a.PAYMENT_STATUS_FLAG, a.INVOICE_TYPE_LOOKUP_CODE )
    AND a.invoice_id   <p_invoice_id
    ORDER BY a.invoice_id;
  ln_unapproved_qty NUMBER:=0;
BEGIN
  FOR cur IN C2
  LOOP
    --print_debug_msg('Unapprved exists :'||to_char(cur.invoice_id));
    ln_unapproved_qty:=ln_unapproved_qty+cur.quantity_invoiced;
  END LOOP;
  --print_debug_msg('Unapproved :'||to_char(ln_unapproved_qty));
  RETURN(ln_unapproved_qty);
EXCEPTION
WHEN OTHERS THEN
  RETURN(ln_unapproved_qty);
END get_unapproved_qty;
-- +======================================================================================+
-- | Name        :  get_consumed_rcvqty                                                   |
-- | Description :  Function used to get consumed qty for approved invoices               |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  po_header_id, p_item_id, p_invoice_id, po_line_id                     |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION get_consumed_rcvqty(
    p_po_header_id IN NUMBER,
    p_item_id      IN NUMBER,
    p_invoice_id   IN NUMBER,
    p_po_line_id   IN NUMBER)
  RETURN NUMBER
IS
  CURSOR C1
  IS
    SELECT a.invoice_num,
      a.invoice_id,
      b.quantity_invoiced,
      b.po_line_location_id,
      b.po_line_id,
      b.inventory_item_id,
      b.po_header_id
    FROM ap_invoices_all a,
      ap_invoice_lines_all b
    WHERE b.po_header_id    = p_po_header_id
    AND b.inventory_item_id = p_item_id
    AND b.po_line_id        =p_po_line_id
      --AND b.invoice_id       <>p_invoice_id
    AND b.invoice_id < p_invoice_id
    AND a.invoice_id =b.invoice_id
    AND a.invoice_num NOT LIKE '%ODDBUIA%'
    AND 'APPROVED'= AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.INVOICE_ID, a.INVOICE_AMOUNT, a.PAYMENT_STATUS_FLAG, a.INVOICE_TYPE_LOOKUP_CODE )
    ORDER BY a.invoice_id;
  ln_tot_cons_rcv_qty  NUMBER:=0;
  ln_consumed_qty      NUMBER:=0;
  ln_qty_rec           NUMBER;
  ln_tot_cons_qty      NUMBER:=0;
  i                    NUMBER:=1;
  ln_cur_totrcv_qty    NUMBER;
  ln_quantity_received NUMBER:=0;
  ln_tot_inv_qty       NUMBER:=0;
BEGIN
  SELECT NVL(SUM(pol.quantity_received),0)
  INTO ln_quantity_received
  FROM po_line_locations_all pol,
    po_lines_all l
  WHERE l.po_header_id = p_po_header_id
  AND l.item_id        = p_item_id
  AND l.po_line_id     =p_po_line_id
  AND pol.po_line_id   = l.po_line_id;
  FOR cur IN C1
  LOOP
    print_debug_msg('Invoice : '||cur.invoice_num);
    ln_qty_rec:=0;
    SELECT COUNT(1)
    INTO ln_qty_rec
    FROM ap_holds_all
    WHERE invoice_id     =cur.invoice_id
    AND line_location_id =cur.po_line_location_id
    AND hold_lookup_code ='QTY REC';
    --print_debug_msg('Qty REC hold: '||ln_qty_rec);
    IF ln_qty_rec         =0 THEN
      ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
    ELSE
      ln_tot_inv_qty:=ln_tot_inv_qty+cur.quantity_invoiced;
      SELECT NVL(SUM(b.quantity_received),0)
      INTO ln_consumed_qty
      FROM ap_holds_all h,
        rcv_shipment_lines b
      WHERE b.po_line_location_id=cur.po_line_location_id
      AND b.po_line_id           =cur.po_line_id
      AND h.invoice_id           =cur.invoice_id
      AND h.line_location_id     =b.po_line_location_id
      AND h.hold_lookup_code     ='QTY REC'
      AND b.creation_date        <h.last_update_date;
      --print_debug_msg('ln_consumed_qty: '||ln_consumed_qty);
      --print_debug_msg('Total Qty Invoiced: '||ln_tot_inv_qty);
      IF ln_tot_inv_qty     >=ln_consumed_qty THEN
        ln_tot_cons_rcv_qty := ln_consumed_qty;
      ELSE
        ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
      END IF;
    END IF;
    ln_tot_cons_qty:=ln_tot_cons_rcv_qty;
    i              :=i+1;
  END LOOP;
  print_debug_msg('Qty Received : '||TO_CHAR(ln_quantity_received));
  print_debug_msg('Consumed RCV Qty :'||TO_CHAR(ln_tot_cons_qty));
  print_debug_msg('Avail Qty : '|| TO_CHAR(NVL(ln_quantity_received,0)-NVL(ln_tot_cons_qty,0)));
  RETURN(ln_tot_cons_qty);
EXCEPTION
WHEN OTHERS THEN
  ln_tot_cons_rcv_qty:=0;
  RETURN(ln_tot_cons_rcv_qty);
END get_consumed_rcvqty;
--Changes for NAIT-50192
-- +======================================================================================+
-- | Name        :  get_unbilled_qty                                                      |
-- | Description :  Function used to get calculated unbilled qty for invoices             |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  po_header_id, p_item_id, p_invoice_id, po_line_id                     |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
FUNCTION get_unbilled_qty(
    p_po_header_id IN NUMBER,
    p_po_line_id   IN NUMBER,
    p_item_id      IN NUMBER,
    p_invoice_id   IN NUMBER)
  RETURN NUMBER
IS
  v_rct_flag             VARCHAR2(1);
  ln_quantity_received   NUMBER;
  ln_tot_quantity_billed NUMBER;
  ln_inv_quantity_billed NUMBER;
  ln_oth_inv_qty_billed  NUMBER;
  ln_po_ord_qty          NUMBER;
  ln_unbilled_qty        NUMBER;
  v_multi                VARCHAR2(1):='N';
  ln_unaprvd_qty         NUMBER     :=0;
  ln_aprvd_qty           NUMBER     :=0;
  ln_cons_rcv_qty        NUMBER     :=0;
BEGIN
  v_multi:=xx_check_multi_inv(p_invoice_id,p_po_line_id,p_po_header_id);
  --v_multi:='Y';
  BEGIN
    SELECT receipt_required_flag
    INTO v_rct_flag
    FROM po_line_locations_all
    WHERE po_line_id=p_po_line_id
    AND ROWNUM      <2;
  EXCEPTION
  WHEN OTHERS THEN
    v_rct_flag:=NULL;
  END;
  SELECT NVL(SUM(pol.quantity_received),0),
    NVL(SUM(pol.quantity_billed),0),
    NVL(SUM(pol.quantity),0)
  INTO ln_quantity_received,
    ln_tot_quantity_billed,
    ln_po_ord_qty
  FROM po_line_locations_all pol,
    po_lines_all l
  WHERE l.po_header_id = p_po_header_id
  AND l.item_id        = p_item_id
  AND l.po_line_id     =p_po_line_id
  AND pol.po_line_id   = l.po_line_id;
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
  INTO ln_inv_quantity_billed
  FROM ap_invoice_lines_all l
  WHERE po_header_id    = p_po_header_id
  AND inventory_item_id = p_item_id
  AND po_line_id        =p_po_line_id
  AND l.invoice_id      =p_invoice_id
  AND EXISTS
    (SELECT 'x'
    FROM ap_holds_all
    WHERE invoice_id     = l.invoice_id
    AND line_location_id = l.po_line_location_id
    );
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
  INTO ln_aprvd_qty
  FROM ap_invoice_lines_all l
  WHERE po_header_id    = p_po_header_id
  AND inventory_item_id = p_item_id
  AND po_line_id        =p_po_line_id
  AND l.invoice_id     <>p_invoice_id
  AND EXISTS
    (SELECT 'x'
    FROM ap_invoices_all ai
    WHERE ai.invoice_id = l.invoice_id
    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
    AND 'APPROVED'= AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID, ai.INVOICE_AMOUNT, ai.PAYMENT_STATUS_FLAG, ai.INVOICE_TYPE_LOOKUP_CODE )
    );
  IF v_rct_flag       ='Y' THEN -- Three Way
    IF v_multi        ='N' THEN
      ln_unbilled_qty:=ln_quantity_received;
    ELSIF v_multi     ='Y' THEN
      --print_debug_msg('Multi :'||v_multi);
      --print_debug_msg('Received Qty : '||TO_CHAR(ln_quantity_received));
      ln_unaprvd_qty:=get_unapproved_qty(p_po_header_id, p_item_id , p_invoice_id ,p_po_line_id);
      --print_debug_msg('Unapproved qty :'||TO_CHAR(ln_unaprvd_qty));
      IF ln_aprvd_qty   =0 THEN
        ln_unbilled_qty:=ln_quantity_received;
        print_debug_msg('Apvd qty 0, Available qty From Received : '||TO_CHAR(ln_unbilled_qty));
      END IF;
      IF ln_aprvd_qty   >0 THEN
        ln_cons_rcv_qty:=get_consumed_rcvqty(p_po_header_id,p_item_id,p_invoice_id,p_po_line_id);
        ln_unbilled_qty:=ln_quantity_received-ln_cons_rcv_qty;
      END IF;
      IF ln_unaprvd_qty>0 THEN
        --print_debug_msg('Un Apvd qty : '||TO_CHAR(ln_unaprvd_qty));
        ln_unbilled_qty:=ln_unbilled_qty-ln_unaprvd_qty; --automatically accounted DM as well
        --print_debug_msg('Available Qty after Unapproved :'||TO_CHAR(ln_unbilled_qty));
      END IF;
    END IF;
  END IF;
  IF v_rct_flag       ='N' THEN -- Two Way
    IF v_multi        ='N' THEN
      ln_unbilled_qty:=ln_po_ord_qty;
    ELSIF v_multi     ='Y' THEN
      ln_unaprvd_qty :=get_unapproved_qty(p_po_header_id, p_item_id , p_invoice_id ,p_po_line_id);
      --print_debug_msg('Unapproved qty :'||TO_CHAR(ln_unaprvd_qty));
      IF ln_aprvd_qty                            =0 THEN
        IF (ln_tot_quantity_billed-ln_po_ord_qty < 0) OR (ln_tot_quantity_billed-ln_po_ord_qty > 0) OR (ln_tot_quantity_billed-ln_po_ord_qty = 0) THEN
          ln_unbilled_qty                       :=ln_po_ord_qty;
        END IF;
      END IF;
      IF ln_aprvd_qty                    >0 THEN
        IF (ln_aprvd_qty-ln_po_ord_qty) >= 0 THEN
          ln_unbilled_qty               :=0;
        END IF;
        IF (ln_aprvd_qty                               -ln_po_ord_qty) < 0 THEN
          ln_unbilled_qty               :=ln_po_ord_qty-ln_aprvd_qty;
        END IF;
      END IF;
      IF ln_unaprvd_qty >0 THEN
        ln_unbilled_qty:=ln_unbilled_qty-ln_unaprvd_qty;
      END IF;
    END IF;
  END IF;
  IF ln_unbilled_qty<0 THEN
    ln_unbilled_qty:=0;
  END IF;
  print_debug_msg('Final Available Qty : '||TO_CHAR(ln_unbilled_qty));
  RETURN(ln_unbilled_qty);
EXCEPTION
WHEN OTHERS THEN
  RETURN(NULL);
END get_unbilled_qty;
FUNCTION xx_check_multi_inv(
    p_invoice_id NUMBER,
    p_po_line_id   IN NUMBER,
    p_po_header_id IN NUMBER)
  RETURN VARCHAR2
IS
  v_multi VARCHAR2(1):='N';
  v_cnt   NUMBER;
  CURSOR C1
  IS
    SELECT DISTINCT po_line_id,
      po_header_id
    FROM ap_invoice_lines_all l
    WHERE l.invoice_id         =p_invoice_id
    AND l.line_type_lookup_code='ITEM'
    AND l.po_line_id           =p_po_line_id
    AND l.discarded_flag       ='N'
  UNION
  SELECT p_po_line_id po_line_id,
    p_po_header_id po_header_id
  FROM DUAL;
  CURSOR C2(p_po_line_id NUMBER,p_po_header_id NUMBER)
  IS
    SELECT DISTINCT l.invoice_id,
      AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID, ai.INVOICE_AMOUNT, ai.PAYMENT_STATUS_FLAG, ai.INVOICE_TYPE_LOOKUP_CODE ) inv_status
    FROM ap_invoices_all ai,
      ap_invoice_lines_all l
    WHERE l.po_line_id  =p_po_line_id
    AND l.po_header_id  =p_po_header_id
    AND l.invoice_id   <>p_invoice_id
    AND l.discarded_flag='N'
    AND ai.invoice_id   =l.invoice_id
    AND ai.invoice_num NOT LIKE '%ODDBUIA%';
BEGIN
  FOR cur IN C1
  LOOP
    FOR c IN C2(cur.po_line_id,cur.po_header_id)
    LOOP
      --IF c.inv_status IN ('NEEDS REAPPROVAL','NEVER APPROVED') THEN
      v_multi:='Y';
      EXIT;
      --END IF;
    END LOOP;
  END LOOP;
  RETURN(v_multi);
EXCEPTION
WHEN OTHERS THEN
  RETURN('X');
END xx_check_multi_inv;
-- +====================================================================================+
-- | Name        :  chargeback_tolerance_check                                            |
-- | Description :  procedure to process automatic charge                                 |
-- |                or N                                                                  |
-- |                                                                                      |
-- | Parameters  :  p_err_buf,p_retcode                                                   |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE chargeback_tolerance_check(
    p_source IN VARCHAR2,
    p_err_buf OUT VARCHAR2,
    p_retcode OUT VARCHAR2)
IS
  CURSOR invoice_cur(p_org_id NUMBER)
  IS
    SELECT a.invoice_id,
      a.invoice_num,
      a.vendor_id,
      a.vendor_site_id,
      NVL(a.po_header_id,a.quick_po_header_id) po_header_id,
      a.org_id,
      a.creation_date,
      ( SELECT DISTINCT DECODE(receipt_required_flag,'Y','3-Way','N','2-Way')
      FROM po_line_locations_all
      WHERE po_header_id =NVL(a.po_header_id,a.quick_po_header_id)
      AND ROWNUM         <2
      ) match_type
  FROM ap_invoices_all a
  WHERE a.validation_request_id =-9999999999
  AND a.source                  =p_source
  AND a.org_id+0                =p_org_id
  AND a.invoice_type_lookup_code='STANDARD'
  AND a.invoice_num NOT LIKE '%ODDBUI%'
  AND TRUNC(a.creation_date)=TRUNC(SYSDATE-6)
  UNION
  SELECT a.invoice_id,
    a.invoice_num,
    a.vendor_id,
    a.vendor_site_id,
    NVL(a.po_header_id,a.quick_po_header_id) po_header_id,
    a.org_id,
    a.creation_date,
    ( SELECT DISTINCT DECODE(receipt_required_flag,'Y','3-Way','N','2-Way')
    FROM po_line_locations_all
    WHERE po_header_id =NVL(a.po_header_id,a.quick_po_header_id)
    AND ROWNUM         <2
    ) match_type
  FROM ap_supplier_sites_all b,
    ap_invoices_all a
  WHERE 1=1
  AND a.creation_date BETWEEN SYSDATE-5 AND SYSDATE
    --AND a.invoice_num LIKE 'FCHB%'
  AND a.validation_request_id  IS NULL
  AND a.source                  =p_source
  AND a.ORG_ID+0                =P_ORG_ID
  AND a.invoice_type_lookup_code='STANDARD'
  AND a.invoice_num NOT LIKE '%ODDBUI%'
  AND b.vendor_site_id=a.vendor_site_id
  AND NOT EXISTS
    (SELECT 'x'
    FROM xla_events xev,
      xla_transaction_entities xte
    WHERE xte.source_id_int_1=a.invoice_id
    AND xte.application_id   = 200
    AND xte.entity_code      = 'AP_INVOICES'
    AND xev.entity_id        = xte.entity_id
    AND xev.event_type_code LIKE '%VALIDATED%'
    AND xev.process_status_code = 'P'
    )
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
    )
  UNION
  SELECT
    /*+ LEADING (h) */
    ai.invoice_id,
    ai.invoice_num,
    ai.vendor_id,
    ai.vendor_site_id,
    NVL(ai.po_header_id,ai.quick_po_header_id) po_header_id,
    ai.org_id,
    ai.creation_date,
    ( SELECT DISTINCT DECODE(receipt_required_flag,'Y','3-Way','N','2-Way')
    FROM po_line_locations_all
    WHERE po_header_id =NVL(ai.po_header_id,ai.quick_po_header_id)
    AND ROWNUM         <2
    ) match_type
  FROM ap_supplier_sites_all b,
    ap_invoices_all ai,
    (SELECT
      /*+ INDEX(aph XX_AP_HOLDS_N1) */
      DISTINCT invoice_id
    FROM ap_holds_all aph
    WHERE aph.creation_date      > '01-JAN-11'
    AND NVL(aph.status_flag,'S') = 'S'
    AND aph.release_lookup_code IS NULL
    )h
  WHERE 1          =1
  AND ai.invoice_id=h.invoice_id
  AND ai.org_id+0  =p_org_id
  AND AI.source    =P_SOURCE
    --  AND ai.invoice_id=156132195
  AND ai.invoice_type_lookup_code='STANDARD'
  AND ai.invoice_num NOT LIKE '%ODDBUI%'
  AND ai.validation_request_id IS NULL
  AND b.vendor_site_id          =ai.vendor_site_id
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
    )
  ORDER BY 7;
TYPE invoice
IS
  TABLE OF invoice_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_invoice_tab INVOICE;
  CURSOR get_std_tolerance_values(p_vendor_id NUMBER, p_vendor_site_id NUMBER, p_org_id NUMBER)
  IS
    SELECT b.price_tolerance,
      b.qty_received_tolerance,
      b.quantity_tolerance
    FROM ap_tolerance_templates b,
      ap_supplier_sites_all ss
    WHERE ss.vendor_site_id = p_vendor_site_id
    AND ss.vendor_id        = p_vendor_id
    AND b.tolerance_id      = ss.tolerance_id
    AND ss.org_id           = p_org_id;
  CURSOR get_min_chargeback_amt(p_vendor_id NUMBER, p_vendor_site_id NUMBER, p_org_id NUMBER)
  IS
    SELECT min_chargeback_amt,
      max_freight_amt
    FROM xx_ap_custom_tolerances
    WHERE supplier_id    = p_vendor_id
    AND supplier_site_id = p_vendor_site_id
    AND org_id           = p_org_id;
  CURSOR inv_lines_cur(p_invoice_id NUMBER)
  IS
    SELECT l.line_number,
      d.po_header_id,
      d.po_line_id,
      d.po_distribution_id,
      c.line_location_id,
      SUM(NVL(c.quantity_received,0)) rcv_qty,
      l.quantity_invoiced inv_qty,
      l.unit_price inv_price,
      l.default_dist_ccid,
      f.dist_code_combination_id,
      b.quantity po_qty,
      b.unit_price po_price,
      d.variance_account_id,
      l.inventory_item_id,
      l.item_description,
      l.invoice_id
    FROM po_headers_all a,
      po_lines_all b,
      po_line_locations_all c,
      po_distributions_all d,
      ap_invoice_distributions_all f,
      ap_invoice_lines_all l
    WHERE l.invoice_id          = p_invoice_id
    AND f.invoice_id            = l.invoice_id
    AND f.invoice_line_number   = l.line_number
    AND f.line_type_lookup_code ='ACCRUAL'
    AND l.line_type_lookup_code = 'ITEM'
    AND d.po_distribution_id    = f.po_distribution_id
    AND c.line_location_id      = d.line_location_id
    AND b.po_header_id          = c.po_header_id
    AND b.po_line_id            = c.po_line_id
    AND a.po_header_id          = b.po_header_id
    GROUP BY l.line_number,
      d.po_header_id,
      d.po_line_id,
      d.po_distribution_id,
      c.line_location_id,
      l.quantity_invoiced,
      l.unit_price,
      l.default_dist_ccid,
      f.dist_code_combination_id,
      b.quantity,
      b.unit_price,
      d.variance_account_id,
      l.inventory_item_id,
      l.item_description,
      l.invoice_id
    ORDER BY 2,1;
TYPE inv_lines
IS
  TABLE OF inv_lines_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_inv_lines_tab INV_LINES;
  CURSOR inv_lines_freight_cur(p_invoice_id NUMBER)
  IS
    SELECT l.line_number,
      f.dist_code_combination_id,
      l.amount,
      l.invoice_id
    FROM ap_invoice_lines_all l,
      ap_invoice_distributions_all f
    WHERE l.invoice_id         = p_invoice_id
    AND f.invoice_id           = l.invoice_id
    AND f.invoice_line_number  = l.line_number
    AND l.line_type_lookup_code='FREIGHT';
TYPE inv_freight_lines
IS
  TABLE OF inv_lines_freight_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_inv_lines_freight_tab INV_FREIGHT_LINES;
  CURSOR inv_header_cur (p_invoice_id NUMBER)
  IS
    SELECT a.invoice_num,
      a.invoice_id,
      a.invoice_type_lookup_code,
      a.invoice_date,
      a.vendor_id,
      a.vendor_site_id,
      a.invoice_currency_code,
      a.terms_id,
      a.description,
      a.attribute7,
      a.source,
      a.payment_method_code,
      a.pay_group_lookup_code,
      a.org_id,
      a.goods_received_date,
      ph.segment1 po_num,
      a.terms_date,
      a.attribute1,
      a.attribute2,
      a.attribute3,
      a.attribute4,
      a.attribute5,
      a.attribute6,
      a.attribute8,
      a.attribute9,
      a.attribute10,
      a.attribute11,
      a.attribute12,
      a.attribute13,
      a.attribute14,
      a.attribute15
    FROM ap_invoices_all a,
      po_headers_all ph
    WHERE a.invoice_id = p_invoice_id
    AND ph.po_header_id=NVL(a.quick_po_header_id,a.po_header_id);
  CURSOR C3(p_po_line_id NUMBER,p_po_header_id NUMBER)
  IS
    SELECT DISTINCT l.invoice_id
    FROM ap_invoices_all ai,
      ap_invoice_lines_all l
    WHERE l.po_line_id=p_po_line_id
    AND l.po_header_id=p_po_header_id
      --AND l.invoice_id<>p_invoice_id
    AND ai.invoice_id=l.invoice_id
    ORDER BY ai.creation_date;
  inv_header_rec inv_header_cur%ROWTYPE;
  indx                      NUMBER;
  l_indx                    NUMBER;
  lf_indx                   NUMBER;
  ln_batch_size             NUMBER := 250;
  ln_count                  NUMBER;
  ln_std_price_tolerance    NUMBER;
  ln_std_qty_tolerance      NUMBER;
  ln_std_qty_rcv_tolerance  NUMBER;
  ln_min_chargeback_amt     NUMBER;
  lc_chargeback_invoice_num VARCHAR2(25);
  lc_chargeback_cr_flag     VARCHAR2(1);
  lc_interface_cr_flag      VARCHAR2(1);
  ln_inv_chargeback_amt     NUMBER;
  ln_hdr_chargeback_amt     NUMBER;
  ln_line_chargeback_amt    NUMBER;
  ln_pt_pct                 NUMBER;
  ln_qt_pct                 NUMBER;
  lc_qty_desc               VARCHAR2(500);
  lc_price_desc             VARCHAR2(500);
  lc_line_desc              VARCHAR2(1000);
  ln_line_amount            NUMBER;
  ln_invoice_id             NUMBER;
  ln_header_amount          NUMBER;
  ln_qty_diff               NUMBER;
  ln_price_diff             NUMBER;
  ln_max_freight_amt        NUMBER;
  ln_interface_line_count   NUMBER;
  ln_interface_hdr_count    NUMBER:=0;
  lc_error_msg              VARCHAR2(1000);
  lc_error_loc              VARCHAR2(100) := 'XX_AP_TR_AUTO_CHBK_PKG.CHARGEBACK_TOLERANCE_CHECK';
  l_multi                   VARCHAR2(1);
  lc_skip_invoice           VARCHAR2(1);
  v_account_id              NUMBER;
  inv_ln_no                 VARCHAR2(10):= NULL;
  quantity_inv              NUMBER;
  v_reason_code             VARCHAR2(10);
  lc_both                   VARCHAR2(1);
  lc_act_both               VARCHAR2(1);
  lc_terms_date_basis       VARCHAR2(50);
  ln_org_id                 NUMBER;
  ln_hold_cnt               NUMBER;
  ln_neg_cnt                NUMBER;
  ln_calc_rcv_qty           NUMBER;
  ln_quantity_received      NUMBER;
  ln_total_billed_qty       NUMBER;
  ln_max_freight_hold       NUMBER        :=0;
  lc_release_lookup_code    VARCHAR2(100) :='INVOICE QUICK RELEASED';
  lc_hold_lookup_code       VARCHAR2(100) := 'OD Max Freight';
  ln_total_qt_pct           NUMBER;
  ln_held_by                NUMBER;
BEGIN
  ln_org_id:=FND_PROFILE.VALUE ('ORG_ID');
  xla_security_pkg.set_security_context(602);
  OPEN invoice_cur(ln_org_id);
  LOOP
    FETCH invoice_cur BULK COLLECT
    INTO l_invoice_tab LIMIT ln_batch_size;
    EXIT
  WHEN l_invoice_tab.COUNT = 0;
    FOR indx IN l_invoice_tab.FIRST..l_invoice_tab.LAST
    LOOP
      ln_max_freight_hold:=0;
      ln_held_by         := NULL;
      BEGIN
        print_debug_msg('Invoice num '||TO_CHAR(l_invoice_tab(indx).invoice_num)||'----'||indx,FALSE);
        SELECT COUNT(1)
        INTO ln_hold_cnt
        FROM ap_holds_all
        WHERE invoice_id=l_invoice_tab(indx).invoice_id
        AND hold_lookup_code LIKE 'OD%'
        AND release_lookup_code IS NULL;
        --print_debug_msg('ln_hold_cnt '||ln_hold_cnt,FALSE);
        IF ln_hold_cnt<>0 THEN
          SELECT COUNT(1)
          INTO ln_max_freight_hold
          FROM ap_holds_all
          WHERE invoice_id         =l_invoice_tab(indx).invoice_id
          AND hold_lookup_code     = lc_hold_lookup_code
          AND release_lookup_code IS NULL;
          IF ln_max_freight_hold   = 0 THEN
            print_debug_msg('exit from this invoice since OD Max Freight hold is not present and other OD% hold count <>0',FALSE);
            CONTINUE;
          ELSE
            BEGIN
              SELECT held_by
              INTO ln_held_by
              FROM ap_holds_all
              WHERE invoice_id         =l_invoice_tab(indx).invoice_id
              AND hold_lookup_code     = lc_hold_lookup_code
              AND release_lookup_code IS NULL;
            EXCEPTION
            WHEN OTHERS THEN
              ln_held_by:=gn_user_id;
            END;
            print_debug_msg('Continue with normal processing as invoice having OD Max Freight hold',FALSE);
          END IF;
        END IF;
        SELECT COUNT(1)
        INTO ln_neg_cnt
        FROM ap_invoice_lines_all
        WHERE invoice_id=l_invoice_tab(indx).invoice_id
        AND amount      <0;
        --print_debug_msg('ln_neg_cnt '||ln_neg_cnt,FALSE);
        IF ln_neg_cnt<>0 THEN
          print_debug_msg('exit from this invoice since neg count <>0',FALSE);
          CONTINUE;
        END IF;
        --l_multi:=xx_check_multi_inv(l_invoice_tab(indx).invoice_id);
        -- print_debug_msg('l_multi '||l_multi,FALSE);
        ------Changes starts for  NAIT-50192
        /* IF l_multi IN ('X','Y') THEN
        CONTINUE;
        END IF;*/
        ----Changes ends for  NAIT-50192
        BEGIN
          SELECT terms_date_basis
          INTO lc_terms_date_basis
          FROM ap_supplier_sites_all
          WHERE vendor_site_id=l_invoice_tab(indx).vendor_site_id;
          --print_debug_msg('Terms date basis '||lc_terms_date_basis,FALSE);
        EXCEPTION
        WHEN OTHERS THEN
          -- print_debug_msg('Exception of terms date basis, setting it NULL',FALSE);
          lc_terms_date_basis:=NULL;
        END;
        OPEN get_std_tolerance_values(l_invoice_tab(indx).vendor_id,l_invoice_tab(indx).vendor_site_id,l_invoice_tab(indx).org_id); --discuss no data/null here
        FETCH get_std_tolerance_values
        INTO ln_std_price_tolerance,
          ln_std_qty_rcv_tolerance,
          ln_std_qty_tolerance;
        CLOSE get_std_tolerance_values;
        --print_debug_msg('ln_std_price_tolerance --- '||ln_std_price_tolerance,FALSE);
        --print_debug_msg('ln_std_qty_rcv_tolerance --- '||ln_std_qty_rcv_tolerance,FALSE);
        --print_debug_msg('ln_std_qty_tolerance --- '||ln_std_qty_tolerance,FALSE);
        IF ln_std_price_tolerance IS NULL THEN
          ln_std_price_tolerance  := 0;
        END IF;
        IF ln_std_qty_rcv_tolerance IS NULL THEN
          ln_std_qty_rcv_tolerance  := 0;
        END IF;
        IF ln_std_qty_tolerance IS NULL THEN
          ln_std_qty_tolerance  := 0;
        END IF;
        --print_debug_msg('Get min chargeback amount for Vendor_Site_Id'||to_char(l_invoice_tab(indx).vendor_site_id),FALSE);
        OPEN get_min_chargeback_amt(l_invoice_tab(indx).vendor_id,l_invoice_tab(indx).vendor_site_id,l_invoice_tab(indx).org_id); --discuss no data found here
        FETCH get_min_chargeback_amt
        INTO ln_min_chargeback_amt,
          ln_max_freight_amt;
        CLOSE get_min_chargeback_amt;
        --print_debug_msg('Min chargeback amt'||ln_min_chargeback_amt,FALSE);
        --Get Invoice Lines
        --print_debug_msg('Get Invoice Lines',FALSE);
        BEGIN
          OPEN inv_lines_cur(l_invoice_tab(indx).invoice_id);
          FETCH inv_lines_cur BULK COLLECT
          INTO l_inv_lines_tab;
          CLOSE inv_lines_cur;
        EXCEPTION
        WHEN OTHERS THEN
          print_debug_msg('exception caught in getting lines cursor');
        END;
        --print_debug_msg('l_inv_lines_tab - '||l_inv_lines_tab.COUNT,FALSE);
        ln_inv_chargeback_amt   := 0;
        lc_chargeback_cr_flag   := 'N';
        lc_skip_invoice         := 'N';
        IF l_inv_lines_tab.COUNT >0 THEN
          FOR l_indx IN 1..l_inv_lines_tab.COUNT
          LOOP
            --print_debug_msg('inside lines cursor',FALSE);
            BEGIN
              ln_line_chargeback_amt := 0;
              ln_calc_rcv_qty        := 0;
              lc_both                := 'N'; -- Initialized this variable as a part of NAIT-50192 changes
              ln_total_billed_qty    :=0;
              ln_quantity_received   :=0;
              ln_total_qt_pct        := NULL;
              print_debug_msg('match_type - '||l_invoice_tab(indx).match_type,FALSE);
              ----Changes starts for  NAIT-50192
              --ln_calc_rcv_qty:=get_unbilled_rcvd_qty(l_inv_lines_tab(l_indx).po_header_id,l_inv_lines_tab(l_indx).po_line_id,l_inv_lines_tab(l_indx).inventory_item_id,l_invoice_tab(indx).invoice_id);
              ln_calc_rcv_qty:=get_unbilled_qty(l_inv_lines_tab(l_indx).po_header_id,l_inv_lines_tab(l_indx).po_line_id,l_inv_lines_tab(l_indx).inventory_item_id,l_invoice_tab(indx).invoice_id);
              --print_debug_msg('ln_calc_rcv_qty '||ln_calc_rcv_qty,FALSE);
              ----Changes ends for  NAIT-50192
              SELECT NVL(SUM(pol.quantity_received),0)
              INTO ln_quantity_received
              FROM po_line_locations_all pol,
                po_lines_all l
              WHERE l.po_header_id = l_inv_lines_tab(l_indx).po_header_id
                --AND l.item_id = p_item_id
              AND l.po_line_id   =l_inv_lines_tab(l_indx).po_line_id
              AND pol.po_line_id = l.po_line_id;
              --print_debug_msg('ln_quantity_received '||ln_quantity_received,FALSE);
              SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
              INTO ln_total_billed_qty
              FROM ap_invoice_lines_all l
              WHERE po_header_id    = l_inv_lines_tab(l_indx).po_header_id
              AND inventory_item_id = l_inv_lines_tab(l_indx).inventory_item_id
              AND po_line_id        =l_inv_lines_tab(l_indx).po_line_id
              AND EXISTS
                (SELECT 'x'
                FROM ap_invoices_all ai
                WHERE ai.invoice_id = l.invoice_id
                AND ai.invoice_num NOT LIKE '%ODDBUIA%'
                )
              AND l.creation_date <=
                (SELECT creation_date
                FROM ap_invoices_all
                WHERE invoice_id = l_inv_lines_tab(l_indx).invoice_id
                );
              IF l_invoice_tab(indx).match_type='3-Way' THEN
                BEGIN
                  ln_pt_pct := ((NVL(l_inv_lines_tab(l_indx).inv_price,0)-NVL(l_inv_lines_tab(l_indx).po_price,0))/NVL(l_inv_lines_tab(l_indx).po_price,0))*100;
                  ----Changes starts for  NAIT-50192
                  --ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-(l_inv_lines_tab(l_indx).rcv_qty))/(l_inv_lines_tab(l_indx).rcv_qty))*100;
                  ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-ln_calc_rcv_qty)/ln_quantity_received)*100;
                  --21-Sep-18, Ragni
                  --IF ln_calc_rcv_qty <=0 THEN
                  ln_total_billed_qty:=ln_total_billed_qty+l_inv_lines_tab(l_indx).inv_qty;
                  --print_debug_msg('ln_total_billed_qty '||ln_total_billed_qty,FALSE);
                  ln_total_qt_pct := ((ln_total_billed_qty-ln_quantity_received)/ln_quantity_received)*100;
                  --END IF;
                  ----Changes ends for  NAIT-50192
                EXCEPTION
                WHEN OTHERS THEN
                  print_debug_msg ('ERROR processing(chargeback_tolerance_check) invoice_num- '||l_invoice_tab(indx).invoice_num||'-'||lc_error_msg,TRUE);
                  lc_skip_invoice := 'Y';
                  EXIT; -- skip the invoice
                END;
                print_debug_msg('Price Percentage-'||TO_CHAR(ln_pt_pct)||' Quantity Percentage-'||TO_CHAR(ln_qt_pct)||' Total billed Percent -'||TO_CHAR(ln_total_qt_pct),FALSE);
                IF (ln_qt_pct > ln_std_qty_rcv_tolerance) OR (ln_pt_pct > ln_std_price_tolerance) THEN
                  print_debug_msg('Above std tolerance,skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  lc_skip_invoice := 'Y';
                  EXIT; --continue; --skip this line and continue to next line --SKIP THE INOICE
                END IF;
                --changes starts for NAIT-50192, below condition commented because program will skip invoice if any of the variance is not found, we should skip if both variance is not found
                --IF (ln_qt_pct < 0) OR (ln_pt_pct < 0) THEN
                IF (ln_qt_pct < 0) AND (ln_pt_pct < 0) THEN
                  --changes ends for NAIT-50192
                  print_debug_msg('Price or Qty Percent is < 0, skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  CONTINUE; --skip this line and continue to next line
                END IF;
                IF (ln_qt_pct = 0) AND (ln_pt_pct = 0) THEN
                  print_debug_msg('Price and Qty Percent are both 0, skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  CONTINUE; --skip this line and continue to next line
                END IF;
                --changes starts for NAIT-50192
                --IF (ln_qt_pct <= ln_std_qty_rcv_tolerance) AND (ln_pt_pct <= ln_std_price_tolerance)  THEN
                IF (ln_qt_pct <= ln_std_qty_rcv_tolerance) AND (ln_pt_pct <= ln_std_price_tolerance) AND (ln_qt_pct > 0) AND (ln_pt_pct > 0) THEN
                  --changes ends for NAIT-50192
                  print_debug_msg('Both tolerances are either equal or less then limit,setting lc_both Y ',FALSE);
                  lc_both:='Y';
                END IF;
                ----Changes starts for  NAIT-50192
                --IF ln_qt_pct <= ln_std_qty_rcv_tolerance THEN
                IF ln_qt_pct <= ln_std_qty_rcv_tolerance AND ln_qt_pct > 0 AND (ln_total_qt_pct <=ln_std_qty_rcv_tolerance AND ln_total_qt_pct>0) THEN
                  print_debug_msg('Qty % <= Std Qty Rec Tolerance',FALSE);
                  --ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -(l_inv_lines_tab(l_indx).rcv_qty)) * l_inv_lines_tab(l_indx).inv_price),2);
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -ln_calc_rcv_qty) * l_inv_lines_tab(l_indx).inv_price),2);
                  ----Changes ends for  NAIT-50192
                  --   print_debug_msg('ln_line_chargeback_amt -- '||ln_line_chargeback_amt,FALSE);
                END IF;
                print_debug_msg('lc_both - '||lc_both,FALSE);
                IF lc_both='Y' THEN
                  ----Changes starts for  NAIT-50192
                  --IF ln_pt_pct <= ln_std_price_tolerance THEN
                  IF ln_pt_pct <= ln_std_price_tolerance AND ln_pt_pct > 0 THEN
                    print_debug_msg('Price % <= Std Price Tolerance',FALSE);
                    --ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).rcv_qty),2);
                    ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * ln_calc_rcv_qty),2);
                    ----Changes ends for  NAIT-50192
                    --print_debug_msg('ln_line_chargeback_amt -- '||ln_line_chargeback_amt,FALSE);
                  END IF;
                ELSIF lc_both='N' THEN
                  --print_debug_msg('Inside lc_both - N condition',FALSE);
                  ----Changes starts for  NAIT-50192
                  --IF ln_pt_pct <= ln_std_price_tolerance  THEN
                  IF ln_pt_pct <= ln_std_price_tolerance AND ln_pt_pct > 0 THEN
                    ----Changes ends for  NAIT-50192
                    print_debug_msg('Price % <= Std Price Tolerance',FALSE);
                    ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).inv_qty),2);
                    --   print_debug_msg('ln_line_chargeback_amt -- '||ln_line_chargeback_amt,FALSE);
                  END IF;
                END IF;
              ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
                --print_debug_msg('match_type - 2 Way',FALSE);
                BEGIN
                  ln_pt_pct := ((NVL(l_inv_lines_tab(l_indx).inv_price,0)-NVL(l_inv_lines_tab(l_indx).po_price,0))/NVL(l_inv_lines_tab(l_indx).po_price,0))*100;
                  ----Changes starts for  NAIT-50192
                  ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-ln_calc_rcv_qty)/(l_inv_lines_tab(l_indx).po_qty))*100;
                  --ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-ln_calc_rcv_qty)/ln_quantity_received)*100;
                  ln_total_billed_qty:=ln_total_billed_qty+l_inv_lines_tab(l_indx).inv_qty;
                  --print_debug_msg('ln_total_billed_qty '||ln_total_billed_qty,FALSE);
                  ln_total_qt_pct := ((ln_total_billed_qty-l_inv_lines_tab(l_indx).po_qty)/l_inv_lines_tab(l_indx).po_qty)*100;
                  ----Changes ends for  NAIT-50192
                EXCEPTION
                WHEN OTHERS THEN
                  print_debug_msg ('ERROR processing(chargeback_tolerance_check) invoice_num- '||l_invoice_tab(indx).invoice_num||'-'||lc_error_msg,TRUE);
                  lc_skip_invoice := 'Y';
                  EXIT; -- skip the invoice
                END;
                print_debug_msg('Price Percentage-'||TO_CHAR(ln_pt_pct)||' Quantity Percentage-'||TO_CHAR(ln_qt_pct)||' Total Billed Percent-'||TO_CHAR(ln_total_qt_pct),FALSE);
                IF (ln_qt_pct > ln_std_qty_tolerance) OR (ln_pt_pct > ln_std_price_tolerance) THEN
                  print_debug_msg('Above std tolerance,skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  lc_skip_invoice := 'Y';
                  EXIT; --continue; --skip this line and continue to next line --SKIP THE INOICE
                END IF;
                --changes starts for NAIT-50192, commented below condition because program skips invoice by checking if any of the variance is not found, we should skip when both vraince is found
                --IF (ln_qt_pct < 0) OR (ln_pt_pct < 0) THEN
                IF (ln_qt_pct < 0) AND (ln_pt_pct < 0) THEN
                  --changes ends for NAIT-50192
                  print_debug_msg('Price or Qty Percent is < 0, skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  CONTINUE; --skip this line and continue to next line
                END IF;
                IF (ln_qt_pct = 0) AND (ln_pt_pct = 0) THEN
                  print_debug_msg('Price and Qty Percent are both 0, skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                  CONTINUE; --skip this line and continue to next line
                END IF;
                --changes starts for NAIT-50192
                --Version 3.6 changes
                IF (ln_qt_pct <= ln_std_qty_rcv_tolerance) AND (ln_pt_pct <= ln_std_price_tolerance) AND (ln_qt_pct > 0) AND (ln_pt_pct > 0) THEN
                  --changes ends for NAIT-50192
                  print_debug_msg('Both tolerances are either equal or less then limit,setting lc_both Y ',FALSE);
                  lc_both:='Y';
                END IF;
                ----Version 3.6 changes ends
                --IF ln_qt_pct <= ln_std_qty_tolerance THEN
                IF ln_qt_pct <= ln_std_qty_tolerance AND ln_qt_pct >0 AND (ln_total_qt_pct <=ln_std_qty_rcv_tolerance AND ln_total_qt_pct>0) THEN
                  print_debug_msg('Qty % <= Std Qty Tolerance',FALSE);
                  --Version 3.6 changes
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty - ln_calc_rcv_qty) * l_inv_lines_tab(l_indx).inv_price),2);
                  --Version 3.6 changes ends
                  ----Changes ends for  NAIT-50192
                END IF;
                --changes starts for NAIT-50192
                --IF ln_pt_pct <= ln_std_price_tolerance THEN
                IF ln_pt_pct <= ln_std_price_tolerance AND ln_pt_pct > 0 THEN
                  --changes end for NAIT-50192
                  print_debug_msg('Price % <= Std Price Tolerance',FALSE);
                  --Version 3.6 changes
                  IF lc_both                ='Y' THEN
                    ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * ln_calc_rcv_qty),2);
                  ELSIF lc_Both             = 'N' THEN
                    ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).inv_qty),2);
                  END IF;
                  --Version 3.6 changes ends
                  -- print_debug_msg('ln_line_chargeback_amt -- '||ln_line_chargeback_amt,FALSE);
                END IF;
              END IF; -- ELSIF IF l_invoice_tab(indx).match_type='2-Way' THEN
              ln_inv_chargeback_amt := ln_inv_chargeback_amt + ln_line_chargeback_amt;
              print_debug_msg('ln_inv_chargeback_amt -- '||ln_inv_chargeback_amt,FALSE);
              IF ln_inv_chargeback_amt >0 THEN
                lc_chargeback_cr_flag := 'Y';
              END IF;
            END;
          END LOOP; --FOR l_indx IN 1..l_inv_lines_tab.COUNT
        END IF;
        print_debug_msg('lc_skip_invoice -- '||lc_skip_invoice,FALSE);
        IF lc_skip_invoice = 'Y' THEN
          CONTINUE; --discuss skip the invoice since standard hold will be placed on it. do we need to check freight only invoice?
        END IF;
        --print_debug_msg('Get Invoice Freight Lines',FALSE);
        OPEN inv_lines_freight_cur(l_invoice_tab(indx).invoice_id);
        FETCH inv_lines_freight_cur BULK COLLECT
        INTO l_inv_lines_freight_tab;
        CLOSE inv_lines_freight_cur;
        /* BEGIN
        SELECT NVL(SUM(l.amount),0)
        INTO ln_freight_amt
        FROM ap_invoice_lines_all l,
        ap_invoice_distributions_all f
        WHERE l.invoice_id         = l_invoice_tab(indx).invoice_id
        AND f.invoice_id           = l.invoice_id
        AND f.invoice_line_number  = l.line_number
        AND l.line_type_lookup_code='FREIGHT';
        EXCEPTION WHEN OTHERS THEN
        ln_freight_amt :=0;
        END;*/
        --ln_inv_chargeback_amt:=
        IF (ln_inv_chargeback_amt > ln_min_chargeback_amt AND lc_chargeback_cr_flag = 'Y') OR (l_inv_lines_freight_tab.count > 0) THEN --discuss even if its freight only shouldn't it be ignored if there is chance of standard hold being placed.
          print_debug_msg('Inside chargeback creation OR Freight condition',FALSE);
          ln_header_amount     := 0;
          lc_interface_cr_flag := 'N';
          --print_debug_msg('Check if chargeback already exists',FALSE);
          lc_chargeback_invoice_num := l_invoice_tab(indx).invoice_num||'DM';
          SELECT COUNT(1)
          INTO ln_count
          FROM ap_invoices_all
          WHERE invoice_num  = lc_chargeback_invoice_num
          AND vendor_id      = l_invoice_tab(indx).vendor_id
          AND vendor_site_id = l_invoice_tab(indx).vendor_site_id;
          --Changes started for NAIT-50192
          IF ln_count = 0 THEN
            SELECT COUNT(1)
            INTO ln_count
            FROM ap_invoices_interface
            WHERE invoice_num  = lc_chargeback_invoice_num
            AND vendor_id      = l_invoice_tab(indx).vendor_id
            AND vendor_site_id = l_invoice_tab(indx).vendor_site_id;
          END IF;
          --Changes ended for NAIT-50192
          IF ln_count > 0 THEN
            print_debug_msg('Chargeback already exists with invoice num, skip this invoice '||lc_chargeback_invoice_num,FALSE);
            CONTINUE; --skip and continue to next invoice record.
          END IF;
          --print_debug_msg('Get more invoice details',FALSE);
          OPEN inv_header_cur(l_invoice_tab(indx).invoice_id);
          FETCH inv_header_cur
          INTO inv_header_rec;
          CLOSE inv_header_cur;
          SELECT ap_invoices_interface_s.nextval
          INTO ln_invoice_id
          FROM dual;
        END IF;
        IF ln_inv_chargeback_amt   > ln_min_chargeback_amt AND lc_chargeback_cr_flag = 'Y' THEN
          ln_hdr_chargeback_amt   := 0;
          ln_interface_line_count :=1;
          FOR l_indx IN 1..l_inv_lines_tab.COUNT
          LOOP
            lc_qty_desc            := NULL;
            lc_line_desc           := NULL;
            lc_price_desc          := NULL;
            ln_line_chargeback_amt := 0;
            ----Changes starts for  NAIT-50192
            lc_act_both         := 'N';
            ln_calc_rcv_qty     := 0;
            ln_total_billed_qty :=0;
            ln_quantity_received:=0;
            --ln_calc_rcv_qty     :=get_unbilled_rcvd_qty(l_inv_lines_tab(l_indx).po_header_id,l_inv_lines_tab(l_indx).po_line_id,l_inv_lines_tab(l_indx).inventory_item_id,l_invoice_tab(indx).invoice_id);
            ln_calc_rcv_qty :=get_unbilled_qty(l_inv_lines_tab(l_indx).po_header_id,l_inv_lines_tab(l_indx).po_line_id,l_inv_lines_tab(l_indx).inventory_item_id,l_invoice_tab(indx).invoice_id);
            SELECT NVL(SUM(pol.quantity_received),0)
            INTO ln_quantity_received
            FROM po_line_locations_all pol,
              po_lines_all l
            WHERE l.po_header_id = l_inv_lines_tab(l_indx).po_header_id
              --AND l.item_id = p_item_id
            AND l.po_line_id   =l_inv_lines_tab(l_indx).po_line_id
            AND pol.po_line_id = l.po_line_id;
            ----Changes ends for  NAIT-50192
            BEGIN
              ln_pt_pct                       := ((NVL(l_inv_lines_tab(l_indx).inv_price,0)-NVL(l_inv_lines_tab(l_indx).po_price,0))/NVL(l_inv_lines_tab(l_indx).po_price,0))*100;
              IF l_invoice_tab(indx).match_type='3-Way' THEN
                --print_debug_msg('inside 3-Way',FALSE);
                ----Changes starts for  NAIT-50192
                --ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-(l_inv_lines_tab(l_indx).rcv_qty))/(l_inv_lines_tab(l_indx).rcv_qty))*100;
                ln_qt_pct := ((l_inv_lines_tab(l_indx).inv_qty-ln_calc_rcv_qty)/ln_Quantity_received)*100;
                --print_debug_msg('ln_qt_pct -- '||ln_qt_pct,FALSE);
              ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
                ln_qt_pct                        := ((l_inv_lines_tab(l_indx).inv_qty- ln_calc_rcv_qty)/(l_inv_lines_tab(l_indx).po_qty))*100;
                --print_debug_msg('ln_qt_pct -- '||ln_qt_pct,FALSE);
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              print_debug_msg ('ERROR processing(chargeback_tolerance_check) invoice_num- '||l_invoice_tab(indx).invoice_num||'-'||lc_error_msg,TRUE);
            END;
            --Changes starts for NAIT-50192
            --IF (ln_qt_pct <= ln_std_qty_rcv_tolerance) AND  (ln_pt_pct <= ln_std_price_tolerance) THEN
            IF (ln_qt_pct <= ln_std_qty_rcv_tolerance) AND (ln_pt_pct <= ln_std_price_tolerance) AND (ln_qt_pct > 0) AND (ln_pt_pct > 0) THEN
              --Changes ends for NAIT-50192
              lc_act_both:='Y';
            END IF;
            --print_debug_msg('lc_act_both '||lc_act_both);
            print_debug_msg('Price Percentage-'||TO_CHAR(ln_pt_pct)||' Quantity Percentage-'||TO_CHAR(ln_qt_pct),FALSE);
            IF l_invoice_tab(indx).match_type='3-Way' THEN
              IF (ln_qt_pct                  > ln_std_qty_rcv_tolerance) OR (ln_pt_pct > ln_std_price_tolerance) THEN
                print_debug_msg('Above std tolerance,skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                CONTINUE; --skip this line and continue to next line
              END IF;
            ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
              IF (ln_qt_pct                     > ln_std_qty_tolerance) OR (ln_pt_pct > ln_std_price_tolerance) THEN
                print_debug_msg('Above std tolerance,skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
                CONTINUE; --skip this line and continue to next line
              END IF;
            END IF;
            --changes starts for NAIT-50192
            --IF (ln_qt_pct < 0) OR (ln_pt_pct < 0) THEN
            IF (ln_qt_pct < 0) AND (ln_pt_pct < 0) THEN
              print_debug_msg('Price or Qty Percent is < 0, skip invoice line '||l_inv_lines_tab(l_indx).line_number,FALSE);
              CONTINUE; --skip this line and continue to next line
            END IF;
            --changes ends for NAIT-50192
            IF l_invoice_tab(indx).match_type='3-Way' THEN
              ----Changes starts for  NAIT-50192
              --IF ln_qt_pct <= ln_std_qty_rcv_tolerance THEN
              IF ln_qt_pct <= ln_std_qty_rcv_tolerance AND ln_qt_pct >0 THEN
                --print_debug_msg('qty % <= std qty rec tolerance ',FALSE);
                --ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -(l_inv_lines_tab(l_indx).rcv_qty)) * l_inv_lines_tab(l_indx).inv_price),2);
                ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -ln_calc_rcv_qty) * l_inv_lines_tab(l_indx).inv_price),2);
                ----Changes ends for  NAIT-50192
              END IF;
            ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
              ----Changes starts for  NAIT-50192
              --IF ln_qt_pct <= ln_std_qty_tolerance  THEN
              IF ln_qt_pct <= ln_std_qty_tolerance AND ln_qt_pct >0 THEN
                print_debug_msg('Qty% <= std qty tolernace',FALSE);
                ----Version 3.6 changes
                --ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -ln_calc_rcv_qty) * l_inv_lines_tab(l_indx).po_price),2);
                ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_qty -ln_calc_rcv_qty) * l_inv_lines_tab(l_indx).inv_price),2);
                --Version 3.6 changes
                ----Changes ends for  NAIT-50192
              END IF;
            END IF;
            --Changes starts for  NAIT-50192
            --IF ln_pt_pct <= ln_std_price_tolerance THEN
            IF ln_pt_pct <= ln_std_price_tolerance AND ln_pt_pct > 0 THEN
              --Changes ends for  NAIT-50192
              print_debug_msg('Price % <= std price tolernace',FALSE);
              IF l_invoice_tab(indx).match_type='3-Way' THEN
                IF lc_act_both                 ='Y' THEN
                  --Changes starts for  NAIT-50192
                  --ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).rcv_qty),2);
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * ln_calc_rcv_qty),2);
                  ----Changes ends for  NAIT-50192
                ELSIF lc_act_both         ='N' THEN
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).inv_qty),2);
                END IF;
              END IF;
            END IF;
            --IF ln_pt_pct <= ln_std_price_tolerance THEN
            IF ln_pt_pct                      <= ln_std_price_tolerance AND ln_pt_pct > 0 THEN
              IF l_invoice_tab(indx).match_type='2-Way' THEN
                --Version 3.6 changes
                IF lc_act_both            ='Y' THEN
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * ln_calc_rcv_qty),2);
                ELSIF lc_act_both         ='N' THEN
                  ln_line_chargeback_amt := ln_line_chargeback_amt + ROUND(((l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price) * l_inv_lines_tab(l_indx).inv_qty),2);
                END IF;
                --Version 3.6 changes ends
              END IF;
            END IF;
            print_debug_msg('ln_line_chargeback_amt -- '||ln_line_chargeback_amt,FALSE);
            ln_hdr_chargeback_amt             := ln_hdr_chargeback_amt + ln_line_chargeback_amt;
            IF ln_line_chargeback_amt          > 0 THEN
              IF l_invoice_tab(indx).match_type='3-Way' THEN
                ----Changes starts for  NAIT-50192
                --ln_qty_diff := l_inv_lines_tab(l_indx).inv_qty -(l_inv_lines_tab(l_indx).rcv_qty);
                ln_qty_diff := l_inv_lines_tab(l_indx).inv_qty - ln_calc_rcv_qty;
                ----Changes ends for  NAIT-50192
              ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
                ----Changes starts for  NAIT-50192
                --ln_qty_diff := l_inv_lines_tab(l_indx).inv_qty -(l_inv_lines_tab(l_indx).po_qty);
                ln_qty_diff := l_inv_lines_tab(l_indx).inv_qty - ln_calc_rcv_qty;
                ----Changes ends for  NAIT-50192
              END IF;
              ln_price_diff := l_inv_lines_tab(l_indx).inv_price - l_inv_lines_tab(l_indx).po_price;
              --
              IF ln_qty_diff                     > 0 THEN
                IF l_invoice_tab(indx).match_type='3-Way' THEN
                  ----Changes starts for  NAIT-50192
                  --Version 3.6 changes
                  --lc_qty_desc := 'QTY: (BQ  '||l_inv_lines_tab(l_indx).inv_qty||'- RQ '||ln_calc_rcv_qty||')* PO PR '||l_inv_lines_tab(l_indx).po_price||'';
                  lc_qty_desc := 'QTY: (BQ  '||l_inv_lines_tab(l_indx).inv_qty||'- RQ '||ln_calc_rcv_qty||')* INV PR '||l_inv_lines_tab(l_indx).inv_price||'';
                  --Version 3.6 changes ends
                  ----Changes ends for  NAIT-50192
                ELSIF l_invoice_tab(indx).match_type='2-Way' THEN
                  ----Changes starts for  NAIT-50192
                  --lc_qty_desc := 'QTY: (BQ  '||l_inv_lines_tab(l_indx).inv_qty||'- POQ '||(l_inv_lines_tab(l_indx).po_qty)||')* INV PR '||l_inv_lines_tab(l_indx).inv_price||'';
                  lc_qty_desc := 'QTY: (BQ  '||l_inv_lines_tab(l_indx).inv_qty||'- PQ '||ln_calc_rcv_qty||')* INV PR '||l_inv_lines_tab(l_indx).inv_price||'';
                  ----Changes ends for  NAIT-50192
                END IF;
              END IF;
              print_debug_msg('Qty_diff'|| ln_qty_diff);
              print_debug_msg('Price_diff'|| ln_price_diff);
              IF ln_price_diff                   > 0 THEN
                IF l_invoice_tab(indx).match_type='3-Way' THEN
                  ----Changes starts for  NAIT-50192
                  --lc_price_desc := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* BQ '|| l_inv_lines_tab(l_indx).inv_qty||')';
                  IF lc_act_both    ='N' THEN
                    lc_price_desc  := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* BQ '|| l_inv_lines_tab(l_indx).inv_qty;
                  ELSIF lc_act_both ='Y' THEN
                    ----Version 3.6 changes
                    --lc_price_desc := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* RQ '|| l_inv_lines_tab(l_indx).rcv_qty||')';
                    lc_price_desc := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* RQ '|| ln_calc_rcv_qty;
                    --Version 3.6 changes ends
                  END IF;
                  ----Changes ends for  NAIT-50192
                END IF;
                IF l_invoice_tab(indx).match_type='2-Way' THEN
                  ----Version 3.6 changes
                  --lc_price_desc                 := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* BQ '|| l_inv_lines_tab(l_indx).inv_qty||')';
                  IF lc_act_both    ='N' THEN
                    lc_price_desc  := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* BQ '|| l_inv_lines_tab(l_indx).inv_qty;
                  ELSIF lc_act_both ='Y' THEN
                    lc_price_desc  := 'Price: (BP '||l_inv_lines_tab(l_indx).inv_price||' - PO PR '|| l_inv_lines_tab(l_indx).po_price ||' )* PQ '|| ln_calc_rcv_qty ;
                  END IF;
                  ----Version 3.6 changes ends
                END IF;
              END IF;
              IF lc_qty_desc IS NOT NULL THEN
                lc_line_desc := lc_qty_desc;
              ELSE
                lc_line_desc:=lc_price_desc;
              END IF;
              ln_line_amount   := ln_line_chargeback_amt*(-1);
              ln_header_amount := ln_hdr_chargeback_amt;
              print_debug_msg('Inserting invoice interface line num-'||l_inv_lines_tab(l_indx).line_number||' InvoiceId:'||TO_CHAR(ln_invoice_id),FALSE);
              print_debug_msg(' Header amount '||ln_header_amount);
              IF ln_qty_diff>0 AND ln_price_diff>0 THEN
                print_debug_msg('Qty diff and price diff found insert one line for both ');
                BEGIN
                  INSERT
                  INTO ap_invoice_lines_interface
                    (
                      invoice_id,
                      invoice_line_id,
                      line_number,
                      line_type_lookup_code,
                      amount,
                      description,
                      dist_code_combination_id,
                      created_by,
                      creation_date,
                      last_updated_by,
                      last_update_date,
                      last_update_login,
                      org_id,
                      inventory_item_id,
                      item_description ,
                      attribute5
                      ---,accounting_date  --Defect#45000
                    )
                    VALUES
                    (
                      ln_invoice_id,
                      ap_invoice_lines_interface_s.nextval,
                      ln_interface_line_count,
                      'MISCELLANEOUS',
                      ---Version 3.6 changes
                      ROUND(((ln_qty_diff*l_inv_lines_tab(l_indx).inv_price)*-1),2),
                      --ROUND(((ln_qty_diff*l_inv_lines_tab(l_indx).po_price)*-1),2),
                      --Version 3.6 changes ends
                      lc_qty_desc,
                      l_inv_lines_tab(l_indx).dist_code_combination_id,
                      gn_user_id,
                      sysdate,
                      gn_user_id,
                      sysdate,
                      gn_login_id,
                      inv_header_rec.org_id,
                      l_inv_lines_tab(l_indx).inventory_item_id,
                      l_inv_lines_tab(l_indx).item_description,
                      l_inv_lines_tab(l_indx).line_number
                      --,SYSDATE  ---Defect#45000
                    );
                EXCEPTION
                WHEN OTHERS THEN
                  lc_interface_cr_flag := 'N';
                  print_debug_msg('Exception caught while instering in interface table',FALSE);
                END;
                ln_interface_line_count := ln_interface_line_count + 1;
                lc_interface_cr_flag    := 'Y';
                BEGIN
                  --print_debug_msg('ln_calc_rcv_qty inside price insert '||ln_calc_rcv_qty);
                  --Version 3.6 changes
                  IF lc_act_both = 'Y' THEN
                    INSERT
                    INTO ap_invoice_lines_interface
                      (
                        invoice_id,
                        invoice_line_id,
                        line_number,
                        line_type_lookup_code,
                        amount,
                        description,
                        dist_code_combination_id,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        last_update_login,
                        org_id,
                        inventory_item_id,
                        item_description,
                        attribute5
                        ----,accounting_date   ---Defect#45000
                      )
                      VALUES
                      (
                        ln_invoice_id,
                        ap_invoice_lines_interface_s.nextval,
                        ln_interface_line_count,
                        'MISCELLANEOUS',
                        ROUND(((ln_price_diff*ln_calc_rcv_qty)*-1),2),
                        lc_price_desc,
                        l_inv_lines_tab(l_indx).variance_account_id,
                        gn_user_id,
                        sysdate,
                        gn_user_id,
                        sysdate,
                        gn_login_id,
                        inv_header_rec.org_id,
                        l_inv_lines_tab(l_indx).inventory_item_id,
                        l_inv_lines_tab(l_indx).item_description,
                        l_inv_lines_tab(l_indx).line_number
                        ---,SYSDATE   ---Defect#45000
                      );
                  ELSIF lc_act_both ='N' THEN
                    INSERT
                    INTO ap_invoice_lines_interface
                      (
                        invoice_id,
                        invoice_line_id,
                        line_number,
                        line_type_lookup_code,
                        amount,
                        description,
                        dist_code_combination_id,
                        created_by,
                        creation_date,
                        last_updated_by,
                        last_update_date,
                        last_update_login,
                        org_id,
                        inventory_item_id,
                        item_description,
                        attribute5
                        ----,accounting_date   ---Defect#45000
                      )
                      VALUES
                      (
                        ln_invoice_id,
                        ap_invoice_lines_interface_s.nextval,
                        ln_interface_line_count,
                        'MISCELLANEOUS',
                        ROUND(((ln_price_diff*l_inv_lines_tab(l_indx).inv_qty)*-1),2),
                        lc_price_desc,
                        l_inv_lines_tab(l_indx).variance_account_id,
                        gn_user_id,
                        sysdate,
                        gn_user_id,
                        sysdate,
                        gn_login_id,
                        inv_header_rec.org_id,
                        l_inv_lines_tab(l_indx).inventory_item_id,
                        l_inv_lines_tab(l_indx).item_description,
                        l_inv_lines_tab(l_indx).line_number
                        ---,SYSDATE   ---Defect#45000
                      );
                  END IF;
                  --Version 3.6 changes ends
                EXCEPTION
                WHEN OTHERS THEN
                  lc_interface_cr_flag := 'N';
                  print_debug_msg('Exception caught while inserting in interface table');
                END;
                ln_interface_line_count := ln_interface_line_count + 1;
                lc_interface_cr_flag    := 'Y';
              ELSE --IF ln_qty_diff>0 AND ln_price_diff>0 THEN
                IF ln_qty_diff >0 THEN
                  print_debug_msg('Qty diff found ');
                  quantity_inv:=ln_qty_diff;
                  v_account_id:=l_inv_lines_tab(l_indx).dist_code_combination_id;
                END IF;
                IF ln_price_diff>0 THEN
                  print_debug_msg('Price diff found ');
                  v_account_id:=l_inv_lines_tab(l_indx).variance_account_id;
                END IF;
                BEGIN
                  INSERT
                  INTO ap_invoice_lines_interface
                    (
                      invoice_id,
                      invoice_line_id,
                      line_number,
                      line_type_lookup_code,
                      amount,
                      description,
                      dist_code_combination_id,
                      created_by,
                      creation_date,
                      last_updated_by,
                      last_update_date,
                      last_update_login,
                      org_id,
                      inventory_item_id,
                      item_description,
                      attribute5
                      --            ,accounting_date      ---Defect#45000
                    )
                    VALUES
                    (
                      ln_invoice_id,
                      ap_invoice_lines_interface_s.nextval,
                      ln_interface_line_count,
                      'MISCELLANEOUS',
                      ROUND(ln_line_amount,2),
                      lc_line_desc,
                      v_account_id,
                      gn_user_id,
                      sysdate,
                      gn_user_id,
                      sysdate,
                      gn_login_id,
                      inv_header_rec.org_id,
                      l_inv_lines_tab(l_indx).inventory_item_id,
                      l_inv_lines_tab(l_indx).item_description,
                      l_inv_lines_tab(l_indx).line_number
                      ---SYSDATE  ---Defect#45000
                    );
                EXCEPTION
                WHEN OTHERS THEN
                  lc_interface_cr_flag := 'N';
                  print_debug_msg('Exception caught in inserting lines ');
                END;
                ln_interface_line_count := ln_interface_line_count + 1;
                lc_interface_cr_flag    := 'Y';
              END IF;             -- IF ln_qty_diff>0 AND ln_price_diff>0 THEN
              quantity_inv:=NULL; --Naveen
            END IF;               --ln_line_chargeback_amt > 0
          END LOOP;               --l_inv_lines_tab
        END IF;                  ---IF ln_inv_chargeback_amt > ln_min_chargeback_amt AND lc_chargeback_cr_flag = 'Y' THEN
        print_debug_msg('lc_chargeback_cr_flag -'||lc_chargeback_cr_flag||'ln_total_qty_pct - '||ln_total_qt_pct,FALSE);
        --Commented if condition and added new IF condition for NAIT-50192
        --IF l_inv_lines_freight_tab.count > 0 THEN
        IF l_inv_lines_freight_tab.count > 0 AND ln_total_qt_pct <= ln_std_qty_rcv_tolerance THEN
          --Added NVL function in ln_maxfrieght_amt to handle null
          --and commented fright amount cursor since it is pointing to wrong indx -- NAIT-50192
          IF NVL(ln_max_freight_amt,0) = 0 --AND NVL(l_inv_lines_freight_tab(indx).amount,0) > 0
            THEN
            FOR lf_indx IN 1..l_inv_lines_freight_tab.COUNT
            LOOP
              -- Added below IF to check if freight amount >0 --NAIT-50192
              IF NVL
                (
                  l_inv_lines_freight_tab(lf_indx).amount,0
                )
                                  > 0 THEN
                ln_header_amount := ln_header_amount + l_inv_lines_freight_tab
                (
                  lf_indx
                )
                .amount;
                print_debug_msg('Inserting invoice interface line num for Freight -'||l_inv_lines_freight_tab(lf_indx).line_number||' InvoiceId:'||TO_CHAR(ln_invoice_id),FALSE);
                BEGIN
                  INSERT
                  INTO ap_invoice_lines_interface
                    (
                      invoice_id,
                      invoice_line_id,
                      line_number,
                      line_type_lookup_code,
                      amount,
                      description,
                      dist_code_combination_id,
                      created_by,
                      creation_date,
                      last_updated_by,
                      last_update_date,
                      last_update_login,
                      org_id
                      ---,accounting_date   ----Defect#45000
                    )
                    VALUES
                    (
                      ln_invoice_id,
                      ap_invoice_lines_interface_s.nextval,
                      ln_interface_line_count,
                      'FREIGHT',
                      ROUND(((-1)*l_inv_lines_freight_tab(lf_indx).amount),2),
                      'Freight chargeback',
                      l_inv_lines_freight_tab(lf_indx).dist_code_combination_id, --discuss
                      gn_user_id,
                      sysdate,
                      gn_user_id,
                      sysdate,
                      gn_login_id,
                      inv_header_rec.org_id
                      ---- ,SYSDATE   ---Defect#45000
                    );
                EXCEPTION
                WHEN OTHERS THEN
                  lc_interface_cr_flag := 'N';
                END;
                BEGIN
                  --print_debug_msg('ln_max_freight_hold -- '||ln_max_freight_hold||'--'||'Org id '||ln_org_id
                  --||'--'||gn_user_id);
                  IF ln_max_freight_hold > 0 THEN
                    mo_global.set_policy_context ('S',ln_org_id);
                    mo_global.init ('SQLAP');
                    --print_debug_msg('ln_invoice_id/lc_hold_lookup_code/lc_release_lookup_code/gn_user_id -- '
                    --||l_inv_lines_freight_tab(lf_indx).invoice_id||'--'||lc_hold_lookup_code||'--'||lc_release_lookup_code||'--'||gn_user_id);
                    ap_holds_pkg.release_single_hold (x_invoice_id => l_inv_lines_freight_tab(lf_indx).invoice_id, x_hold_lookup_code => lc_hold_lookup_code, x_release_lookup_code => lc_release_lookup_code, x_held_by => ln_held_by, x_calling_sequence => NULL );
                  END IF;
                EXCEPTION
                WHEN OTHERS THEN
                  print_debug_msg('Exception caught in releasing hold for freight for invoice id :'||TO_CHAR(ln_invoice_id)||'--'||SQLERRM,FALSE);
                END;
                ln_interface_line_count := ln_interface_line_count + 1;
                lc_interface_cr_flag    := 'Y';
              END IF; -- if l_inv_lines_freight_tab(lf_indx.amount > 0 THEN
            END LOOP;
          END IF; --                IF ln_max_freight_amt = 0 AND l_inv_lines_freight_tab(indx).amount > 0 THEN
        END IF;   --l_inv_lines_freight_tab.count > 0
        IF lc_interface_cr_flag = 'Y' THEN
          ln_header_amount     := ln_header_amount *(-1);
          print_debug_msg('Inserting invoice interface header- invoice_id:'||TO_CHAR(ln_invoice_id),FALSE);
          BEGIN
            INSERT
            INTO ap_invoices_interface
              (
                invoice_id,
                invoice_num,
                invoice_type_lookup_code,
                invoice_date,
                vendor_id,
                vendor_site_id,
                invoice_amount,
                invoice_currency_code,
                terms_id,
                description,
                attribute7,
                source,
                payment_method_code,
                pay_group_lookup_code,
                org_id,
                goods_received_date,
                created_by,
                creation_date,
                last_updated_by,
                last_update_date,
                last_update_login,
                po_number,
                ---  gl_date,   --Defect#45000
                attribute12,
                attribute5,
                terms_date,
                attribute1,
                attribute2,
                attribute3,
                attribute4,
                attribute6,
                attribute8,
                attribute9,
                attribute10,
                attribute11,
                attribute13,
                attribute14,
                attribute15
              )
              VALUES
              (
                ln_invoice_id,
                lc_chargeback_invoice_num,
                'DEBIT', --discuss --need to put debit memo
                inv_header_rec.invoice_date,
                l_invoice_tab(indx).vendor_id,
                l_invoice_tab(indx).vendor_site_id,
                ROUND(ln_header_amount,2),
                inv_header_rec.invoice_currency_code,
                inv_header_rec.terms_id,
                inv_header_rec.description,
                inv_header_rec.attribute7,
                Upper(inv_header_rec.source), -- Temporarily modified to work for Manual Invoice Entry source..
                inv_header_rec.payment_method_code,
                inv_header_rec.pay_group_lookup_code,
                inv_header_rec.org_id,
                DECODE(lc_terms_date_basis,'Goods Received',NVL(inv_header_rec.goods_received_date,inv_header_rec.terms_date),NULL),
                gn_user_id,
                sysdate,
                gn_user_id,
                sysdate,
                gn_login_id,
                inv_header_rec.po_num,
                --- SYSDATE,     -----Defect#45000
                'Y',
                inv_header_rec.attribute5,
                inv_header_rec.terms_date,
                inv_header_rec.attribute1,
                inv_header_rec.attribute2,
                inv_header_rec.attribute3,
                inv_header_rec.attribute4,
                inv_header_rec.attribute6,
                inv_header_rec.attribute8,
                inv_header_rec.attribute9,
                inv_header_rec.attribute10,
                inv_header_rec.attribute11,
                inv_header_rec.attribute13,
                inv_header_rec.attribute14,
                inv_header_rec.attribute15
              );
            ln_interface_hdr_count := ln_interface_hdr_count + 1;
            UPDATE ap_invoices_all
            SET attribute3  =lc_chargeback_invoice_num
            WHERE invoice_id=inv_header_rec.invoice_id;
          EXCEPTION
          WHEN OTHERS THEN
            print_debug_msg('When others in Inserting invoice interface header : '||SUBSTR(SQLERRM,1,100),TRUE);
            lc_interface_cr_flag:='N';
            ROLLBACK;
          END;
        END IF; -- IF lc_interface_cr_flag = 'Y' THEN
        IF lc_interface_cr_flag='Y' THEN
          COMMIT;
        ELSE
          ROLLBACK;
        END IF;
      EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        lc_error_msg := SUBSTR(sqlerrm,1,250);
        print_debug_msg ('ERROR processing(chargeback_tolerance_check) invoice_num- '||l_invoice_tab(indx).invoice_num||'-'||lc_error_msg,TRUE);
        log_exception ('OD AP Trade Match Prevalidation Program',lc_error_loc,lc_error_msg);
        p_retcode := '2';
      END;
    END LOOP; --l_invoice_tab
  END LOOP;   --invoice_cur
  CLOSE invoice_cur;
  print_out_msg('Chargeback Tolerance Check Stats');
  print_out_msg('-------------------------------');
  print_out_msg(TO_CHAR(ln_interface_hdr_count)||' : invoice header records interfaced');
END chargeback_tolerance_check;
-- +====================================================================================+
-- | Name        :  main                                                                  |
-- | Description :  This procedure put the invoices in 6 day wait, validates              |
-- |                                                                                      |
-- |                                                                                      |
-- | Parameters  :  p_err_buf,p_retcode,p_debug                                           |
-- |                                                                                      |
-- | Returns     :                                                                        |
-- |                                                                                      |
-- +======================================================================================+
PROCEDURE main(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_source IN VARCHAR2 ,
    p_debug  IN VARCHAR2 )
AS
  lc_error_msg   VARCHAR2(1000) := NULL;
  lc_error_loc   VARCHAR2(100)  := 'XX_AP_TR_AUTO_CHBK_PKG.main';
  lc_retcode     VARCHAR2(3)    := NULL;
  data_exception EXCEPTION;
BEGIN
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  --print_debug_msg('Check for chargeback tolerance',TRUE);
  --print_debug_msg('Check for chargeback tolerance',TRUE);
  chargeback_tolerance_check(p_source,lc_error_msg,lc_retcode);
  IF lc_retcode = '2' THEN --One of the invoice(s) has errors.
    p_retcode  := '1';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  lc_error_msg := lc_error_msg ||'-'|| SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR AP Trade Match - '||lc_error_msg,TRUE);
  log_exception ('OD AP Trade Match Prevalidation Program', lc_error_loc, lc_error_msg);
  p_retcode := 2;
END main;
END;
/
SHOW ERRORS;