--*
--* short term fix 1. for OTB purge
--*
        DELETE FROM xxfin.xx_ar_otb_transactions xaot
        WHERE EXISTS
                (SELECT 'x'
                 FROM   apps.ra_customer_trx_all rct,
                        apps.oe_order_headers_all ooh,
                        apps.oe_transaction_types_tl ott
                 WHERE  ooh.order_type_id = ott.transaction_type_id
                 AND    rct.interface_header_attribute2 = ott.name
                 AND    rct.interface_header_context = 'ORDER ENTRY'
                 AND    rct.trx_number = to_char(ooh.order_number)
                 AND    ooh.orig_sys_document_ref =
                           DECODE(xaot.register_num,'99',
                             xaot.order_num||LPAD(xaot.sub_order_num,3,'0'),
                             xaot.store_num||TO_CHAR(xaot.trans_date,'YYYYMMDD')
                               ||LPAD(xaot.register_num,3,'0')||LPAD(xaot.sale_tran,5,'0') ) );

--*
--* short term fix 2. for OTB purge
--*
  DELETE FROM xxfin.xx_ar_otb_transactions xaot
         WHERE EXISTS
                (SELECT 'X'
                 FROM   apps.ra_customer_trx_all rct
                 WHERE  xaot.order_num||LPAD(xaot.sub_order_num,3,'0') = rct.trx_number
                 AND    xaot.register_num = '99');

--*
--* short term fix 3. for OTB purge
--*
  delete FROM xxfin.xx_ar_otb_transactions xaot
         WHERE EXISTS
                (SELECT 'X'
                 FROM   apps.ra_customer_trx_all rct,
                        apps.oe_order_headers_all ooh
                 WHERE  rct.trx_number = to_char(ooh.order_number)   
                 and ooh.orig_sys_document_ref = xaot.store_num||TO_CHAR(xaot.trans_date,'YYYYMMDD')
                               ||LPAD(xaot.register_num,3,'0')||LPAD(xaot.sale_tran,5,'0')
                 AND    xaot.register_num <> '99');


--*
--* short term fix 4. for OTB purge
--* 
  DELETE FROM xxfin.xx_ar_otb_transactions xaot 
         WHERE xaot.response_code <> '0'

--*
--* short term fix 5. for OTB purge where substr(order_num,1,5) = 2
--* 
delete 
from   xxfin.xx_ar_otb_transactions otb
       where exists (
             select 'x'
             from   apps.oe_order_headers_all ord
             where  ord.orig_sys_document_ref = 
             substr(otb.order_num,1,4)||'1'||substr(otb.order_num,6,4)||LPAD(otb.sub_order_num,3,'0')
             and    otb.register_num = '99'
             and    otb.response_code = '0')
and substr(otb.order_num,5,1) = '2'
and trunc(otb.trans_date) <= '17-JUL-2009';      
