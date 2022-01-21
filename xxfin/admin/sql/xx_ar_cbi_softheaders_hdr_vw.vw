CREATE OR REPLACE VIEW XX_AR_CBI_SOFTHEADERS_HDR_V
(CONS_INV_ID, CBI_NUMBER, TRX_ID, CONSINV_LNUM, INVOICE_NUMBER, 
 INV_DATE, TYPE, U1, S1, D1, 
 L1, R1, LINE_AMOUNT, TAX_AMOUNT, TOTAL_AMOUNT)
AS 
SELECT   c.cons_inv_id ,d.cons_billing_number cbi_number ,b.customer_trx_id trx_id,
            c.cons_inv_line_number consinv_lnum,
            b.trx_number "INVOICE_NUMBER",
            TO_CHAR (b.trx_date, 'MM/DD/RRRR') "INV_DATE",
            c.transaction_type "TYPE",
            xx_ar_reprint_summbill.get_po_number (c.cons_inv_id,
                                                  c.cons_inv_line_number
                                                 ) u1,
            hzsu.LOCATION s1, xxomh.cost_center_dept d1,
            xxomh.desk_del_addr l1, xxomh.release_number r1,
            c.amount_original line_amount, c.tax_original tax_amount,
            (c.amount_original + c.tax_original) "TOTAL_AMOUNT"
       FROM ar_cons_inv_trx_lines a,
            ra_customer_trx b,
            ar_cons_inv_trx c,
            ar_cons_inv     d,
            hz_cust_site_uses hzsu,
            xx_om_header_attributes_all xxomh,
            oe_order_headers oeoh
      WHERE a.customer_trx_id = b.customer_trx_id
        AND a.cons_inv_line_number = c.cons_inv_line_number
        AND c.cons_inv_id = a.cons_inv_id
        AND hzsu.site_use_id(+) = b.ship_to_site_use_id
        AND b.interface_header_attribute1 = TO_CHAR (oeoh.order_number(+))
        AND oeoh.header_id = xxomh.header_id(+)
        AND d.cons_inv_id =c.cons_inv_id
   GROUP BY c.cons_inv_id,
            d.cons_billing_number,
            b.customer_trx_id,
            c.cons_inv_line_number,
            b.trx_number,
            b.trx_date,
            c.transaction_type,
            xx_ar_reprint_summbill.get_po_number (c.cons_inv_id,
                                                  c.cons_inv_line_number
                                                 ),
            c.amount_original,
            c.tax_original,
            hzsu.LOCATION,
            xxomh.cost_center_dept,
            xxomh.desk_del_addr,
            xxomh.release_number
/