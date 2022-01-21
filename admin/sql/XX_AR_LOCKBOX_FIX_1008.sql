--Update script to fix Lockbox issue

update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in (4843921,4843959,4843971,4839217,4844015,4843930,4839209,4844002,4843940,4843952,4843983,4843910,4843993)
      and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT') ;

-- 994 records should get updated.

update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where 
  a2.transmission_request_id in  (4843921,4843959,4843971,4839217,4844015,4843930,4839209,4844002,4843940,4843952,4843983,4843910,4843993)
 and a2.status = 'AR_PLB_INVALID_RECEIPT';


update ar_payments_interface_all a2
set a2.customer_number = 1133
where a2.transmission_request_id in  (4843921,4843959,4843971,4839217,4844015,4843930,4839209,4844002,4843940,4843952,4843983,4843910,4843993)
and a2.status = 'AR_PLB_BAD_CUST_NUM';

--32 rows should get updated.

update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where 
  a2.transmission_request_id in  (4843921,4843959,4843971,4839217,4844015,4843930,4839209,4844002,4843940,4843952,4843983,4843910,4843993)
  and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in  (4843921,4843959,4843971,4839217,4844015,4843930,4839209,4844002,4843940,4843952,4843983,4843910,4843993));

