CREATE OR REPLACE VIEW XX_AR_CBI_SOFTHEADERS_DTL_V
(CONS_INV_ID, CONSINV_LNUM, CONS_LINES_LNUM, INVOICE_NUMBER, INV_DATE, 
 TYPE, U1, S1, D1, L1, 
 R1, TRX_ID, TRX_LINE_ID, INVENTORY_ITEM_ID, ITEM_NUMBER, 
 DESCRIPTION, UNIT_OF_MEASURE, LINE_TAX_AMT, QUANTITY, PRICE, 
 EACH_LINE_AMOUNT, LINE_TOT_AMT)
AS 
SELECT
       arcit.cons_inv_id                                        cons_inv_id
      ,arcit.cons_inv_line_number                               consinv_lnum
      ,consinv_lines.line_number                                cons_lines_lnum
      ,arcit.trx_number                                         invoice_number
      ,TO_CHAR(arcit.transaction_date,'mm/dd/rrrr')             inv_date
      ,DECODE
         (
          arcit.transaction_type
          ,'invoice'
          ,'inv'
          ,'credit_memo'
          ,'cm'
          ,NULL
         )                                                      TYPE
      ,xx_ar_reprint_summbill.get_po_number
         ( arcit.cons_inv_id
          ,arcit.cons_inv_line_number
         )                                                      U1
      ,hzsu.location                                            S1
      ,xxomh.cost_center_dept                                   D1
      ,xxomh.desk_del_addr                                      L1
      ,xxomh.release_number                                     R1
      ,consinv_lines.customer_trx_id                            trx_id
      ,consinv_lines.customer_trx_line_id                       trx_line_id
      ,consinv_lines.inventory_item_id
      ,xx_ar_reprint_summbill.get_item_number
        (
          consinv_lines.inventory_item_id
        )                                                       item_number
      ,consinv_lines.description                                description
      ,consinv_lines.uom_code                                   unit_of_measure
      ,TO_CHAR(consinv_lines.tax_amount,'999990.90')            line_tax_amt
      ,consinv_lines.quantity_invoiced                          quantity
      ,TO_CHAR(consinv_lines.unit_selling_price,'999990.90')    price
      ,TO_CHAR(consinv_lines.extended_amount,'999990.90')       each_line_amount
      ,TO_CHAR
       (
        (  consinv_lines.extended_amount
          +
           consinv_lines.tax_amount
        ),'999990.90'
       )                                                        line_tot_amt
FROM
       ar_cons_inv_trx             arcit
      ,ar_cons_inv_trx_lines       consinv_lines
      ,ar_cons_inv                 arc
      ,hz_cust_site_uses           hzsu
      ,xx_om_header_attributes_all xxomh
      ,oe_order_headers            oeoh
      ,ra_customer_trx             ract
WHERE arc.cons_inv_id                    =arcit.cons_inv_id
  AND consinv_lines.cons_inv_id          =arcit.cons_inv_id
  AND consinv_lines.cons_inv_line_number =arcit.cons_inv_line_number
  AND ract.customer_trx_id               =consinv_lines.customer_trx_id
  AND arcit.transaction_type IN ('INVOICE' ,'CREDIT_MEMO')
  AND hzsu.site_use_id(+)                =ract.ship_to_site_use_id
  AND ract.interface_header_attribute1   =TO_CHAR(oeoh.order_number(+))
  AND oeoh.header_id                     =xxomh.header_id(+)
/