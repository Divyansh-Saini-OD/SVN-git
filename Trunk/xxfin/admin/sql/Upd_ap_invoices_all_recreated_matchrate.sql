-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update_ap_invoices_all_matchrate                                               |
-- | Description : This Script is used to update the attribute4 of ap_invoices_all for recreated invoices |
-- |Change Record: 
---| Rice ID: E3523                                                                            |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 24-MAY-18  Priyam Parmar                Update for Re-created invoice for Match Rate     |
-- +===========================================================================================+
--

DECLARE
  CURSOR c_inv_can
  IS
    SELECT ---h.cancelled_invoice_num,
      h.new_invoice_num,
      h.vendor_id ,
      h.vendor_site_id,
      to_char(MIN(h.creation_date)+6,'DD-MON-YYYY') release_date
    FROM
      (SELECT a.invoice_num cancelled_invoice_num,
       ----to_char(rtrim (a.invoice_num,substr(a.invoice_num,-9,9))) new_invoice_num,
    substr(a.invoice_num,1,(INSTR(a.invoice_num, 'ODDB')-1)) new_invoice_num,
        ---- a.invoice_id,
        a.vendor_id,
        a.vendor_site_id,
        a.creation_date
      from ap_invoices_all a
      where 1=1
      and a.source='US_OD_TRADE_EDI'
      AND a.invoice_num LIKE '%ODDBUIA%'
        ----and a.cancelled_date is null
      AND a.creation_date BETWEEN TO_DATE(TO_CHAR('07-APR-18')
        ||' 00:00:00','DD-MON-RR HH24:MI:SS')
      AND TO_DATE(TO_CHAR(sysdate)
        ||' 23:59:59','DD-MON-RR HH24:MI:SS')-7
       ) h
    GROUP BY
      --cancelled_invoice_num,
      new_invoice_num,
      vendor_id ,
      vendor_site_id;
    lv_invoice_num VARCHAR2(50);
  BEGIN
    FOR i IN c_inv_can
    LOOP
      update ap_invoices_all b
      SET b.attribute4  =i.release_date
      WHERE b.invoice_num =i.new_invoice_num
      AND b.vendor_id     =i.vendor_id
      AND b.vendor_site_id=i.vendor_site_id;
      COMMIT;
    END LOOP;
  end;

/