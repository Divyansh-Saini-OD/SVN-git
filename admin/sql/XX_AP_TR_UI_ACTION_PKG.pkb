create or replace PACKAGE BODY      XX_AP_TR_UI_ACTION_PKG
  -- +==================================================================================+
  -- |                  Office Depot - Project Simplify                                 |
  -- +==================================================================================+
  -- | Name        :  XX_AP_TR_UI_ACTION_PKG.pkb                                        |
  -- | Description :  Plsql package for Invoice UI actions                              |
  -- | RICE ID     :  E3522_OD Trade Match Foundation                                   |
  -- |Change Record:                                                                    |
  -- |===============                                                                   |
  -- |Version   Date        Author             Remarks                                  |
  -- |========  =========== ================== =========================================|
  -- |1.0       12-Aug-2017 Paddy Sanjeevi     Initial version                          |
  -- |1.1       02-Oct-2017 Paddy Sanjeevi     upd_invoice_num to set v_error           |
  -- |1.2       17-Oct-2017 Naveen Patha       Added release lookup code is null        |   
  -- |1.3       18-Oct-2017 Naveen Patha       Added attribute columns                  |
  -- |1.4       27-Oct-2017 Paddy Sanjeevi     Added xx_insert_new_holds                |  
  -- |1.5       06-Dec-2017 Paddy Sanjeevi     Modified for 17 Scenarios requirement    |
  -- |1.6       13-Dec-2017 Paddy Sanjeevi     Modified check_hold_exists function      |
  -- |1.7       21-Dec-2017 Paddy Sanjeevi     Modified xx_create_invoice to add RC     |   
  -- |1.8       26-Dec-2017 Paddy Sanjeevi     Modified xx_get_total                    |
  -- |1.9       29-Dec-2017 Naveen Patha       UOM change xx_insert_custom_invoice_table|
  -- |1.10      02-Jan-2018 Naveen Patha       Modified for RC in xx_release_hold       |
  -- |1.11      02-Jan-2018 Naveen Patha       Modified chargeback in xx_upd_reason_code|
  -- |1.12      03-Jan-2018 Paddy Sanjeevi     Added xx_purge_errors                    |
  -- |1.13      04-Jan-2018 Paddy Sanjeevi     Added notification for stuck in POI      |
  -- |1.14      05-Jan-2018 Naveen Patha       Modified xx_get_total for price variance |
  -- |1.14      10-Jan-2018 Naveen Patha       Added xx_apps_initialize                 |
  -- |1.15      11-Jan-2018 Paddy Sanjeevi     Fixed chargeback invoice date            |
  -- |1.16      16-Jan-2018 Paddy Sanjeevi     Fixed the chargeback rounding issue      |
  -- |1.17      23-Jan-2018 Naveen Patha       Update ap_invoices_all with DM number    |
  -- |1.18      25-Jan-2018 Naveen Patha       Modified gn_userid with p_user_id        |
  -- |1.19      01-Feb-2018 Naveen Patha       Added org_id parameter                   |
  -- |1.20      07-Feb-2018 Naveen Patha       Fixed get_unbiled_qty                    |
  -- |2.0       28-Feb-2018 Paddy Sanjeevi     Changed answer code PO -> P O            |
  -- |2.1       12-Apr-2018 Paddy Sanjeevi     Removed the hard code user_id            |
  -- |2.2       16-Apr-2018 Paddy Sanjeevi     Modified to purge 45 days old records    |
  -- |2.3       06-JUN-2018 Vivek Kumar       Defect#45000 Commented Accounting_date and|
  -- |                                        gl_date from AP_INVOICES_INTERFACE Table  |
  -- |                                         so that gl_date and accounting date will |
  -- |                                         be populated as null value.              |
  -- |2.4       18-Jul-2018 Chandra            Modified the code for                    |
  -- |                                         for defect #NAIT-41954                   |
  -- |2.5       17-Jan-2018 Atul Khard	      NAIT-53015 Added Hold Lookup Code 'OD Max |
  -- |                                        Price' so the line amount will be         |
  -- |                                        calculated only once.                     |
  -- +==================================================================================+
AS
  gn_org_id              NUMBER;
  gc_po_type            VARCHAR2(10);
  gn_user_id             NUMBER:=FND_GLOBAL.user_id;
  gn_source              VARCHAR2(100);
  gn_created_by          NUMBER;
  gn_invoice_num         VARCHAR2(50);
  gn_invoice_id             NUMBER;
  gn_po_hdr_id            NUMBER;
  gn_grp_seq             NUMBER;
  gn_final_process         VARCHAR2(10);
  gn_status             VARCHAR2(10);
  gc_only_release         VARCHAR2(1);
  gc_cancel                  VARCHAR2(1);
  gn_vendor_id             NUMBER;
  gn_vend_site_id         NUMBER;
  gc_newinv_status        VARCHAR2(1);
  gc_newchbk_status        VARCHAR2(1);
  gn_new_inv_id            NUMBER;
  gn_chbk_invoice_id    NUMBER;

-- +======================================================================+
-- | Procedure to log messages                                            |
-- | Will log to dbms_output if request id is not set,                    |
-- | else will log to concurrent program log file.                        |
-- +======================================================================+
PROCEDURE print_debug_msg (p_message   IN VARCHAR2)
IS
   lc_message   VARCHAR2 (4000) := NULL;
BEGIN
  lc_Message := P_Message;
  fnd_file.put_line(fnd_file.log, lc_Message);
   IF (   fnd_global.conc_request_id = 0
        OR fnd_global.conc_request_id = -1)
   THEN
       dbms_output.put_line (lc_message);
   END IF;
EXCEPTION
   WHEN others THEN
       NULL;
END print_debug_msg;
-- +======================================================================+
-- | Name        :  xx_apps_initialize                                    |
-- | Description :  To update apps initialize                             |
-- |                                                                      |
-- | Parameters  :  p_user_id,p_resp_id,p_resp_app_id                     |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_apps_initialize(p_user_id NUMBER,
                             p_resp_id NUMBER,
                             p_resp_app_id NUMBER)
IS
BEGIN
FND_GLOBAL.apps_initialize( p_user_id, p_resp_id, p_resp_app_id );

EXCEPTION 
  WHEN others THEN
       NULL;
END;

-- +======================================================================+
-- | Name        :  get_answer_code                                       |
-- | Description :  To get the answer code from xx_ap_cost_variance       |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, po_po_line_id                           |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_answer_code(p_invoice_id IN NUMBER,p_po_line_id IN NUMBER)
RETURN VARCHAR2
IS
v_anwswer_code VARCHAR2(10);
BEGIN
  SELECT answer_code
    INTO v_anwswer_code
    FROM xx_ap_cost_variance
   WHERE invoice_id=p_invoice_id
     AND po_line_id=p_po_line_id;
  RETURN(v_anwswer_code);
EXCEPTION
  WHEN others THEN 
    v_anwswer_code:=NULL;
    RETURN(v_anwswer_code);
END get_answer_code;

-- +======================================================================+
-- | Name        :  xx_update_answer                                      |
-- | Description :  To update answer code in custom holds table           |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+

PROCEDURE xx_update_answer(p_invoice_id IN NUMBER)
IS

CURSOR C1
IS
SELECT po_line_id
  FROM xx_ap_chbk_action_holds
 WHERE invoice_id=p_invoice_id
   AND answer_code IS NULL
   AND hold_lookup_code='PRICE';

lc_ans_code VARCHAR2(10) ;
BEGIN
  FOR cur IN C1 LOOP
    lc_ans_code := get_answer_code(p_invoice_id,cur.po_line_id);
    UPDATE xx_ap_chbk_action_holds
       SET answer_code=lc_ans_code
     WHERE invoice_id=p_invoice_id
       AND po_line_id=cur.po_line_id;
  END LOOP;
  COMMIT;
Exception
  WHEN others THEN
    print_debug_msg('Error in Updating Answer code in holds table :'||SUBSTR(SQLERRM,1,100));
END xx_update_answer;

-- +==========================================================================+
-- | Name        :  xx_purge_errors                                           |
-- | Description :  To purge processed invoiced errors from custom table      |
-- |                                                                          |
-- | Parameters  :  N/A                                                       |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+

PROCEDURE xx_purge_errors(x_errbuf         OUT NOCOPY  VARCHAR2 ,
                          x_retcode         OUT NOCOPY VARCHAR2 
                         )
IS
CURSOR C1
IS
SELECT distinct invoice_id
  FROM XX_AP_TR_MATCH_EXCEPTIONS;
  
CURSOR C2(p_invoice_id NUMBER)  
IS
SELECT ai.invoice_id, 
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) inv_status
                                                        
  FROM ap_invoices_all ai
 WHERE invoice_id=p_invoice_id;
 
CURSOR C3
IS
SELECT invoice_id,invoice_num
  FROM xx_ap_chbk_action_hdr
 WHERE process_flag<>'N'
   AND creation_date<SYSDATE-45;
   
CURSOR C4(p_invoice_no VARCHAR2,p_vend_id NUMBER,p_vend_site_id NUMBER)  
IS
SELECT ai.invoice_id, 
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) inv_status
                                                        
  FROM ap_invoices_all ai
 WHERE invoice_num=p_invoice_no 
   AND vendor_id+0=p_vend_id
   AND vendor_site_id+0=p_vend_site_id;
   
i NUMBER:=0; 
ln_vend_id NUMBER;
ln_vend_site_id NUMBER;
BEGIN
  FOR cur IN C1 LOOP
    i:=i+1;
    IF i>1000 THEN
       COMMIT;
       i:=0;
    END IF;
    FOR cr IN C2(cur.invoice_id) LOOP
    
      IF cr.inv_status IN ('APPROVED','CANCELLED') THEN
      
         DELETE 
           FROM xx_ap_tr_match_exceptions
          WHERE invoice_id=cr.invoice_id;
      
      END IF;
      
    END LOOP;
   
  END LOOP;
  COMMIT;
  
  FOR cur IN C3 LOOP
    i:=i+1;
    IF i>1000 THEN
       COMMIT;
       i:=0;
    END IF;
    ln_vend_id:=NULL;
    ln_vend_site_id:=NULL;    
    
    BEGIN
      SELECT vendor_id,
             vendor_site_id
        INTO ln_vend_id,
             ln_vend_site_id
        FROM ap_invoices_all
       WHERE invoice_id=cur.invoice_id;
    
       FOR cr IN C4(cur.invoice_num,ln_vend_id,ln_vend_site_id) LOOP
    
         IF cr.inv_status='APPROVED' THEN
         
           DELETE 
             FROM xx_ap_chbk_action_holds
            WHERE invoice_id=cr.invoice_id;

           DELETE 
             FROM xx_ap_chbk_action_dtl
            WHERE invoice_id=cr.invoice_id;

           DELETE 
             FROM xx_ap_chbk_action_hdr
            WHERE invoice_id=cr.invoice_id;

             DELETE 
             FROM xx_ap_uiaction_errors
            WHERE invoice_id=cr.invoice_id;

         END IF;
      
       END LOOP;
    EXCEPTION
      WHEN others THEN
      ln_vend_id:=NULL;
      ln_vend_site_id:=NULL;
    END;
   
  END LOOP;
  UPDATE xx_ap_chbk_action_hdr
     SET request_id=null
   WHERE process_flag='E'
     AND creation_date<SYSDATE;
  COMMIT;
EXCEPTION
  WHEN others THEN
    print_debug_msg('Error in purging from custom table :'||SUBSTR(SQLERRM,1,100));  
END xx_purge_errors;  


-- +==========================================================================+
-- | Name        :  xx_no_chbk_no_split                                       |
-- | Description :  To indentify if multiple invoices exists for the po line  |
-- |                                                                          |
-- | Parameters  :  p_invoice_id,p_po_line_id                                 |
-- |                                                                          |
-- | Returns     :  Y/N                                                       |
-- |                                                                          |
-- +==========================================================================+
FUNCTION xx_no_chbk_no_split(p_invoice_id NUMBER) RETURN VARCHAR2 
IS
CURSOR C1(p_invoice_id NUMBER) IS
SELECT line_number
   FROM xx_ap_chbk_action_dtl
WHERE invoice_id=p_invoice_id
   AND hold_exists_flag='Y';

CURSOR C2(p_invoice_id NUMBER,p_line_number NUMBER) IS
SELECT line_number
       FROM XX_AP_CHBK_ACTION_HOLDS
      WHERE invoice_id=p_invoice_id
        AND line_number=p_line_number
        AND hold_lookup_code like 'QTY%'
        AND nvl(chargeback,'X')<>'Y'
        AND NOT EXISTS (SELECT 1
                          FROM xx_ap_chbk_action_holds
                         WHERE invoice_id=p_invoice_id
                           AND line_number=p_line_number
                           AND hold_lookup_code is NULL
                           AND reason_code IS NOT NULL)
        AND NOT EXISTS (SELECT 1
                           FROM xx_ap_chbk_action_holds
                         WHERE nvl(uom,'X')<>nvl(org_uom,'X')
                           AND invoice_id=p_invoice_id
                           AND line_number=p_line_number);     
                           
v_result VARCHAR2(1) :='N';
BEGIN
   FOR cur1 IN C1(p_invoice_id) LOOP
       FOR cur2 IN C2(p_invoice_id,cur1.line_number) LOOP
           v_result:='Y';
       END LOOP;
   END LOOP;    

   RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN('X');
END xx_no_chbk_no_split;


-- +==========================================================================+
-- | Name        :  xx_check_multi                                            |
-- | Description :  To indentify if multiple invoices exists for the po line  |
-- |                                                                          |
-- | Parameters  :  p_invoice_id,p_po_line_id                                 |
-- |                                                                          |
-- | Returns     :  Y/N                                                       |
-- |                                                                          |
-- +==========================================================================+

FUNCTION xx_check_multi_inv(p_invoice_id NUMBER,p_po_line_id IN NUMBER,p_po_header_id IN NUMBER) RETURN VARCHAR2
IS
v_multi VARCHAR2(1):='N';
v_cnt   NUMBER;
CURSOR C1
IS
SELECT DISTINCT po_line_id,po_header_id  
  FROM ap_invoice_lines_all l
 WHERE l.invoice_id=p_invoice_id
   AND l.line_type_lookup_code='ITEM'
   AND l.po_line_id=p_po_line_id
   AND l.discarded_flag='N'
UNION
SELECT p_po_line_id po_line_id,
       p_po_header_id po_header_id
  FROM DUAL;

CURSOR C2(p_po_line_id NUMBER,p_po_header_id NUMBER)   
IS
SELECT DISTINCT l.invoice_id,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) inv_status
 FROM ap_invoices_all ai,
      ap_invoice_lines_all l
WHERE l.po_line_id=p_po_line_id
  AND l.po_header_id=p_po_header_id
  AND l.invoice_id<>p_invoice_id
  AND l.discarded_flag='N'  
  AND ai.invoice_id=l.invoice_id
  AND ai.invoice_num NOT LIKE '%ODDBUIA%';
BEGIN
  FOR cur IN C1 LOOP
    FOR c IN C2(cur.po_line_id,cur.po_header_id) LOOP
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
-- +==========================================================================+
-- | Name        :  get_consumed_rcvqty                                       |
-- | Description :  To get consumed received qty                              |
-- |                                                                          |
-- | Parameters  :  p_invoice_id, p_item_id, p_po_header_id                   |
-- |                                                                          |
-- | Returns     :                                                            |
-- |                                                                          |
-- +==========================================================================+

FUNCTION get_consumed_rcvqty(p_po_header_id IN NUMBER, p_item_id IN NUMBER, p_invoice_id IN NUMBER,p_po_line_id IN NUMBER)
RETURN NUMBER
IS

CURSOR C1 IS
SELECT a.invoice_num,
       a.invoice_id,
       b.quantity_invoiced,
       b.po_line_location_id,
       b.po_line_id,
       b.inventory_item_id,
       b.po_header_id
  FROM ap_invoices_all a,
       ap_invoice_lines_all b
 WHERE b.po_header_id = p_po_header_id
   AND b.inventory_item_id = p_item_id
   AND b.po_line_id=p_po_line_id
   AND b.invoice_id<>p_invoice_id
   AND a.invoice_id=b.invoice_id
   AND a.invoice_num NOT LIKE '%ODDBUIA%'
   AND 'APPROVED'=            AP_INVOICES_PKG.GET_APPROVAL_STATUS(a.INVOICE_ID,
                                                         a.INVOICE_AMOUNT,
                                                         a.PAYMENT_STATUS_FLAG,
                                                         a.INVOICE_TYPE_LOOKUP_CODE
                                                        )
 ORDER by a.invoice_id;
 
ln_tot_cons_rcv_qty NUMBER:=0;                                                         
ln_consumed_qty        NUMBER:=0;
ln_qty_rec            NUMBER;

BEGIN
  FOR cur IN C1 LOOP
    ln_qty_rec:=0;
    SELECT COUNT(1)
      INTO ln_qty_rec
      FROM ap_holds_all
     WHERE invoice_id=cur.invoice_id
       AND line_location_id=cur.po_line_location_id
       AND hold_lookup_code='QTY REC';
      
    IF ln_qty_rec=0 THEN
       ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
    ELSE
         SELECT NVL(SUM(b.quantity_received),0)
         INTO ln_consumed_qty
           FROM ap_holds_all h,
               rcv_shipment_lines b
        WHERE b.po_line_location_id=cur.po_line_location_id
          AND b.po_line_id=cur.po_line_id
          AND h.invoice_id=cur.invoice_id
          AND h.line_location_id=b.po_line_location_id
          AND h.hold_lookup_code='QTY REC'
          AND b.creation_date<h.last_update_date;
       IF cur.quantity_invoiced>=ln_consumed_qty THEN
          ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+ln_consumed_qty;
       ELSE
          ln_tot_cons_rcv_qty:=ln_tot_cons_rcv_qty+cur.quantity_invoiced;
       END IF;
    END IF;
  END LOOP;    
  RETURN(ln_tot_cons_rcv_qty);
  --dbms_output.put_line('Consumed RCV Qty :'||to_char(ln_tot_cons_rcv_qty));
EXCEPTION
  WHEN others THEN
    ln_tot_cons_rcv_qty:=0;
    RETURN(ln_tot_cons_rcv_qty);
END get_consumed_rcvqty;

-- +======================================================================+
-- | Name        :  get_unbilled_qty                                      |
-- | Description :  Return unbilled QTY                                   |
-- |                                                                      |
-- | Parameters  :  p_po_header_id, p_po_line_id,p_item_id                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_unbilled_qty(p_po_header_id IN NUMBER,p_po_line_id IN NUMBER, p_item_id IN NUMBER, p_invoice_id IN NUMBER)
RETURN NUMBER
IS
   v_rct_flag                     VARCHAR2(1);
   ln_quantity_received            NUMBER;
   ln_tot_quantity_billed        NUMBER;   
   ln_inv_quantity_billed        NUMBER;
   ln_oth_inv_qty_billed         NUMBER;
   ln_po_ord_qty                 NUMBER;
   ln_unbilled_qty                NUMBER;
   v_multi                        VARCHAR2(1):='N';
   ln_unaprvd_qty                 NUMBER;
   ln_aprvd_qty                     NUMBER;
   ln_cons_rcv_qty                NUMBER;
   
BEGIN
  v_multi:=xx_check_multi_inv(p_invoice_id,p_po_line_id,p_po_header_id);
  BEGIN
    SELECT receipt_required_flag
      INTO v_rct_flag
      FROM po_line_locations_all
     WHERE po_line_id=p_po_line_id
       AND ROWNUM<2;
  EXCEPTION
    WHEN others THEN
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
     AND l.item_id = p_item_id
     AND l.po_line_id=p_po_line_id
     AND pol.po_line_id = l.po_line_id;     
     
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_inv_quantity_billed
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
     AND po_line_id=p_po_line_id
     AND l.invoice_id=p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_holds_all
                  WHERE invoice_id = l.invoice_id
                    AND line_location_id = l.po_line_location_id);     
  
  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_unaprvd_qty
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
     AND po_line_id=p_po_line_id
     AND l.invoice_id<>p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_invoices_all ai
                  WHERE ai.invoice_id = l.invoice_id
                    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
                    AND 'APPROVED'<>            AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) 
                );                

  SELECT NVL(SUM(l.QUANTITY_INVOICED),0)        
    INTO ln_aprvd_qty
    FROM ap_invoice_lines_all l
   WHERE po_header_id = p_po_header_id
     AND inventory_item_id = p_item_id
     AND po_line_id=p_po_line_id
     AND l.invoice_id<>p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM ap_invoices_all ai
                  WHERE ai.invoice_id = l.invoice_id
                    AND ai.invoice_num NOT LIKE '%ODDBUIA%'
                    AND 'APPROVED'=            AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.INVOICE_ID,
                                                         ai.INVOICE_AMOUNT,
                                                         ai.PAYMENT_STATUS_FLAG,
                                                         ai.INVOICE_TYPE_LOOKUP_CODE
                                                        ) 
                );                 
  IF v_rct_flag='Y' THEN      -- Three Way
     IF v_multi='N' THEN
        ln_unbilled_qty:=ln_quantity_received;
     ELSIF v_multi='Y' THEN
        IF ln_aprvd_qty=0 THEN
           ln_unbilled_qty:=ln_quantity_received ;
        END IF;
        IF ln_aprvd_qty>0 THEN
           ln_cons_rcv_qty:=get_consumed_rcvqty(p_po_header_id,p_item_id,p_invoice_id,p_po_line_id);
           ln_unbilled_qty:=ln_quantity_received-ln_cons_rcv_qty;
        END IF;
     END IF;      
  END IF;
  IF v_rct_flag='N' THEN     -- Two Way
     IF v_multi='N' THEN
        ln_unbilled_qty:=ln_po_ord_qty;
     ELSIF v_multi='Y' THEN
        IF ln_aprvd_qty=0 THEN
           IF (ln_tot_quantity_billed-ln_po_ord_qty < 0) OR (ln_tot_quantity_billed-ln_po_ord_qty > 0) OR  (ln_tot_quantity_billed-ln_po_ord_qty = 0) THEN  
               ln_unbilled_qty:=ln_po_ord_qty;
           END IF;
        END IF;
        IF ln_aprvd_qty>0 THEN
            IF (ln_aprvd_qty-ln_po_ord_qty) >= 0 THEN
               ln_unbilled_qty:=0;
            END IF;
            IF (ln_aprvd_qty-ln_po_ord_qty) < 0 THEN
               ln_unbilled_qty:=ln_po_ord_qty-ln_aprvd_qty;
            END IF;
         END IF;
     END IF; 
  END IF;
  IF ln_unbilled_qty<0 THEN 
     ln_unbilled_qty:=0;
  END IF;
  RETURN(ln_unbilled_qty);
EXCEPTION
  WHEN others THEN
    RETURN(NULL);
END get_unbilled_qty;


-- +==========================================================================+
-- | Name        :  get_freight_chargeback                                    |
-- | Description :  To check chargeback exists for the freight line           |
-- |                                                                          |
-- | Parameters  :  p_invoice_id                                              |
-- |                                                                          |
-- | Returns     :                                                            |
-- |                                                                          |
-- +==========================================================================+

FUNCTION get_freight_chargeback(p_vendor_site_id IN NUMBER,p_org_id IN NUMBER)
RETURN VARCHAR2
IS

CURSOR get_max_freight_amt
IS
SELECT max_freight_amt 
  FROM xx_ap_custom_tolerances
 WHERE supplier_site_id = p_vendor_site_id
   AND org_id = p_org_id;

ln_max_freight_amt          NUMBER:=NULL;
lc_chargeback                VARCHAR2(1):='N';

BEGIN
  OPEN get_max_freight_amt;
  FETCH get_max_freight_amt INTO ln_max_freight_amt;
  CLOSE get_max_freight_amt;
  IF ln_max_freight_amt IS NOT NULL AND ln_max_freight_amt=0 THEN           
     lc_chargeback:='Y';
  END IF;
  RETURN lc_chargeback;
EXCEPTION 
  WHEN OTHERS THEN
    RETURN(lc_chargeback);
END get_freight_chargeback;

-- +==========================================================================+
-- | Name        :  xx_check_freight                                          |
-- | Description :  To update chbk_create_flag in custom table if chbk exists |
-- |                                                                          |
-- | Parameters  :  p_invoice_id                                              |
-- |                                                                          |
-- | Returns     :                                                            |
-- |                                                                          |
-- +==========================================================================+

PROCEDURE xx_check_freight(p_invoice_id IN NUMBER) IS
CURSOR get_max_freight_amt
    IS
       SELECT max_freight_amt 
         FROM xx_ap_custom_tolerances 
        WHERE supplier_id = gn_vendor_id 
          AND supplier_site_id = gn_vend_site_id 
          AND org_id = gn_org_id;
    CURSOR inv_freight_amt_cur
                IS      
       SELECT SUM(l.line_amount)
         FROM xx_ap_chbk_action_dtl l
        WHERE l.invoice_id = p_invoice_id
          AND l.line_type_lookup_code='FREIGHT';
    ln_max_freight_amt          NUMBER;
    ln_inv_freight_amt                        NUMBER;
BEGIN
    SELECT hdr.org_id,
           ai.vendor_id,
           ai.vendor_site_id
      INTO gn_org_id,
           gn_vendor_id,
           gn_vend_site_id
      FROM ap_invoices_all ai,
           xx_ap_chbk_action_hdr hdr
     WHERE hdr.invoice_id=p_invoice_id
       AND ai.invoice_id=hdr.invoice_id;
      ln_max_freight_amt := NULL;
      OPEN get_max_freight_amt;
      FETCH get_max_freight_amt INTO ln_max_freight_amt;
      CLOSE get_max_freight_amt;
      fnd_file.put_line(fnd_file.log,'ln_max_freight_amt'||ln_max_freight_amt );      
      IF ln_max_freight_amt IS NOT NULL AND ln_max_freight_amt=0 
        THEN           
          ln_inv_freight_amt := NULL;   
            OPEN inv_freight_amt_cur;
            FETCH inv_freight_amt_cur INTO ln_inv_freight_amt;
            CLOSE inv_freight_amt_cur;
        fnd_file.put_line(fnd_file.log,'ln_inv_freight_amt'||ln_inv_freight_amt );  
         IF ln_inv_freight_amt>0 THEN
         UPDATE xx_ap_chbk_action_hdr
         set chbk_create_flag='Y'
         WHERE invoice_id=p_invoice_id; 
         fnd_file.put_line(fnd_file.log,'freight updated:'||SQL%ROWCOUNT );  
         COMMIT;
         END IF;
      END IF;
EXCEPTION WHEN OTHERS THEN
print_debug_msg('ERROR in xx_check_freight'||SQLERRM);
END xx_check_freight; 
-- +======================================================================+
-- | Name        :  xx_release_template_holds                             |
-- | Description :  To release qty rec/ qty ord holds                     |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_release_template_holds(
                                    x_errbuf         OUT NOCOPY  VARCHAR2 ,
                                    x_retcode         OUT NOCOPY VARCHAR2 ,
                                    p_source         IN  VARCHAR2,
                                                                        p_invoice_id IN NUMBER
                                   )
IS
CURSOR C1(p_org_id NUMBER)
IS                        
SELECT d.invoice_id,
       d.line_location_id,
       d.hold_lookup_code,
       d.hold_id,
       d.held_by,
       d.status_flag,
       TRUNC(d.hold_date) hold_date
  FROM ap_invoices_all ai,
       ap_holds_all d                
 WHERE d.release_lookup_code is NULL
   AND d.hold_lookup_code='QTY REC'
   AND ai.invoice_id=d.invoice_id
   AND ai.org_id+0=p_org_id
   AND ai.invoice_id=NVL(p_invoice_id,ai.invoice_id)
   AND ai.source=NVL(p_source,ai.source)
   AND EXISTS ( SELECT 'x'
                  FROM po_line_locations_all 
                 WHERE line_location_id=d.line_location_id
                   AND DECODE(receipt_required_flag,'Y','3-Way','N','2-Way')='2-Way'
                   AND po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)
              )   
ORDER BY 2 asc;               
CURSOR C2(p_org_id NUMBER)
IS                        
SELECT d.invoice_id,
       d.line_location_id,
       d.hold_lookup_code,
       d.hold_id,
       d.held_by,
       d.status_flag,
       TRUNC(d.hold_date) hold_date
  FROM ap_invoices_all ai,
       ap_holds_all d                
 WHERE d.release_lookup_code is NULL
   AND d.hold_lookup_code='QTY ORD'
   AND ai.invoice_id=d.invoice_id
   AND ai.org_id+0=p_org_id
   AND ai.invoice_id=NVL(p_invoice_id,ai.invoice_id)   
   AND ai.source=NVL(p_source,ai.source)
   AND EXISTS ( SELECT 'x'
                  FROM po_line_locations_all 
                 WHERE line_location_id=d.line_location_id
                   AND DECODE(receipt_required_flag,'Y','3-Way','N','2-Way')='3-Way'
                   AND po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)
              )   
ORDER BY 2 asc;   
ln_org_id           NUMBER;             
BEGIN
  ln_org_id:=FND_PROFILE.VALUE('ORG_ID');
  
  FOR CUR IN C1(ln_org_id) LOOP
      UPDATE ap_holds_all
         SET release_lookup_code = 'HOLDS QUICK RELEASED',
             release_reason = 'HOLD QUICK RELEASE REASON',
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id,
             status_flag='R'
       WHERE invoice_id = cur.invoice_id
         AND line_location_id=cur.line_location_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = cur.hold_lookup_code
         AND NVL(status_flag,'X')<>'R';                         
  END LOOP;
  COMMIT;
  FOR CUR IN C2(ln_org_id) LOOP

      UPDATE ap_holds_all
         SET release_lookup_code = 'HOLDS QUICK RELEASED',
             release_reason = 'HOLD QUICK RELEASE REASON',
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id,
             status_flag='R'
       WHERE invoice_id = cur.invoice_id
         AND line_location_id=cur.line_location_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = cur.hold_lookup_code
         AND NVL(status_flag,'X')<>'R';                         
  END LOOP;
  COMMIT;
  
EXCEPTION
  WHEN others THEN
    print_debug_msg('Error in Cancelling Debit Memo');
END xx_release_template_holds; 
-- +======================================================================+
-- | Name        :  xx_upd_invoice_flags                                  |
-- | Description :  To update flags based on user action                  |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_upd_invoice_flags(p_invoice_id IN varchar2)
IS
ln_inv_cancel                 NUMBER:=0;
v_chbk_dtl_count             NUMBER:=0;
v_chbk_hold_count             NUMBER:=0;
v_rel_dtl_count             NUMBER:=0;
v_rel_hold_count             NUMBER:=0;
v_org_inv_line_count        NUMBER:=0;
v_xx_inv_line_count         NUMBER:=0;
BEGIN
update xx_ap_chbk_Action_hdr 
set rel_hold_flag='N',
    chbk_create_flag='N',
    cancel_invoice='N'
where invoice_id=p_invoice_id;
  -- create line at hold region
  SELECT count(1) 
    INTO ln_inv_cancel
    FROM xx_ap_chbk_action_holds a
   WHERE a.invoice_id=p_invoice_id
        AND a.hold_lookup_code IS NULL;
  IF ln_inv_cancel<>0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET cancel_invoice='Y'
      WHERE invoice_id=p_invoice_id;
  END IF;
  -- update line at line region
  UPDATE xx_ap_chbk_action_hdr a
     SET a.cancel_invoice='Y'
   WHERE a.INVOICE_ID=p_invoice_id
     AND EXISTS (SELECT 'x'
                      FROM xx_ap_chbk_action_dtl
                  WHERE invoice_id=a.invoice_id  
                    AND unmatch_po_flag='N'                  
                    AND (quantity_invoiced<>org_invoice_qty
                    OR   invoice_price<>org_invoice_price
                    OR   NVL(uom,'X')<>NVL(org_uom,'X')
                         )
                 );
   -- update line at hold region
   UPDATE xx_ap_chbk_action_hdr a
     SET a.cancel_invoice='Y'
   WHERE a.INVOICE_ID=p_invoice_id
     AND EXISTS (SELECT 'x'
                      FROM xx_ap_chbk_action_holds
                  WHERE invoice_id=a.invoice_id    
                    AND hold_lookup_code IS NOT NULL
                    AND (unmatched_qty<>org_invoice_qty
                    OR   unit_price<>org_invoice_price
                    OR   NVL(uom,'X')<>NVL(org_uom,'X')
                        )                    
                 );
    -- create line at line region
    UPDATE xx_ap_chbk_action_hdr a
     SET a.cancel_invoice='Y'
   WHERE a.INVOICE_ID=p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_dtl
                  WHERE invoice_id=a.invoice_id    
                    AND new_line_flag='Y'                    
                 );
  -- load unmatch PO line
  UPDATE xx_ap_chbk_action_hdr a
     SET a.cancel_invoice='Y'
   WHERE a.INVOICE_ID=p_invoice_id
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_dtl
                  WHERE invoice_id=a.invoice_id    
                    AND unmatch_po_flag='Y'
                    AND NVL(quantity_invoiced,0)<>0
                 );
  -- delete line at line region
  SELECT COUNT(1)
    INTO v_org_inv_line_count
    FROM AP_INVOICE_LINES_ALL
   WHERE invoice_id=p_invoice_id
     AND line_type_lookup_code<>'TAX';
  SELECT COUNT(1)
    INTO v_xx_inv_line_count
    FROM XX_AP_CHBK_ACTION_DTL
   WHERE invoice_id=p_invoice_id
     AND unmatch_po_flag='N'
     AND NVL(new_line_flag,'N')='N';
  IF v_org_inv_line_count<>v_xx_inv_line_count THEN
     UPDATE xx_ap_chbk_action_hdr a
       SET a.cancel_invoice='Y'
     WHERE a.INVOICE_ID=p_invoice_id;
  END IF;
  COMMIT;
  -- chargeback flag
  SELECT COUNT(1)
    INTO v_chbk_hold_count
    FROM xx_ap_chbk_action_holds
   WHERE invoice_id=p_invoice_id
     AND chargeback='Y';
  IF v_chbk_hold_count >0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET chbk_create_flag='Y'
      WHERE invoice_id=p_invoice_id;
     COMMIT;
  END IF;
  v_chbk_hold_count:=0;
  SELECT COUNT(1)
    INTO v_chbk_hold_count
    FROM xx_ap_chbk_action_dtl
   WHERE invoice_id=p_invoice_id
     AND chargeback='Y';
  IF v_chbk_hold_count >0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET chbk_create_flag='Y'
      WHERE invoice_id=p_invoice_id;
     COMMIT;
  END IF;
  -- release hold flag
  SELECT COUNT(1)
    INTO v_rel_hold_count
    FROM xx_ap_chbk_action_holds
   WHERE invoice_id=p_invoice_id
     AND release_hold='Y';
  IF v_rel_hold_count>0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET rel_hold_Flag='Y'
      WHERE invoice_id=p_invoice_id;
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END xx_upd_invoice_flags;
-- +======================================================================+
-- | Name        :  xx_upd_reason_code                                    |
-- | Description :  To update reason code for custom holds                |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_upd_reason_code(p_invoice_id IN NUMBER,p_inv_total IN NUMBER)
IS
lc_reason_code         VARCHAR2(30);
ln_line_total         NUMBER:=0;
ln_rc_total            NUMBER:=0;
ln_inv_total        NUMBER:=0;
BEGIN

  BEGIN
    SELECT DECODE(DECODE(SUBSTR(attribute_category,1,1),'D','Y','N'),'Y','FS','FR') 
      INTO lc_reason_code
      FROM po_headers_all 
      WHERE po_header_id=(SELECT nvl(po_header_id,quick_po_header_id) 
                          FROM ap_invoices_all  
                           WHERE invoice_id=p_invoice_id);
  EXCEPTION
    WHEN others THEN
      lc_reason_code:='FR';
      dbms_output.put_line(sqlerrm);
  END;      
  UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y'--,
         --reason_code=DECODE(hold_lookup_code,'OD Favorable','PD','OD Max Price','PD','OD Max Freight','OD_VA_APPRVD_HDR')
   WHERE invoice_id=p_invoice_id  
     AND hold_lookup_code IN ('OD Favorable','OD Max Price','OD Line Variance','OD Max Freight');
   xx_get_total(p_invoice_id,ln_line_total,ln_rc_total); 
   IF p_inv_total=ln_line_total+ln_rc_total THEN 
      UPDATE xx_ap_chbk_action_holds
         SET release_hold='Y',
             reason_code= 'OD_VA_APPRVD_HDR'
       WHERE invoice_id=p_invoice_id
         AND hold_lookup_code IN ('OD Line Variance','LINE VARIANCE');
   END IF;
   UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y',
         chargeback='Y'
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code IS NOT NULL
     AND line_number IS NOT NULL
     AND NVL(release_hold,'X')<>'Y';
   UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y'         
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code IS NOT NULL
     AND line_number IS NULL
     AND NVL(release_hold,'X')<>'Y';
   COMMIT;
   xx_upd_invoice_flags(p_invoice_id);
EXCEPTION
  WHEN others THEN
     dbms_output.put_line('whenothers'||DBMS_UTILITY.format_error_backtrace);
END xx_upd_reason_code;
-- +======================================================================+
-- | Name        :  xx_get_total                                          |
-- | Description :  To get line total and reason code total               |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Out Parameters : p_line_total, p_rc_total                            |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_get_total(p_invoice_id IN NUMBER,
                                 p_line_total    OUT NUMBER,
                                 p_rc_total    OUT NUMBER
                            )
IS
tot_nohld_nrc NUMBER:=0;
tot_nohld_rc NUMBER:=0;
tot_hld_nrc NUMBER:=0;
tot_hld_rc NUMBER:=0;
ln_nohld_nrc     NUMBER:=0;
ln_nohld_other_nrc    NUMBER:=0;
ln_nohld_rc     NUMBER:=0;
ln_hld_rc         NUMBER:=0;
ln_hld_nrc         NUMBER:=0;
ln_amt            NUMBER:=0;
ln_hold_cnt        NUMBER;
ln_qty_hold        NUMBER:=0;
ln_po_total           NUMBER:=0;
ln_price_split        NUMBER;
ln_qty_split        NUMBER;
ln_price_exists     NUMBER;
CURSOR C1 
IS
SELECT DISTINCT line_number
  FROM xx_ap_chbk_action_holds
 WHERE invoice_id=p_invoice_id
 ORDER by 1; 
CURSOR C3_Lines1(p_invoice_id NUMBER,p_Line_Number NUMBER)
IS
SELECT a.hold_lookup_code,
       a.unmatched_qty,
       a.unit_price
  FROM xx_ap_chbk_action_holds a         
 WHERE a.invoice_id=p_invoice_id
   AND a.Line_Number=p_Line_Number
   AND a.hold_lookup_code IS NOT NULL      
   AND NVL(a.unmatched_qty,0) > 0
   AND a.hold_lookup_code IN ('QTY ORD','QTY REC','OD Favorable') --NOT IN ('MAX SHIP AMOUNT','PO NOT APPROVED','PRICE')
   AND NOT EXISTS ( SELECT 'x'
                      FROM xx_ap_chbk_action_holds
                     WHERE invoice_id=a.invoice_id  
                       AND line_number=a.line_number
                       AND hold_lookup_code IS NULL
                  )
   AND NOT EXISTS ( SELECT 'x'
                      FROM xx_ap_chbk_action_holds
                     WHERE invoice_id=a.invoice_id
                       AND line_number=a.line_number
                       AND hold_lookup_code IN ('PRICE','OD Max Price'))  --Added 'OD Max Price' for NAIT-53015
ORDER BY a.hold_lookup_code desc;

CURSOR C3_price(p_invoice_id NUMBER,p_Line_Number NUMBER)
IS
SELECT a.hold_lookup_code,
       a.unmatched_qty,
       a.unit_price,
       NVL(a.chargeback,'N') chargeback,
       a.org_invoice_price,
       a.org_invoice_qty,
       a.po_price,
       a.uom,
       a.org_uom
  FROM xx_ap_chbk_action_holds a         
 WHERE a.invoice_id=p_invoice_id
   AND a.Line_Number=p_Line_Number
   AND a.hold_lookup_code in ('PRICE','OD Max Price')
   AND NOT EXISTS ( SELECT 'x'
                      FROM xx_ap_chbk_action_holds
                     WHERE invoice_id=a.invoice_id  
                       AND line_number=a.line_number
                       AND hold_lookup_code IS NULL
                  );

CURSOR qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
IS
SELECT a.unmatched_qty, 
       NVL(a.unit_price,a.org_invoice_price) unit_price,     
       NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
       a.reason_code       
  FROM xx_ap_chbk_action_holds a         
 WHERE a.invoice_id=p_invoice_id
   AND a.line_number=p_line_number
   AND NVL(a.unmatched_qty,0) > 0
   AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE'
   AND NOT EXISTS ( SELECT 'x'
                        FROM xx_ap_chbk_action_holds
                     WHERE invoice_id=a.invoice_id
                       AND line_number=a.line_number
                       AND hold_lookup_code='PRICE'
                  )
   AND EXISTS ( SELECT 'x'
                  FROM xx_ap_chbk_action_holds
                 WHERE invoice_id=a.invoice_id
                   AND line_number=a.line_number
                   AND hold_lookup_code IS NULL
                   AND NVL(unmatched_qty,0)>=0
              )                       
ORDER BY a.hold_lookup_code;    
CURSOR price_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
IS
SELECT nvl(SUM(NVL(a.unmatched_qty,0)),0) unmatched_qty, 
       nvl(SUM(NVL(a.unit_price,0)),0) unit_price
  FROM xx_ap_chbk_action_holds a        
 WHERE a.invoice_id=p_invoice_id
   AND a.line_number=p_line_number
   AND NVL(a.hold_lookup_code,'SPLIT')  NOT LIKE 'QTY%'
   AND a.unit_price IS NOT NULL
   AND EXISTS ( SELECT 'x'
                  FROM xx_ap_chbk_action_holds
                 WHERE invoice_id=a.invoice_id
                   AND line_number=a.line_number
                   AND hold_lookup_code IS NULL
                   AND NVL(unit_price,0)>0
              );        
CURSOR price_qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
IS
SELECT NVL(a.unmatched_qty,0) unmatched_qty, 
       NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
       reason_code
  FROM xx_ap_chbk_action_holds a         
 WHERE a.invoice_id=p_invoice_id
   AND a.line_number=p_line_number
   AND NVL(a.unmatched_qty,0) > 0
   AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE' 
 ORDER BY NVL(a.hold_lookup_code,'SPLIT');
CURSOR noprice_qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER) 
IS
SELECT NVL(a.unmatched_qty,0) unmatched_qty, 
       NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
       reason_code,
       NVL(unit_price,org_invoice_price) unit_price
  FROM xx_ap_chbk_action_holds a         
 WHERE a.invoice_id=p_invoice_id
   AND a.line_number=p_line_number
   AND NVL(a.unmatched_qty,0) > 0
   AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE' 
 ORDER BY NVL(a.hold_lookup_code,'SPLIT'); 
BEGIN
  SELECT NVL(SUM(ROUND((quantity_invoiced*invoice_price),2)),0)
    INTO ln_nohld_nrc
    FROM xx_ap_chbk_action_dtl
   WHERE invoice_id=p_invoice_id
     AND hold_exists_flag='N' 
     AND unmatch_po_flag='N'
     AND reason_code IS NULL
     AND line_type_lookup_code='ITEM';

  SELECT NVL(SUM(ROUND((quantity_invoiced*invoice_price),2)),0)
    INTO ln_po_total
    FROM xx_ap_chbk_action_dtl
   WHERE invoice_id=p_invoice_id
     AND hold_exists_flag='Y' 
     AND unmatch_po_flag='Y'
     AND quantity_invoiced > 0
     AND invoice_price > 0
     AND reason_code IS NULL;
     
     SELECT nvl(SUM(line_amount),0)
       INTO ln_nohld_other_nrc
       FROM xx_ap_chbk_action_dtl
      WHERE invoice_id=p_invoice_id
        AND ( ( hold_exists_flag='N' and unmatch_po_flag='N')
          OR
           ( hold_exists_flag='Y' and unmatch_po_flag='Y')
            )
        AND reason_code IS NULL
        AND line_type_lookup_code<>'ITEM';

     
  SELECT NVL(SUM(line_amount),0)
    INTO ln_nohld_rc
    FROM xx_ap_chbk_action_dtl
   WHERE invoice_id=p_invoice_id
     AND reason_code IS NOT NULL;
  FOR CUR IN C1 LOOP

    ln_hld_nrc:=0;
    ln_hld_rc:=0;
    FOR c3L1 IN  C3_Lines1(p_invoice_id,cur.line_number) LOOP
      ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(c3L1.unmatched_qty,0)*c3L1.unit_price),2);
        EXIT;
    END LOOP;

    FOR cr IN C3_price(p_invoice_id,cur.line_number) LOOP
    
       IF cr.chargeback='Y' THEN
          ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(cr.unmatched_qty,0)*cr.unit_price),2);
       ELSIF cr.chargeback='N' AND  (NVL(cr.uom,'x')=NVL(cr.org_uom,'x')) THEN
          ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(cr.unmatched_qty,0)*cr.po_price),2);
          ln_hld_rc:=NVL(ln_hld_rc,0)+ROUND((NVL(cr.unmatched_qty,0)* (cr.org_invoice_price-cr.po_price)),2);
       ELSIF cr.chargeback='N' AND (NVL(cr.uom,'x')<>NVL(cr.org_uom,'x')) THEN
          ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(cr.unmatched_qty,0)*cr.unit_price),2);
       END IF;
       

    END LOOP;
    FOR qs IN qty_split(p_invoice_id,cur.Line_Number) 
    LOOP             

      IF (qs.reason_code IS NULL AND qs.hold_lookup_code LIKE 'QTY%') OR  (qs.unmatched_qty>0 AND qs.hold_lookup_code LIKE 'SP%' AND qs.reason_code IS NULL ) THEN
          ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(qs.unmatched_qty,0)*qs.unit_price),2);
      END IF;
      IF qs.reason_code IS NOT NULL AND qs.hold_lookup_code LIKE 'SP%' THEN
         ln_hld_rc:=NVL(ln_hld_rc,0)+ROUND((NVL(qs.unmatched_qty,0)*qs.unit_price),2);
      END IF;
      END LOOP;
    FOR ps IN price_split(p_invoice_id,cur.Line_Number) 
    LOOP    
      SELECT COUNT(1)
        INTO ln_qty_hold
        FROM xx_ap_chbk_action_holds
       WHERE invoice_id=p_invoice_id
         AND line_number=cur.line_number
         AND hold_lookup_code IN ('QTY REC','QTY ORD');
         IF ln_qty_hold = 0 THEN
         ln_hld_nrc:=NVL(ln_hld_nrc,0)+ NVL(ps.unmatched_qty,0)*ps.unit_price;
      ELSE 
        FOR pqs IN price_qty_split(p_invoice_id,cur.Line_Number) 
        LOOP
          IF (pqs.reason_code IS NULL AND pqs.hold_lookup_code LIKE 'QTY%') OR  (pqs.unmatched_qty>0 AND pqs.hold_lookup_code LIKE 'SP%' AND pqs.reason_code IS NULL ) THEN
              ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(pqs.unmatched_qty,0)*ps.unit_price),2);
          END IF;
          IF pqs.reason_code IS NOT NULL AND pqs.hold_lookup_code LIKE 'SP%' THEN
             ln_hld_rc:=NVL(ln_hld_rc,0)+ROUND((NVL(pqs.unmatched_qty,0)*ps.unit_price),2);
           END IF;                
        END LOOP;
       END IF;  --IF ln_qty_hold = 0 THEN              
    END LOOP;
    SELECT COUNT(1)
      INTO ln_price_split
      FROM xx_ap_chbk_action_holds
     WHERE invoice_id=p_invoice_id
       AND line_number=cur.line_number
       AND unit_price>0
       AND hold_lookup_code IS NULL;
       
    SELECT COUNT(1)
      INTO ln_qty_split
      FROM xx_ap_chbk_action_holds
     WHERE invoice_id=p_invoice_id
       AND line_number=cur.line_number
       AND unmatched_qty>=0
       AND hold_lookup_code IS NULL;

    SELECT COUNT(1)
      INTO ln_price_exists
      FROM xx_ap_chbk_action_holds
     WHERE invoice_id=p_invoice_id
       AND line_number=cur.line_number
       AND hold_lookup_code='PRICE';
       
    IF (ln_price_split=0 AND ln_qty_split>0 AND ln_price_exists>0) THEN
       FOR pqs IN noprice_qty_split(p_invoice_id,cur.Line_Number) 
       LOOP
         IF (pqs.reason_code IS NULL AND pqs.hold_lookup_code LIKE 'QTY%') OR  (pqs.unmatched_qty>0 AND pqs.hold_lookup_code LIKE 'SP%' AND pqs.reason_code IS NULL ) THEN
            ln_hld_nrc:=NVL(ln_hld_nrc,0)+ ROUND((NVL(pqs.unmatched_qty,0)*pqs.unit_price),2);
         END IF;
         IF pqs.reason_code IS NOT NULL AND pqs.hold_lookup_code LIKE 'SP%' THEN
           ln_hld_rc:=NVL(ln_hld_rc,0)+ROUND((NVL(pqs.unmatched_qty,0)*pqs.unit_price),2);
         END IF;                
       END LOOP;
     END IF;
  tot_hld_nrc:=tot_hld_nrc+ln_hld_nrc;
  tot_hld_rc:=tot_hld_rc+ln_hld_rc;
  END LOOP;  
  p_line_total:=ROUND((ln_nohld_nrc+ln_po_total+tot_hld_nrc+ln_nohld_other_nrc),2);
  p_rc_total  :=ROUND((ln_nohld_rc+tot_hld_rc),2);  
EXCEPTION
  WHEN others THEN
    dbms_output.put_line('whenothers1'||DBMS_UTILITY.format_error_backtrace);
END xx_get_total;                      

-- +======================================================================+
-- | Name        :  xx_freight_upd                                        |
-- | Description :  To update chargeback flag for Freight Lines           |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_freight_upd(p_invoice_id IN NUMBER)
IS
BEGIN
  UPDATE xx_ap_chbk_action_dtl
     SET chargeback='Y'
   WHERE invoice_id=p_invoice_id
     AND line_type_lookup_code='FREIGHT'
     AND new_line_flag='N';
  UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y'
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code like 'OD Max Freight%';
  COMMIT;
EXCEPTION
  WHEN others THEN
    NULL;
END xx_freight_upd;

-- +======================================================================+
-- | Name        :  xx_nrc_rc_upd                                         |
-- | Description :  To update reason code for QTY REC hold                |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_nrc_rc_upd(p_invoice_id IN NUMBER)
IS
BEGIN
  UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y',
         chargeback='Y'
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code='QTY REC';
  UPDATE xx_ap_chbk_action_holds
     SET release_hold='Y',
         chargeback='Y'
   WHERE invoice_id=p_invoice_id
     AND hold_lookup_code like 'OD NO Receipt%';
  COMMIT;
EXCEPTION
  WHEN others THEN
    NULL;
END xx_nrc_rc_upd;
-- +======================================================================+
-- | Name        :  xx_del_line                                           |
-- | Description :  To delete line in custom table from Dashboard         |
-- |                                                                      |
-- | Parameters  :  p_invoice_id,p_line_seq_id                            |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_del_line(p_invoice_id IN NUMBER, p_line_seq_id IN NUMBER)
IS
lc_pre_bal VARCHAR2(1):='N';
lc_misc_hold_flag VARCHAR2(1):='N';
BEGIN
  BEGIN
    SELECT pre_balance_flg,misc_hold_flag
      INTO lc_pre_bal,lc_misc_hold_flag
      FROM xx_ap_chbk_action_dtl
     WHERE invoice_id=p_invoice_id
       AND line_seq_id=p_line_seq_id;
  EXCEPTION
    WHEN others THEN 
      lc_pre_bal:=NULL;
  END;
  IF lc_pre_bal='Y' THEN
     DELETE 
       FROM xx_ap_chbk_action_holds
      WHERE invoice_id=p_invoice_id
        AND hold_lookup_code like 'OD Line Variance%';
  END IF;
   IF lc_misc_hold_flag='Y' THEN
     DELETE 
       FROM xx_ap_chbk_action_holds
      WHERE invoice_id=p_invoice_id
        AND hold_lookup_code like 'OD MISC HOLD%';
  END IF;
  DELETE 
    FROM xx_ap_chbk_action_holds
   WHERE invoice_id=p_invoice_id
     AND line_number IN (SELECT line_number
                             FROM xx_ap_chbk_action_dtl
                          WHERE invoice_id=p_invoice_id
                            AND line_seq_id=p_line_seq_id
                        );
 -- DELETE
 --   FROM xx_ap_chbk_action_dtl
  -- WHERE invoice_id=p_invoice_id
 --   AND line_seq_id=p_line_seq_id;
  COMMIT;
EXCEPTION
  WHEN others THEN
    NULL;
END xx_del_line;
-- +======================================================================+
-- | Name        :  get_uom                                               |
-- | Description :  To check UOM                                          |
-- |                                                                      |
-- | Parameters  :  p_item_id                                             |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_uom(p_item_id IN NUMBER)
RETURN VARCHAR2
IS
lc_uom VARCHAR2(25);
BEGIN
  IF p_item_id IS NOT NULL THEN
     BEGIN
       SELECT primary_unit_of_measure
         INTO lc_uom
         FROM mtl_system_items_b
        WHERE inventory_item_id=p_item_id
          AND rownum<2;
     EXCEPTION
       WHEN others THEN 
         lc_uom:=NULL;
     END;
  END IF;
  RETURN lc_uom;
END get_uom;
-- +======================================================================+
-- | Name        :  get_tot_bqty                                          |
-- | Description :  To check UOM                                          |
-- |                                                                      |
-- | Parameters  :  p_item_id                                             |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_tot_bqty(p_invoice_id IN NUMBER, p_po_line_id IN NUMBER)
RETURN VARCHAR2
IS
ln_tot_bqty        NUMBER;
BEGIN
 SELECT NVL(SUM(pol.quantity_billed),0)
   INTO ln_tot_bqty
   FROM po_line_locations_all pol,
        ap_invoice_lines_all l
  WHERE l.invoice_id=p_invoice_id
    AND l.po_Line_id=p_po_line_id
    AND pol.po_line_id = l.po_line_id;    
RETURN ln_tot_bqty;
EXCEPTION
  WHEN others THEN
   ln_tot_bqty:=-1;
END get_tot_bqty;
-- +======================================================================+
-- | Name        :  check_hold_exists                                     |
-- | Description :  To check hold exists                                  |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_line_location_id                      |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION check_hold_exists(p_invoice_id IN NUMBER, p_line_location_id IN NUMBER) 
RETURN VARCHAR2 
IS
lc_hold_exists VARCHAR2(1):='N';
BEGIN
  SELECT DECODE(COUNT(hold_id),0,'N','Y')
    INTO lc_hold_exists
    FROM ap_holds_all a
   WHERE a.line_location_id=p_line_location_id
     AND a.invoice_id=p_invoice_id
     AND a.release_lookup_code IS NULL;
  RETURN(lc_hold_exists);            
EXCEPTION
  WHEN others THEN
    lc_hold_exists:=NULL;
    RETURN(lc_hold_exists);
END check_hold_exists;
-- +======================================================================+
-- | Name        :  get_shipment_num                                      |
-- | Description :  To get shipment_num                                   |
-- |                                                                      |
-- | Parameters  :  p_po_line_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_shipment_num(p_po_line_id IN NUMBER)
RETURN NUMBER 
IS
ln_ship_num NUMBER:=0;
BEGIN
  SELECT shipment_num
    INTO ln_ship_num
    FROM po_line_locations_all
    WHERE po_line_id=p_po_line_id;
                RETURN(ln_ship_num); 
EXCEPTION
  WHEN others THEN
    ln_ship_num:=NULL;
                RETURN(ln_ship_num);
END get_shipment_num;
-- +======================================================================+
-- | Name        :  get_line_acct                                         |
-- | Description :  To get charge Account                                 |
-- |                                                                      |
-- | Parameters  :  p_ccid                                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_line_acct(p_ccid IN NUMBER)
RETURN VARCHAR2
IS
lc_charge_acct  VARCHAR2(100);
BEGIN
SELECT g.segment1
      ||'.'
      ||g.segment2
      ||'.'
      ||g.segment3
      ||'.'
      ||g.segment4
      ||'.'
      ||g.segment5
      ||'.'
      ||g.segment6
      ||'.'
      ||g.segment7
  INTO lc_charge_acct
  FROM gl_code_combinations g
WHERE g.code_combination_id=p_ccid;
RETURN(lc_charge_acct);             
EXCEPTION
  WHEN others THEN
    lc_charge_acct:=NULL;
    RETURN(lc_charge_acct);
END get_line_acct;
-- +======================================================================+
-- | Name        :  get_acct_id                                           |
-- | Description :  To get ccid                                           |
-- |                                                                      |
-- | Parameters  :  p_concat_segments                                     |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_acct_id(p_concat_segments IN VARCHAR2)
RETURN NUMBER
IS
lc_ccid NUMBER;
BEGIN
SELECT code_combination_id
  INTO lc_ccid
  FROM gl_code_combinations_kfv g
 WHERE g.concatenated_segments=p_concat_segments
   AND enabled_flag='Y';
RETURN(lc_ccid);             
EXCEPTION
  WHEN others THEN
    lc_ccid:=NULL;
    RETURN(lc_ccid);
END get_acct_id;
-- +======================================================================+
-- | Name        :  get_charge_acct                                       |
-- | Description :  To get charge Account                                 |
-- |                                                                      |
-- | Parameters  :  p_po_line_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_charge_acct(p_po_line_id IN NUMBER)
RETURN VARCHAR2 
IS
lc_charge_acct  VARCHAR2(100);
BEGIN
SELECT g.segment1
      ||'.'
      ||g.segment2
      ||'.'
      ||g.segment3
      ||'.'
      ||g.segment4
      ||'.'
      ||g.segment5
      ||'.'
      ||g.segment6
      ||'.'
      ||g.segment7
  INTO lc_charge_acct
  FROM gl_code_combinations g,
       po_distributions_all d
WHERE d.po_line_id       =p_po_line_id
   AND g.code_combination_id=d.code_combination_id;
                RETURN(lc_charge_acct);             
EXCEPTION
  WHEN others THEN
    lc_charge_acct:=NULL;
                RETURN(lc_charge_acct);
END get_charge_acct;
--+======================================================================+
-- | Name        :  get_freight_acct                                      |
-- | Description :  To get freight Account                                |
-- |                                                                      |
-- | Parameters  :  p_po_line_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_freight_acct(p_invoice_id NUMBER ,p_line_number IN NUMBER)
RETURN VARCHAR2 
IS
lc_charge_acct  VARCHAR2(100);
BEGIN
SELECT g.segment1
      ||'.'
      ||g.segment2
      ||'.'
      ||g.segment3
      ||'.'
      ||g.segment4
      ||'.'
      ||g.segment5
      ||'.'
      ||g.segment6
      ||'.'
      ||g.segment7
  INTO lc_charge_acct
  FROM gl_code_combinations g,
       ap_invoice_distributions_all d
WHERE  d.invoice_id=p_invoice_id
   AND d.line_type_lookup_code='FREIGHT'
   AND d.invoice_line_number=p_line_number
   AND g.code_combination_id=d.dist_code_combination_id;
   RETURN(lc_charge_acct);             
EXCEPTION
  WHEN others THEN
    lc_charge_acct:=NULL;
    RETURN(lc_charge_acct);
END get_freight_acct;
-- +======================================================================+
-- | Name        :  get_distribution_list                                 |
-- | Description :  This function gets email distribution list from       |
-- |                the translation                                       |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_distribution_list 
RETURN VARCHAR2
IS
  lc_first_rec      VARCHAR2(1);
  lc_temp_email     VARCHAR2(2000);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  Type TYPE_TAB_EMAIL IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL         TYPE_TAB_EMAIL;
BEGIN
     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
             ,TV.target_value8
             ,TV.target_value9
             ,TV.target_value10
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
             ,EMAIL_TBL(3)
             ,EMAIL_TBL(4)
             ,EMAIL_TBL(5)
             ,EMAIL_TBL(6)
             ,EMAIL_TBL(7)
             ,EMAIL_TBL(8)
             ,EMAIL_TBL(9)
             ,EMAIL_TBL(10)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'XX_AP_TRADE_MATCH_DL'
       AND   source_value1    = 'UI_ACTION_ERRORS';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..10 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
       IF lc_temp_email IS NULL THEN
      lc_temp_email:='padmanaban.sanjeevi@officedepot';
       END IF;
       RETURN(lc_temp_email);
     EXCEPTION
       WHEN others then
         lc_temp_email:='padmanaban.sanjeevi@officedepot';
         RETURN(lc_temp_email);
     END;
END get_distribution_list;
-- +======================================================================+
-- | Name        :  get_address                                           |
-- | Description :  This function returns valid email address to be used  |
-- |                in smtp conn                                          |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_address(addr_list IN OUT VARCHAR2) RETURN VARCHAR2 IS
    addr VARCHAR2(256);
    i    pls_integer;
    FUNCTION lookup_unquoted_char(str  IN VARCHAR2,
                  chrs IN VARCHAR2) RETURN pls_integer AS
      c            VARCHAR2(5);
      i            pls_integer;
      len          pls_integer;
      inside_quote BOOLEAN;
    BEGIN
       inside_quote := false;
       i := 1;
       len := length(str);
       WHILE (i <= len) LOOP
     c := substr(str, i, 1);
     IF (inside_quote) THEN
       IF (c = '"') THEN
         inside_quote := false;
       ELSIF (c = '\') THEN
         i := i + 1; -- Skip the quote character
       END IF;
       GOTO next_char;
     END IF;
     IF (c = '"') THEN
       inside_quote := true;
       GOTO next_char;
     END IF;
     IF (instr(chrs, c) >= 1) THEN
        RETURN i;
     END IF;
     <<next_char>>
     i := i + 1;
       END LOOP;
       RETURN 0;
    END;
  BEGIN
    addr_list := ltrim(addr_list);
    i := lookup_unquoted_char(addr_list, ',;');
    IF (i >= 1) THEN
      addr      := substr(addr_list, 1, i - 1);
      addr_list := substr(addr_list, i + 1);
    ELSE
      addr := addr_list;
      addr_list := '';
    END IF;
    i := lookup_unquoted_char(addr, '<');
    IF (i >= 1) THEN
      addr := substr(addr, i + 1);
      i := instr(addr, '>');
      IF (i >= 1) THEN
    addr := substr(addr, 1, i - 1);
      END IF;
    END IF;
    RETURN addr;
END get_address;

PROCEDURE xx_send_rejected_notification(p_invoice_num IN VARCHAR2)
IS
lc_temp_email             VARCHAR2(2000);
conn                     utl_smtp.connection;
BEGIN
  lc_temp_email:=get_distribution_list;
  conn := xx_pa_pb_mail.begin_mail(
                    sender => 'Accounts-Payable@officedepot.com',
                    recipients => lc_temp_email,
                    cc_recipients=>NULL,
                    subject => 'OD AP UI Action Invoice/Chargeback Rejection : '|| p_invoice_num,
                    mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);  
  xx_pa_pb_mail.attach_text( conn => conn,
                             data => p_invoice_num || ' is rejected in POI, Please check and resolve this rejection as well as corresponding DM/Invoice' 
                                            );
  xx_pa_pb_mail.end_mail( conn => conn );
END xx_send_rejected_notification;                

-- +======================================================================+
-- | Name        :  xx_send_uierror_report                                |
-- | Description :  To send UI Action Error Report                        |
-- |                                                                      |
-- | Parameters  :  N/A                                                   |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_send_uierror_report ( x_errbuf       OUT NOCOPY VARCHAR2
                                  ,x_retcode      OUT NOCOPY VARCHAR2
                                 )
IS
  v_addlayout         boolean;
  v_wait             BOOLEAN;
  v_request_id         NUMBER;
  vc_request_id     NUMBER;
  v_file_name         varchar2(200);
  v_dfile_name        varchar2(200);
  v_sfile_name         varchar2(200);
  x_dummy            varchar2(2000)     ;
  v_dphase            varchar2(100)    ;
  v_dstatus            varchar2(100)    ;
  v_phase            varchar2(100)   ;
  v_status            varchar2(100)   ;
  x_cdummy            varchar2(2000)     ;
  v_cdphase            varchar2(100)    ;
  v_cdstatus        varchar2(100)    ;
  v_cphase            varchar2(100)   ;
  v_cstatus            varchar2(100)   ;
  ld_date            VARCHAR2(15);
  conn                 utl_smtp.connection;
  lc_temp_email     VARCHAR2(2000);
  ln_cnt            NUMBER:=0;
BEGIN
  ld_date:=TO_CHAR(TRUNC(SYSDATE));
  SELECT COUNT(1)
    INTO ln_cnt
    FROM xx_ap_uiaction_errors
   WHERE last_update_date BETWEEN to_date(to_char(sysdate)||' 00:00:00','DD-MON-RR HH24:MI:SS') 
                            AND to_date(to_char(sysdate)||' 23:59:59','DD-MON-RR HH24:MI:SS');
  IF ln_cnt<>0 THEN
     lc_temp_email:=get_distribution_list;  
     v_addlayout:=FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXFIN',
                                          template_code => 'XXAPUIAE',
                                          template_language => 'en',
                                          template_territory => 'US',
                                          output_format => 'EXCEL'); 
     IF (v_addlayout) THEN
        fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
     ELSE
        fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
     END IF;
     v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXAPUIAE','OD: AP UI Action Errors Report',NULL,FALSE,
        ld_date,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
        NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
     IF v_request_id>0 THEN
        COMMIT;
        v_file_name:='XXAPUIAE_'||to_char(v_request_id)||'_1.xls';
        v_sfile_name:='OD_AP_UIAction_Error_Report'||'_'||TO_CHAR(SYSDATE,'MMDDYYHH24MI')||'.xls';
        v_dfile_name:='$XXMER_DATA/outbound/'||v_sfile_name;
        v_file_name:='$APPLCSF/$APPLOUT/'||v_file_name;
     END IF;
     IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
            v_status,v_dphase,v_dstatus,x_dummy))  THEN
        IF v_dphase = 'COMPLETE' THEN
           vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
               v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
              NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
           IF vc_request_id>0 THEN
              COMMIT;
           END IF;
           IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
               v_cstatus,v_cdphase,v_cdstatus,x_cdummy))  THEN
              IF v_cdphase = 'COMPLETE' THEN  -- child
                  conn := xx_pa_pb_mail.begin_mail(
                  sender => 'Accounts-Payable@officedepot.com',
                  recipients => lc_temp_email,
                      cc_recipients=>NULL,
                 subject => 'OD: AP UI Action Error Report',
                mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
                 xx_pa_pb_mail.xx_attach_excel(conn,v_sfile_name);
                xx_pa_pb_mail.end_attachment(conn => conn);
                xx_pa_pb_mail.attach_text( conn => conn,
                                             data => 'Please find the attached report for the details' 
                                            );
                xx_pa_pb_mail.end_mail( conn => conn );
                COMMIT;
              END IF; --IF v_cdphase = 'COMPLETE' THEN -- child
           END IF; 
        END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main
     END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
  END IF;  
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_send_uierror_report :'||SQLERRM);
END xx_send_uierror_report;
-- +======================================================================+
-- | Name        :  xx_intf_stuck_notify                                  |
-- | Description :  To send notification for Interface Stuck Invoice/DM   |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_intf_stuck_notify(p_invoice_num IN VARCHAR2)
IS

lc_temp_email                VARCHAR2(2000);
v_subject                    VARCHAR2(500);
conn                         utl_smtp.connection;
v_text                        VARCHAR2(2000);
v_smtp_hostname                VARCHAR2 (120):=FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');

BEGIN
  v_text :='Invoice : '||p_invoice_num|| ' is stuck in the Payables Open Interface, Please resolve';
  lc_temp_email:=get_distribution_list;  
  conn := xx_pa_pb_mail.begin_mail(
                  sender => 'Accounts-Payable@officedepot.com',
                  recipients => lc_temp_email,
                  cc_recipients=>NULL,
                  subject => 'OD: AP UI Action Interface Stuck Invoice :'||p_invoice_num ,
                  mime_type => xx_pa_pb_mail.MULTIPART_MIME_TYPE);
                  xx_pa_pb_mail.attach_text( conn => conn,
                                             data => v_text
                                            );
                xx_pa_pb_mail.end_mail( conn => conn );
                COMMIT;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in xx_inft_stuck_notify :'||SQLERRM);
END xx_intf_stuck_notify;

-- +======================================================================+
-- | Name        :  xx_send_notify                                        |
-- | Description :  To send notification for Interface Insertion Errors   |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_send_notify(p_invoice_id IN NUMBER)
IS
CURSOR C1 IS
SELECT a.invoice_num,
       a.line_no,
       a.error_message
  FROM xx_ap_uiaction_errors a
 WHERE a.invoice_id=p_invoice_id
   order by 2;
v_instance            VARCHAR2(25);
v_email_list        VARCHAR2(2000);
v_subject            VARCHAR2(500);
conn                 utl_smtp.connection;
v_text                VARCHAR2(2000);
v_smtp_hostname        VARCHAR2 (120):=FND_PROFILE.VALUE('XX_PA_PB_MAIL_HOST');
l_body                 VARCHAR2 (32767);
l_new_line             VARCHAR2 (1) := fnd_global.newline;
lc_body_hdr_html     VARCHAR2(2000);
v_html                 VARCHAR2(32767);
v_from              VARCHAR2 (140) := 'Accounts-Payable@officedepot.com';
BEGIN
  SELECT name INTO v_instance from v$database;
  lc_body_hdr_html := '<p>Team,</p>
                         <p>Errors were encountered while inserting into AP Invoice Interface Table</p>
                      ';
  l_body    :=NULL;
  v_email_list:=get_distribution_list;
  v_subject   :='Errors While inserting into AP Invoice Interface Table';
    IF v_instance<>'GSIPRDGB' THEN
       v_subject:=v_instance||' Please Ignore this mail :'||v_subject;  
    END IF;
    l_body :='<HTML> <CENTER>  <small> <FONT size="3" face="Arial">'
            || '<B>'
            || 'AP Invoice Interface Insert Errors'
            || '</B>'
            || '</small> </CENTER>';
    l_body := l_body || '<BR />';
    l_body :=l_body
            || '<TABLE BORDER=1 BGCOLOR="#D8D8D8" CELLPADDING=2 CELLSPACING=2>'
            || CHR (10);
    l_body := l_body || '<TR BGCOLOR="SkyBlue">' || CHR (10);
    l_body := l_body
            || '<TH WIDTH="4.5%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Invoice #</FONT>'
            || CHR (10);
    l_body := l_body
            || '<TH WIDTH="2.25%" ALIGN="RIGHT"><FONT size="2" face="verdana" COLOR="BLACK">Line #</FONT>'
            || CHR (10);
    l_body := l_body
            || '<TH WIDTH="20%" ALIGN="LEFT"><FONT size="2" face="verdana" COLOR="BLACK">Error Message</FONT>'
            || CHR (10);
    l_body := l_body || '</TR>' || CHR (10);
    FOR cur IN C1 LOOP
            l_body := l_body || '<TR>';
            l_body := l_body || '<TR BGCOLOR="WhiteSmoke">' || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || cur.invoice_num
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD ALIGN="RIGHT">'
                || '<FONT size="2" face="verdana">'
                || TO_CHAR(cur.line_no)
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body :=
                   l_body
                || '<TD>'
                || '<FONT size="2" face="verdana">'
                || cur.error_message
                || '</FONT>'
                || '</TD>'
                || CHR (10);
            l_body := l_body || '</TR>' || CHR (10);
    END LOOP;
    l_body := l_body || '</TABLE>' || CHR (10);
    l_body := l_body || l_new_line || '<BR />' || CHR (10);
    l_body := l_body || '</TABLE>' || CHR (10);
    v_html := l_body;
    conn := utl_smtp.open_connection(v_smtp_hostname,25);
    utl_smtp.helo(conn,v_smtp_hostname);
    utl_smtp.mail(conn,v_from);
    WHILE (v_email_list IS NOT NULL) LOOP
      utl_smtp.rcpt(conn, get_address(v_email_list));
    END LOOP;
    utl_smtp.data(conn,'Return-Path: ' || v_from || utl_tcp.crlf ||
                'Sent: ' || TO_CHAR(SYSDATE,'MM/DD/YYYY HH24:MI:SS') || utl_tcp.crlf ||
                'From: ' || v_from || utl_tcp.crlf ||
                'Subject: ' || v_subject  ||utl_tcp.crlf ||
                'To: ' || v_email_list || utl_tcp.crlf ||
                'Content-Type: multipart/mixed; boundary="MIME.Bound"' ||utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound' || utl_tcp.crlf ||
                'Content-Type: multipart/alternative; boundary="MIME.Bound2"' || utl_tcp.crlf || utl_tcp.crlf || '--MIME.Bound2' || utl_tcp.crlf ||
                'Content-Type: text/html; ' || utl_tcp.crlf ||
                'Content-Transfer_Encoding: 7bit' || utl_tcp.crlf ||utl_tcp.crlf ||
                 utl_tcp.crlf ||'<html><head><title>'||'AP Interface Insert Errors'||'</title></head>
                <body> <font face = "verdana" size = "2" color="#336699">'||lc_body_hdr_html||'<br><br>
                '||v_html||'
                <br><hr>
                </font></body></html>' ||
                utl_tcp.crlf || '--MIME.Bound2--' || utl_tcp.crlf || utl_tcp.crlf);
            utl_smtp.quit(conn);
EXCEPTION
  WHEN others THEN
    print_debug_msg('Error while sending notification :'||SUBSTR(SQLERRM,1,100));
END xx_send_notify;
-- +======================================================================+
-- | Name        :  xx_rel_ansinv_holds                                   |
-- | Description :  To release price holds with answer=INV                |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :  N/A                                                   |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_rel_ansinv_holds(p_invoice_id IN NUMBER)
IS
CURSOR c_rel_inv_holds 
IS
SELECT /*+ LEADING (h) */
       ai.invoice_id,
       al.po_line_location_id line_location_id,
       h.hold_lookup_code
  FROM ap_invoice_lines_all al,
       ap_invoices_all ai,
      (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */
              distinct 
              aph.invoice_id,
              aph.hold_lookup_code,
              aph.line_location_id
         FROM ap_holds_all aph
        WHERE aph.invoice_id=p_invoice_id
          AND NVL(aph.status_flag,'S')= 'S'
          AND aph.release_lookup_code IS NULL
          AND aph.hold_lookup_code='PRICE'
      )h   
 WHERE ai.invoice_id=h.invoice_id
   AND ai.source=NVL(gn_source,ai.source)
   AND ai.org_id=gn_org_id
   AND al.invoice_id=ai.invoice_id
   AND al.po_line_location_id=h.line_location_id   
   AND EXISTS ( SELECT 'X'
                 FROM xx_ap_cost_variance cv
                WHERE cv.invoice_id=al.invoice_id
                  AND cv.po_line_id=al.po_line_id
                  AND cv.line_num=al.line_number
                  AND cv.answer_code='INV'
              );
BEGIN
  FOR cur IN c_rel_inv_holds LOOP
      UPDATE ap_holds_all
         SET release_lookup_code = 'APPROVED',
             release_reason = 'Hold Released',  
             last_updated_by = fnd_global.user_id,
             last_update_date = SYSDATE,
             last_update_login = fnd_global.user_id,
             status_flag='R'
       WHERE invoice_id = cur.invoice_id
         AND line_location_id=cur.line_location_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code = cur.hold_lookup_code
         AND NVL(status_flag,'X')<>'R';                         
  END LOOP;  
  COMMIT;
EXCEPTION
  WHEN others THEN
    print_debug_msg ('Error while Releasing Holds : '||SUBSTR(SQLERRM,1,100));
END xx_rel_ansinv_holds;
-- +======================================================================+
-- | Name        :  get_reason_code_desc                                  |
-- | Description :  To get the reason code description                    |
-- |                                                                      |
-- | Parameters  :  p_reason_code                                         |
-- |                                                                      |
-- | Returns     :  Reason Code Description                               |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_reason_code_desc(p_reason_code IN VARCHAR2)
RETURN VARCHAR2
IS
v_desc VARCHAR2(240);
BEGIN
  SELECT description
    INTO v_desc
    FROM ap_lookup_codes
   WHERE lookup_type = 'HOLD CODE'
     AND lookup_code = p_reason_code;
  RETURN(v_desc);
EXCEPTION  
  WHEN others THEN
    v_desc:=NULL;
    RETURN(v_desc);    
END get_reason_code_desc;  
-- +======================================================================+
-- | Name        :  xx_rel_newinvoice_holds                               |
-- | Description :  To release new invoice holds                          |
-- |                                                                      |
-- | Parameters  :  p_new_invoice_id                                      |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_rel_newinvoice_holds(p_new_invoice_id IN NUMBER)
IS
CURSOR C1
IS
SELECT ah.invoice_id,
       ah.line_location_id,
       ah.hold_lookup_code
  FROM ap_holds_all ah
 WHERE ah.invoice_id=p_new_invoice_id
   AND ah.line_location_id IS NOT NULL
   AND ah.release_lookup_code IS NULL
   AND ah.hold_lookup_code='PRICE'
   AND EXISTS ( SELECT 'x'
                  FROM xx_ap_cost_variance cst,
                       po_line_locations_all pll
                 WHERE pll.line_location_id=ah.line_location_id
                   AND cst.po_line_id=pll.po_line_id
                   AND cst.answer_code='OTH'
              );
v_desc                     VARCHAR2(240);
lc_error_message        VARCHAR2(150);   
v_hold_rel_cnt            NUMBER;
v_rlcode                VARCHAR2(30);
BEGIN   

  FOR cur IN C1 LOOP
    v_desc := get_reason_code_desc('APPROVED');
    v_rlcode:='APPROVED';    
    UPDATE ap_holds_all
       SET release_lookup_code = v_rlcode,
           release_reason =v_desc,
           last_updated_by = gn_user_id,
           last_update_date = SYSDATE,
           last_update_login =gn_user_id,
           status_flag='R'
     WHERE invoice_id = cur.invoice_id
       AND line_location_id=cur.line_location_id
       AND release_lookup_code IS NULL
       AND hold_lookup_code = cur.hold_lookup_code;
    IF SQL%NOTFOUND THEN
          lc_error_message:='Error in Releasing Holds for New Invoice :'||SUBSTR(SQLERRM,1,100);       
          BEGIN
         INSERT
           INTO xx_ap_uiaction_errors
               (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
         VALUES
               (p_new_invoice_id,cur.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
      EXCEPTION
        WHEN others THEN
        print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
      END;
    END IF;
  END LOOP;
  v_desc := get_reason_code_desc('APPROVED');
  UPDATE ap_holds_all a
     SET release_lookup_code = 'APPROVED',
         release_reason =v_desc,
         last_updated_by = gn_user_id,
         last_update_date = SYSDATE,
         last_update_login =gn_user_id,
         status_flag='R'
   WHERE invoice_id = p_new_invoice_id
     AND release_lookup_code IS NULL
     AND hold_lookup_code IN ('OD Favorable','OD Max Price')
     AND EXISTS (SELECT 'x'
                   FROM ap_holds_all
                  WHERE invoice_id=gn_invoice_id
                    AND line_location_id=a.line_location_id
                    AND hold_lookup_code=a.hold_lookup_code
               );

  v_desc := get_reason_code_desc('APPROVED');     
  UPDATE ap_holds_all
     SET release_lookup_code = 'APPROVED',
         release_reason =v_desc,
         last_updated_by = gn_user_id,
         last_update_date = SYSDATE,
         last_update_login =gn_user_id,
         status_flag='R'
   WHERE invoice_id = p_new_invoice_id
     AND release_lookup_code IS NULL
     AND hold_lookup_code like 'OD NO Receipt'
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_holds
                  WHERE invoice_id=gn_invoice_id
                    AND hold_lookup_code='OD NO Receipt'
                    AND release_hold='Y'
                );

  v_desc := get_reason_code_desc('OD_VA_APPRVD_HDR');
  UPDATE ap_holds_all
     SET release_lookup_code = 'OD_VA_APPRVD_HDR',
         release_reason =v_desc,
         last_updated_by = gn_user_id,
         last_update_date = SYSDATE,
         last_update_login =gn_user_id,
         status_flag='R'
   WHERE invoice_id = p_new_invoice_id
     AND release_lookup_code IS NULL
     AND hold_lookup_code like 'OD Max Freight'
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_dtl
                  WHERE invoice_id=gn_invoice_id
                    AND line_type_lookup_code='FREIGHT'
                    AND release_hold='Y'
                );

  v_desc := get_reason_code_desc('APPROVED');
  UPDATE ap_holds_all a
     SET release_lookup_code = 'APPROVED',
         release_reason =v_desc,
         last_updated_by = gn_user_id,
         last_update_date = SYSDATE,
         last_update_login =gn_user_id,
         status_flag='R'
   WHERE invoice_id = p_new_invoice_id
     AND release_lookup_code IS NULL
     AND hold_lookup_code like 'QTY%'
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_holds
                  WHERE invoice_id=gn_invoice_id
                    AND line_location_id=a.line_location_id
                    AND hold_lookup_code=a.hold_lookup_code  
                    AND release_hold='Y'
                );                

  v_desc := get_reason_code_desc('APPROVED');
  UPDATE ap_holds_all a
     SET release_lookup_code = 'APPROVED',
         release_reason =v_desc,
         last_updated_by = gn_user_id,
         last_update_date = SYSDATE,
         last_update_login =gn_user_id,
         status_flag='R'
   WHERE invoice_id = p_new_invoice_id
     AND release_lookup_code IS NULL
     AND hold_lookup_code like 'PRICE%'
     AND EXISTS (SELECT 'x'
                   FROM xx_ap_chbk_action_holds
                  WHERE invoice_id=gn_invoice_id
                    AND line_location_id=a.line_location_id
                    AND hold_lookup_code=a.hold_lookup_code 
                    AND release_hold='Y'
                );   

   v_desc := get_reason_code_desc('OD_VA_APPRVD_HDR');                
   IF gc_po_type='2-Way' THEN
   
      UPDATE ap_holds_all
         SET release_lookup_code = 'OD_VA_APPRVD_HDR',
             release_reason =v_desc,
             last_updated_by = gn_user_id,
             last_update_date = SYSDATE,
             last_update_login =gn_user_id,
             status_flag='R'
       WHERE invoice_id = p_new_invoice_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code like 'QTY REC%';

   ELSIF gc_po_type='3-Way' THEN
      UPDATE ap_holds_all
         SET release_lookup_code = 'OD_VA_APPRVD_HDR',
             release_reason =v_desc,
             last_updated_by = gn_user_id,
             last_update_date = SYSDATE,
             last_update_login =gn_user_id,
             status_flag='R'
       WHERE invoice_id = p_new_invoice_id
         AND release_lookup_code IS NULL
         AND hold_lookup_code like 'QTY ORD%';

   END IF;
  COMMIT;        
EXCEPTION
  WHEN others THEN
    print_debug_msg ('Error in xx_rel_newinvoice_holds : ' ||SUBSTR(SQLERRM,1,100));  
    lc_error_message:='When others in releasing Holds for New Invoice :'||SUBSTR(SQLERRM,1,100);           
    BEGIN
      INSERT
        INTO xx_ap_uiaction_errors
            (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
        VALUES
            (p_new_invoice_id,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
    EXCEPTION
      WHEN others THEN
        print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
    END;    
END xx_rel_newinvoice_holds;     
-- +======================================================================+
-- | Name        :  xx_cancel_invoice                                     |
-- | Description :  To cancel the invoice                                 |
-- |                                                                      |
-- | Parameters  :  p_invoice_num                                         |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
  FUNCTION xx_cancel_invoice(p_invoice_id IN NUMBER)
  RETURN VARCHAR2
  IS
    l_invoice_id            AP_INVOICES_ALL.INVOICE_ID%type;
    l_set_of_books_id       AP_INVOICES_ALL.SET_OF_BOOKS_ID%type;
    l_holds_count           NUMBER;
    l_approval_status       VARCHAR2(100);
    l_funds_return_code     VARCHAR2(100);
    l_user_id               NUMBER := 3813068;
    l_resp_id               NUMBER := 20639;
    l_app_id                NUMBER := 200;   
    req_id                  NUMBER;
    l_cancel_result         BOOLEAN := TRUE;
    l_message_name          FND_NEW_MESSAGES.message_name%TYPE;
    l_token                 VARCHAR2(4000);
    l_invoice_amount        AP_INVOICES.invoice_amount%TYPE;
    l_base_amount           AP_INVOICES.base_amount%TYPE;
    l_temp_cancelled_amount AP_INVOICES.temp_cancelled_amount%TYPE;
    l_cancelled_by          AP_INVOICES.cancelled_by%TYPE;
    l_cancelled_amount      AP_INVOICES.cancelled_amount%TYPE;
    l_cancelled_date        AP_INVOICES.cancelled_date%TYPE;
    l_last_update_date      AP_INVOICES.last_update_date%TYPE;
    l_dummy                 NUMBER;
    l_manualcount           NUMBER;                                               --Bug 746366
    l_date                  DATE;                                                 --Bug1715368
    l_period                gl_period_statuses.period_name%TYPE;                       --Bug1715368
    l_pay_curr_invoice_amount AP_INVOICES.pay_curr_invoice_amount%TYPE; --1805525
    l_stop_approval_result  BOOLEAN := TRUE;                             --bug4299234
    l_cancellation_count    NUMBER;                                      -- bug 6669048
    l_open_period           VARCHAR2(15);                                --bug 6338165
    l_max_acc_date          DATE;                                        --bug 6338165
    l_open_gl_date          DATE;                                        --bug 6338165
    l_amount_paid           NUMBER;                                      --bug8411165
    l_invalid_acct_count    NUMBER;                                      --bug9290164   
    l_wfinv_approval_status VARCHAR2(100);
    l_org_id                NUMBER;
    l_wfapproval_status     VARCHAR2(100);
    l_amount_withheld       NUMBER;
    l_prepaid_amount        NUMBER;
    l_Invoice_date          DATE;
    lc_cancel_status        VARCHAR2(10):='SUCCESS';
    p_invoice_num            VARCHAR2(50);
  BEGIN
    SELECT invoice_id,
           set_of_books_id,
           org_id,
           invoice_date,
           invoice_num
      INTO l_invoice_id,
           l_set_of_books_id,
           l_org_id,
           l_invoice_date,
           p_invoice_num
      FROM ap_invoices_all i
     WHERE invoice_id=p_invoice_id;
    MO_GLOBAL.SET_POLICY_CONTEXT('S',l_org_id);
    l_wfinv_approval_status    := AP_INVOICES_PKG.GET_WFAPPROVAL_STATUS(L_INVOICE_ID, l_org_id );
    IF (L_WFINV_APPROVAL_STATUS ='INITIATED') THEN
      l_stop_approval_result   := AP_WORKFLOW_PKG.Stop_Approval(L_INVOICE_ID,NULL,'INV_SUM_ACTIONS_CANCEL.do_cancel');
      IF L_STOP_APPROVAL_RESULT = true THEN
        l_WFAPPROVAL_STATUS    :='NOT REQUIRED';
      END IF;
    END IF;
    --start of 9290164
    IF L_INVOICE_ID IS NOT NULL THEN
      BEGIN
        SELECT COUNT(1)
          INTO l_invalid_acct_count
          FROM ap_invoice_distributions D
         WHERE D.invoice_id          =L_INVOICE_ID
           AND NVL(D.posted_flag,'N') <> 'Y'
           AND ( ( EXISTS
               (SELECT 'x'
                  FROM gl_code_combinations C
                 WHERE D.dist_code_combination_id = C.code_combination_id (+)
                   AND ( C.code_combination_id IS NULL
                    OR C.detail_posting_allowed_flag = 'N'
                    OR C.start_date_active > D.accounting_date
                    OR C.end_date_active < D.accounting_date
                    OR C.template_id                IS NOT NULL
                    OR C.enabled_flag               <> 'Y'
                    OR C.summary_flag               <> 'N' )
                ) )
                    OR ( D.dist_code_combination_id = -1) )
          ----Valid alternate account is not defined
        AND NOT EXISTS
          (SELECT 'alternate account'
             FROM gl_code_combinations glcc
            WHERE glcc.code_combination_id          = D.dist_code_combination_id
              AND glcc.alternate_code_combination_id IS NOT NULL
              AND EXISTS
                 (SELECT 'Account Valid'
                    FROM gl_code_combinations a
                   WHERE a.code_combination_id  = glcc.alternate_code_combination_id
                     AND a.enabled_flag = 'Y'
                     AND a.detail_posting_allowed_flag = 'Y'
                     AND D.accounting_date BETWEEN NVL(a.start_date_active, D.accounting_date) AND NVL(a.end_date_active, D.accounting_date)
                 )
          )
          --Invoice is not in partially canceled state
        AND EXISTS
          (SELECT 1
             FROM ap_invoices_all ai
            WHERE ai.invoice_id =D.invoice_id
              AND ai.temp_cancelled_amount IS NULL
          ) ;
      EXCEPTION
      WHEN OTHERS THEN
        NULL;
      END;
    END IF; --  IF L_INVOICE_ID IS NOT NULL THEN
    BEGIN
      SELECT MAX(aid.accounting_date)
        INTO l_max_acc_date --Bug6338165
        FROM ap_invoice_distributions_all aid
       WHERE aid.invoice_id        = L_INVOICE_ID
         AND awt_invoice_payment_id IS NULL; --Bug9537200
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
    END;
    L_CANCEL_RESULT := AP_CANCEL_PKG.AP_CANCEL_SINGLE_INVOICE ( P_INVOICE_ID => L_INVOICE_ID,
                                                                P_LAST_UPDATED_BY => gn_user_id, 
                                                                P_LAST_UPDATE_LOGIN => 69114867,                                                                                                                                                                                                                                            -- FND_PROFILE.value('USER_ID'),
                                                                P_accounting_date => l_max_acc_date,                                                                                                                                                                                                                                                                                                                                                                                     --Bug6338165
                                                                P_MESSAGE_NAME => L_MESSAGE_NAME, 
                                                                P_INVOICE_AMOUNT => L_INVOICE_AMOUNT, 
                                                                P_BASE_AMOUNT => L_BASE_AMOUNT, 
                                                                P_TEMP_CANCELLED_AMOUNT => L_TEMP_CANCELLED_AMOUNT,
                                                                P_CANCELLED_BY => L_CANCELLED_BY, 
                                                                P_CANCELLED_AMOUNT => L_CANCELLED_AMOUNT, 
                                                                P_CANCELLED_DATE => L_CANCELLED_DATE, 
                                                                P_LAST_UPDATE_DATE => L_LAST_UPDATE_DATE, 
                                                                P_ORIGINAL_PREPAYMENT_AMOUNT => L_DUMMY, 
                                                                P_pay_curr_invoice_amount => l_pay_curr_invoice_amount, --1805525
                                                                P_Token => l_token, 
                                                                P_calling_sequence => 'APXINWKB'
                                                              );
    SELECT NVL(amount_paid,0)
      INTO l_amount_paid
      FROM AP_INVOICES_all
     WHERE invoice_id   =l_invoice_id;
    IF L_CANCEL_RESULT = true THEN
       lc_cancel_status:='SUCCESS';
      IF L_WFAPPROVAL_STATUS IN ('REQUIRED','STOPPED','REJECTED','NEEDS WFREAPPROVAL') THEN
        L_WFAPPROVAL_STATUS := 'NOT REQUIRED';        
      END IF;
    END IF;
    -- If an invoice is called for cancellation once, increment the cancellation count.
    -- inv_sum_folder_item_overflow.update_cancellation_count('INIT'); -- Bug 5506252
    -- Bug 746366 - Adding message to inform users that there might be
    -- manually-created invoices if there are any manually-created withholding
    -- tax distribution lines for that invoice.
    SELECT COUNT(*)
      INTO l_manualcount
      FROM ap_invoice_distributions aid
     WHERE invoice_id = l_invoice_id
       AND awt_flag     = 'M'
       AND rownum       = 1; --bug5739273
    IF (NOT l_cancel_result) THEN
       lc_cancel_status:='ERROR';    
      FND_FILE.PUT_LINE(FND_FILE.LOG, p_invoice_num ||' Cancellation Failed ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Message '||L_TOKEN);
    ELSE
      FND_FILE.PUT_LINE(FND_FILE.LOG, p_invoice_num|| ' is Cancelled');
    END IF;
    RETURN(lc_cancel_status);    
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'When others in xx_cancel_invoice :'||SQLERRM);
    RETURN(lc_cancel_status);
  END xx_cancel_invoice;
-- +======================================================================+
-- | Name        :  xx_ui_invoice_cancel                                  |
-- | Description :  To cancel the invoice                                 |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :  Cancel Status                                         |
-- |                                                                      |
-- +======================================================================+  
FUNCTION xx_ui_invoice_cancel(p_invoice_id IN NUMBER) RETURN VARCHAR2 
IS
lc_invoice_cancel_status VARCHAR2(10);
l_user_id                NUMBER;
l_responsibility_id      NUMBER;
l_responsibility_appl_id NUMBER;
BEGIN
  BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
      INTO l_user_id,
           l_responsibility_id,
           l_responsibility_appl_id
      FROM fnd_user_resp_groups
     WHERE user_id=
          (SELECT user_id 
             FROM fnd_user 
            WHERE user_name='740733'
          )
       AND responsibility_id=
          (SELECT responsibility_id
             FROM FND_RESPONSIBILITY
            WHERE responsibility_key = 'PAYABLES_MANAGER'
      );
  EXCEPTION
    WHEN others THEN
      NULL;
  END;       
  --FND_GLOBAL.apps_initialize( l_user_id, l_responsibility_id, l_responsibility_appl_id );
  lc_invoice_cancel_status:=xx_cancel_invoice(p_invoice_id);
  RETURN(lc_invoice_cancel_status);
END xx_ui_invoice_cancel;
-- +======================================================================+
-- | Name        :  xx_derive_upd_invoice_num                             |
-- | Description :  To derive invoice seq to Update invoice no ODBDUIA    |
-- |                                                                      |
-- | Parameters  :  p_invoice_num                                         |
-- |                                                                      |
-- | Returns     :  VARCHAR2                                              |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_derive_upd_invoice_num(p_invoice_num IN VARCHAR2) RETURN VARCHAR2
IS
CURSOR C1 IS
SELECT invoice_num
  FROM ap_invoices_all
 WHERE invoice_num like p_invoice_num||'ODDBUIA%' 
   AND vendor_id=gn_vendor_id
 ORDER BY SUBSTR(invoice_num, -1, 1) desc;
ln_cnt             NUMBER;
v_newinvoice     VARCHAR2(50);
v_seq             VARCHAR2(2);
ln_pos             NUMBER;
BEGIN
  SELECT count(1) 
    INTO ln_cnt
    FROM ap_invoices_all
   WHERE invoice_num like p_invoice_num||'ODDBUIA%'
     AND vendor_id=gn_vendor_id;
  IF ln_cnt=0 THEN
     v_newinvoice:=p_invoice_num||'ODDBUIA-1';
  ELSE
     FOR cur IN C1 LOOP
       v_newinvoice:=cur.invoice_num;
       EXIT;
     END LOOP;    
     ln_pos :=INSTR(v_newinvoice,'-');
     IF ln_pos=0 THEN
        v_newinvoice:=v_newinvoice||'-1';
     ELSE
       v_seq   :=SUBSTR(v_newinvoice,ln_pos+1);
       v_newinvoice:=SUBSTR(v_newinvoice,1,length(v_newinvoice)-1)||(TO_NUMBER(v_seq)+1);
     END IF;       
  END IF;
  RETURN(v_newinvoice);
EXCEPTION
  WHEN others THEN
    v_newinvoice:=NULL;
    RETURN(v_newinvoice);
END xx_derive_upd_invoice_num;
-- +======================================================================+
-- | Name        :  xx_upd_invoice_num                                    |
-- | Description :  To Update invoice no before cancelling the invoice    |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_cancel_type                           |
-- |                                                                      |
-- | Returns     :  p_error                                               |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_upd_invoice_num(p_invoice_id IN NUMBER)
IS
v_app_id          NUMBER;
v_error              VARCHAR2(1):='N';
v_invoice_num      VARCHAR2(50);
lc_inv_num          VARCHAR2(50);
BEGIN
  SELECT invoice_num 
    INTO lc_inv_num
    FROM ap_invoices_all
   WHERE invoice_id=p_invoice_id;
  v_invoice_num:=xx_derive_upd_invoice_num(lc_inv_num);
  BEGIN
    SELECT application_id 
      INTO v_app_id
      FROM fnd_application
     WHERE application_short_name='SQLAP';
  EXCEPTION
    WHEN others THEN
      v_app_id :=-1;
  END;
  IF v_app_id <> -1 THEN
    UPDATE ZX_LINES_SUMMARY
      SET trx_number=v_invoice_num
    WHERE trx_id=p_invoice_id
      AND APPLICATION_ID = v_app_id
      AND ENTITY_CODE ='AP_INVOICES'
      AND EVENT_CLASS_CODE ='STANDARD INVOICES';
    --IF SQL%NOTFOUND THEN
    --   v_error:='Y';
    --END IF;
    IF v_error='N' THEN
      UPDATE ZX_REC_NREC_DIST
         SET trx_number=v_invoice_num
       WHERE trx_id=p_invoice_id
         AND APPLICATION_ID = v_app_id
         AND ENTITY_CODE ='AP_INVOICES'
         AND EVENT_CLASS_CODE ='STANDARD INVOICES';
        --IF SQL%NOTFOUND THEN
      --   v_error:='Y';
      --END IF;
    END IF;     
    IF v_error='N' THEN
       UPDATE ZX_LINES_DET_FACTORS
          SET trx_number=v_invoice_num
        WHERE trx_id=p_invoice_id
          AND APPLICATION_ID = v_app_id
          AND ENTITY_CODE ='AP_INVOICES'
          AND EVENT_CLASS_CODE ='STANDARD INVOICES';
        --IF SQL%NOTFOUND THEN
      --   v_error:='Y';
      --END IF;
    END IF;     
    IF v_error='N' THEN
       UPDATE ZX_LINES
          SET trx_number=v_invoice_num
        WHERE trx_id=p_invoice_id
          AND APPLICATION_ID = v_app_id
          AND ENTITY_CODE ='AP_INVOICES'
          AND EVENT_CLASS_CODE ='STANDARD INVOICES';
        --IF SQL%NOTFOUND THEN
      --   v_error:='Y';
      --END IF;
    END IF;     
    IF v_error='N' THEN    
       xla_security_pkg.set_security_context(602); 
       UPDATE xla_transaction_entities
          SET transaction_number=v_invoice_num
        WHERE source_id_int_1=p_invoice_id
          AND APPLICATION_ID+0 = v_app_id
          AND ENTITY_CODE||'' ='AP_INVOICES';
        --IF SQL%NOTFOUND THEN
      --   v_error:='Y';
      --END IF;
    END IF;     
    IF v_error='N' THEN    
          UPDATE ap_invoices_all
          SET invoice_num=v_invoice_num
        WHERE invoice_id=p_invoice_id;
       IF SQL%NOTFOUND THEN
          v_error:='Y';
       END IF;
    END IF;     
  END IF;
  IF v_error='Y' THEN
     ROLLBACK;
  ELSE
     COMMIT;
  END IF;     
END xx_upd_invoice_num;
-- +======================================================================+
-- | Name        :  xx_call_payables_import                               |
-- | Description :  To submit payables open interface import              |
-- |                                                                      |
-- | Parameters  :  NULL                                                  |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_call_payables_import RETURN VARCHAR2
IS
    v_request_id           NUMBER;
    x_dummy                VARCHAR2(2000) ;
    v_dphase               VARCHAR2(100) ;
    v_dstatus              VARCHAR2(100) ;
    v_phase                VARCHAR2(100) ;
    v_status               VARCHAR2(100) ;
    v_error                   VARCHAR2(100);
BEGIN
fnd_file.put_line(fnd_file.log,' testing import');
  v_request_id  :=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APXIIMPT','Payables Open Interface',NULL,FALSE,
                    gn_org_id,gn_source,gn_grp_seq,'N/A',NULL,NULL,NULL,'N','N','N','N',1000,gn_created_by,-1,'N');
  IF v_request_id>0 THEN
     COMMIT;
     print_debug_msg('Request id : ' ||TO_CHAR(v_request_id));
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
        IF (v_dphase = 'COMPLETE' AND v_dstatus='NORMAL') THEN
           RETURN('SUCCESS');
        ELSIF (v_dphase = 'COMPLETE' AND v_dstatus<>'NORMAL') THEN
           RETURN('ERROR');           
        END IF;        
     END IF;
  ELSE
    RETURN('ERROR');
  END IF;
EXCEPTION
  WHEN others THEN
    v_error:=SUBSTR(SQLERRM,1,100);
    dbms_output.put_line('Error in xx_call_payables_import : '||SUBSTR(SQLERRM,1,100));
    RETURN('ERROR');
END xx_call_payables_import;  
-- +======================================================================+
-- | Name        :  get_misc_account                                      |
-- | Description :  To derive distribution acct from reason code mapping  |
-- |                                                                      |
-- | Parameters  :  p_invoice_id,p_po_line_no,p_reason_cd                 |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_misc_account(p_invoice_id IN NUMBER,p_line_no IN NUMBER,p_reason_cd IN VARCHAR2)
RETURN VARCHAR2
IS
lc_ln_company        VARCHAR2(10):=NULL;
lc_ln_cc            VARCHAR2(10):=NULL;
lc_ln_acct            VARCHAR2(10):=NULL;
lc_ln_loc            VARCHAR2(10):=NULL;
lc_ln_ic            VARCHAR2(10):=NULL;
lc_ln_lob            VARCHAR2(10):=NULL;
lc_ln_future        VARCHAR2(10):=NULL;    
lc_gl_company         VARCHAR2(10):= NULL;
lc_gl_cost_center     VARCHAR2(10):= NULL;
lc_gl_account         VARCHAR2(10):= NULL;
lc_gl_location         VARCHAR2(10):= NULL;
lc_gl_lob             VARCHAR2(10):= NULL;
lc_gl_segments        VARCHAR2(100);
ln_cnt                NUMBER:=0;
BEGIN
  BEGIN
    SELECT gcc.segment1,gcc.segment2,gcc.segment3,gcc.segment4,gcc.segment5,gcc.segment6,gcc.segment7
      INTO lc_ln_company,lc_ln_cc,lc_ln_acct,lc_ln_loc,lc_ln_ic,lc_ln_lob,lc_ln_future
      FROM gl_code_combinations gcc,
           ap_invoice_distributions_all f
     WHERE f.invoice_id =p_invoice_id
       and f.invoice_line_number=p_line_no
       and f.line_type_lookup_code='ACCRUAL'
       and gcc.code_combination_id=f.dist_code_combination_id
       and gcc.enabled_flag='Y';
  EXCEPTION
    WHEN others THEN 
      lc_ln_company:=NULL;
  END;
  BEGIN
    SELECT b.target_value4 GV_GL_Company,
           b.target_value5 GV_GL_Cost_Center,
           b.target_value6 GV_GL_Account,
           b.target_value7 GV_GL_Location,
           b.target_value8 GV_GL_LOB
      INTO lc_gl_company,
           lc_gl_cost_center,
           lc_gl_account,
           lc_gl_location,
           lc_gl_lob
      FROM xx_fin_translatevalues b, 
           xx_fin_translatedefinition a
     WHERE a.translation_name='OD_AP_REASON_CD_ACCT_MAP'
       AND b.translate_id=a.translate_id
       AND b.enabled_flag='Y'
       AND b.target_value1=p_reason_cd
       AND nvl(b.end_date_active,SYSDATE+1)>SYSDATE;
  EXCEPTION
    WHEN OTHERS THEN
      fnd_file.put_line(fnd_file.log,'Unable to get the new Invoice Line ID for new line');
  END;
  lc_gl_segments:=  NVL(lc_gl_company,lc_ln_company)||'.'||
                    NVL(lc_gl_cost_center,lc_ln_cc)||'.'||
                    NVL(lc_gl_account,lc_ln_acct)||'.'||
                    NVL(lc_gl_location,lc_ln_loc)||'.'||'0000'||'.'||
                    NVL(lc_gl_lob,lc_ln_lob)||'.'||'000000';
  SELECT COUNT(1)
    INTO ln_cnt
    FROM gl_code_combinations
   WHERE segment1=NVL(lc_gl_company,lc_ln_company)
     AND segment2=NVL(lc_gl_cost_center,lc_ln_cc)
     AND segment3=NVL(lc_gl_account,lc_ln_acct)     
     AND segment4=NVL(lc_gl_location,lc_ln_loc)     
     AND segment5='0000'     
     AND segment6=NVL(lc_gl_lob,lc_ln_lob)     
     AND segment7='000000'     
     AND enabled_flag='Y';
   IF ln_cnt=0 THEN
      lc_gl_segments:='1001.00000.20109000.010000.0000.90.000000';   
   END IF;
  RETURN(lc_gl_segments);                    
EXCEPTION
  WHEN others THEN
    RETURN(lc_gl_segments);
END get_misc_account;
-- +======================================================================+
-- | Name        :  get_po_uom                                            |
-- | Description :  To get po uom                                         |
-- |                                                                      |
-- | Parameters  :  po_po_line_id                                         |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_po_uom(p_po_line_id IN NUMBER)
RETURN VARCHAR2
IS
v_uom VARCHAR2(25);
BEGIN
  SELECT unit_meas_lookup_code
    INTO v_uom
    FROM po_lines_all
   WHERE po_line_id=p_po_line_id;
  RETURN(v_uom);
EXCEPTION
  WHEN others THEN
    v_uom:=NULL;  
    RETURN(v_uom);
END get_po_uom;

-- +======================================================================+
-- | Name        :  get_po_uom                                            |
-- | Description :  To get po uom                                         |
-- |                                                                      |
-- | Parameters  :  po_po_line_id                                         |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_po_item_desc(p_po_line_id IN NUMBER)
RETURN VARCHAR2
IS
v_desc VARCHAR2(240);
BEGIN
  SELECT item_description
    INTO v_desc
    FROM po_lines_all
   WHERE po_line_id=p_po_line_id;
  RETURN(v_desc);
EXCEPTION
  WHEN others THEN
    v_desc:=NULL;  
    RETURN(v_desc);
END get_po_item_desc;

-- +======================================================================+
-- | Name        :  get_unmatch_acct                                      |
-- | Description :  To get the accrual account from po_distributions      |
-- |                                                                      |
-- | Parameters  :  po_po_line_id                                         |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_unmatch_acct(p_po_line_id IN NUMBER) 
RETURN NUMBER
IS
v_ccid NUMBER:=0;
BEGIN
  SELECT code_combination_id
    INTO v_ccid
    FROM po_distributions_all
   WHERE po_line_id=p_po_line_id;
  RETURN(v_ccid);
EXCEPTION
  WHEN others THEN
    v_ccid:=NULL;
    RETURN(v_ccid);
END get_unmatch_acct;
-- +======================================================================+
-- | Name        :  xx_create_invoice                                     |
-- | Description :  To create invoice                                     |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION  XX_CREATE_INVOICE(P_INVOICE_ID NUMBER, p_chbk_flag IN VARCHAR2) RETURN VARCHAR2
IS 
    CURSOR C1_Header(p_invoice_id NUMBER)
    IS
       SELECT a.invoice_id xx_invoice_id,
              a.org_id,
              a.invoice_num xx_invoice_num,
              b.last_updated_by last_updated_by,
              b.last_update_date last_update_date,
              b.created_by created_by,
              b.creation_date creation_date,
              ph.segment1 po_num,              
              b.invoice_type_lookup_code org_invoice_type_lookup_code,
              b.invoice_date org_invoice_date,
              b.vendor_id org_vendor_id,
              b.vendor_site_id org_vendor_site_id,
              b.invoice_amount org_invoice_amount,
              b.invoice_currency_code org_invoice_currency_code,
              b.terms_id org_terms_id,
              b.description org_description,
              b.attribute7 org_attribute7,
              b.source org_source,
              b.payment_method_code org_payment_method_code,
              b.pay_group_lookup_code org_pay_group_lookup_code,
              b.org_id org_org_id,
              b.goods_received_date org_goods_received_date,
              b.invoice_amount org_amount,
              b.invoice_id,
              b.terms_date,
              b.invoice_received_date,
              b.voucher_num,
              b.gl_date,
              b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute5,b.attribute6,b.attribute8,
              b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,b.attribute14,b.attribute15
        FROM  po_headers_all ph,             
              ap_invoices_all b,
              xx_ap_chbk_action_hdr a            
        WHERE a.invoice_id=p_invoice_id
          AND a.invoice_id=b.invoice_id
          AND ph.po_header_id=NVL(quick_po_header_id,b.po_header_id);
    CURSOR C2_No_Holds(p_invoice_id NUMBER)
    IS
      SELECT a.invoice_id,
             a.line_number, 
             a.line_type_lookup_code,      
             a.quantity_invoiced, 
             a.invoice_price unit_price,a.reason_code,  
             a.po_qty,a.rcv_qty,a.org_invoice_qty,a.uom
        FROM         
          xx_ap_chbk_action_dtl a
       WHERE a.invoice_id=p_invoice_id
         AND a.unmatch_po_flag='N'
       AND a.hold_exists_flag='N'      
         AND a.LINE_TYPE_LOOKUP_CODE='ITEM' 
            AND NOT EXISTS (SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                        )
       ORDER BY a.line_number;            
CURSOR C2_No_Holds_dtl(p_invoice_id NUMBER,p_line_num IN NUMBER)
    IS
      SELECT  
             b.description,
             b.org_id,
             b.inventory_item_id,
             --b.item_description,
             get_po_item_desc(b.po_line_id) item_description,
             b.prorate_across_all_items,
             get_po_uom(b.po_line_id) unit_meas_lookup_code,
             --b.unit_meas_lookup_code, -- to be uom 
             b.creation_date, 
             b.created_by, 
             b.last_updated_by, 
             b.last_update_date, 
             b.attribute1,b.attribute2,b.attribute3,b.attribute4,
             b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,b.attribute14,b.attribute15
        FROM po_distributions_all d,
             ap_invoice_distributions_all c,      
             ap_invoice_lines_all b 
       WHERE  
           b.invoice_id=p_invoice_id
         AND b.line_number=p_line_num
         AND b.invoice_id=c.invoice_id           
         AND b.line_number=c.invoice_line_number  
         AND c.line_type_lookup_code='ACCRUAL'
         AND b.line_type_lookup_code='ITEM'
         AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
         AND c.po_distribution_id=d.po_distribution_id;                   
    CURSOR C3_PARENT(p_invoice_id NUMBER)
    IS
      SELECT a.invoice_id , 
             a.line_number,
             d.dist_code_combination_id
        FROM po_distributions_all e,
             ap_invoice_distributions_all d,      
             ap_invoice_lines_all c,                          
             xx_ap_chbk_action_dtl a             
       WHERE a.invoice_id=p_invoice_id
         AND a.unmatch_po_flag='N'
         AND a.hold_exists_flag='Y'      
         AND a.LINE_TYPE_LOOKUP_CODE='ITEM'
         AND a.invoice_id=c.invoice_id
         AND a.line_number=c.line_number
         AND c.invoice_id=d.invoice_id           
         AND c.line_number=d.invoice_line_number  
         AND d.line_type_lookup_code='ACCRUAL'
         AND c.line_type_lookup_code='ITEM'
         AND (d.CANCELLATION_FLAG IS NULL or d.CANCELLATION_FLAG='N')
         AND d.po_distribution_id=e.po_distribution_id   
         AND NVL(a.quantity_invoiced,0)>0
      ORDER BY 2;
    CURSOR C3_Lines1(p_invoice_id NUMBER,p_Line_Number NUMBER)
    IS
    SELECT a.line_number, 
           a.hold_lookup_code,    
           b.description,
           b.line_type_lookup_code,
           a.unmatched_qty,
           a.unit_price,                
           NVL(a.chargeback,'N') chargeback,
           b.inventory_item_id,
           --b.item_description,
           get_po_item_desc(b.po_Line_id) item_description,
           b.prorate_across_all_items,
           --a.uom unit_meas_lookup_code,
           get_po_uom(b.po_line_id) unit_meas_lookup_code, -- Added to use po uom
           a.org_uom,
           b.org_id,           
           a.reason_code, 
           b.created_by, 
           b.creation_date, 
           b.last_updated_by, 
           b.last_update_date,
           b.attribute1,b.attribute2,b.attribute3,b.attribute4,a.po_qty,a.rcv_qty,a.org_invoice_qty,
           b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,b.attribute14,b.attribute15    
      FROM po_distributions_all d,
           ap_invoice_distributions_all c,      
           ap_invoice_lines_all b,
           xx_ap_chbk_action_holds a         
     WHERE a.invoice_id=p_invoice_id
       AND a.Line_Number=p_Line_Number
       AND a.hold_lookup_code IS NOT NULL      
       AND a.invoice_id=b.invoice_id
       AND a.line_number=b.line_number
       AND b.invoice_id=c.invoice_id           
       AND b.line_number=c.invoice_line_number  
       AND c.line_type_lookup_code='ACCRUAL'
       AND b.line_type_lookup_code='ITEM'
       AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
       AND c.po_distribution_id=d.po_distribution_id 
       AND NVL(a.unmatched_qty,0) > 0
       AND a.hold_lookup_code NOT IN ('MAX SHIP AMOUNT','PO NOT APPROVED')
       AND NOT EXISTS ( SELECT 'x'
                          FROM xx_ap_chbk_action_holds
                         WHERE invoice_id=a.invoice_id  
                           AND line_number=a.line_number
                           AND hold_lookup_code IS NULL
                      )
       ORDER BY a.hold_lookup_code desc;
    CURSOR qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
    IS
     SELECT a.line_number, 
            b.description,
            a.unmatched_qty, 
            NVL(a.unit_price,a.org_invoice_price) unit_price,     
            b.inventory_item_id,
            --b.item_description,
            get_po_item_desc(b.po_line_id) item_description,
            a.reason_code, 
            b.org_id,
            a.po_qty,
            a.rcv_qty,
            a.org_invoice_qty,
            b.created_by, 
            b.creation_date, 
            b.last_updated_by, 
            b.last_update_date,
            NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
            b.prorate_across_all_items,
            --a.uom unit_meas_lookup_code,
            get_po_uom(b.po_line_id) unit_meas_lookup_code,
            b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,
            b.attribute8,b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,
            b.attribute14,b.attribute15,a.chargeback
       FROM po_distributions_all d,
            ap_invoice_distributions_all c,      
            ap_invoice_lines_all b,
            xx_ap_chbk_action_holds a         
      WHERE a.invoice_id=p_invoice_id
        AND a.line_number=p_line_number
        AND NVL(a.unmatched_qty,0) > 0
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND c.invoice_id           =b.invoice_id
        AND c.invoice_line_number  =b.line_number
        AND c.line_type_lookup_code='ACCRUAL'
        AND b.line_type_lookup_code='ITEM'
        AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
        AND d.po_distribution_id   =c.po_distribution_id
        AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE'
        AND NOT EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                AND hold_lookup_code='PRICE'
                       )
        AND     EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND hold_lookup_code IS NULL
                            AND NVL(unmatched_qty,0)>=0
                       )                       
    ORDER BY a.hold_lookup_code;                       
    CURSOR price_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
    IS
     SELECT a.line_number, 
            b.description,
            SUM(NVL(a.unmatched_qty,0)) unmatched_qty, 
            SUM(a.unit_price) unit_price,     
            b.inventory_item_id,
            --b.item_description,
            get_po_item_desc(b.po_line_id) item_description,
            b.org_id,
            a.po_qty,
            a.rcv_qty,
            a.org_invoice_qty,
            b.created_by, 
            b.creation_date, 
            b.last_updated_by, 
            b.last_update_date,
            b.prorate_across_all_items,
            --a.uom unit_meas_lookup_code,
            get_po_uom(b.po_line_id) unit_meas_lookup_code,
            b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,
            b.attribute8,b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,
            b.attribute14,b.attribute15
       FROM po_distributions_all d,
            ap_invoice_distributions_all c,      
            ap_invoice_lines_all b,
            xx_ap_chbk_action_holds a         
      WHERE a.invoice_id=p_invoice_id
        AND a.line_number=p_line_number
        AND NVL(a.hold_lookup_code,'SPLIT') NOT LIKE 'QTY%'
        AND a.unit_price IS NOT NULL
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND c.invoice_id           =b.invoice_id
        AND c.invoice_line_number  =b.line_number
        AND c.line_type_lookup_code='ACCRUAL'
        AND b.line_type_lookup_code='ITEM'
        AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
        AND d.po_distribution_id   =c.po_distribution_id
        AND     EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND hold_lookup_code IS NULL
                            AND NVL(unit_price,0)>0
                       )        
   GROUP BY a.line_number, 
            b.description,
            b.inventory_item_id,
            get_po_item_desc(b.po_line_id),
            b.org_id,
            a.po_qty,
            a.rcv_qty,
            a.org_invoice_qty,
            b.created_by, 
            b.creation_date, 
            b.last_updated_by, 
            b.last_update_date,
            b.prorate_across_all_items,
            get_po_uom(b.po_line_id),
            b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,
            b.attribute8,b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,
            b.attribute14,b.attribute15;
    CURSOR price_qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
    IS
     SELECT a.line_number, 
            b.description,
            a.unmatched_qty, 
            NVL(a.unit_price,a.org_invoice_price) unit_price,     
            b.inventory_item_id,
            --b.item_description,
            get_po_item_desc(b.po_line_id) item_description,
            a.reason_code, 
            b.org_id,
            a.po_qty,
            a.rcv_qty,
            a.org_invoice_qty,
            b.created_by, 
            b.creation_date, 
            b.last_updated_by, 
            b.last_update_date,
            NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
            b.prorate_across_all_items,
            --a.uom unit_meas_lookup_code,
            get_po_uom(b.po_line_id) unit_meas_lookup_code,
            b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,
            b.attribute8,b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,
            b.attribute14,b.attribute15,a.chargeback
       FROM po_distributions_all d,
            ap_invoice_distributions_all c,      
            ap_invoice_lines_all b,
            xx_ap_chbk_action_holds a         
      WHERE a.invoice_id=p_invoice_id
        AND a.line_number=p_line_number
        AND NVL(a.unmatched_qty,0) > 0
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND c.invoice_id           =b.invoice_id
        AND c.invoice_line_number  =b.line_number
        AND c.line_type_lookup_code='ACCRUAL'
        AND b.line_type_lookup_code='ITEM'
        AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
        AND d.po_distribution_id   =c.po_distribution_id
        AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE'
      ORDER BY NVL(a.hold_lookup_code,'SPLIT');

    CURSOR noprice_qty_split(p_invoice_id NUMBER,p_Line_Number NUMBER)
    IS
     SELECT a.line_number, 
            b.description,
            a.unmatched_qty, 
            NVL(a.unit_price,a.org_invoice_price) unit_price,     
            b.inventory_item_id,
            --b.item_description,
            get_po_item_desc(b.po_line_id) item_description,
            a.reason_code, 
            b.org_id,
            a.po_qty,
            a.rcv_qty,
            a.org_invoice_qty,
            b.created_by, 
            b.creation_date, 
            b.last_updated_by, 
            b.last_update_date,
            NVL(a.hold_lookup_code,'SPLIT') hold_lookup_code,
            b.prorate_across_all_items,
            --a.uom unit_meas_lookup_code,
            get_po_uom(b.po_line_id) unit_meas_lookup_code,
            b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,
            b.attribute8,b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,
            b.attribute14,b.attribute15,a.chargeback
       FROM po_distributions_all d,
            ap_invoice_distributions_all c,      
            ap_invoice_lines_all b,
            xx_ap_chbk_action_holds a         
      WHERE a.invoice_id=p_invoice_id
        AND a.line_number=p_line_number
        AND NVL(a.unmatched_qty,0) > 0
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND a.invoice_id=b.invoice_id
        AND a.line_number=b.line_number
        AND c.invoice_id           =b.invoice_id
        AND c.invoice_line_number  =b.line_number
        AND c.line_type_lookup_code='ACCRUAL'
        AND b.line_type_lookup_code='ITEM'
        AND (c.CANCELLATION_FLAG IS NULL or c.CANCELLATION_FLAG='N')
        AND d.po_distribution_id   =c.po_distribution_id
        AND NVL(a.hold_lookup_code,'SPLIT')<>'PRICE'
      ORDER BY NVL(a.hold_lookup_code,'SPLIT');
      
      
    CURSOR C_unm_poline(p_invoice_id NUMBER)
    IS
       SELECT a.invoice_id, 
              a.quantity_invoiced,                     
              a.invoice_price,                 
              a.po_line_no    ,
              a.po_header_id,
              a.po_line_id,
              a.inventory_item_id,
              a.sku_desc,
              a.line_number,
              a.po_qty,
              a.rcv_qty,
              a.org_invoice_qty,
              get_po_uom(a.po_line_id) unit_meas_lookup_code
         FROM xx_ap_chbk_action_dtl a
        WHERE a.invoice_id=p_invoice_id
          AND a.unmatch_po_flag='Y'    
          AND NVL(a.quantity_invoiced,0)<>0
      ORDER BY a.line_number;
    CURSOR C3_Freight(p_invoice_id NUMBER)
    IS
    SELECT a.line_number, 
           a.reason_code, 
           a.line_type_lookup_code ,
           b.created_by, 
           b.creation_date, 
           b.last_updated_by, 
           b.last_update_date,
           c.dist_code_combination_id,
           b.org_id,
           b.amount,
           b.description,
           b.prorate_across_all_items,
           b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,b.attribute8,
           b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,b.attribute14,b.attribute15,
           NVL(a.chargeback,'N') chargeback
      FROM ap_invoice_distributions_all c,
           ap_invoice_lines_all b,
           xx_ap_chbk_action_dtl a
     WHERE a.invoice_id=p_invoice_id
       AND a.line_type_lookup_code='FREIGHT'
       AND a.invoice_id=b.invoice_id
       AND a.line_number=b.line_number
       AND NVL(a.new_line_flag,'X')='N'       
       AND b.invoice_id=c.invoice_id             
       AND b.line_number=c.invoice_line_number    
       AND b.line_type_lookup_code='FREIGHT'
       AND c.line_type_lookup_code='FREIGHT'
       AND (c.cancellation_flag IS NULL or c.cancellation_flag='N')
     ORDER BY 1;
    CURSOR C_misc(p_invoice_id NUMBER)
    IS
    SELECT a.line_number, 
           a.reason_code, 
           a.line_type_lookup_code ,
           b.created_by, 
           b.creation_date, 
           b.last_updated_by, 
           b.last_update_date,
           c.dist_code_combination_id,
           b.org_id,
           b.amount,
           b.description,
           b.prorate_across_all_items,
           b.attribute1,b.attribute2,b.attribute3,b.attribute4,b.attribute6,b.attribute7,b.attribute8,
           b.attribute9,b.attribute10,b.attribute11,b.attribute12,b.attribute13,b.attribute14,b.attribute15,
           NVL(a.chargeback,'N') chargeback
      FROM ap_invoice_distributions_all c,
           ap_invoice_lines_all b,
           xx_ap_chbk_action_dtl a
     WHERE a.invoice_id=p_invoice_id
       AND a.line_type_lookup_code='MISCELLANEOUS'
       AND a.invoice_id=b.invoice_id
       AND a.line_number=b.line_number
       AND b.invoice_id=c.invoice_id             
       AND b.line_number=c.invoice_line_number    
       AND b.line_type_lookup_code='MISCELLANEOUS'
       AND c.line_type_lookup_code='MISCELLANEOUS'
       AND NVL(a.new_line_flag,'X')='N'
       AND (c.cancellation_flag IS NULL or c.cancellation_flag='N')
      ORDER BY 1;
    CURSOR new_line(p_invoice_id NUMBER)       
    IS
    SELECT a.line_number, 
           a.reason_code, 
           a.line_type_lookup_code ,
           a.line_amount
      FROM xx_ap_chbk_action_dtl a
     WHERE a.invoice_id=p_invoice_id
       AND a.new_line_flag='Y'
       AND a.line_type_lookup_code IN ('FREIGHT','MISCELLANEOUS')
      ORDER BY 1;
   ln_interface_line_count     NUMBER :=1;
   ln_grp_seq                 NUMBER;
   v_request_id               NUMBER;  
   v_invoice_id             NUMBER;
   lc_inv_ins_status         VARCHAR2(10):='SUCCESS';
   lc_acct_segments         VARCHAR2(100);
   lc_error_message         VARCHAR2(200);  
   lc_line_type                VARCHAR2(20);
   ln_item_line                NUMBER;
   ln_line_qty_price        NUMBER;
   ln_qty_hold                NUMBER;
   ln_ccid                    NUMBER;
   lc_uom_change            VARCHAR2(1);
   lc_reason_code            VARCHAR2(10);
   ln_price_split        NUMBER;
   ln_qty_split        NUMBER;
   ln_price_exists   NUMBER;
   
   BEGIN
   gin_invoice_id:=NULL; ----2.4# Added by Chandra for defect #NAIT-41954
    SELECT ap_invoices_interface_s.NEXTVAL 
      INTO v_invoice_id
      FROM dual;
     gin_invoice_id :=v_invoice_id; ----2.4# Added by Chandra for defect #NAIT-41954
    BEGIN  -- to be removed later
        SELECT XX_AP_CHBK_IMPORT_SEQ.nextval INTO gn_grp_seq FROM dual;
    EXCEPTION
        WHEN others THEN
        print_debug_msg('Error in xx_ap_chbk_import_seq :'||SUBSTR(SQLERRM,1,100));      
    END;
    FOR curhdr IN C1_Header(p_invoice_id) 
    LOOP  
        FOR CURNoHolds IN C2_No_Holds(p_invoice_id)
        LOOP 
          FOR CURNoHoldsdtl IN C2_no_holds_dtl(curnoholds.invoice_id,curnoholds.line_number)
          LOOP
            BEGIN
              INSERT
                INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                    quantity_invoiced,
                    inventory_item_id,
                    item_description,
                    attribute5,
                    unit_price,
                    prorate_across_flag,
                   --- accounting_date, --Defect#45000
                    unit_of_meas_lookup_code,
                    attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                    attribute8,attribute9,attribute10,attribute11,attribute12,attribute13,
                    attribute14,attribute15
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,                    
                    CURNoHolds.line_type_lookup_code,
                    ROUND((CURNoHolds.QUANTITY_INVOICED*CURNoHolds.unit_price),2),
                    CURNoHoldsdtl.description,
                    NULL, --CURNoHolds.dist_code_combination_id,
                    gn_user_id, 
                    CURNoHoldsdtl.creation_date,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    CURNoHoldsdtl.ORG_ID,
                    CURNoHolds.quantity_invoiced,
                    CURNoHoldsdtl.inventory_item_id,
                    CURNoHoldsdtl.item_description,
                    CURNoHolds.line_number,
                    CURNoHolds.unit_price,
                    CURNoHoldsdtl.prorate_across_all_items,
                  --  SYSDATE,            -- Accounting Date  --Defect#45000
                    CURNoHoldsdtl.unit_meas_lookup_code,  -- Added to use po uom
                    CURNoHoldsdtl.attribute1,CURNoHoldsdtl.attribute2,NULL,CURNoHoldsdtl.attribute4,CURNoHolds.po_qty,CURNoHolds.rcv_qty,
                    CURNoHolds.org_invoice_qty,CURNoHoldsdtl.attribute9,NULL,CURNoHoldsdtl.attribute11,CURNoHoldsdtl.attribute12,CURNoHoldsdtl.attribute13,
                    CURNoHoldsdtl.attribute14,CURNoHoldsdtl.attribute15
                  );
            EXCEPTION
              WHEN OTHERS THEN
                ROLLBACK;
                lc_inv_ins_status:='ERROR';
                lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                BEGIN
                  INSERT
                    INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                  VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,CURNoHolds.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                EXCEPTION
                  WHEN OTHERS THEN
                    print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                 END;
                COMMIT;     
            END;                  
            ln_interface_line_count := ln_interface_line_count + 1;
          END LOOP;
        END LOOP;
        FOR curparent IN C3_PARENT(p_invoice_id) LOOP  
            FOR CURLines1 IN C3_Lines1(p_invoice_id,curparent.line_number) 
            LOOP 
              lc_reason_code:=NULL;
              IF CURLines1.chargeback='N' THEN
                 IF CURLines1.hold_lookup_code IN ('PRICE','OD Max Price') THEN
                    lc_reason_code:='PD';
                 END IF;
              END IF; 

              --IF CURLines1.unit_meas_lookup_code<>CURLines1.org_uom THEN
                 --lc_uom_change:='Y';
              --ELSE
                 --lc_uom_change:=NULL;
              --END IF;
              BEGIN
                INSERT
                INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                    quantity_invoiced,
                    inventory_item_id,
                    item_description,
                    attribute5,
                    unit_price,
                    prorate_across_flag,
                   --- accounting_date,  ----Defect#45000
                    unit_of_meas_lookup_code,
                    attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                    attribute8,attribute9,attribute10,attribute11,attribute12,attribute13,
                    attribute14,attribute15
                  )
                VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,                    
                    CURLines1.line_type_lookup_code,
                    ROUND((CURLines1.unmatched_qty*CURLines1.unit_price),2),   -- check with Naveen
                    CURLines1.description,
                    NULL, --CURLines1.dist_code_combination_id,
                    gn_user_id,
                    CURLines1.creation_date,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    curlines1.org_id,
                    CURLines1.unmatched_qty,
                    CURLines1.inventory_item_id,
                    CURLines1.item_description,
                    CURLines1.line_number,
                    CURLines1.unit_price,
                    CURLines1.prorate_across_all_items,
                   -- SYSDATE,  --Defect#45000
                    CURLines1.unit_meas_lookup_code,
                    CURLines1.attribute1,CURLines1.attribute2,NULL,CURLines1.org_uom,CURLines1.po_qty,CURLines1.rcv_qty,
                    CURLines1.org_invoice_qty,CURLines1.attribute9,NULL,
                    DECODE(lc_reason_code,NULL,CURLines1.attribute11,lc_reason_code),  
                    CURLines1.attribute12,
                    CURLines1.attribute13,
                    CURLines1.attribute14,CURLines1.attribute15
                  );
              EXCEPTION
                  WHEN OTHERS THEN                    
                  ROLLBACK;
                  lc_inv_ins_status:='ERROR';
                  lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                  BEGIN
                     INSERT
                      INTO xx_ap_uiaction_errors
                          (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                    VALUES
                          (curhdr.xx_invoice_num,curhdr.invoice_id,CURLines1.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                  EXCEPTION
                     WHEN others THEN
                      print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                  END;
                  COMMIT;    
              END;
              ln_interface_line_count := ln_interface_line_count + 1;
              EXIT;
            END LOOP;
        END LOOP; --C3_Parent            
        FOR curparent IN c3_parent(p_invoice_id) LOOP
            FOR qs IN qty_split(p_invoice_id,curparent.Line_Number) 
            LOOP             
              lc_line_type:=NULL;
              IF qs.hold_lookup_code LIKE 'QTY%' THEN
                 ln_line_qty_price:=qs.unit_price;
              END IF;
              IF (qs.reason_code IS NULL AND qs.hold_lookup_code LIKE 'QTY%') THEN
                 lc_line_type:='ITEM';
              ELSIF qs.reason_code IS NOT NULL AND qs.hold_lookup_code LIKE 'SP%' THEN
                 lc_line_type:='MISCELLANEOUS';
                 lc_acct_segments:=get_misc_account(p_invoice_id,qs.line_number,qs.reason_code);  
                 ln_ccid:=get_acct_id(lc_acct_segments);
              ELSIF  (qs.unmatched_qty>0 AND qs.hold_lookup_code LIKE 'SP%' AND qs.chargeback IS NOT NULL AND qs.reason_code IS NULL ) THEN
                 lc_line_type:='MISCELLANEOUS';
                 ln_ccid:=curparent.dist_code_combination_id;
              END IF;
              BEGIN
                INSERT
                INTO ap_invoice_lines_interface
                  ( invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    quantity_invoiced,
                    unit_price,
                    description,
                    dist_code_combination_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    attribute11,                
                    inventory_item_id,
                    item_description,
                    attribute5,                  
                    amount,
                   -- accounting_date, ----Defect#45000
                    prorate_across_flag,
                    attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                    attribute8,attribute9,attribute10,attribute12,attribute13,
                    attribute14,attribute15,
                    unit_of_meas_lookup_code
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,                    
                    lc_line_type,
                    DECODE(lc_line_type,'MISCELLANEOUS',NULL,qs.unmatched_qty),
                    DECODE(lc_line_type,'MISCELLANEOUS',NULL,NVL(ln_line_qty_price,qs.unit_price)),                    
                    qs.description,
                    DECODE(lc_line_type,'MISCELLANEOUS',ln_ccid,NULL),
                    gn_user_id,
                    qs.creation_date,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    qs.org_id,
                    qs.reason_code,               
                    --DECODE(lc_line_type,'MISCELLANEOUS',NULL,qs.inventory_item_id),
                    --DECODE(lc_line_type,'MISCELLANEOUS',NULL,qs.item_description),
                    qs.inventory_item_id,
                    qs.item_description,
                    qs.line_number,                
                    ROUND((qs.unmatched_qty*NVL(ln_line_qty_price,qs.unit_price)),2),
                  ---  SYSDATE,  --Defect#45000
                    qs.prorate_across_all_items,
                    qs.attribute1,qs.attribute2,NULL,qs.attribute4,qs.po_qty,qs.rcv_qty,
                    qs.org_invoice_qty,DECODE(lc_line_type,'MISCELLANEOUS',qs.unmatched_qty,NULL),
                    NULL,qs.attribute12,qs.attribute13,
                    qs.attribute14,qs.attribute15,
                    DECODE(lc_line_type,'MISCELLANEOUS',NULL,qs.unit_meas_lookup_code)                    
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
              EXCEPTION 
                WHEN OTHERS THEN                    
                  ROLLBACK;
                  lc_inv_ins_status:='ERROR';
                  lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                  BEGIN
                    INSERT
                    INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                    VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,qs.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                  EXCEPTION
                    WHEN OTHERS THEN
                      print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                  END;
                  COMMIT;                        
              END;                  
            END LOOP;
        END LOOP; --C3_PARENT        
        -- Price Split
        FOR curparent IN C3_PARENT(p_invoice_id) LOOP
            FOR ps IN price_split(p_invoice_id,curparent.Line_Number) 
            LOOP                 
              SELECT COUNT(1)
                INTO ln_qty_hold
                FROM xx_ap_chbk_action_holds
               WHERE invoice_id=p_invoice_id
                 AND line_number=ps.line_number
                 AND hold_lookup_code IN ('QTY REC','QTY ORD');
            IF ln_qty_hold = 0 THEN
                 BEGIN
                   INSERT
                     INTO ap_invoice_lines_interface
                        (     invoice_id,
                            invoice_line_id,
                            line_number,
                            line_type_lookup_code,
                            amount,
                            description,
                            created_by,
                            creation_date,
                            last_updated_by,
                            last_update_date,
                            last_update_login,
                            org_id,
                            quantity_invoiced,
                            inventory_item_id,
                            item_description,
                            attribute5,
                            unit_price,
                            prorate_across_flag,
                          ---  accounting_date,  --Defect#45000
                            unit_of_meas_lookup_code,
                            attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                            attribute8,attribute9,attribute10,attribute11,attribute12,attribute13,
                            attribute14,attribute15
                        )
                   VALUES
                        (     v_invoice_id,
                            ap_invoice_lines_interface_s.nextval,
                            ln_interface_line_count,                    
                            'ITEM',
                            ROUND((ps.unmatched_qty*ps.unit_price),2),
                            ps.description,
                            gn_user_id,
                            ps.creation_date,
                            gn_user_id,
                            SYSDATE,
                            -1,
                            ps.org_id,
                            ps.unmatched_qty,
                            ps.inventory_item_id,
                            ps.item_description,
                            ps.line_number,
                            ps.unit_price,
                            ps.prorate_across_all_items,
                           -- SYSDATE, --Defect#45000
                            ps.unit_meas_lookup_code,
                            ps.attribute1,ps.attribute2,NULL,ps.attribute4,ps.po_qty,ps.rcv_qty,
                            ps.org_invoice_qty,ps.attribute9,NULL,ps.attribute11,ps.attribute12,ps.attribute13,
                            ps.attribute14,ps.attribute15
                        ); 
                     COMMIT;
                    EXCEPTION
                   WHEN OTHERS THEN                    
                     ROLLBACK;
                     lc_inv_ins_status:='ERROR';
                     lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                     BEGIN
                        INSERT
                         INTO xx_ap_uiaction_errors
                             (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                       VALUES
                             (curhdr.xx_invoice_num,curhdr.invoice_id,ps.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                     EXCEPTION
                        WHEN others THEN
                         print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                     END;
                 END;
                 ln_interface_line_count := ln_interface_line_count + 1;
              ELSE 
                FOR pqs IN price_qty_split(p_invoice_id,curparent.Line_Number) 
                LOOP
                    lc_line_type:=NULL;
                    IF pqs.hold_lookup_code LIKE 'QTY%' THEN
                       ln_line_qty_price:=pqs.unit_price;
                    END IF;
                    IF (pqs.reason_code IS NULL AND pqs.hold_lookup_code LIKE 'QTY%') THEN  --OR  (pqs.unmatched_qty>0 AND pqs.hold_lookup_code LIKE 'SP%'  AND pqs.reason_code IS NULL ) THEN
                        lc_line_type:='ITEM';
                    ELSIF pqs.reason_code IS NOT NULL AND pqs.hold_lookup_code LIKE 'SP%' THEN
                        lc_line_type:='MISCELLANEOUS';
                        lc_acct_segments:=get_misc_account(p_invoice_id,pqs.line_number,pqs.reason_code);
                        ln_ccid:=get_acct_id(lc_acct_segments);
                    ELSIF  (pqs.unmatched_qty>0 AND pqs.hold_lookup_code LIKE 'SP%' AND pqs.chargeback IS NOT NULL AND pqs.reason_code IS NULL ) THEN
                        lc_line_type:='MISCELLANEOUS';
                        ln_ccid:=curparent.dist_code_combination_id;
                    END IF; 
                    BEGIN
                      INSERT
                        INTO ap_invoice_lines_interface
                              ( invoice_id,
                                invoice_line_id,
                                line_number,
                                line_type_lookup_code,
                                quantity_invoiced,
                                unit_price,
                                description,
                                dist_code_combination_id,
                                created_by,
                                creation_date,
                                last_updated_by,
                                last_update_date,
                                last_update_login,
                                org_id,
                                attribute11,                
                                inventory_item_id,
                                item_description,
                                attribute5,                  
                                amount,  
                              ---  accounting_date,   --Defect#45000
                                prorate_across_flag,
                                attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                                attribute8,attribute9,attribute10,attribute12,attribute13,
                                attribute14,attribute15,
                                unit_of_meas_lookup_code
                              )
                      VALUES
                              ( v_invoice_id,
                                ap_invoice_lines_interface_s.nextval,
                                ln_interface_line_count,                    
                                lc_line_type,
                                DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.unmatched_qty),
                                DECODE(lc_line_type,'MISCELLANEOUS',NULL,NVL(ln_line_qty_price,pqs.unit_price)),                                            pqs.description,
                                DECODE(lc_line_type,'MISCELLANEOUS',ln_ccid,NULL),
                                gn_user_id,
                                pqs.creation_date,
                                gn_user_id,
                                SYSDATE,
                                -1,
                                pqs.org_id,
                                pqs.reason_code,               
                                --DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.inventory_item_id),
                                --DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.item_description),
                                pqs.inventory_item_id,
                                pqs.item_description,
                                pqs.line_number,                
                                ROUND((pqs.unmatched_qty*(NVL(ln_line_qty_price,pqs.unit_price))),2),
                               --- SYSDATE,  --Defect#45000
                                pqs.prorate_across_all_items,
                                pqs.attribute1,pqs.attribute2,NULL,pqs.attribute4,pqs.po_qty,pqs.rcv_qty,
                                pqs.org_invoice_qty,DECODE(lc_line_type,'MISCELLANEOUS',pqs.unmatched_qty,NULL),
                                NULL,pqs.attribute12,pqs.attribute13,
                                pqs.attribute14,pqs.attribute15,DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.unit_meas_lookup_code)                
                              );
                      ln_interface_line_count := ln_interface_line_count + 1;
                 COMMIT;    
                 EXCEPTION 
                      WHEN OTHERS THEN                    
                        ROLLBACK;
                        lc_inv_ins_status:='ERROR';
                        lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                        BEGIN
                          INSERT
                            INTO xx_ap_uiaction_errors
                            (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                          VALUES
                            (curhdr.xx_invoice_num,curhdr.invoice_id,pqs.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                        EXCEPTION
                          WHEN OTHERS THEN
                            print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                        END;
                    END;                  
                END LOOP;
              END IF;  --IF ln_qty_hold = 0 THEN              
           END LOOP; 
           SELECT COUNT(1)
             INTO ln_price_split
             FROM xx_ap_chbk_action_holds
            WHERE invoice_id=p_invoice_id
              AND line_number=curparent.line_number
              AND unit_price>0
              AND hold_lookup_code IS NULL;
       
           SELECT COUNT(1)
             INTO ln_qty_split
             FROM xx_ap_chbk_action_holds
            WHERE invoice_id=p_invoice_id
              AND line_number=curparent.line_number
              AND unmatched_qty>=0
              AND hold_lookup_code IS NULL;
              
           SELECT COUNT(1)
             INTO ln_price_exists
             FROM xx_ap_chbk_action_holds
            WHERE invoice_id=p_invoice_id
              AND line_number=curparent.line_number
              AND hold_lookup_code='PRICE';              
       
           IF (ln_price_split=0 AND ln_qty_split>0 AND ln_price_exists>0) THEN
           
           FOR pqs IN noprice_qty_split(p_invoice_id,curparent.Line_Number) 
           LOOP
             lc_line_type:=NULL;
             IF pqs.hold_lookup_code LIKE 'QTY%' THEN
                ln_line_qty_price:=pqs.unit_price;
             END IF;
             IF (pqs.reason_code IS NULL AND pqs.hold_lookup_code LIKE 'QTY%') THEN  
                 lc_line_type:='ITEM';
             ELSIF pqs.reason_code IS NOT NULL AND pqs.hold_lookup_code LIKE 'SP%' THEN
                 lc_line_type:='MISCELLANEOUS';
                 lc_acct_segments:=get_misc_account(p_invoice_id,pqs.line_number,pqs.reason_code);
                 ln_ccid:=get_acct_id(lc_acct_segments);
             ELSIF  (pqs.unmatched_qty>0 AND pqs.hold_lookup_code LIKE 'SP%' AND pqs.chargeback IS NOT NULL AND pqs.reason_code IS NULL ) THEN
                 lc_line_type:='MISCELLANEOUS';
                 ln_ccid:=curparent.dist_code_combination_id;
             END IF; 
             BEGIN
               INSERT
                 INTO ap_invoice_lines_interface
                              ( invoice_id,
                                invoice_line_id,
                                line_number,
                                line_type_lookup_code,
                                quantity_invoiced,
                                unit_price,
                                description,
                                dist_code_combination_id,
                                created_by,
                                creation_date,
                                last_updated_by,
                                last_update_date,
                                last_update_login,
                                org_id,
                                attribute11,                
                                inventory_item_id,
                                item_description,
                                attribute5,                  
                                amount,
                              ---  accounting_date,  --Defect#45000
                                prorate_across_flag,
                                attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                                attribute8,attribute9,attribute10,attribute12,attribute13,
                                attribute14,attribute15,
                                unit_of_meas_lookup_code
                              )
                  VALUES
                              ( v_invoice_id,
                                ap_invoice_lines_interface_s.nextval,
                                ln_interface_line_count,                    
                                lc_line_type,
                                DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.unmatched_qty),
                                DECODE(lc_line_type,'MISCELLANEOUS',NULL,NVL(ln_line_qty_price,pqs.unit_price)),                                            pqs.description,
                                DECODE(lc_line_type,'MISCELLANEOUS',ln_ccid,NULL),
                                gn_user_id,
                                pqs.creation_date,
                                gn_user_id,
                                SYSDATE,
                                -1,
                                pqs.org_id,
                                pqs.reason_code,               
                                --DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.inventory_item_id),
                                --DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.item_description),
                                pqs.inventory_item_id,
                                pqs.item_description,
                                pqs.line_number,                
                                ROUND((pqs.unmatched_qty*(NVL(ln_line_qty_price,pqs.unit_price))),2),
                               --- SYSDATE,  --Defect#45000
                                pqs.prorate_across_all_items,
                                pqs.attribute1,pqs.attribute2,NULL,pqs.attribute4,pqs.po_qty,pqs.rcv_qty,
                                pqs.org_invoice_qty,DECODE(lc_line_type,'MISCELLANEOUS',pqs.unmatched_qty,NULL),
                                NULL,pqs.attribute12,pqs.attribute13,
                                pqs.attribute14,pqs.attribute15,DECODE(lc_line_type,'MISCELLANEOUS',NULL,pqs.unit_meas_lookup_code)                
                              );
                      ln_interface_line_count := ln_interface_line_count + 1;
                 COMMIT;  
               EXCEPTION 
                 WHEN OTHERS THEN                    
                   ROLLBACK;
                   lc_inv_ins_status:='ERROR';
                   lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
                   BEGIN
                     INSERT
                            INTO xx_ap_uiaction_errors
                            (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                          VALUES
                            (curhdr.xx_invoice_num,curhdr.invoice_id,pqs.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
                   EXCEPTION
                     WHEN OTHERS THEN
                       print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
                   END;
               END;                  
           END LOOP;
           END IF;
        END LOOP; --C3_PARENT        
        FOR curfrg IN C3_Freight(p_invoice_id) 
        LOOP
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                    attribute5,
                    ---accounting_date,  --Defect#45000
                    prorate_across_flag,
                    attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                    attribute8,attribute9,attribute10,attribute11,attribute12,attribute13,
                    attribute14,attribute15
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,   
                    'FREIGHT',
                    curfrg.AMOUNT,
                    curfrg.description,
                    curfrg.dist_code_combination_id,
                    gn_user_id,
                    curfrg.creation_date,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    curfrg.org_id,                  
                    curfrg.line_number,
                   --- SYSDATE,  --Defect#45000
                    curfrg.prorate_across_all_items,
                    curfrg.attribute1,curfrg.attribute2,NULL,curfrg.attribute4,curfrg.attribute6,curfrg.attribute7,
                    curfrg.attribute8,curfrg.attribute9,NULL,
                    DECODE(curfrg.chargeback,'N',curfrg.attribute11,NULL),
                    curfrg.attribute12,curfrg.attribute13,
                    curfrg.attribute14,curfrg.attribute15
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN others THEN                    
              ROLLBACK;
              lc_inv_ins_status:='ERROR';
              lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,curfrg.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;                    
          END;
        END LOOP;
        FOR cm IN c_misc(p_invoice_id) 
        LOOP
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                    attribute5,
                   --- accounting_date,  --Defect#45000
                    prorate_across_flag,
                    attribute1,attribute2,attribute3,attribute4,attribute6,attribute7,
                    attribute8,attribute9,attribute10,attribute11,attribute12,attribute13,
                    attribute14,attribute15
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,   
                    'MISCELLANEOUS',
                    cm.AMOUNT,
                    cm.description,
                    cm.dist_code_combination_id,
                    gn_user_id,
                    cm.creation_date,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    cm.org_id,                  
                    cm.line_number,
                   -- SYSDATE,  --Defect#45000
                    cm.prorate_across_all_items,
                    cm.attribute1,cm.attribute2,NULL,cm.attribute4,cm.attribute6,cm.attribute7,
                    cm.attribute8,cm.attribute9,NULL,
                    DECODE(cm.chargeback,'N',cm.attribute11,NULL),
                    cm.attribute12,cm.attribute13,
                    cm.attribute14,cm.attribute15
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN others THEN                    
              ROLLBACK;
              lc_inv_ins_status:='ERROR';
              lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,cm.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;                    
          END;
        END LOOP;
        FOR cur_unmpoline IN C_unm_poline(p_invoice_id) LOOP
          BEGIN
             INSERT
             INTO ap_invoice_lines_interface
                  ( invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    description,
                    dist_code_combination_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    quantity_invoiced,
                    inventory_item_id,
                    item_description,
                    unit_price,
                    amount,
                   -- accounting_date,  Defect#45000
                    prorate_across_flag,
                    attribute6,
                    attribute7,
                    attribute8,
                    unit_of_meas_lookup_code
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,                    
                    'ITEM',
                    'Matched to Unmatched PO LINE',
                    NULL,
                    gn_user_id,
                    SYSDATE,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    curhdr.org_id,
                    cur_unmpoline.quantity_invoiced,
                    cur_unmpoline.inventory_item_id,
                    cur_unmpoline.sku_desc,
                     cur_unmpoline.invoice_price,        
                    ROUND((cur_unmpoline.quantity_invoiced*cur_unmpoline.invoice_price),2),
                   --- SYSDATE,  -- revisit for accounting date  --Defect#45000
                    'N',
                    cur_unmpoline.po_qty,
                    cur_unmpoline.rcv_qty,
                    cur_unmpoline.org_invoice_qty,
                    cur_unmpoline.unit_meas_lookup_code
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN            
              ROLLBACK;
              lc_inv_ins_status:='ERROR';
              lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,cur_unmpoline.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;                    
          END;
        END LOOP;
        FOR nl IN new_line(p_invoice_id)
        LOOP
          BEGIN        
            SELECT MIN(line_number)
              INTO ln_item_line
              FROM ap_invoice_lines_all
                WHERE invoice_id=p_invoice_id
               AND line_type_lookup_code='ITEM';
          EXCEPTION
            WHEN others THEN
              ln_item_line:=NULL;
          END;
          IF ln_item_line IS NULL THEN
             lc_acct_segments:='1001.00000.20109000.010000.0000.90.000000';   
          ELSIF ln_item_line IS NOT NULL THEN
             lc_acct_segments:=get_misc_account(p_invoice_id,ln_item_line,nl.reason_code);
          END IF;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    description,
                    dist_code_concatenated,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    attribute11,                
                    amount,
                   -- accounting_date,  --Defect#45000
                    prorate_across_flag
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.NEXTVAL,
                    ln_interface_line_count,                    
                    nl.line_type_lookup_code,
                    DECODE(nl.line_type_lookup_code,'FREIGHT','Freight Charges','Miscellaneous Charges'),
                    lc_acct_segments,
                    gn_user_id,
                    SYSDATE,
                    gn_user_id,
                    SYSDATE,
                    -1,
                    curhdr.org_id,
                    nl.reason_code,               
                    nl.line_amount,
                   ---- SYSDATE,   --Defect#45000
                    'N'
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION 
            WHEN OTHERS THEN                    
              ROLLBACK;
              lc_inv_ins_status:='ERROR';
              lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (curhdr.xx_invoice_num,curhdr.invoice_id,nl.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN OTHERS THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;                        
          END;                  
        END LOOP;
        BEGIN        
          gn_source := curhdr.org_source;
          INSERT
            INTO ap_invoices_interface
                ( invoice_id,
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
                  group_id,po_number,
                  terms_date,
                  invoice_received_date,
                 -- voucher_num,
                 -- gl_date,  --Defect#45000
                  attribute1,attribute2,attribute3,attribute4,attribute5,attribute6,attribute8,
                  attribute9,attribute10,attribute11,attribute12,attribute13,attribute14,attribute15
                )
          VALUES
               (
                  v_invoice_id,
                  curhdr.xx_invoice_num,
                  'STANDARD',
                  curhdr.org_invoice_date,
                  curhdr.org_vendor_id,
                  curhdr.org_vendor_site_id,
                  curhdr.org_amount,
                  curhdr.org_invoice_currency_code,
                  curhdr.org_terms_id,
                  curhdr.org_description,
                  curhdr.org_attribute7,
                  curhdr.org_source,
                  curhdr.org_payment_method_code,
                  curhdr.org_pay_group_lookup_code,
                  curhdr.org_org_id,
                  curhdr.org_goods_received_date,
                  gn_user_id,
                  curhdr.creation_date,
                  gn_user_id,
                  SYSDATE,
                  -1,
                  gn_grp_seq,
                  curhdr.po_num,
                  curhdr.terms_date,
                  curhdr.invoice_received_date,
                 -- SYSDATE,  -- gl_date  --Defect#45000
                  curhdr.attribute1,curhdr.attribute2,
                  DECODE(p_chbk_flag,'Y',gn_invoice_num||'DM',NULL),
                  curhdr.attribute4,curhdr.attribute5,
                  curhdr.attribute6,curhdr.attribute8,curhdr.attribute9,curhdr.attribute10,curhdr.attribute11,
                  DECODE(p_chbk_flag,'Y','Y',NULL),
                  curhdr.attribute13,
                  curhdr.attribute14,curhdr.attribute15
                );
        EXCEPTION
          WHEN others THEN          
          ROLLBACK;
          lc_inv_ins_status:='ERROR';
          lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
          BEGIN
            INSERT
              INTO xx_ap_uiaction_errors
                (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
            VALUES
                (curhdr.xx_invoice_num,curhdr.invoice_id,null,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
          EXCEPTION
          WHEN others THEN
            print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
          END;
          COMMIT;            
        END;     
END LOOP;
COMMIT;
RETURN(lc_inv_ins_status);  
END XX_CREATE_INVOICE;             
-- +======================================================================+
-- | Name        :  xx_create_chargeback                                  |
-- | Description :  Insert into interface table for the chargeback details|
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_create_chargeback(p_invoice_id NUMBER, p_org_id NUMBER)
RETURN VARCHAR2
IS
CURSOR C1
IS
SELECT * 
  FROM xx_ap_chbk_action_hdr 
 WHERE invoice_id=p_invoice_id;
CURSOR C2_qty(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unmatched_qty,
        last_updated_by,
        po_line_id,
        po_qty
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  = 'Y'
   AND NVL(unmatched_qty,0)>0
   AND hold_lookup_code IN ('QTY REC','QTY ORD')
 ORDER BY line_number;
 CURSOR C2_qty_split(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unmatched_qty,
        last_updated_by
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  = 'Y'
   AND NVL(unmatched_qty,0)>0
   AND hold_lookup_code IS NULL
   AND NOT EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND hold_lookup_code='PRICE'
                       )
 ORDER BY line_number;
  CURSOR C2_qty_price_split(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unmatched_qty,
        last_updated_by
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  = 'Y'
   AND NVL(unmatched_qty,0)>0
   AND hold_lookup_code IS NULL
   AND EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND hold_lookup_code='PRICE'
                       )
 ORDER BY line_number; 
CURSOR C2_price(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unit_price,
        rcv_qty,
        last_updated_by
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  ='Y'
   AND hold_lookup_code='PRICE'   
   AND NVL(unit_price,0) > 0
  ORDER BY line_number; 
CURSOR C2_price_split(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unit_price,
        rcv_qty,
        last_updated_by
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  ='Y'
   AND hold_lookup_code IS NULL  
   AND NVL(unit_price,0) > 0
   AND NOT EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND nvl(hold_lookup_code,'SPLIT') IN ('QTY REC','QTY ORD')
                       )
  ORDER BY line_number; 
CURSOR C2_price_qty_split(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unit_price,
        rcv_qty,
        last_updated_by,
        po_line_id,
        po_qty
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  ='Y'
   AND hold_lookup_code IS NULL  
   AND NVL(unit_price,0) > 0
   AND EXISTS ( SELECT 'x'
                           FROM xx_ap_chbk_action_holds
                          WHERE invoice_id=a.invoice_id
                            AND line_number=a.line_number
                            AND nvl(hold_lookup_code,'SPLIT') IN ('QTY REC','QTY ORD')
                       )
  ORDER BY line_number;  
CURSOR inv_lines_cur(p_invoice_id NUMBER,p_inv_line_number NUMBER)
IS
SELECT l.invoice_id,
       l.line_number,
       f.dist_code_combination_id,
       SUM(NVL(c.quantity_received,0)) qty_received,
       SUM(NVL(l.quantity_invoiced,0)) org_inv_qty,
       SUM(NVL(l.unit_price,0)) org_inv_price,
       SUM(NVL(b.unit_price,0)) po_price,
       SUM(NVL(b.quantity,0)) po_qty,
       l.inventory_item_id,
       l.item_description,
       c.line_location_id,
       c.po_header_id,
       c.po_line_id
  FROM po_lines_all b,
       po_line_locations_all c,
       po_distributions_all d,
       ap_invoice_distributions_all f,
       ap_invoice_lines_all l
 WHERE l.invoice_id         = p_invoice_id
   AND l.line_number          =p_inv_line_number
   AND f.invoice_id           =l.invoice_id
   AND f.invoice_line_number  =l.line_number
   AND f.line_type_lookup_code='ACCRUAL'
   AND l.line_type_lookup_code='ITEM'
   AND d.po_distribution_id   =f.po_distribution_id
   AND c.line_location_id     =d.line_location_id
   AND b.po_header_id         =c.po_header_id
   AND b.po_line_id           =c.po_line_id
 GROUP BY l.invoice_id,
          l.line_number,
          f.dist_code_combination_id,
          l.inventory_item_id,
          l.item_description,
          c.line_location_id,
          c.po_header_id,
          c.po_line_id;
CURSOR price_lines_cur(p_invoice_id NUMBER,p_inv_line_number NUMBER)
IS
SELECT l.invoice_id,
       l.line_number,
       d.variance_account_id, 
       l.inventory_item_id,
       l.item_description,
       c.line_location_id,
       b.po_header_id,
       b.po_line_id,
       SUM(NVL(c.quantity_received,0)) qty_received,
       SUM(NVL(l.quantity_invoiced,0)) org_inv_qty,
       SUM(NVL(l.unit_price,0)) org_inv_price,
       SUM(NVL(b.unit_price,0)) po_price,
       SUM(NVL(b.quantity,0)) po_qty
  FROM po_lines_all b,
       po_line_locations_all c,
       po_distributions_all d,
       ap_invoice_distributions_all f,
       ap_invoice_lines_all l
 WHERE l.invoice_id         =p_invoice_id
   AND l.line_number          =p_inv_line_number
   AND f.invoice_id           =l.invoice_id
   AND f.invoice_line_number  =l.line_number
   AND f.line_type_lookup_code='ACCRUAL'
   AND l.line_type_lookup_code='ITEM'
   AND d.po_distribution_id   =f.po_distribution_id
   AND c.line_location_id     =d.line_location_id
   AND b.po_header_id         =c.po_header_id
   AND b.po_line_id           =c.po_line_id
 GROUP BY l.invoice_id,
          l.line_number,
          d.variance_account_id,
          l.inventory_item_id,
          l.item_description,
          b.po_header_id,
          b.po_line_id,
          c.line_location_id
          ;
CURSOR inv_header_cur (p_invoice_id NUMBER)
IS
SELECT ai.invoice_num,
       ai.invoice_id,
       ai.invoice_type_lookup_code,
       ai.invoice_date,
       ai.vendor_id,
       ai.vendor_site_id,
       ai.invoice_currency_code,
       ai.terms_id,
       ai.description,
       ai.attribute7,
       ai.source,
       ai.payment_method_code,
       ai.pay_group_lookup_code,
       ai.org_id,
       ai.goods_received_date,
       ai.terms_date,
       ai.attribute1,ai.attribute2,ai.attribute3,ai.attribute4,ai.attribute5,ai.attribute6,
       ai.attribute8,ai.attribute9,ai.attribute10,ai.attribute11,ai.attribute12,ai.attribute13,ai.attribute14,
       ai.attribute15,
       ph.segment1 po_num       
  FROM po_headers_all ph,
       ap_invoices_all ai
 WHERE ai.invoice_id = p_invoice_id
   AND ph.po_header_id=NVL(ai.quick_po_header_id,ai.po_header_id); 
CURSOR c_misc(p_invoice_id NUMBER) 
IS
SELECT invoice_id,
       line_number,
       line_type_lookup_code, 
       line_amount,  
       reason_code,
       new_line_flag,
       charge_account
  FROM xx_ap_chbk_action_dtl
 WHERE invoice_id=p_invoice_id
   AND line_type_lookup_code='MISCELLANEOUS'
   AND chargeback='Y'
 ORDER by line_number;     
CURSOR inv_lines_freight_cur(p_invoice_id NUMBER)
IS
SELECT invoice_id,
       line_number,
       line_amount,
       reason_code,
       new_line_flag,
       charge_account
  FROM xx_ap_chbk_action_dtl
 WHERE invoice_id         = p_invoice_id
   AND line_type_lookup_code='FREIGHT'
   AND chargeback='Y';
CURSOR C2_maxprice(p_invoice_id NUMBER)
IS
SELECT  decode(hold_lookup_code,NULL,'SPLIT',hold_lookup_code) hold_lookup_code,
        line_number,       
        reason_code, 
        unit_price,
        rcv_qty,
        last_updated_by
  FROM xx_ap_chbk_action_holds a
 WHERE invoice_id=p_invoice_id
   AND chargeback  ='Y'
   AND hold_lookup_code='OD Max Price'   
   AND NVL(unit_price,0) > 0
  ORDER BY line_number;
ln_total_chbk_amt              NUMBER;
lc_line_desc                VARCHAR2(200):=NULL; 
ln_item_line                NUMBER;
lc_reason_code            VARCHAR2(50);
lc_acct_segments             VARCHAR2(100);
ln_line_chbk_amt            NUMBER:=0;
ln_max_frt_amt                NUMBER;
ln_price_chbk_amt              NUMBER:=0;
ln_qty_chbk_amt                NUMBER:=0;
ln_interface_line_count     NUMBER:=0; 
v_invoice_id                NUMBER;
lc_chbk_status                VARCHAR2(10):='SUCCESS';
ln_ins_cnt                    NUMBER:=0;
lc_error_message            VARCHAR2(150);
ln_unbilled_qty                NUMBER;
lc_terms_date_basis          VARCHAR2(50);
v_multi                        VARCHAR2(1):='N';
ln_tot_bqty                    NUMBER;
ln_chbk_qty                    NUMBER;
ln_calc_rcv_qty                   NUMBER;
ln_frt_acct_id                   NUMBER;
ln_price_split                 NUMBER;
BEGIN
  BEGIN
    SELECT terms_date_basis
      INTO lc_terms_date_basis
      FROM ap_supplier_sites_all
     WHERE vendor_site_id=gn_vend_site_id;
  EXCEPTION
    WHEN others THEN
       lc_terms_date_basis:=NULL;
  END;    
gcn_invoice_id:=NULL;----2.4# Added by Chandra for defect #NAIT-41954
  SELECT AP_INVOICES_INTERFACE_S.nextval
    INTO v_invoice_id
    FROM DUAL;
	
	gcn_invoice_id:=v_invoice_id;  ----2.4# Added by Chandra for defect #NAIT-41954
	
  BEGIN
    SELECT max_freight_amt
      INTO ln_max_frt_amt
      FROM xx_ap_custom_tolerances 
     WHERE supplier_id = gn_vendor_id
       AND supplier_site_id = gn_vend_site_id
       AND org_id = gn_org_id;         
  EXCEPTION
    WHEN OTHERS THEN
      ln_max_frt_amt:=NULL;
  END;
  IF ln_max_frt_amt=0 THEN
     UPDATE xx_ap_chbk_action_dtl
        SET chargeback='Y'
      WHERE invoice_id=p_invoice_id
        AND line_type_lookup_code='FREIGHT';
     COMMIT;
  END IF;
  ln_interface_line_count :=1;
  FOR cur IN C1 
  LOOP
      gn_created_by    :=cur.last_updated_by;
      ln_total_chbk_amt:=0;
      FOR c IN C2_qty(cur.invoice_id)
      LOOP
        ln_line_chbk_amt :=0;      
        FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
        LOOP  
          IF c.hold_lookup_code='QTY REC' THEN  
             ln_calc_rcv_qty:=get_unbilled_qty(cc.po_header_id,cc.po_line_id,cc.inventory_item_id,cc.invoice_id);  -- orig cc.qty_received
             lc_line_desc     := 'QTY: (BQ '||c.unmatched_qty||'- RQ '||(ln_calc_rcv_qty)||')* INV PR '|| cc.org_inv_price||''; 
             ln_line_chbk_amt   :=ROUND(((c.unmatched_qty-ln_calc_rcv_qty) * cc.org_inv_price),2);  
          END IF;
          IF c.hold_lookup_code='QTY ORD' THEN  
             /*v_multi:=xx_check_multi_inv(p_invoice_id,c.po_line_id);  
             ln_tot_bqty:=get_tot_bqty(p_invoice_id,c.po_line_id);
             IF v_multi='N' THEN
                ln_chbk_qty:=c.po_qty;
             ELSIF v_multi='Y' THEN
                ln_chbk_qty := (ln_tot_bqty-c.po_qty);
             END IF;  
             --lc_line_desc     := 'QTY: (BQ '||c.unmatched_qty||'- POQ '||(cc.po_qty)||')* INV PR '|| cc.org_inv_price||''; 
             --ln_line_chbk_amt   :=(c.unmatched_qty-cc.po_qty) * cc.org_inv_price;   
             lc_line_desc     := 'QTY: (BQ '||ln_tot_bqty||'- POQ '||(cc.po_qty)||')* INV PR '|| cc.org_inv_price||''; 
             ln_line_chbk_amt   :=(ln_chbk_qty) * cc.org_inv_price;   
             */
             ln_calc_rcv_qty:=get_unbilled_qty(cc.po_header_id,cc.po_line_id,cc.inventory_item_id,cc.invoice_id);
             lc_line_desc     := 'QTY: (BQ '||c.unmatched_qty||'- RQ '||(ln_calc_rcv_qty)||')* INV PR '|| cc.org_inv_price||''; 
             ln_line_chbk_amt   :=ROUND(((c.unmatched_qty-ln_calc_rcv_qty) * cc.org_inv_price),2);
             
          END IF; 
          ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.dist_code_combination_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN 
                INSERT
                  INTO xx_ap_uiaction_errors
            (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2(cur.invoice_id)
      FOR c IN C2_qty_split(cur.invoice_id)
      LOOP
      ln_line_chbk_amt :=0;
        FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
        LOOP    
             lc_line_desc     := 'QTY: (SPLIT Q '||c.unmatched_qty||')* INV PR '||cc.org_inv_price||'';   
             ln_line_chbk_amt   :=ROUND((c.unmatched_qty * cc.org_inv_price),2); 
          ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.dist_code_combination_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN 
                INSERT
                  INTO xx_ap_uiaction_errors
            (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_qty_split(cur.invoice_id)
      FOR c IN C2_qty_price_split(cur.invoice_id)
      LOOP
        ln_line_chbk_amt :=0;    
        ln_price_split     :=0;        
        FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
        LOOP   
          BEGIN
            SELECT unit_price
              INTO ln_price_split
              FROM xx_ap_chbk_action_holds a
             WHERE invoice_id=cur.invoice_id
               AND line_number=c.line_number
               AND chargeback  ='Y'
               AND hold_lookup_code IS NULL  
               AND NVL(unit_price,0) > 0
               AND EXISTS ( SELECT 'x'
                              FROM xx_ap_chbk_action_holds
                             WHERE invoice_id=a.invoice_id
                               AND line_number=a.line_number
                               AND nvl(hold_lookup_code,'SPLIT') IN ('QTY REC','QTY ORD')
                          );
          EXCEPTION
            WHEN others THEN
              ln_price_split:=0; 
          END;
          IF ln_price_split=0 THEN
             lc_line_desc     := 'QTY: (SPLIT Q '||c.unmatched_qty||')* INV PR '||cc.org_inv_price||'';   
             ln_line_chbk_amt   :=ROUND((c.unmatched_qty * cc.org_inv_price),2);      
             ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          ElSE
             lc_line_desc     := 'QTY: (SPLIT Q '||c.unmatched_qty||')* SPLIT PR '||ln_price_split||'';   
             ln_line_chbk_amt   :=ROUND((c.unmatched_qty * ln_price_split),2);      
             ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          END IF;        
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.dist_code_combination_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN 
                INSERT
                  INTO xx_ap_uiaction_errors
            (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN inv_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_qty_price_split(cur.invoice_id)
      FOR c IN C2_price(cur.invoice_id)
      LOOP
        ln_line_chbk_amt :=0;      
        FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
        LOOP
             ln_calc_rcv_qty:=get_unbilled_qty(cc.po_header_id,cc.po_line_id,cc.inventory_item_id,cc.invoice_id);  -- orig cc.qty_received        
             IF ln_calc_rcv_qty>cc.org_inv_qty  THEN
                ln_calc_rcv_qty:=cc.org_inv_qty;
             END IF;
             lc_line_desc       := 'Price: (BP '||cc.org_inv_price||' - PO PR '|| cc.po_price ||' )* RQ '|| ln_calc_rcv_qty||'';      
             ln_line_chbk_amt   :=ROUND(((cc.org_inv_price - cc.po_price) * ln_calc_rcv_qty),2);
             ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.variance_account_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_price(cur.invoice_id)
      FOR c IN C2_price_split(cur.invoice_id)
      LOOP
        ln_line_chbk_amt :=0;      
        FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
        LOOP 
          lc_line_desc       := 'Price: (BP '|| c.unit_price ||' )* IQ '|| cc.org_inv_qty||'';          
          ln_line_chbk_amt   :=ROUND(((c.unit_price) * cc.org_inv_qty),2);     
          ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.variance_account_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_price_split(cur.invoice_id)
      FOR c IN C2_price_qty_split(cur.invoice_id)  
      LOOP
        ln_line_chbk_amt :=0;
        ln_unbilled_qty     :=0;    
        FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
        LOOP 
           IF gc_po_type='2-Way' THEN
             
            /* v_multi:=xx_check_multi_inv(p_invoice_id,c.po_line_id);  
             ln_tot_bqty:=get_tot_bqty(p_invoice_id,c.po_line_id);
             IF v_multi='N' THEN
                 ln_chbk_qty:=c.po_qty;
             ELSIF v_multi='Y' THEN
                 ln_chbk_qty := (ln_tot_bqty-c.po_qty);
             END IF;  
            */ 
             lc_line_desc       := 'Price: (BP '|| c.unit_price ||' )* POQ '|| c.po_qty||'';          
             ln_line_chbk_amt   :=ROUND(((c.unit_price) * c.po_qty),2);     
             
           ELSIF gc_po_type='3-Way' THEN
           
             ln_calc_rcv_qty:=get_unbilled_qty(cc.po_header_id,cc.po_line_id,cc.inventory_item_id,cc.invoice_id);  -- orig cc.qty_received
             lc_line_desc       := 'Price: (BP '|| c.unit_price ||' )* RQ '|| ln_calc_rcv_qty||'';          
             ln_line_chbk_amt   :=ROUND(((c.unit_price) * ln_calc_rcv_qty),2);                    
           
             /*ln_unbilled_qty := get_unbilled_qty(cc.po_header_id, cc.po_line_id, cc.inventory_item_id, cc.invoice_id);  
             lc_line_desc       := 'Price: (BP '|| c.unit_price ||' )* RQ '|| ln_unbilled_qty||'';          
             ln_line_chbk_amt   :=(c.unit_price) * ln_unbilled_qty;     */    
             
           END IF;
          ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.variance_account_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_price_qty_split(cur.invoice_id)
      FOR c IN C2_maxprice(cur.invoice_id)
      LOOP
        ln_line_chbk_amt :=0;      
        FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
        LOOP
             lc_line_desc       := 'Price: (BP '||cc.org_inv_price||' - PO PR '|| cc.po_price ||' )* IQ '|| cc.org_inv_qty||'';          
             ln_line_chbk_amt   :=ROUND(((cc.org_inv_price - cc.po_price) * cc.org_inv_qty),2);
             ln_total_chbk_amt     :=ln_total_chbk_amt+ln_line_chbk_amt;
          BEGIN
            INSERT
              INTO ap_invoice_lines_interface
                  ( invoice_id,
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
                  )
                  VALUES
                  (
                    v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((ln_line_chbk_amt*-1),2),
                    lc_line_desc,
                    cc.variance_account_id,
                    c.last_updated_by,
                    sysdate,
                    c.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    cc.inventory_item_id,
                    cc.item_description,
                    cc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
          EXCEPTION
            WHEN OTHERS THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',cc.invoice_id,cc.line_number,cc.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
        END LOOP;  -- FOR cc IN price_lines_cur(cur.invoice_id,c.line_number)
      END LOOP;    -- End Loop of C2_maxprice(cur.invoice_id)
      FOR mi IN c_misc(cur.invoice_id)  
      LOOP
        BEGIN
          IF mi.new_line_flag='N' THEN
             lc_acct_segments:= mi.charge_account;
             IF lc_acct_segments IS NULL THEN
                lc_acct_segments:='1001.00000.20109000.010000.0000.90.000000';
             END IF;
          ELSE        
            BEGIN        
              SELECT MIN(line_number)
                INTO ln_item_line
                FROM ap_invoice_lines_all
               WHERE invoice_id=cur.invoice_id
                 AND line_type_lookup_code='ITEM';
            EXCEPTION
              WHEN others THEN
              ln_item_line:=NULL;
            END;
            IF ln_item_line IS NULL THEN
              lc_acct_segments:='1001.00000.20109000.010000.0000.90.000000';   
            ELSIF ln_item_line IS NOT NULL THEN
              lc_acct_segments:=get_misc_account(cur.invoice_id,ln_item_line,mi.reason_code);
            END IF;
          END IF;    
             INSERT
               INTO ap_invoice_lines_interface
                  ( invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    amount,
                    description,
                    dist_code_concatenated, 
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    attribute5
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'MISCELLANEOUS',
                    ROUND((mi.line_amount*-1),2),
                    'Miscellaneous Line Chargeback',
                    lc_acct_segments, 
                    cur.last_updated_by,
                    sysdate,
                    cur.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    mi.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
                  ln_total_chbk_amt       :=ln_total_chbk_amt+ROUND(mi.line_amount,2);                  
            EXCEPTION
            WHEN others THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',mi.invoice_id,mi.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
      END LOOP;
      FOR fcc in inv_lines_freight_cur(cur.invoice_id)
      LOOP
        IF fcc.new_line_flag='N' THEN
           lc_acct_segments:= fcc.charge_account;
              IF lc_acct_segments IS NULL THEN
               lc_acct_segments:='1001.00000.20109000.010000.0000.90.000000';
           END IF;
        ELSE           
          BEGIN        
            SELECT MIN(line_number)
              INTO ln_item_line
              FROM ap_invoice_lines_all
             WHERE invoice_id=cur.invoice_id
               AND line_type_lookup_code='ITEM';
          EXCEPTION
            WHEN others THEN
              ln_item_line:=NULL;
          END;
          IF ln_item_line IS NULL THEN
             lc_acct_segments:='1001.00000.20109000.010000.0000.90.000000';   
          ELSIF ln_item_line IS NOT NULL THEN
             lc_acct_segments:=get_misc_account(cur.invoice_id,ln_item_line,fcc.reason_code);
          END IF;
        END IF;
            BEGIN
             INSERT
               INTO ap_invoice_lines_interface
                  ( invoice_id,
                    invoice_line_id,
                    line_number,
                    line_type_lookup_code,
                    amount,
                    description,
                    dist_code_concatenated,
                    --dist_code_combination_id,
                    created_by,
                    creation_date,
                    last_updated_by,
                    last_update_date,
                    last_update_login,
                    org_id,
                    attribute5
                  )
                  VALUES
                  ( v_invoice_id,
                    ap_invoice_lines_interface_s.nextval,
                    ln_interface_line_count,
                    'FREIGHT',
                    ROUND((fcc.line_amount*-1),2),
                    'FREIGHT Line Chargeback',
                    lc_acct_segments,
                    --fcc.dist_code_combination_id,
                    cur.last_updated_by,
                    sysdate,
                    cur.last_updated_by,
                    sysdate,
                    -1,
                    gn_org_id,
                    fcc.line_number
                  );
                  ln_interface_line_count := ln_interface_line_count + 1;
                  ln_total_chbk_amt       :=ln_total_chbk_amt+ROUND(fcc.line_amount,2);                      
            EXCEPTION
            WHEN others THEN
              ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback line :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',fcc.invoice_id,fcc.line_number,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;
              COMMIT;
          END;
         END LOOP;
     -- END IF;  --       IF ln_max_frt_amt=0 THEN
      SELECT COUNT(1)
        INTO ln_ins_cnt
        FROM ap_invoice_lines_interface
       WHERE invoice_id=v_invoice_id;
      IF ln_ins_cnt>0 THEN
        FOR ch IN inv_header_cur(cur.invoice_id)
        LOOP
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
              group_id,
              po_number,
              attribute12,
              attribute1,attribute2,attribute3,attribute4,attribute5,attribute6,
              attribute8,attribute9,attribute10,attribute11,attribute13,attribute14,attribute15,
              terms_date
            )
            VALUES
            (
              v_invoice_id,
              cur.invoice_num||'DM',
              'DEBIT',
              ch.invoice_date,
              ch.vendor_id,
              ch.vendor_site_id,
              ROUND((ln_total_chbk_amt*-1),2),
              ch.invoice_currency_code,
              ch.terms_id,
              ch.description,
              ch.attribute7,
              ch.source,
              ch.payment_method_code,
              ch.pay_group_lookup_code,
              ch.org_id,
              DECODE(lc_terms_date_basis,'Goods Received',NVL(ch.goods_received_date,ch.terms_date),NULL),
              cur.last_updated_by,
              SYSDATE,
              cur.last_updated_by,
              SYSDATE,
              cur.last_updated_by,
              gn_grp_seq, 
              ch.po_num,'Y',
              ch.attribute1,ch.attribute2,ch.attribute3,ch.attribute4,ch.attribute5,ch.attribute6,
              ch.attribute8,ch.attribute9,ch.attribute10,ch.attribute11,ch.attribute13,ch.attribute14,ch.attribute15,
              ch.terms_date
            );            
          EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
              lc_chbk_status:='ERROR';
               lc_error_message:='Error while inserting chargeback header :'||SUBSTR(SQLERRM,1,100);
              BEGIN
                INSERT
                  INTO xx_ap_uiaction_errors
                      (invoice_num,invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
                VALUES
                      (cur.invoice_num||'DM',ch.invoice_id,NULL,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
              EXCEPTION
                WHEN others THEN
                  print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
              END;    
              COMMIT;
          END;
        END LOOP;  -- inv_header_cur(cur.invoice_id)
      END IF; --IF ln_ins_cnt>0 THEN      
  END LOOP;  --  FOR cur IN C1 
  IF lc_chbk_status<>'ERROR' THEN
     COMMIT;
  END IF;
  RETURN(lc_chbk_status);  
EXCEPTION 
  WHEN others THEN
    print_debug_msg('When others in xx_create_chargeback :'||SUBSTR(SQLERRM,1,100));
    ROLLBACK;
    lc_chbk_status:='ERROR';
    lc_error_message:='Error in When others xx_create_chargeback :'||SUBSTR(SQLERRM,1,100);
    BEGIN
      INSERT
        INTO xx_ap_uiaction_errors
             (invoice_id,line_no,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
        VALUES
             (p_invoice_id,NULL,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
    EXCEPTION
      WHEN others THEN
        print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
    END;    
    COMMIT;
    RETURN(lc_chbk_status);
END xx_create_chargeback;
-- +======================================================================+
-- | Name        :  xx_upd_invoice_chargeback                             |
-- | Description :  To submit flags in custom hdr table for action        |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_upd_invoice_chargeback(p_invoice_id IN varchar2,p_org_id IN varchar2)
IS
ln_inv_cancel                 NUMBER:=0;
v_chbk_dtl_count             NUMBER:=0;
v_chbk_hold_count             NUMBER:=0;
v_rel_dtl_count             NUMBER:=0;
v_rel_hold_count             NUMBER:=0;
ln_request_id                NUMBER;
BEGIN
  /*SELECT count(1) 
    INTO ln_inv_cancel
    FROM xx_ap_chbk_action_holds a
   WHERE a.invoice_id=p_invoice_id
        AND a.hold_lookup_code IS NULL
        AND a.unmatched_qty<>0;
  IF ln_inv_cancel<>0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET cancel_invoice='Y'
      WHERE invoice_id=p_invoice_id;
  END IF;
  UPDATE xx_ap_chbk_action_hdr a
     SET a.cancel_invoice='Y'
   WHERE a.INVOICE_ID=p_invoice_id
     AND EXISTS (SELECT 'x'
                      FROM xx_ap_chbk_action_dtl
                  WHERE invoice_id=a.invoice_id    
                    AND unmatch_po_flag='Y'
                    AND NVL(quantity_invoiced,0)<>0
                 );
  COMMIT;
  SELECT COUNT(1)
    INTO v_chbk_hold_count
    FROM xx_ap_chbk_action_holds
   WHERE invoice_id=p_invoice_id
     AND chargeback='Y';
  IF v_chbk_hold_count >0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET chbk_create_flag='Y'
      WHERE invoice_id=p_invoice_id;
     COMMIT;
  END IF;
  SELECT COUNT(1)
    INTO v_rel_hold_count
    FROM xx_ap_chbk_action_holds
   WHERE invoice_id=p_invoice_id
     AND release_hold='Y';
  IF v_rel_hold_count>0 THEN
     UPDATE xx_ap_chbk_action_hdr
        SET rel_hold_Flag='Y'
      WHERE invoice_id=p_invoice_id;
  END IF;
  COMMIT;*/
  ln_request_id:=xx_call_chbk_act(to_number(p_invoice_id),to_number(p_org_id));
EXCEPTION
  WHEN OTHERS THEN
    NULL;
END xx_upd_invoice_chargeback;   
-- +======================================================================+
-- | Name        :  xx_release_hold                                       |
-- | Description :  To Release holds                                      |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_release_hold(p_invoice_id IN NUMBER,p_org_id IN NUMBER)
RETURN VARCHAR2
IS
CURSOR C3 (p_invoice_id NUMBER)
IS
SELECT * 
  FROM xx_ap_chbk_action_holds 
 WHERE invoice_id=p_invoice_id
   AND line_location_id IS NOT NULL
   --AND reason_code IS NOT NULL
   AND NVL(status_flag,'X')<>'R';
CURSOR C31 (p_invoice_id NUMBER)
IS
SELECT * 
 FROM xx_ap_chbk_action_holds 
WHERE invoice_id=p_invoice_id
  AND line_location_id IS NULL    
  --AND reason_code IS NOT NULL  
  AND NVL(status_flag,'X')<>'R';
v_hold_rel_cnt               NUMBER;
lc_hold_status               VARCHAR2(1):='S';
v_desc                    VARCHAR2(240);
lc_error_message        VARCHAR2(150);
v_rlcode                VARCHAR2(30);
BEGIN
  FOR cur IN c3(p_invoice_id) LOOP
    IF cur.hold_lookup_code IN ('PRICE','OD Favorable','OD Max Price','QTY ORD','QTY REC') THEN 
       v_desc := get_reason_code_desc('APPROVED');
       v_rlcode:='APPROVED';
    ELSE 
       v_desc := get_reason_code_desc(cur.reason_code);
       v_rlcode:=cur.reason_code;
    END IF;
    UPDATE ap_holds_all
       SET release_lookup_code = v_rlcode,
           release_reason = v_desc,
           last_updated_by = cur.last_updated_by,
           last_update_date = SYSDATE,
           last_update_login = cur.last_updated_by,
           status_flag='R'
     WHERE invoice_id = p_invoice_id
       AND line_location_id=cur.line_location_id
       AND release_lookup_code IS NULL
       AND hold_lookup_code = cur.hold_lookup_code;
       
    IF cur.hold_lookup_code IN ('PRICE','OD Max Price') AND NVL(cur.chargeback,'N')='N' THEN        
       UPDATE ap_invoice_lines_all 
          SET attribute11='PD'
        WHERE invoice_id = p_invoice_id
          AND line_number=cur.line_number;
    END IF;
    COMMIT;
       
    IF SQL%NOTFOUND THEN        
       lc_hold_status:='E';
       print_debug_msg('Unable to Release Hold '||SQLERRM);
       lc_error_message:='Unable to Release AP Hold '||SUBSTR(SQLERRM,1,100);
       BEGIN
         INSERT
           INTO xx_ap_uiaction_errors
               (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
         VALUES
               (p_invoice_id,cur.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
       EXCEPTION
         WHEN others THEN
           print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
       END;
    END IF;
    UPDATE xx_ap_chbk_action_holds
       SET process_flag='Y',
           status_flag='R'
     WHERE invoice_id=p_invoice_id
       AND line_location_id=cur.line_location_id
       AND status_flag='S';
    IF SQL%NOTFOUND THEN        
       lc_hold_status:='E';
       print_debug_msg('Unable to update xx_ap_chbk_action_holds : '||SQLERRM);
       lc_error_message:='Unable to update xx_ap_chbk_action_holds :'||SUBSTR(SQLERRM,1,100);       
       BEGIN
         INSERT
           INTO xx_ap_uiaction_errors
               (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
         VALUES
               (p_invoice_id,cur.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
       EXCEPTION
         WHEN others THEN
           print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
       END;
    END IF;
  END LOOP;
  COMMIT;
  FOR cur IN c31(p_invoice_id) LOOP
     IF cur.hold_lookup_code='OD Line Variance' THEN
       v_desc := get_reason_code_desc('OD_VA_APPRVD_HDR');
       v_rlcode:='OD_VA_APPRVD_HDR';
    ELSIF cur.hold_lookup_code='OD NO Receipt' THEN
       v_desc := get_reason_code_desc('APPROVED'); 
       v_rlcode:='APPROVED';       
    ELSIF cur.hold_lookup_code ='OD Max Freight' THEN 
       v_desc := get_reason_code_desc('OD_VA_APPRVD_HDR');
       v_rlcode:='OD_VA_APPRVD_HDR';            
    ELSE 
       v_desc := get_reason_code_desc(cur.reason_code);
       v_rlcode:=cur.reason_code;
    END IF;
    UPDATE ap_holds_all
       SET release_lookup_code = v_rlcode,
           release_reason = v_desc,
           last_updated_by = cur.last_updated_by,
           last_update_date = SYSDATE,
           last_update_login = cur.last_updated_by,
           status_flag='R'
     WHERE invoice_id = p_invoice_id
       AND release_lookup_code IS NULL
       AND line_location_id IS NULL
       AND hold_lookup_code = cur.hold_lookup_code;
    IF SQL%NOTFOUND THEN        
        lc_hold_status:='E';
       print_debug_msg('Unable to Release Hold '||SQLERRM);
       lc_error_message:='Unable to Release AP Hold '||SUBSTR(SQLERRM,1,100);
       BEGIN
         INSERT
           INTO xx_ap_uiaction_errors
               (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
         VALUES
               (p_invoice_id,cur.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
       EXCEPTION
         WHEN others THEN
           print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
       END;
    END IF;
    UPDATE xx_ap_chbk_action_holds
       SET process_flag='Y',
           status_flag='R'
     WHERE invoice_id=p_invoice_id
           AND line_location_id IS NULL
           AND status_flag='S'
           AND hold_lookup_code = cur.hold_lookup_code;
    IF SQL%NOTFOUND THEN        
        lc_hold_status:='E';
       print_debug_msg('Unable to update xx_ap_chbk_action_holds : '||SQLERRM);
       lc_error_message:='Unable to update xx_ap_chbk_action_holds :'||SUBSTR(SQLERRM,1,100);       
       BEGIN
         INSERT
           INTO xx_ap_uiaction_errors
               (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
         VALUES
               (p_invoice_id,cur.line_location_id,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
       EXCEPTION
         WHEN others THEN
           print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
       END;
    END IF;
  END LOOP;
  COMMIT;    
  SELECT count(1) 
    INTO v_hold_rel_cnt
    FROM ap_holds_all a
   WHERE invoice_id=p_invoice_id
     AND release_lookup_code IS NULL;
  IF v_hold_rel_cnt<>0 THEN
     lc_hold_status:='E';
     UPDATE xx_ap_chbk_action_hdr
        SET rel_hold_process_flag='E',
            process_flag='E',
            error_message = error_message||' '||'Error In Releasing Holds'
      WHERE invoice_id=p_invoice_id;
  ELSE
     UPDATE xx_ap_chbk_action_hdr
        SET rel_hold_process_flag='Y',
            process_Flag='Y'
      WHERE invoice_id=p_invoice_id;
  END IF;
  COMMIT;
  return lc_hold_status;  
EXCEPTION
  WHEN others THEN
    lc_hold_status:='E';
    print_debug_msg('When others in xx_relesae_hold : '||SUBSTR(SQLERRM,1,100));    
    lc_error_message:='When others in xx_release_hold :'||SUBSTR(SQLERRM,1,100);       
    BEGIN
      INSERT
        INTO xx_ap_uiaction_errors
            (invoice_id,line_location_id,creation_date,created_by,last_updated_by,last_update_date,error_message)
        VALUES
            (p_invoice_id,NULL,SYSDATE,gn_user_id,gn_user_id,SYSDATE,lc_error_message);
    EXCEPTION
      WHEN others THEN
        print_debug_msg('Error in inserting into xx_ap_uiaction_errors : '||SQLERRM);
    END;
    RETURN lc_hold_status;
END xx_release_hold;
-- +======================================================================+
-- | Name        :  xx_process_chargeback                                 |
-- | Description :  Process the chargeback creation                       |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_process_chargeback(p_invoice_id NUMBER) 
IS
lc_rel_hold         VARCHAR2(1);
lc_chbk_status        VARCHAR2(10);
lc_ins_status        VARCHAR2(1):='E';
lc_imp_status         VARCHAR2(100);
lc_proc_status        VARCHAR2(1):='S';
ln_inv_cnt            NUMBER:=0;
lc_rh_status        VARCHAR(10);
BEGIN
  lc_chbk_status:=xx_create_chargeback(p_invoice_id,gn_org_id);
  fnd_file.put_line (fnd_file.log, 'xx_process_chargeback gn_source'||gn_source);
  print_debug_msg('xx_process_chargeback lc_chbk_status'||lc_chbk_status||'gn_source'||gn_source);
  IF lc_chbk_status<>'ERROR' THEN
     lc_ins_status:='S';
  ELSIF lc_chbk_status='ERROR' THEN              
     lc_ins_status:='E';
  END IF;
  IF lc_ins_status='S' THEN
     lc_imp_status:=xx_call_payables_import;
     print_debug_msg('lc_imp_status'||lc_imp_status);
     IF lc_imp_status<>'ERROR' THEN
        BEGIN
               SELECT invoice_id
               INTO gn_chbk_invoice_id
            FROM ap_invoices_all
           WHERE invoice_num=gn_invoice_num||'DM'
             AND vendor_id=gn_vendor_id
             AND vendor_site_id=gn_vend_site_id;
        EXCEPTION
          WHEN others THEN
            gn_chbk_invoice_id:=-1;
        END;
        IF gn_chbk_invoice_id=-1 THEN
           UPDATE xx_ap_chbk_action_hdr
              SET PROCESS_FLAG='E',
                  chbk_process_Flag='I',  -- consider only chbk_process_flag='E' for reprocessing automatically
                  error_message='Error while processing, Chargeback import Invoice Id'
            WHERE invoice_id=p_invoice_id;
			-- Start: 2.4# Added by Chandra for defect #NAIT-41954
			UPDATE ap_invoices_interface
			SET group_id = 'TDM-TRADE'
			WHERE source ='US_OD_TDM'
			AND invoice_id = gcn_invoice_id;   
			-- End: 2.4# Added by Chandra for defect #NAIT-41954
           lc_proc_status:='E';   
        END IF;
        ELSIF lc_imp_status='ERROR' THEN  
        print_debug_msg('lc_imp_status '||lc_imp_status);
        UPDATE xx_ap_chbk_action_hdr
           SET process_flag='E',
               chbk_process_Flag='I',
               error_message='Error while processing, Chargeback import'
         WHERE invoice_id=p_invoice_id;
        lc_proc_status:='E';
     END IF;  --IF lc_imp_status<>'ERROR' THEN            
  ELSIF lc_ins_status='E' THEN        
     lc_proc_status:='E';
     UPDATE xx_ap_chbk_action_hdr
        SET process_flag='E',
            chbk_process_Flag='E',
            error_message='Error while inserting into interface table for chargeback invoice creation'
      WHERE invoice_id=p_invoice_id;
      xx_send_notify(p_invoice_id);
  END IF;  --IF lc_proc_status='S' THEN             
  IF lc_proc_status='S' THEN
     UPDATE xx_ap_chbk_action_hdr
        SET process_flag='Y',
            chbk_process_flag='Y'
      WHERE invoice_id=p_invoice_id;  
     SELECT NVL(rel_hold_flag,'N')
       INTO lc_rel_hold
       FROM xx_ap_chbk_action_hdr
      WHERE invoice_id=p_invoice_id;     
  END IF; 
  IF lc_rel_hold='Y' THEN
        lc_rh_status:=xx_release_hold(p_invoice_id,gn_org_id); 
  END IF;  
EXCEPTION
  WHEN others THEN
    print_debug_msg('Exception When others in xx_process_chargeback :'|| SUBSTR(SQLERRM,1,100));
END xx_process_chargeback;
-- +======================================================================+
-- | Name        :  xx_check_inv_status                                   |
-- | Description :  Check recreate invoice and chargeback                 |
-- |                                                                      |
-- | Parameters  :  p_chbk_flag, p_import_status                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_check_inv_status(p_chbk_flag IN VARCHAR2)
IS
BEGIN
     IF p_chbk_flag='Y' THEN
        BEGIN
          SELECT invoice_id
            INTO gn_new_inv_id
            FROM ap_invoices_all
           WHERE invoice_num=gn_invoice_num
               AND vendor_id=gn_vendor_id
             AND vendor_site_id=gn_vend_site_id;
          EXCEPTION
            WHEN others THEN
              gn_new_inv_id:=-1;
          END;
          BEGIN
                 SELECT invoice_id
                 INTO gn_chbk_invoice_id
                 FROM ap_invoices_all
             WHERE invoice_num=gn_invoice_num||'DM'
               AND vendor_id=gn_vendor_id
               AND vendor_site_id=gn_vend_site_id;
          EXCEPTION
             WHEN others THEN
               gn_chbk_invoice_id:=-1;
          END;
          IF gn_new_inv_id = -1 THEN
             UPDATE xx_ap_chbk_action_hdr
                SET process_flag='E',
                      inv_recreate_flag='I',                -- No need to reprocess only to cancel the original invoice
                    error_message=error_message||','||'Error while processing, import failed'
               WHERE invoice_id=gn_invoice_id;
			   
			   -- Start: 2.4# Added by Chandra for defect #NAIT-41954
			
			UPDATE ap_invoices_interface
			SET group_id = 'TDM-TRADE'
			WHERE source ='US_OD_TDM'
			AND invoice_id = gin_invoice_id ;
			
			-- End:----2.4# Added by Chandra for defect #NAIT-41954
               gc_newinv_status:='E';
          END IF;
          IF gn_chbk_invoice_id = -1 THEN
             UPDATE xx_ap_chbk_action_hdr
                SET process_flag='E',
                      chbk_process_Flag='I',                -- No need to reprocess only to cancel the original invoice
                    error_message=error_message||','||'Error while processing, import failed'
               WHERE invoice_id=gn_invoice_id;
               gc_newchbk_status:='E';
			   
			   -- Start: 2.4# Added by Chandra for defect #NAIT-41954
			
			UPDATE ap_invoices_interface
			SET group_id = 'TDM-TRADE'
			WHERE source ='US_OD_TDM'
			AND invoice_id = gcn_invoice_id ;
			-- End:2.4# Added by Chandra for defect #NAIT-41954
          END IF;
          IF gn_new_inv_id<>-1 THEN
              UPDATE xx_ap_chbk_action_hdr
                 SET inv_recreate_flag='Y',
                     process_flag='P'
               WHERE invoice_id=gn_invoice_id;              
               gc_newinv_status:='S';               
          END IF;
          IF gn_chbk_invoice_id<>-1 THEN
              UPDATE xx_ap_chbk_action_hdr
                 SET chbk_process_Flag='Y',
                     process_flag='P'
               WHERE invoice_id=gn_invoice_id;              
               gc_newchbk_status:='S';
          END IF;
     ELSIF p_chbk_flag='N' THEN        
          BEGIN
                 SELECT invoice_id
                 INTO gn_new_inv_id
              FROM ap_invoices_all
             WHERE invoice_num=gn_invoice_num
               AND vendor_id=gn_vendor_id
               AND vendor_site_id=gn_vend_site_id;
          EXCEPTION
            WHEN others THEN
              gn_new_inv_id:=-1;
          END;
          IF gn_new_inv_id=-1  THEN
             UPDATE xx_ap_chbk_action_hdr
                SET process_flag='E',
                    inv_recreate_flag='I',                -- No need to reprocess only to cancel the original invoice
                    error_message='Error while processing, import failed'
              WHERE invoice_id=gn_invoice_id;
              gc_newinv_status:='E';
			  
			  -- Start: 2.4# Added by Chandra for defect #NAIT-41954
			
			UPDATE ap_invoices_interface
			SET group_id = 'TDM-TRADE'
			WHERE source ='US_OD_TDM'
			AND invoice_id = gin_invoice_id ;
			-- End: 2.4# Added by Chandra for defect #NAIT-41954
             xx_intf_stuck_notify(gn_invoice_num);
          ELSIF gn_new_inv_id<>-1 THEN
             UPDATE XX_AP_CHBK_ACTION_HDR
                SET inv_recreate_flag='Y', process_flag='P'
              WHERE INVOICE_ID=gn_INVOICE_ID;              
              gc_newinv_status:='S';
          END IF;
     END IF;  --p_chbk_flag='N' THEN    
     COMMIT;     
EXCEPTION
  WHEN others THEN
    print_debug_msg('When others in xx_check_inv_status :'||SUBSTR(SQLERRM,1,100));
END xx_check_inv_status;
-- +======================================================================+
-- | Name        :  xx_invoice_call_proc                                  |
-- | Description :  Process the data from cutom table for UI Actions      |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_invoice_call_proc(p_invoice_id NUMBER,p_chbk_create_flag VARCHAR2)
IS
v_cancel_type                 VARCHAR2(1):='A';
lc_status                      VARCHAR2(100);
lc_chbk_cr                      VARCHAR2(1);
lc_rel_hold                      VARCHAR2(1);
lc_imp_status                 VARCHAR2(100);
lc_chbk_status                VARCHAR2(10);
lc_rh_status                VARCHAR2(100);
ln_inv_cnt                      NUMBER;
lc_proc_status                VARCHAR2(1):='S';
gn_status                    VARCHAR2(1):='S';
v_chbk_no                      VARCHAR2(50):=gn_invoice_num||'DM';
lc_inv_can_sts                VARCHAR2(10);
p_error                        VARCHAR2(1):='N';
gc_crinv_ins_status            VARCHAR2(10);
gc_chbk_ins_status            VARCHAR2(10);
gc_insert_status            VARCHAR2(1):='S';
BEGIN
  lc_chbk_cr:=p_chbk_create_flag;
  --xx_upd_invoice_num(p_invoice_id,v_cancel_type,p_error);
  --IF p_error='N' THEN
     gc_crinv_ins_status:=xx_create_invoice(p_invoice_id,lc_chbk_cr);
     IF gc_crinv_ins_status='SUCCESS' THEN
        IF lc_chbk_cr='Y' THEN
           gc_chbk_ins_status:=xx_create_chargeback(p_invoice_id,gn_org_id);  
           IF gc_chbk_ins_status='ERROR' THEN  
              gc_insert_status:='E';
           END IF;
        END IF;
        IF gc_insert_status='S' THEN  
           xx_upd_invoice_num(p_invoice_id);
           lc_imp_status:=xx_call_payables_import; --Calling Open interface import
           xx_check_inv_status(lc_chbk_cr);  
        END IF;
     ELSE --gc_crinv_ins_status='SUCCESS'  --IF lc_status<>'ERROR' THEN    
        gc_insert_status:='E';
      
       END IF;
     print_debug_msg('gc insert status :'||gc_insert_status);
     IF gc_insert_status='E' THEN
        xx_send_notify(p_invoice_id);  
        --xx_upd_invoice_num(p_invoice_id,'R',p_error);             
         UPDATE xx_ap_chbk_action_hdr
           SET process_flag='E',inv_recreate_flag='E',chbk_process_flag='E',cancel_inv_process_flag='E',  -- Reprocess
               error_message='Error while inserting into interface table for invoice creation'
         WHERE invoice_id=p_invoice_id; 
        DELETE
           FROM ap_invoice_lines_interface
         WHERE invoice_id IN (SELECT invoice_id
                                FROM ap_invoices_interface
                                  WHERE group_id=TO_CHAR(gn_grp_seq)
                             );
        DELETE
           FROM ap_invoices_interface
         WHERE group_id=TO_CHAR(gn_grp_seq);
        COMMIT;
     ELSIF gc_insert_status='S' THEN
       print_debug_msg('Before cancel');
       lc_inv_can_sts:=xx_cancel_invoice(p_invoice_id);  
       print_debug_msg('After cancel');       
       IF lc_inv_can_sts='ERROR' THEN
             UPDATE xx_ap_chbk_action_hdr
             SET process_flag='E',cancel_inv_process_flag='E',            -- Reprocess
                 error_message=error_message||','||'Error while Cancelling Invoice'
           WHERE invoice_id=p_invoice_id;
       ELSIF lc_inv_can_sts='SUCCESS' THEN
          UPDATE xx_ap_chbk_action_hdr
             SET cancel_inv_process_flag='Y',process_flag='P'
           WHERE invoice_id=p_invoice_id;
       END IF;       
     END IF;
  COMMIT;
EXCEPTION
  WHEN others THEN
    print_debug_msg('When others in xx_invoice_call_proce :'||SUBSTR(SQLERRM,1,100));
END xx_invoice_call_proc;
-- +======================================================================+
-- | Name        :  xx_submit_inv_validation                              |
-- | Description :  To submit invoice validation                          |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_submit_preval(p_invoice_id IN NUMBER)
RETURN NUMBER
IS
  l_request_id NUMBER;
BEGIN
   l_request_id  :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXAP_TR_MATCH_PREVAL','OD: AP Trade Match Prevalidation Program',NULL,FALSE, 
                                               NULL,'NO',p_invoice_id
                                             );
   IF l_request_id>0 THEN
      COMMIT;
      print_debug_msg ('Request id : ' ||TO_CHAR(l_request_id));
   END IF;
   RETURN l_request_id;
EXCEPTION
  WHEN OTHERS THEN
    l_request_id:=-1;
    print_debug_msg ('When Others in xx_submit_preval : '||SUBSTR(SQLERRM,1,100));
    RETURN l_request_id;
END xx_submit_preval;
-- +======================================================================+
-- | Name        :  xx_submit_inv_validation                              |
-- | Description :  To submit invoice validation                          |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_submit_inv_validation(
      p_invoice_id IN NUMBER,
      p_org_id     IN NUMBER)
RETURN NUMBER
IS
  l_request_id         NUMBER;
  x_dummy           VARCHAR2(2000);
  v_dphase          VARCHAR2(100);
  v_dstatus         VARCHAR2(100);
  v_phase           VARCHAR2(100);
  v_status          VARCHAR2(100);
  
BEGIN
   l_request_id  :=FND_REQUEST.SUBMIT_REQUEST('SQLAP','APPRVL','Invoice Validation',NULL,FALSE, 
                                               p_org_id,'All',NULL,NULL,NULL,NULL,NULL,p_invoice_id,NULL,'N','1000','1','N' 
                                             );
   IF l_request_id>0 THEN
      COMMIT;
      IF (FND_CONCURRENT.WAIT_FOR_REQUEST(l_request_id,1,60000,v_phase,
            v_status,v_dphase,v_dstatus,x_dummy))  THEN
          IF v_dphase = 'COMPLETE' THEN
             print_debug_msg ('Request id : ' ||TO_CHAR(l_request_id));
          END IF;
      END IF;
   END IF;
   RETURN l_request_id;
EXCEPTION
  WHEN OTHERS THEN
    l_request_id:=-1;
    print_debug_msg ('When Others in xx_submit_inv_validation : '||SUBSTR(SQLERRM,1,100));
    RETURN l_request_id;
END xx_submit_inv_validation;
-- +======================================================================+
-- | Name        :  xx_submi_rel_invoices                                 |
-- | Description :  Submit Invoice Validation for related invoices        |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_vendor_id,p_po_hdr_id                 |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_submit_rel_invoices(p_invoice_id      IN NUMBER,
                                 p_vendor_id     IN NUMBER,
                                 p_po_hdr_id     IN NUMBER
                                )
IS
CURSOR C1 IS
SELECT ai.invoice_id,
       ai.org_id
  FROM ap_invoices_all ai
 WHERE vendor_id=p_vendor_id
   AND quick_po_header_id=p_po_hdr_id
   AND invoice_id<>p_invoice_id
   AND invoice_num not like '%ODDBUIA%'
   AND invoice_type_lookup_code='STANDARD'
   AND 'APPROVED'<>  AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          );
v_request_id NUMBER;                                          
BEGIN
  FOR cur IN C1 LOOP
    v_request_id:=xx_submit_inv_validation(cur.invoice_id,cur.org_id);
  END LOOP;
END xx_submit_rel_invoices;
-- +======================================================================+
-- | Name        :  xx_cancel_debit_memo                                  |
-- | Description :  Procedure to cancel debit memo                        |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_cancel_debit_memo(p_invoice_id IN NUMBER)
IS
lc_inv_can_sts                VARCHAR2(10);
BEGIN
  xx_upd_invoice_num(p_invoice_id);
  lc_inv_can_sts:=xx_cancel_invoice(p_invoice_id);  
EXCEPTION
  WHEN others THEN
    print_debug_msg('Error in Cancelling Debit Memo');
END xx_cancel_debit_memo;
PROCEDURE xx_delete_dmint IS
BEGIN
  DELETE from ap_invoice_lines_interface
  WHERE invoice_id in (select invoice_id from ap_invoices_interface where invoice_num=gn_invoice_num||'DM');
  DELETE from ap_invoices_interface where invoice_num=gn_invoice_num||'DM';
  COMMIT;
END;
-- +======================================================================+
-- | Name        :  xx_chbk_action                                        |
-- | Description :  Process the data from cutom table for UI Actions      |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_chbk_action(
                            x_errbuf         OUT NOCOPY  VARCHAR2 ,
                            x_retcode         OUT NOCOPY VARCHAR2 ,
                            p_invoice_id     IN NUMBER,
                            p_org_id         IN NUMBER
                        )
IS
l_chbk_invoice_id              NUMBER;
v_cancel_flag                  VARCHAR2(1);
v_chbk_create_flag             VARCHAR2(1);
v_rel_hold_flag             VARCHAR2(1);
v_invoice_id                 NUMBER;
lc_rh_status                 VARCHAR2(10);
v_request_id                NUMBER;
x_dummy                        VARCHAR2(2000) ;
v_errbuf                  VARCHAR2(100);
v_retcode                 VARCHAR2(100);
v_dphase                       VARCHAR2(100) ;
v_dstatus                      VARCHAR2(100) ;
v_phase                        VARCHAR2(100) ;
v_status                       VARCHAR2(100) ;
v_error                           VARCHAR2(100);
lc_new_invoice_status        VARCHAR2(20);
ln_chbk_rejected_cnt        NUMBER;
ln_inv_rejected_cnt            NUMBER;
ln_org_id           NUMBER;
BEGIN
  gn_invoice_id:=p_invoice_id;
  ln_org_id:=FND_PROFILE.VALUE('ORG_ID');
  FND_FILE.PUT_LINE (FND_FILE.LOG,' Org_id '||ln_org_id);
  BEGIN
    SELECT XX_AP_CHBK_IMPORT_SEQ.nextval INTO gn_grp_seq FROM dual;
  EXCEPTION
    WHEN others THEN
      print_debug_msg('Error in xx_ap_chbk_import_seq :'||SUBSTR(SQLERRM,1,100));      
  END;
  FND_FILE.PUT_LINE (FND_FILE.LOG,'xx_chbk_action gn_grp_seq');
  xx_check_freight(p_invoice_id);
  BEGIN
    SELECT NVL(hdr.cancel_invoice,'N'),
           NVL(hdr.chbk_create_flag,'N'),
           NVL(hdr.rel_hold_flag,'N'),
           hdr.org_id,
           hdr.invoice_num,
           ai.vendor_id,
           ai.vendor_site_id,
           ai.source,
           hdr.last_updated_by,
           NVL(ai.po_header_id,ai.quick_po_header_id) 
      INTO v_cancel_flag,
           v_chbk_create_flag,
           v_rel_hold_flag,
           gn_org_id,
           gn_invoice_num,
           gn_vendor_id,
           gn_vend_site_id,
           gn_source,
           gn_created_by,
           gn_po_hdr_id
      FROM ap_invoices_all ai,
           xx_ap_chbk_action_hdr hdr
     WHERE hdr.invoice_id=p_invoice_id
       AND ai.invoice_id=hdr.invoice_id;
  EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg('Error in deriving Action from Custom table :'||SUBSTR(SQLERRM,1,100));      
  END;
  BEGIN  
      SELECT DISTINCT DECODE(c.receipt_required_flag,'Y','3-Way','N','2-Way') match_type
      INTO gc_po_type
      FROM po_line_locations_all c
      WHERE c.po_header_id IN (SELECT NVL(po_header_id,quick_po_header_id)
                              FROM ap_invoices_all
                             WHERE invoice_id=p_invoice_id
                           );
  EXCEPTION
    WHEN OTHERS THEN
      gc_po_type:=NULL;
  END;      
  IF v_cancel_flag='Y' THEN
     gc_cancel:='Y';  
     xx_invoice_call_proc(p_invoice_id,v_chbk_create_flag);  
  ELSE
     IF v_chbk_create_flag='Y' AND v_rel_hold_flag='Y' THEN
        xx_process_chargeback(p_invoice_id);  
        v_request_id:=xx_submit_inv_validation(gn_invoice_id,p_org_id);        
        IF gn_chbk_invoice_id>0 THEN
           v_request_id:=xx_submit_inv_validation(gn_chbk_invoice_id,p_org_id);     
        END IF;
        BEGIN
          SELECT  AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          ) inv_status
            INTO lc_new_invoice_status
            FROM ap_invoices_all ai
           WHERE invoice_id=gn_invoice_id;
        EXCEPTION
          WHEN others THEN
            lc_new_invoice_status:=NULL;
        END;
        IF lc_new_invoice_status<>'APPROVED' THEN
           IF gn_chbk_invoice_id>0 THEN
              xx_cancel_debit_memo(gn_chbk_invoice_id); 
           ELSE
              xx_delete_dmint;
           END IF;
        ELSIF lc_new_invoice_status='APPROVED' THEN
           IF gn_chbk_invoice_id=-1 THEN
              xx_intf_stuck_notify(gn_invoice_num||'DM');
           END IF;
           UPDATE ap_invoices_all
               SET attribute3=gn_invoice_num||'DM'
             WHERE invoice_id=p_invoice_id;
        END IF;
      END IF;
      IF v_chbk_create_flag='N' AND v_rel_hold_flag='Y' THEN
        lc_rh_status:=xx_release_hold(p_invoice_id,gn_org_id);
      END IF;
  END IF;

  IF gc_cancel='Y' THEN
     IF gn_new_inv_id > 0 THEN
        v_request_id :=xx_submit_preval(gn_new_inv_id);
        COMMIT;
        IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
           IF (v_dphase = 'COMPLETE' AND v_dstatus='NORMAL') THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'Prevalidation Completed');
           END IF;        
        END IF;
        v_request_id :=xx_submit_inv_validation(gn_new_inv_id,p_org_id);
        COMMIT;
        IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase, v_status,v_dphase,v_dstatus,x_dummy)) THEN
           IF (v_dphase = 'COMPLETE' AND v_dstatus='NORMAL') THEN
              xx_rel_newinvoice_holds(gn_new_inv_id);  
           END IF;        
        END IF;

        xx_rel_ansinv_holds(gn_new_inv_id);        

        xx_submit_rel_invoices(gn_new_inv_id,gn_vendor_id,gn_po_hdr_id);

        xx_release_template_holds(v_errbuf, v_retcode,gn_source,gn_new_inv_id);

           BEGIN
          SELECT  AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          ) inv_status
            INTO lc_new_invoice_status
            FROM ap_invoices_all ai
           WHERE invoice_id=gn_new_inv_id;
        EXCEPTION
          WHEN others THEN
            lc_new_invoice_status:=NULL;
        END;
          IF lc_new_invoice_status<>'APPROVED' THEN
           IF v_chbk_create_flag='Y' THEN
              IF gn_chbk_invoice_id>0 THEN
                 xx_cancel_debit_memo(gn_chbk_invoice_id);
                 COMMIT;
              ELSE
                 xx_delete_dmint;
              END IF;
           END IF;
           IF gc_po_type='2-Way' THEN
              UPDATE ap_holds_all
                 SET release_lookup_code = NULL,
                     release_reason =NULL,
                     status_flag=NULL
               WHERE invoice_id =gn_new_inv_id
                 AND hold_lookup_code<>'QTY REC';
           ELSIF gc_po_type='3-Way'    THEN             
              UPDATE ap_holds_all
                 SET release_lookup_code = NULL,
                     release_reason =NULL,
                     status_flag=NULL
               WHERE invoice_id =gn_new_inv_id
                 AND hold_lookup_code<>'QTY ORD';
           END IF;
                 
           UPDATE ap_invoice_lines_all
              SET attribute11=NULL
            WHERE invoice_id =gn_new_inv_id
              AND attribute11 in ('SH','PD');            
        ELSE
          IF v_chbk_create_flag='Y' AND gn_chbk_invoice_id>0 THEN
             v_request_id:=xx_submit_inv_validation(gn_chbk_invoice_id,p_org_id);     
          ELSIF    v_chbk_create_flag='Y' AND gn_chbk_invoice_id<0 THEN  
            SELECT COUNT(1) 
              INTO ln_chbk_rejected_cnt
              FROM ap_invoices_interface
             WHERE invoice_num=gn_invoice_num||'DM'
               AND status='REJECTED';
            IF ln_chbk_rejected_cnt<>0 THEN
               xx_send_rejected_notification(gn_invoice_num||'DM');
            END IF;
          END IF;
        END IF;
     ELSE  --IF gn_new_inv_id > 0 THEN              
       IF v_chbk_create_flag='Y' AND gn_chbk_invoice_id>0 AND gn_new_inv_id<0 THEN
          SELECT COUNT(1) 
            INTO ln_inv_rejected_cnt
            FROM ap_invoices_interface
           WHERE invoice_num=gn_invoice_num
             AND status='REJECTED';
          IF ln_inv_rejected_cnt<>0 THEN
             xx_send_rejected_notification(gn_invoice_num);
             NULL;
          END IF;
       END IF;
     END IF;
     UPDATE xx_ap_chbk_action_hdr
        SET process_flag='Y'
      WHERE invoice_id=p_invoice_id;
     COMMIT;
  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
    x_errbuf :=SUBSTR(SQLERRM,1,150);
    x_retcode:='2';
END xx_chbk_action;
-- +======================================================================+
-- | Name        :  xx_call_chbk_act                                      |
-- | Description :  To submit OD AP Chargeback Action Process             |
-- |                                                                      |
-- | Parameters  :  p_invoice_id, p_org_id                                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION  xx_call_chbk_act( p_invoice_id IN NUMBER,
                            p_org_id     IN NUMBER)
RETURN NUMBER                            
IS
v_request_id             NUMBER:=-99999;
l_user_id                NUMBER;
l_responsibility_id      NUMBER;
l_responsibility_appl_id NUMBER;

BEGIN
  commit;
  /*SELECT user_id,
         responsibility_id,
         responsibility_application_id
    INTO l_user_id,
         l_responsibility_id,
         l_responsibility_appl_id
    FROM fnd_user_resp_groups
   WHERE user_id=(SELECT user_id FROM fnd_user WHERE user_name=gn_user_id)
    AND responsibility_id=(SELECT responsibility_id
                             FROM FND_RESPONSIBILITY
                            WHERE responsibility_key = 'XX_US_PAYABLES_MANAGER'
                           );
   FND_GLOBAL.apps_initialize( l_user_id, l_responsibility_id, l_responsibility_appl_id );*/
   DELETE FROM XX_AP_CHBK_ACTION_HOLDS 
   WHERE invoice_id=p_invoice_id 
     and hold_lookup_code IS NULL
     and unmatched_qty is NULL
     and unit_price IS NULL;
   COMMIT;
   v_request_id  :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXAPCBAP','OD: AP Trade Match UI Action Process',NULL,FALSE, p_invoice_id,p_org_id);
   IF v_request_id>0 THEN
      COMMIT;
      UPDATE xx_ap_chbk_action_hdr
         SET request_id=v_request_id
       WHERE invoice_id=p_invoice_id;
      COMMIT;
      print_debug_msg ('Request id : ' ||TO_CHAR(v_request_id));
   END IF;
   RETURN(v_request_id);   
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg('When others :'|| SQLERRM);
    RETURN(v_request_id);
  END xx_call_chbk_act;
-- +======================================================================+
-- | Name        :  get_assigned_user                                     |
-- | Description :  Returns assigned user                                 |
-- |                                                                      |
-- | Parameters  :  p_po_header_id, p_po_line_id,p_item_id                |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION get_assigned_user(p_invoice_id IN NUMBER,p_user_id IN NUMBER)
RETURN VARCHAR2
IS
v_user VARCHAR2(100);
v_cnt  NUMBER;
v_name VARCHAR2(100);
BEGIN
  BEGIN
    SELECT per.full_name
      INTO v_name
      FROM per_all_people_f per,
           fnd_user fu
     WHERE fu.user_id=p_user_id
       AND per.employee_number=fu.user_name
       AND sysdate between effective_start_date and effective_end_date;
  EXCEPTION
    WHEN others THEN
      v_name:=NULL;
  END; 
  SELECT COUNT(1),created_by_name
    INTO v_cnt,v_user
    FROM xx_ap_chbk_action_hdr
   WHERE invoice_id=p_invoice_id
     AND process_flag<>'Y'
   GROUP BY created_by_name;     
   IF v_cnt<>0 AND v_user IS NULL THEN
     UPDATE xx_ap_chbk_action_hdr
        SET created_by_name=v_name
      WHERE invoice_id=p_invoice_id
        AND process_flag<>'Y';
     COMMIT;
     RETURN('EI');
   END IF;
   IF v_cnt<>0 AND v_user IS NOT NULL THEN
      RETURN('AB'||v_user);
   END IF;
   IF v_cnt=0 THEN
      RETURN('NI');
   END IF;
EXCEPTION
  WHEN others THEN
    RETURN(NULL);
END get_assigned_user;
-- +======================================================================+
-- | Name        :  unassign_user                                         |
-- | Description :  unassign user for invoice                             |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+    
PROCEDURE unassign_user(p_invoice_id IN NUMBER)
IS
BEGIN 
  UPDATE xx_ap_chbk_action_hdr
     SET created_by_name=NULL
   WHERE invoice_id=p_invoice_id
     AND process_flag<>'Y';
EXCEPTION
  WHEN others THEN
    NULL;
END unassign_user;
-- +======================================================================+
-- | Name        :  get_freight_chbk                                      |
-- | Description :  Get chargeback Eligible for the invoice for Freight   |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+  
FUNCTION get_freight_chbk(p_invoice_id NUMBER)
RETURN VARCHAR2
IS
CURSOR get_max_freight_amt
IS
SELECT tol.max_freight_amt 
  FROM xx_ap_custom_tolerances tol,
       ap_invoices_all ai
 WHERE ai.invoice_id=p_invoice_id
   AND tol.supplier_id = ai.vendor_id
   AND tol.supplier_site_id = ai.vendor_site_id
   AND tol.org_id = ai.org_id;
v_chbk         VARCHAR2(1):='N';   
v_frt_amt     NUMBER;
BEGIN
  FOR cur IN get_max_freight_amt LOOP
    v_frt_amt:=cur.max_freight_amt;
    IF v_frt_amt=0 THEN
       v_chbk:='Y';
    ELSE
       v_chbk:='N';
    END IF;
  END LOOP;
  RETURN(v_chbk);
EXCEPTION
  WHEN others THEN 
    v_chbk:='N';
    RETURN(v_chbk);
END get_freight_chbk;
-- +======================================================================+
-- | Name        :  xx_insert_custom_invoice_table                        |
-- | Description :  load invoice data in custom table                     |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_insert_custom_invoice_table(p_invoice_id VARCHAR2,
                                        p_user_id    VARCHAR2,
                                        p_user_name  VARCHAR2)
RETURN VARCHAR2
IS
CURSOR c1(p_invoice_id NUMBER)
IS
SELECT invoice_num,
       NVL(po_header_id,quick_po_header_id) po_header_id,
       NVL(DECODE(source,'Manual Invoice Entry',attribute7,source),'US_OD_TRADE_EDI') source,
       invoice_amount,
       org_id,
       vendor_site_id
  FROM ap_invoices_all
 WHERE invoice_id=p_invoice_id;
CURSOR c2(p_invoice_id NUMBER)
IS
SELECT l.invoice_id,
       l.line_number                 dtl_line_number, 
       l.quantity_invoiced             dtl_quantity_invoiced,
       l.unit_price                 dtl_unit_price, 
       l.amount                     dtl_amount,
       l.line_type_lookup_code         dtl_line_type_lookup_code,
       l.po_line_id                 dtl_po_line_id,
       l.po_line_location_id         dtl_po_line_location_id,
       ph.segment1                     dtl_po_num,
       SUBSTR(location_code,1,6)         dtl_location,
       get_shipment_num(l.po_line_id)     dtl_shipment_num,       
       pol.line_num                     dtl_po_line_num,
       l.inventory_item_id                 dtl_inventory_item_id,       
       msi.segment1                     dtl_sku,       
       l.item_description                 dtl_sku_desc,       
       pol.quantity                     dtl_po_qty,
       pol.unit_price                     dtl_po_price,
       l.po_line_id                     po_line_id,
       get_charge_acct(l.po_line_id)     dtl_charge_account,
       l.po_line_location_id,       
       SUM(nvl(pll.quantity_received,0)) rcv_qty,
       nvl(l.attribute4,l.unit_meas_lookup_code) unit_meas_lookup_code,
       l.unit_price,
       l.amount,
       l.attribute11
  FROM po_headers_all ph,
       hr_locations_all hrl,
       mtl_system_items_b msi,
       po_line_locations_all pll,
       po_lines_all pol,        
       ap_invoice_lines_all l
 WHERE l.invoice_id = p_invoice_id
   AND l.line_type_lookup_code='ITEM'
   AND pol.po_line_id=l.po_line_id
   AND pol.po_header_id=pll.po_header_id
   AND pol.po_line_id=pll.po_line_id
   AND msi.inventory_item_id=l.inventory_item_id
   AND msi.organization_id+0=441
   AND hrl.location_id=l.ship_to_location_id
   AND ph.po_header_id=l.po_header_id
 GROUP BY l.invoice_id,
          l.line_number,
            l.quantity_invoiced,
            l.unit_price,
            l.amount,
            l.line_type_lookup_code,            
            l.po_line_id,
            l.po_line_location_id,
            ph.segment1,
            SUBSTR(location_code,1,6),
            pol.line_num,
            l.inventory_item_id,
            msi.segment1,
            l.item_description,
            pol.quantity,        
            l.item_description,
            pol.quantity,
            pol.unit_price,
            l.po_line_id,            
            l.po_line_location_id,
            nvl(l.attribute4,l.unit_meas_lookup_code),
            l.unit_price,
            l.amount,
            l.attribute11;
CURSOR Freight_C2(p_invoice_id NUMBER)
IS
SELECT line_number,
       line_type_lookup_code,
       description,
       org_id,
       amount,
       'N' dtl_unmatch_po_flag,
       'N' dtl_hold_exists_flag,
       attribute11
  FROM ap_invoice_lines_all
 WHERE invoice_id=p_invoice_id
   AND line_type_lookup_code='FREIGHT'
 ORDER BY line_number;
CURSOR c_misc(p_invoice_id NUMBER)
IS
SELECT line_number,
       line_type_lookup_code,
       description,
       org_id,
       amount,
       default_dist_ccid,
       'N' dtl_unmatch_po_flag,
       'N' dtl_hold_exists_flag,
        attribute11 reason_code,
        attribute3 misc_hold_flag
  FROM ap_invoice_lines_all
 WHERE invoice_id=p_invoice_id
   AND line_type_lookup_code='MISCELLANEOUS'
 ORDER by line_number;     
CURSOR unmatch_c2(p_invoice_id NUMBER,p_po_header_id NUMBER)
IS
SELECT pol.po_line_id dtl_po_line_id,
       pol.line_num dtl_po_line_num,
       ph.segment1 dtl_po_num,
       substr(location_code,1,6) dtl_location,
       pll.shipment_num dtl_shipment_num,
       msi.segment1 dtl_sku,       
       pol.item_description dtl_sku_desc,
       pol.quantity dtl_po_qty,
       pol.unit_price dtl_po_price,
       get_charge_acct(pol.po_line_id) dtl_charge_account,
       pol.item_id dtl_inventory_item_id,
       sum(nvl(pll.quantity_received,0)) rcv_qty,
       pol.unit_meas_lookup_code    
  FROM po_headers_all ph,
       hr_locations_all hrl,
       mtl_system_items_b msi,
       po_line_locations_all pll,
       po_lines_all pol        
 WHERE pol.po_header_id=p_po_header_id
   AND msi.inventory_item_id=pol.item_id
   AND msi.organization_id+0=441
   AND ph.po_header_id=pol.po_header_id
   AND pll.po_line_id=pol.po_line_id
   AND hrl.location_id =pll.ship_to_location_id   
   AND NOT EXISTS (SELECT 'x'
                    FROM ap_invoice_lines_all
                   WHERE invoice_id=p_invoice_id
                     AND po_line_id=pol.po_line_id
                  )               
GROUP BY pol.po_line_id,
         pol.line_num,
         ph.segment1,
         substr(location_code,1,6),
         pll.shipment_num,
         msi.segment1,
         pol.item_description,
         pol.quantity,
         pol.unit_price,
         pol.item_id,
         pol.unit_meas_lookup_code;
CURSOR c3(p_invoice_id NUMBER,p_line_location_id NUMBER)
IS
SELECT d.hold_lookup_code ,
       d.hold_id,
       d.held_by,
       d.status_flag,
       TRUNC(d.hold_date) hold_date,
       SUM(NVL(c.quantity_received,0)) rcv_qty,
       DECODE(c.receipt_required_flag,'Y','3-Way','N','2-Way') match_type
  FROM po_line_locations_all c,
       ap_holds_all d                
 WHERE d.invoice_id=p_invoice_id
   AND d.line_location_id=p_line_location_id
   AND c.line_location_id=d.line_location_id
   AND d.release_lookup_code is NULL
 GROUP BY d.hold_lookup_code,
          d.hold_id,
          d.held_by,
          d.status_flag,
          TRUNC(d.hold_date),
          DECODE(c.receipt_required_flag,'Y','3-Way','N','2-Way');
CURSOR c4(p_invoice_id NUMBER) 
IS
SELECT * 
  FROM ap_holds_all
 WHERE invoice_id=p_invoice_id
   AND line_location_id is NULL
   AND release_lookup_code is NULL;
p_po_header_id                     NUMBER;
p_invoice_num                     VARCHAR2(50);
p_ins_status                     VARCHAR2(1) :='S';
p_answer_code                     VARCHAR2(50);
l_max_line_number                 NUMBER;
p_release_hold                     VARCHAR2(1):='N';
p_chargeback                     VARCHAR2(1):='N';
p_reason_code                     VARCHAR2(50):=NULL;
lc_acct                            VARCHAR2(100);
v_chbk                            VARCHAR2(1);
l_pre_balance_flag                VARCHAR2(1);
l_frt_chbk                          VARCHAR2(1);
ln_vendor_site_id                  NUMBER;
ln_org_id                          NUMBER;
lc_check_hold                      VARCHAR2(1);
BEGIN
  IF gn_user_id < 0 THEN
     gn_user_id:=p_user_id;
  END IF;
  FOR cur1 IN c1(p_invoice_id)
  LOOP
    ln_vendor_site_id:=cur1.vendor_site_id;
    ln_org_id:=cur1.org_id;
    BEGIN
      INSERT
      INTO xx_ap_chbk_action_hdr
        (
          invoice_id,
          invoice_num,
          po_header_id,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          process_flag,
          chbk_create_flag,
          rel_hold_flag,
          error_message,
          created_by_name,
          cancel_invoice,
          chbk_process_flag,
          rel_hold_process_flag,
          cancel_inv_process_flag,
          source,
          org_invoice_amount,
          org_id
        )
        VALUES
        (
          p_invoice_id,
          cur1.invoice_num,
          cur1.po_header_id,
          gn_user_id,
          SYSDATE,
          gn_user_id,
          SYSDATE,
          'N',
          NULL,
          NULL,
          NULL,
          p_user_name,
          NULL,
          NULL,
          NULL,
          NULL,
          cur1.source,
          cur1.invoice_amount,
          cur1.org_id
        );
    EXCEPTION
      WHEN others THEN
        p_ins_status:='E';
    END;
    p_po_header_id     :=cur1.po_header_id;
    p_invoice_num    :=cur1.invoice_num;
  END LOOP;
  FOR cur2 IN c2(p_invoice_id)
  LOOP
    lc_check_hold:=check_hold_exists(cur2.invoice_id,cur2.dtl_po_line_location_id);
    BEGIN
      INSERT
      INTO xx_ap_chbk_action_dtl
      (
        invoice_id,
        invoice_num,
        line_number,
        quantity_invoiced,
        invoice_price,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        process_flag,        
        po_line_no,
        po_header_id,        
        line_type_lookup_code,
        charge_account,
        unmatch_po_flag,
        hold_exists_flag,
        po_line_id,
        po_qty,
        po_price,
        sku,
        sku_desc,
        inventory_item_id,
        po_num,
        shipment_num,
        po_line_num,
        location,
        rcv_qty,
        org_invoice_qty,    
        line_seq_id,
        line_amount,
        org_invoice_price,
        uom,
        org_uom,
        reason_code,
        new_line_flag
      )
      VALUES
      (
        p_invoice_id,
        p_invoice_num,
        cur2.dtl_line_number,
        cur2.dtl_quantity_invoiced,
        cur2.dtl_unit_price,
        gn_user_id,
        SYSDATE,
        gn_user_id,
        SYSDATE,
        'N',        
        cur2.dtl_po_line_num,
        p_po_header_id,        
        cur2.dtl_line_type_lookup_code,
        cur2.dtl_charge_account,
        'N',
        lc_check_hold,
        cur2.dtl_po_line_id,
        cur2.dtl_po_qty,
        cur2.dtl_po_price,
        cur2.dtl_sku,
        cur2.dtl_sku_desc,
        cur2.dtl_inventory_item_id,
        cur2.dtl_po_num,
        cur2.dtl_shipment_num,
        cur2.dtl_po_line_num,
        cur2.dtl_location,
        cur2.rcv_qty,
        cur2.dtl_quantity_invoiced,        
        xx_ap_chbk_line_seq.NEXTVAL,
        cur2.amount,
        cur2.unit_price,
        cur2.unit_meas_lookup_code,
        cur2.unit_meas_lookup_code,
        cur2.attribute11,'N'
      );
    EXCEPTION
      WHEN OTHERS THEN
        p_ins_status:='E';
    END;
    FOR cur3 IN c3(p_invoice_id,cur2.dtl_po_line_location_id) 
    LOOP
         IF cur3.match_type='2-Way' AND cur3.hold_lookup_code='QTY REC' THEN
         CONTINUE;
      ELSIF cur3.match_type='3-Way' AND cur3.hold_lookup_code='QTY ORD' THEN 
         CONTINUE;
      END IF;
      p_release_hold:=NULL;
         p_chargeback:=NULL;
      p_reason_code:=NULL;
      BEGIN
        p_answer_code := get_answer_code(p_invoice_id,cur2.po_line_id);
        IF p_answer_code='INV' and cur3.hold_lookup_code='PRICE' THEN
           p_release_hold:='Y';
           p_reason_code:='PD';  
        END IF;
        IF p_answer_code='P O' and cur3.hold_lookup_code='PRICE' THEN
           p_release_hold:='Y';
           p_chargeback:='Y';
           p_reason_code:='PD';
        END IF;
        IF cur3.hold_lookup_code='QTY REC' THEN
           p_answer_code:=NULL;
        END IF;
        INSERT
        INTO xx_ap_chbk_action_holds
        (    invoice_id,
            line_number,
            po_line_id,
            hold_id,
            hold_lookup_code,
            release_hold,
            chargeback,
            reason_code,
            line_location_id,
            held_by,
            hold_date,
            status_flag,
            process_flag,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,      
            unmatched_qty,
            unit_price,
            po_price,
            org_invoice_qty,
            answer_code,
            po_qty,
            rcv_qty,
            hold_line_id,
            line_type_lookup_code,
            org_invoice_price,
            uom,
      org_uom
        )
        VALUES
        (   p_invoice_id,
            cur2.dtl_line_number,
            cur2.po_line_id,
            cur3.hold_id,
            cur3.hold_lookup_code,
            p_release_hold,
            p_chargeback,
            p_reason_code,
            cur2.dtl_po_line_location_id,
            cur3.held_by,
            cur3.hold_date,
            cur3.status_flag,
            'N',
            p_user_id,
            SYSDATE,
            p_user_id,
            SYSDATE,
            cur2.dtl_quantity_invoiced,      
            cur2.dtl_unit_price,
            cur2.dtl_po_price,
            cur2.dtl_quantity_invoiced,
            p_answer_code,
            cur2.dtl_po_qty,
            cur3.rcv_qty,
            xx_ap_chbk_action_holds_seq.NEXTVAL,
            cur2.dtl_line_type_lookup_code,
            cur2.unit_price,
            cur2.unit_meas_lookup_code,
      cur2.unit_meas_lookup_code
        );
        P_ANSWER_CODE:=NULL;
        p_release_hold:='N';
        p_chargeback:='N';
        p_reason_code:=NULL;
      EXCEPTION
        WHEN OTHERS THEN
          p_ins_status:='E';
      END;
    END LOOP;  
  END LOOP;
  FOR freight_cur2 IN freight_c2(p_invoice_id)
  LOOP
    lc_acct:=get_freight_acct(p_invoice_id,freight_cur2.line_number);
    l_frt_chbk:=get_freight_chargeback(ln_vendor_site_id,ln_org_id);
    
    BEGIN
        INSERT
      INTO xx_ap_chbk_action_dtl
      (
        invoice_id,
        invoice_num,
        line_number,
        quantity_invoiced,
        invoice_price,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        process_flag,        
        line_type_lookup_code,
        charge_account,
        unmatch_po_flag,
        hold_exists_flag,
        line_seq_id,
        line_amount,
        reason_code,
        new_line_flag,
        chargeback
      )
      VALUES
      (
        p_invoice_id,
        p_invoice_num,
        freight_cur2.line_number,
        NULL,
        NULL,
        p_user_id,
        SYSDATE,
        p_user_id,
        SYSDATE,
        'N',        
        freight_cur2.line_type_lookup_code,
        lc_acct,
        freight_cur2.dtl_unmatch_po_flag,
        freight_cur2.dtl_hold_exists_flag,
        xx_ap_chbk_line_seq.NEXTVAL,
        freight_cur2.amount,
        freight_cur2.attribute11,'N',
        DECODE(l_frt_chbk,'Y','Y','N',NULL)
      );
    EXCEPTION
     WHEN OTHERS THEN
      p_ins_status:='E';
    END;
  END LOOP;
  COMMIT;
  FOR cr_misc IN c_misc(p_invoice_id)
  LOOP
    lc_acct:=get_line_acct(cr_misc.default_dist_ccid);
    IF cr_misc.reason_code in ('GV','DV') then
        l_pre_balance_flag :='Y';
    ELSE
        l_pre_balance_flag := NULL;
    END IF;
    BEGIN
      INSERT
      INTO xx_ap_chbk_action_dtl
      (
        invoice_id,
        invoice_num,
        line_number,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        process_flag,        
        line_type_lookup_code,
        charge_account,
        unmatch_po_flag,
        hold_exists_flag,
        line_seq_id,
        line_amount,
        pre_balance_flg,
        reason_code,
        new_line_flag,
    misc_hold_flag
      )
      VALUES
      (
        p_invoice_id,
        p_invoice_num,
        cr_misc.line_number,
        p_user_id,
        SYSDATE,
        p_user_id,
        SYSDATE,
        'N',        
        cr_misc.line_type_lookup_code,
        lc_acct,
        cr_misc.dtl_unmatch_po_flag,
        cr_misc.dtl_hold_exists_flag,
        xx_ap_chbk_line_seq.NEXTVAL,
        cr_misc.amount,
        l_pre_balance_flag,
        cr_misc.reason_code,'N',
        cr_misc.misc_hold_flag
      );
    EXCEPTION
      WHEN others THEN
        p_ins_status:='E';
    END;
  END LOOP;
  COMMIT;
  SELECT MAX(line_number)
    INTO l_max_line_number
    FROM xx_ap_chbk_action_dtl
   WHERE invoice_id=p_invoice_id;
  FOR unmatch_cur2 IN unmatch_c2(p_invoice_id,p_po_header_id)
  LOOP
    --l_max_line_number:=l_max_line_number+1;
    BEGIN
      INSERT
        INTO xx_ap_chbk_action_dtl
      (
        invoice_id,
        invoice_num,
      --  line_number,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        process_flag,
        po_line_no,
        po_header_id,
        charge_account,
        unmatch_po_flag,
        hold_exists_flag,
        po_line_id,
        po_qty,
        po_price,
        sku,
        sku_desc,
        inventory_item_id,
        rcv_qty,
        line_type_lookup_code,
        line_seq_id,
        new_line_flag,
        uom,
        shipment_num,
        po_line_num
      )
      VALUES
      (
        p_invoice_id,
        p_invoice_num,
        --l_max_line_number,
        p_user_id,
        SYSDATE,
        p_user_id,
        SYSDATE,
        'N',
        unmatch_cur2.dtl_po_line_num,
        p_po_header_id,
        unmatch_cur2.dtl_charge_account,
        'Y',
        'Y',
        unmatch_cur2.dtl_po_line_id,
        unmatch_cur2.dtl_po_qty,
        unmatch_cur2.dtl_po_price,
        unmatch_cur2.dtl_sku,
        unmatch_cur2.dtl_sku_desc,
        unmatch_cur2.dtl_inventory_item_id,
        unmatch_cur2.rcv_qty,
        'ITEM',
        xx_ap_chbk_line_seq.NEXTVAL,'N',
        unmatch_cur2.unit_meas_lookup_code,
        unmatch_cur2.dtl_shipment_num,
        unmatch_cur2.dtl_po_line_num        
      );
    EXCEPTION
      WHEN OTHERS THEN
        p_ins_status:='E';
    END;
  END LOOP;  
  FOR cur4 IN c4(p_invoice_id) LOOP
    p_release_hold :=NULL;
    p_chargeback   :=NULL;
    IF cur4.hold_lookup_code='OD Max Freight' THEN
       v_chbk:=get_freight_chbk(p_invoice_id);
       IF v_chbk='Y' THEN
          p_release_hold:='Y';
          p_chargeback    :='Y';         
       ELSIF v_chbk='N' THEN
          p_chargeback:=NULL;
          p_release_hold:=NULL;
       END IF;
    END IF;       
    BEGIN
      INSERT
        INTO xx_ap_chbk_action_holds
      (
        invoice_id,      
        hold_id,
        hold_lookup_code,      
        held_by,
        hold_date,
        status_flag,
        process_flag,
        created_by,
        creation_date,
        last_updated_by,
        last_update_date,
        hold_line_id,
        chargeback,
        release_hold        
      )
      VALUES
      (
        p_invoice_id,      
        cur4.hold_id,
        cur4.hold_lookup_code,      
        cur4.held_by,
        SYSDATE,
        cur4.status_flag,
        'N',
        p_user_id,
        SYSDATE,
        p_user_id,
        SYSDATE,
        XX_AP_CHBK_ACTION_HOLDS_SEQ.nextval,
        DECODE(cur4.hold_lookup_code,'OD Max Freight',p_chargeback,NULL),
        DECODE(cur4.hold_lookup_code,'OD Max Freight',p_release_hold,NULL)
      );
    EXCEPTION
      WHEN others THEN
        p_ins_status:='E';
    END;
  END LOOP;
  COMMIT;
  RETURN p_ins_status;
END xx_insert_custom_invoice_table; 
-- +======================================================================+
-- | Name        :  xx_insert_new_holds                                   |
-- | Description :  Add new holds in the custom table for the invoice     |
-- |                                                                      |
-- | Parameters  :  p_invoice_id                                          |
-- |                                                                      |
-- | Returns     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_insert_new_holds(p_invoice_id IN VARCHAR2) RETURN VARCHAR2
IS
CURSOR C1(p_invoice_id NUMBER) 
IS
SELECT a.line_number             hold_line_number,
       a.po_line_location_id     hold_LINE_LOCATION_ID,
       a.po_line_id             hold_po_line_id,
       a.unit_meas_lookup_code,
       a.line_type_lookup_code,
       d.hold_lookup_code ,
       a.quantity_invoiced         hold_quantity_invoiced,
       a.unit_price             hold_unit_price,
       b.unit_price             hold_po_price,           
       d.hold_id,
       d.held_by,
       d.status_flag,
       TRUNC(d.hold_date)        hold_date,
       b.quantity po_qty,
       SUM(NVL(c.quantity_received,0)) rcv_qty,
       DECODE(c.receipt_required_flag,'Y','3-Way','N','2-Way') match_type       
  FROM 
       po_lines_all b,
       po_line_locations_all c,
       ap_holds_all d,
       ap_invoice_lines_all a
 WHERE a.invoice_id=p_invoice_id
   AND a.po_line_id=b.po_line_id
   AND b.po_line_id=c.po_line_id
   AND c.line_location_id=d.line_location_id
   AND a.invoice_id=d.invoice_id
   AND d.release_lookup_code is NULL
  AND NOT EXISTS (SELECT 'x'
                     FROM xx_ap_chbk_action_holds
                    WHERE invoice_id=d.invoice_id    
                      AND hold_lookup_code=d.hold_lookup_code
                      AND line_location_id=d.line_location_id
                   ) 
   AND d.creation_date>(select creation_date 
                         FROM xx_ap_chbk_action_hdr 
                   Where invoice_id=a.invoice_id)      
   GROUP BY a.line_number,
              a.po_line_location_id,
            a.po_line_id,
            a.unit_meas_lookup_code,    
            a.line_type_lookup_code,
            d.hold_lookup_code,
            a.quantity_invoiced,
            a.unit_price,
            b.unit_price,
            d.hold_id,
            d.held_by,
            d.status_flag,
            TRUNC(d.hold_date),
            b.quantity,
            DECODE(c.receipt_required_flag,'Y','3-Way','N','2-Way');
CURSOR c2(p_invoice_id NUMBER) 
IS
SELECT a.* 
  FROM ap_holds_all a
 WHERE invoice_id=p_invoice_id
   AND line_location_id IS NULL
   AND release_lookup_code IS NULL
   AND NOT EXISTS (SELECT 'x'
                     FROM xx_ap_chbk_action_holds
                    WHERE invoice_id=a.invoice_id
                      AND hold_lookup_code=a.hold_lookup_code
                      AND line_location_id IS NULL
                   ) 
   AND a.creation_date>(select creation_date 
                         FROM xx_ap_chbk_action_hdr 
                   Where invoice_id=a.invoice_id);
CURSOR c3(p_invoice_id NUMBER)
IS
SELECT hold_id,
       line_location_id
  FROM ap_holds_all
 WHERE invoice_id=p_invoice_id 
   AND release_lookup_code IS NOT NULL; 
p_answer_code     VARCHAR2(50);
p_release_hold     VARCHAR2(1):='N';
p_reason_code     VARCHAR2(50):=NULL;
p_ins_status     VARCHAR2(1) :='S';
p_chargeback    VARCHAR2(1):='N';
l_invoice_id    NUMBER:=TO_NUMBER(p_invoice_id);
v_chbk            VARCHAR2(1);
BEGIN
  FOR cur3 IN c1(l_invoice_id) LOOP
    IF cur3.match_type='2-Way' AND cur3.hold_lookup_code='QTY REC' THEN
       CONTINUE;
    ELSIF cur3.match_type='3-Way' AND cur3.hold_lookup_code='QTY ORD' THEN 
       CONTINUE;
    END IF;
    p_answer_code:=NULL;
    p_release_hold:='N';
    p_chargeback:='N';
    p_reason_code:=NULL;
    BEGIN
      p_answer_code := get_answer_code(l_invoice_id,cur3.hold_po_line_id);
      IF p_answer_code='INV' AND cur3.hold_lookup_code='PRICE' THEN
        p_release_hold:='Y';
        p_reason_code:='PD';  
      END IF;
     IF p_answer_code='P O' AND cur3.hold_lookup_code='PRICE' THEN
        p_release_hold:='Y';
        p_chargeback:='Y';
        p_reason_code:='PD';
     END IF;
     IF cur3.hold_lookup_code='QTY REC' THEN
        p_answer_code:=NULL;
     END IF;
     INSERT
       INTO xx_ap_chbk_action_holds
        (
            invoice_id,
            line_number,
            po_line_id,
            hold_id,
            hold_lookup_code,
            release_hold,
            chargeback,
            reason_code,
            line_location_id,
            held_by,
            hold_date,
            status_flag,
            process_flag,
            created_by,
            creation_date,
            last_updated_by,
            last_update_date,      
            unmatched_qty,
            unit_price,
            po_price,
            org_invoice_qty,
            answer_code,
            po_qty,
            rcv_qty,
            hold_line_id,
            line_type_lookup_code,
            org_invoice_price,
            uom      
        )
    VALUES
        (
            l_invoice_id,
            cur3.hold_line_number,
            cur3.hold_po_line_id,
            cur3.hold_id,
            cur3.hold_lookup_code,
            p_release_hold,
            p_chargeback,
            p_reason_code,
            cur3.hold_line_location_id,
            cur3.held_by,
            cur3.hold_date,
            cur3.status_flag,
            'N',
            gn_user_id,
            SYSDATE,
            gn_user_id,
            SYSDATE,
            decode(cur3.hold_lookup_code,'QTY REC',cur3.hold_quantity_invoiced,0),      
            cur3.hold_unit_price,
            cur3.hold_po_price,
            cur3.hold_quantity_invoiced,
            p_answer_code,
            cur3.po_qty,
            cur3.rcv_qty,
            xx_ap_chbk_action_holds_seq.NEXTVAL,
            cur3.line_type_lookup_code,
            cur3.hold_unit_price,
            cur3.unit_meas_lookup_code
    );
    UPDATE xx_ap_chbk_action_dtl
       SET hold_exists_flag='Y'
     WHERE invoice_id=l_invoice_id
       AND po_line_id=cur3.hold_po_line_id;     
    EXCEPTION
     WHEN OTHERS THEN
       p_ins_status:='E';
    END;
  END LOOP;  
  COMMIT;
  FOR cur4 IN c2(l_invoice_id) LOOP
      p_release_hold :=NULL;
    p_chargeback   :=NULL;
    IF cur4.hold_lookup_code='OD Max Freight' THEN
       v_chbk:=get_freight_chbk(p_invoice_id);
       IF v_chbk='Y' THEN
          p_release_hold:='Y';
          p_chargeback    :='Y';         
       ELSIF v_chbk='N' THEN
          p_chargeback:=NULL;
          p_release_hold:=NULL;
       END IF;
    END IF;       
    BEGIN
      INSERT
        INTO xx_ap_chbk_action_holds
        (
          invoice_id,      
          hold_id,
          hold_lookup_code,      
          held_by,
          hold_date,
          status_flag,
          process_flag,
          created_by,
          creation_date,
          last_updated_by,
          last_update_date,
          hold_line_id,
              chargeback,
          release_hold        
        )
    VALUES
        (
          l_invoice_id,      
          cur4.hold_id,
          cur4.hold_lookup_code,      
          cur4.held_by,
          SYSDATE,
          cur4.status_flag,
          'N',
          gn_user_id,
          SYSDATE,
          gn_user_id,
          SYSDATE,
          XX_AP_CHBK_ACTION_HOLDS_SEQ.nextval,
          DECODE(cur4.hold_lookup_code,'OD Max Freight',p_chargeback,NULL),
          DECODE(cur4.hold_lookup_code,'OD Max Freight',p_release_hold,NULL)
        );
  EXCEPTION
  WHEN OTHERS THEN
     p_ins_status:='E';
  END;
  END LOOP;
  COMMIT;
     FOR cur IN C3(p_invoice_id) LOOP
    DELETE 
                  FROM xx_ap_chbk_action_holds
                WHERE invoice_id=p_invoice_id
                   AND hold_id=cur.hold_id;
                IF cur.line_location_id IS NOT NULL THEN
                   UPDATE xx_ap_chbk_action_dtl a
                      SET hold_exists_flag='N'
                                WHERE invoice_id=p_invoice_id   
                                  AND unmatch_po_flag='N'
                                  AND NOT EXISTS (SELECT 'x'
                                                    FROM xx_ap_chbk_action_holds
                                                    WHERE invoice_id=p_invoice_id
                                                    AND line_number=a.line_number);
                END IF;
  END LOOP;
  COMMIT;
  xx_update_answer(p_invoice_id);
  COMMIT;
  RETURN p_ins_status;
END xx_insert_new_holds;
END; 
/
SHOW ERRORS;