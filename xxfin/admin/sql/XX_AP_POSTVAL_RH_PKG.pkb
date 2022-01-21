SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_POSTVAL_RH_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE BODY XX_AP_POSTVAL_RH_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name     :  XX_AP_POSTVAL_RH_PKG                                                            |
  -- |  RICE ID      :  E3522_OD Trade Match Foundation                                             |
  -- |  Description:  Custom post invoice validation program to validate and release holds        |
  -- |                                                                                               |
  -- |                                                                                             |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         08/18/2017   Paddy/Avinash    Initial version                                  |
  -- | 1.1         12/12/2017   Paddy Sanjeevi   Added Hold_lookup_code=QTY REC                   |
  -- | 1.2         01/30/2017   Naveen Patha     Added org_id parameter                           |
  -- | 1.3         09/25/2018   Ragni Gupta      Removed date condition also added new cursor to  |
  --                                             handle QTY ORD hold for NAIT-50192               |
  -- | 1.4         10/16/2018   Ragni Gupta      Added logic to handle release hold for previous
  --                                             invoice(FIFO) if it is within tolerance, NAIT-50192
  -- | 1.5         11/27/2018   Ragni Gupta      Added procedure release_hold with commit, to release 
  --                                             hold and called same instead of writing update,NAIT-73009 
  --                                             multiple times and made p_source as IN parameter
  -- | 1.6         12/03/2018   Ragni Gupta		 Added po line id in all query of validate_release_holds
  --											 NAIT-73009
  
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name     : Log Exception                                                                    |
  -- |  Description: The log_exception procedure logs all exceptions                                |
  -- =============================================================================================|
  gc_debug VARCHAR2(2);
  gn_request_id fnd_concurrent_requests.request_id%TYPE;
  gn_user_id fnd_concurrent_requests.requested_by%TYPE;
  gn_login_id NUMBER;
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
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT FALSE)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_Message := P_Message;
    fnd_file.put_line (fnd_file.log, lc_Message);
    IF ( fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line (lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_debug_msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE print_out_msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2 (4000) := NULL;
BEGIN
  lc_message := p_message;
  fnd_file.put_line (fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line (lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END print_out_msg;
--NAIT-73009 - Added below procedure to release hold
PROCEDURE release_hold(
    p_invoice_id       IN NUMBER ,
    p_line_loc_id      IN NUMBER ,
    p_hold_lookup_code IN VARCHAR2)
IS
  ln_user_id NUMBER := fnd_global.user_id;
  CURSOR get_hold_inv_id
  IS
    SELECT rowid row_id
    FROM ap_holds_all
    WHERE invoice_id         = p_invoice_id
    AND line_location_id     = p_line_loc_id
    AND hold_lookup_code     = p_hold_lookup_code
    AND release_lookup_code IS NULL;
    --PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
fnd_file.put_line(fnd_file.log, 'inside release hold program');
  FOR i IN get_hold_inv_id
  LOOP
  fnd_file.put_line(fnd_file.log, 'inside for loop- rowid '||i.row_id);
    UPDATE ap_holds_all
    SET release_lookup_code = 'INVOICE QUICK RELEASED',
      release_reason        = 'Holds released in Invoice Holds window',
      last_update_date      = SYSDATE,
      last_updated_by       = ln_user_id
    WHERE rowid             = i.row_id;
    COMMIT;
    fnd_file.put_line(fnd_file.log, 'Hold Released for invoice id - '||p_invoice_id||' Hold Name- '||p_hold_lookup_code);
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log, 'Error while releasing hold for invoice id...'||p_invoice_id||' Hold Name- '||p_hold_lookup_code||'  '||SQLERRM);
END release_hold;
PROCEDURE validate_release_holds(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT VARCHAR2 ,
    p_source IN VARCHAR2 ,
    p_debug VARCHAR2)
AS
  CURSOR po_items_cur(p_org_id NUMBER)
  IS
    SELECT NVL(ai.po_header_id,ai.quick_po_header_id) po_header_id,
      apl.inventory_item_id,
      ai.vendor_id,
      ai.vendor_site_id,
      apl.po_line_id --Added this in SELECT query , NAIT-73009, 03-DEC-18
    FROM ap_invoices_all ai,
      ap_invoice_lines_all apl
    WHERE ai.invoice_id           = apl.invoice_id
    AND ai.org_id+0               =p_org_id
    AND apl.line_type_lookup_code = 'ITEM'    
      --AND ai.creation_date >= TO_DATE((TO_CHAR(sysdate-6,'DD-MON-YYYY')||' 00:00:00'), 'DD-MON-YYYY HH24:MI:SS')
      --AND ai.creation_date <= TO_DATE((TO_CHAR(sysdate-6,'DD-MON-YYYY')||' 23:59:59'), 'DD-MON-YYYY HH24:MI:SS')
    AND ai.source = NVL(p_source,ai.source)
    AND EXISTS
      (SELECT xftv.Target_value1,
        xftv.translate_id
      FROM xx_fin_translatedefinition xftd,
        xx_fin_translatevalues xftv
      WHERE xftd.translation_name = 'XX_AP_TR_MATCH_INVOICES'
      AND xftd.translate_id       = xftv.translate_id
      AND xftv.target_value1      = ai.source
      AND xftv.enabled_flag       = 'Y'
      AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,sysdate)
      )
  AND EXISTS
    (SELECT 'x'
    FROM ap_holds_all aph
    WHERE aph.invoice_id         = ai.invoice_id
    AND aph.hold_lookup_code    IN ('QTY REC','QTY ORD') --Quantity billed exceeds quantity received
    AND aph.release_lookup_code IS NULL
    )
    --Added below exists for NAIT-50192
  AND EXISTS
    (SELECT 'x'
    FROM ap_supplier_sites_all
    WHERE vendor_site_id = ai.vendor_site_id
    AND vendor_id        = ai.vendor_id
    AND attribute8 LIKE 'TR%'
    )
  GROUP BY NVL(ai.po_header_id,ai.quick_po_header_id),
    apl.inventory_item_id,
    apl.po_line_id, --Added po_line in query , NAIT-73009, 03-DEC-18
    ai.vendor_id,
    ai.vendor_site_id
  HAVING COUNT(*) > 1 ;
TYPE po_items
IS
  TABLE OF po_items_cur%ROWTYPE INDEX BY PLS_INTEGER;
  l_po_items_tab po_items;
  indx NUMBER;
  CURSOR ap_lines_cur(p_po_header_id NUMBER, p_item_id NUMBER, p_po_line_id NUMBER, p_org_id NUMBER)
  IS
    SELECT l.invoice_id,
      SUM(l.quantity_invoiced) quantity_invoiced,
      l.po_line_location_id
    FROM ap_invoice_lines_all l
    WHERE l.po_header_id    = p_po_header_id
    AND l.po_line_id = p_po_line_id --Added po_line in query , NAIT-73009, 03-DEC-18
    AND l.inventory_item_id = p_item_id
    AND l.org_id+0          =p_org_id
    AND EXISTS
      (SELECT 'x'
      FROM ap_holds_all h
      WHERE h.invoice_id         = l.invoice_id
      AND h.line_location_id     = l.po_line_location_id
      AND h.hold_lookup_code     = 'QTY REC'
      AND h.release_lookup_code IS NULL
      )      
      GROUP BY l.invoice_id, l.po_line_location_id
  ORDER BY l.invoice_id ASC;
TYPE ap_lines
IS
  TABLE OF ap_lines_cur%ROWTYPE INDEX BY PLS_INTEGER;
  --Added below cursor to remove QTY ORD hold for 2-way invoice, NAIT-50192
  CURSOR ap_lines_qty_ord_cur(p_po_header_id NUMBER, p_item_id NUMBER, p_po_line_id NUMBER, p_org_id NUMBER)
  IS
    SELECT l.invoice_id,
      SUM(l.quantity_invoiced) quantity_invoiced,
      l.po_line_location_id
    FROM ap_invoice_lines_all l
    WHERE l.po_header_id    = p_po_header_id
    AND l.po_line_id = p_po_line_id  --Added po_line in query , NAIT-73009, 03-DEC-18
    AND l.inventory_item_id = p_item_id
    AND l.org_id+0          =p_org_id
    AND EXISTS
      (SELECT 'x'
      FROM ap_holds_all h
      WHERE h.invoice_id         = l.invoice_id
      AND h.line_location_id     = l.po_line_location_id
      AND h.hold_lookup_code     = 'QTY ORD'
      AND h.release_lookup_code IS NULL
      )   
      GROUP BY l.invoice_id, l.po_line_location_id
  ORDER BY l.invoice_id ASC;
TYPE ap_lines_qty
IS
  TABLE OF ap_lines_qty_ord_cur%ROWTYPE INDEX BY PLS_INTEGER;
  CURSOR get_std_tolerance_values(p_vendor_id NUMBER, p_vendor_site_id NUMBER, p_org_id NUMBER)
  IS
    SELECT b.qty_received_tolerance,
      b.quantity_tolerance
    FROM ap_tolerance_templates b,
      ap_supplier_sites_all ss
    WHERE ss.vendor_site_id = p_vendor_site_id
    AND ss.vendor_id        = p_vendor_id
    AND b.tolerance_id      = ss.tolerance_id
    AND ss.org_id           = p_org_id;
  l_ap_lines_tab ap_lines;
  l_ap_lines_qty_tab ap_lines_qty;
  l_indx                   NUMBER;
  ln_unbilled_qty          NUMBER;
  ln_tot_quantity_billed   NUMBER;
  ln_inv_quantity_billed   NUMBER;
  ln_quantity_received     NUMBER;
  lc_error_loc             VARCHAR2(100) := 'XX_AP_POSTVAL_RH_PKG.validate_release_holds';
  lc_error_msg             VARCHAR2(2000);
  ln_org_id                NUMBER;
  ln_qtyord_unbilled_qty   NUMBER;
  ln_po_qty                NUMBER;
  ln_std_qty_rcv_tolerance NUMBER;
  ln_std_qty_tolerance     NUMBER;
  ln_inv_qty_invoice       NUMBER;
  ln_qty_diff_pt           NUMBER;
BEGIN
  ln_org_id     :=FND_PROFILE.VALUE ('ORG_ID');
  gc_debug      := p_debug;
  gn_request_id := fnd_global.conc_request_id;
  gn_user_id    := fnd_global.user_id;
  gn_login_id   := fnd_global.login_id;
  p_retcode     := NULL;
  print_debug_msg('Start Validation of Holds - QTY REC',TRUE);
  OPEN po_items_cur(ln_org_id);
  FETCH po_items_cur BULK COLLECT
  INTO l_po_items_tab;
  CLOSE po_items_cur;
  FOR indx IN 1..l_po_items_tab.COUNT
  LOOP
    ln_qtyord_unbilled_qty:=0;
    ln_unbilled_qty       :=0;
    BEGIN
      print_debug_msg('Processing Po_header_id:'||TO_CHAR(l_po_items_tab(indx).po_header_id)|| ' ItemId:'||TO_CHAR(l_po_items_tab(indx).inventory_item_id),FALSE);
      print_debug_msg('Get PO quantities for the Item',FALSE);
      SELECT NVL(SUM(pol.quantity_received),0),
        NVL(SUM(pol.quantity_billed),0),
        NVL(SUM (l.quantity),0)
      INTO ln_quantity_received,
        ln_tot_quantity_billed,
        ln_po_qty
      FROM po_line_locations_all pol,
        po_lines_all l
      WHERE l.po_header_id = l_po_items_tab(indx).po_header_id
      AND l.po_line_id = l_po_items_tab(indx).po_line_id --Added po_line in query , NAIT-73009, 03-DEC-18
      AND l.item_id        = l_po_items_tab(indx).inventory_item_id      
      AND pol.po_line_id   = l.po_line_id;
      SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
      INTO ln_inv_quantity_billed
      FROM ap_invoice_lines_all l
      WHERE po_header_id    = l_po_items_tab(indx).po_header_id
      AND   po_line_id = l_po_items_tab(indx).po_line_id --Added po_line in query , NAIT-73009, 03-DEC-18
      AND inventory_item_id = l_po_items_tab(indx).inventory_item_id
      AND EXISTS
        (SELECT 'x'
        FROM ap_holds_all
        WHERE invoice_id         = l.invoice_id
        AND line_location_id     = l.po_line_location_id
        AND hold_lookup_code    IN ('QTY REC','QTY ORD')
        AND release_lookup_code IS NULL
        );
      print_debug_msg('Get Inv Quantity Billed for the Item '||ln_inv_quantity_billed,FALSE);
      ln_unbilled_qty := ln_quantity_received - (ln_tot_quantity_billed - ln_inv_quantity_billed);
      print_debug_msg('Calculate unbilled quantity -- '||ln_unbilled_qty,FALSE);
      OPEN ap_lines_cur(l_po_items_tab(indx).po_header_id,l_po_items_tab(indx).inventory_item_id,l_po_items_tab(indx).po_line_id, ln_org_id);
      FETCH ap_lines_cur BULK COLLECT
      INTO l_ap_lines_tab;
      CLOSE ap_lines_cur;
      FOR l_indx IN 1..l_ap_lines_tab.COUNT
      LOOP
        ln_qty_diff_pt:=0;
        print_debug_msg('Processing Invoice_Id:'||TO_CHAR(l_ap_lines_tab(l_indx).invoice_id),FALSE);
        IF l_ap_lines_tab(l_indx).quantity_invoiced <= ln_unbilled_qty THEN
          ln_unbilled_qty                           := ln_unbilled_qty - l_ap_lines_tab(l_indx).quantity_invoiced;
          print_debug_msg('Release the hold for the invoice id / New Unbilled : '||TO_CHAR(l_ap_lines_tab(l_indx).invoice_id)||' / '||TO_CHAR(ln_unbilled_qty),FALSE);
          --NAIT-73009 - Calling procedure instead of direct call of Update statement
		  release_hold( p_invoice_id => l_ap_lines_tab(l_indx).invoice_id , p_line_loc_id => l_ap_lines_tab(l_indx).po_line_location_id , p_hold_lookup_code => 'QTY REC');
		  
          /*UPDATE ap_holds_all
          SET release_lookup_code  = 'INVOICE QUICK RELEASED',
          release_reason         = 'Holds released in Invoice Holds window',
          last_update_date       = SYSDATE,
          last_updated_by        = gn_user_id
          WHERE invoice_id         = l_ap_lines_tab(l_indx).invoice_id
          AND line_location_id     = l_ap_lines_tab(l_indx).po_line_location_id
          AND hold_lookup_code     = 'QTY REC'
          AND release_lookup_code IS NULL; */
		  --changes ends for NAIT-73009
        ELSE
          --changes start for NAIT-50192, to handle release hold for previous invoice(FIFO) if it is within tolerance
          print_debug_msg('Inside qty invoice > unbilled qty',FALSE);
          OPEN get_std_tolerance_values(l_po_items_tab(indx).vendor_id,l_po_items_tab(indx).vendor_site_id,ln_org_id); --discuss no data/null here
          FETCH get_std_tolerance_values
          INTO ln_std_qty_rcv_tolerance,
            ln_std_qty_tolerance;
          CLOSE get_std_tolerance_values;
          IF ln_std_qty_rcv_tolerance IS NULL THEN
            ln_std_qty_rcv_tolerance  :=0;
          END IF;
          SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
          INTO ln_inv_qty_invoice
          FROM ap_invoice_lines_all l
          WHERE po_header_id    = l_po_items_tab(indx).po_header_id
          AND   po_line_id = l_po_items_tab(indx).po_line_id --Added po_line in query , NAIT-73009, 03-DEC-18
          AND inventory_item_id = l_po_items_tab(indx).inventory_item_id          
          AND EXISTS
            (SELECT 'x'
            FROM ap_holds_all
            WHERE invoice_id         = l.invoice_id
            AND line_location_id     = l.po_line_location_id
            AND hold_lookup_code     = 'QTY REC'
            AND release_lookup_code IS NULL
            )
          AND l.invoice_id <= l_ap_lines_tab(l_indx).invoice_id;
          BEGIN
            ln_qty_diff_pt := ((ln_inv_qty_invoice-ln_quantity_received)/ln_quantity_received)*100;
          EXCEPTION
          WHEN OTHERS THEN
            ln_qty_diff_pt :=0;
          END;
          print_debug_msg('ln_inv_qty_invoice/ln_qty_diff_pt -- ' ||ln_inv_qty_invoice||' -- '||ln_qty_diff_pt,FALSE);
          IF ln_qty_diff_pt <= ln_std_qty_rcv_tolerance AND ln_qty_diff_pt > 0 THEN
            print_debug_msg('Release the hold for the invoice id since within tolerance/ ln_qty_diff_pt : '||TO_CHAR(l_ap_lines_tab(l_indx).invoice_id)||' / '||TO_CHAR(ln_qty_diff_pt),FALSE);
            ln_unbilled_qty   := ln_unbilled_qty - l_ap_lines_tab(l_indx).quantity_invoiced;
            IF ln_unbilled_qty <0 THEN
              ln_unbilled_qty :=0;
            END IF;
			--NAIT-73009 - Calling procedure instead of direct call of Update statement
            release_hold( p_invoice_id => l_ap_lines_tab(l_indx).invoice_id , p_line_loc_id => l_ap_lines_tab(l_indx).po_line_location_id , p_hold_lookup_code => 'QTY REC');
            /*        UPDATE ap_holds_all
            SET release_lookup_code  = 'INVOICE QUICK RELEASED',
            release_reason         = 'Holds released in Invoice Holds window',
            last_update_date       = SYSDATE,
            last_updated_by        = gn_user_id
            WHERE invoice_id         = l_ap_lines_tab(l_indx).invoice_id
            AND line_location_id     = l_ap_lines_tab(l_indx).po_line_location_id
            AND hold_lookup_code     = 'QTY REC'
            AND release_lookup_code IS NULL; */
			--changes ends for NAIT-73009
          ELSE
            print_debug_msg('Not releasing hold for this and subsequent invoice for same PO line since out of tolerance/less than 0',FALSE);
            EXIT;
          END IF;
          --changes ends for NAIT-50192
          -- EXIT;
        END IF;
      END LOOP;
      --changes start for NAIT-50192
      OPEN ap_lines_qty_ord_cur(l_po_items_tab(indx).po_header_id,l_po_items_tab(indx).inventory_item_id,l_po_items_tab(indx).po_line_id,ln_org_id);
      FETCH ap_lines_qty_ord_cur BULK COLLECT
      INTO l_ap_lines_qty_tab;
      CLOSE ap_lines_qty_ord_cur;
      ln_qtyord_unbilled_qty := ln_po_qty - (ln_tot_quantity_billed - ln_inv_quantity_billed);
      FOR l_qindx                        IN 1..l_ap_lines_qty_tab.COUNT
      LOOP
        ln_qty_diff_pt:=0;
        print_debug_msg('For Qty ORD Hold --Processing invoice_id /ln_qtyord_unbilled_qty/l_ap_lines_qty_tab(l_qindx).quantity_invoiced -- '||l_ap_lines_qty_tab(l_qindx).invoice_id||' / '||ln_qtyord_unbilled_qty||' / '||l_ap_lines_qty_tab(l_qindx).quantity_invoiced);
        IF l_ap_lines_qty_tab(l_qindx).quantity_invoiced <= ln_qtyord_unbilled_qty THEN
          ln_qtyord_unbilled_qty                         := ln_qtyord_unbilled_qty - l_ap_lines_qty_tab(l_qindx).quantity_invoiced;
          print_debug_msg('Release the hold for the invoice id / New Unbilled : '||TO_CHAR(l_ap_lines_qty_tab(l_qindx).invoice_id)||' / '||TO_CHAR(ln_qtyord_unbilled_qty),FALSE);
		  --NAIT-73009 - Calling procedure instead of direct call of Update statement
          release_hold( p_invoice_id => l_ap_lines_qty_tab(l_qindx).invoice_id, p_line_loc_id => l_ap_lines_qty_tab(l_qindx).po_line_location_id, p_hold_lookup_code => 'QTY ORD');
          /*UPDATE ap_holds_all
          SET release_lookup_code  = 'INVOICE QUICK RELEASED',
          release_reason         = 'Holds released in Invoice Holds window',
          last_update_date       = SYSDATE,
          last_updated_by        = gn_user_id
          WHERE invoice_id         = l_ap_lines_qty_tab(l_qindx).invoice_id
          AND line_location_id     = l_ap_lines_qty_tab(l_qindx).po_line_location_id
          AND hold_lookup_code     = 'QTY ORD'
          AND release_lookup_code IS NULL;*/
		  -- changes ends for NAIT-73009
        ELSE
          ----To handle release hold for previous invoice(FIFO) if it is within tolerance, NAIT-50192
          print_debug_msg('Inside qty invoice > unbilled qty',FALSE);
          OPEN get_std_tolerance_values(l_po_items_tab(indx).vendor_id,l_po_items_tab(indx).vendor_site_id,ln_org_id); --discuss no data/null here
          FETCH get_std_tolerance_values
          INTO ln_std_qty_rcv_tolerance,
            ln_std_qty_tolerance;
          CLOSE get_std_tolerance_values;
          IF ln_std_qty_tolerance IS NULL THEN
            ln_std_qty_tolerance  :=0;
          END IF;
          SELECT NVL(SUM(l.QUANTITY_INVOICED),0)
          INTO ln_inv_qty_invoice
          FROM ap_invoice_lines_all l
          WHERE po_header_id    = l_po_items_tab(indx).po_header_id
          AND   po_line_id = l_po_items_tab(indx).po_line_id --Added po_line in query , NAIT-73009, 03-DEC-18
          AND inventory_item_id = l_po_items_tab(indx).inventory_item_id
          AND EXISTS
            (SELECT 'x'
            FROM ap_holds_all
            WHERE invoice_id         = l.invoice_id
            AND line_location_id     = l.po_line_location_id
            AND hold_lookup_code     = 'QTY ORD'
            AND release_lookup_code IS NULL
            )
          AND l.invoice_id <= l_ap_lines_qty_tab(l_qindx).invoice_id;
          BEGIN
            ln_qty_diff_pt := ((ln_inv_qty_invoice-ln_po_qty)/ln_po_qty)*100;
          EXCEPTION
          WHEN OTHERS THEN
            ln_qty_diff_pt:=0;
          END;
          print_debug_msg('ln_inv_qty_invoice/ln_qty_diff_pt/ln_std_qty_tolerance -- ' ||ln_inv_qty_invoice||' -- '||ln_qty_diff_pt||' --'||ln_std_qty_tolerance,FALSE);
          IF ln_qty_diff_pt <= ln_std_qty_tolerance AND ln_qty_diff_pt >0 THEN
            print_debug_msg('Release the hold for the invoice id since within tolerance/ ln_qty_diff_pt : '||TO_CHAR(l_ap_lines_qty_tab(l_qindx).invoice_id)||' / '||TO_CHAR(ln_qty_diff_pt),FALSE);
            ln_qtyord_unbilled_qty   := ln_qtyord_unbilled_qty - l_ap_lines_qty_tab(l_qindx).quantity_invoiced;
            IF ln_qtyord_unbilled_qty <0 THEN
              ln_qtyord_unbilled_qty :=0;
            END IF;
			--NAIT-73009 - Calling procedure instead of direct call of Update statement
            release_hold( p_invoice_id => l_ap_lines_qty_tab(l_qindx).invoice_id, p_line_loc_id => l_ap_lines_qty_tab(l_qindx).po_line_location_id, p_hold_lookup_code => 'QTY ORD');
            /*
            UPDATE ap_holds_all
            SET release_lookup_code  = 'INVOICE QUICK RELEASED',
            release_reason         = 'Holds released in Invoice Holds window',
            last_update_date       = SYSDATE,
            last_updated_by        = gn_user_id
            WHERE invoice_id         = l_ap_lines_qty_tab(l_qindx).invoice_id
            AND line_location_id     = l_ap_lines_qty_tab(l_qindx).po_line_location_id
            AND hold_lookup_code     = 'QTY ORD'
            AND release_lookup_code IS NULL;*/
			--changes ends for NAIT-73009
          ELSE
            print_debug_msg('Not releasing hold for this and subsequent invoice for same PO line since out of tolerance/less than 0',FALSE);
            EXIT;
          END IF;
          --EXIT;
        END IF;
      END LOOP;
      --changes ends for NAIT-50192
    EXCEPTION
    WHEN OTHERS THEN
      lc_error_msg := SUBSTR(sqlerrm,1,250);
      print_debug_msg ('Validation Release Hold failed for Po_header_id:'||TO_CHAR(l_po_items_tab(indx).po_header_id)|| ' ItemId:'||TO_CHAR(l_po_items_tab(indx).inventory_item_id),TRUE);
      print_debug_msg (lc_error_msg,TRUE);
      log_exception('OD AP Postvalidation Release Hold Program', lc_error_loc, lc_error_msg);
      p_retcode := '1';
    END;
  END LOOP;
  IF p_retcode IS NULL THEN
    p_retcode  := '0';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  p_errbuf := lc_error_msg ||'-'|| SUBSTR(sqlerrm,1,250);
  print_debug_msg ('ERROR AP POST Validation Release Hold - '||lc_error_msg,TRUE);
  log_exception ('OD AP Postvalidation Release Hold Program', lc_error_loc, lc_error_msg);
  p_retcode := '2';
END validate_release_holds;
END XX_AP_POSTVAL_RH_PKG;
/
SHOW ERR
