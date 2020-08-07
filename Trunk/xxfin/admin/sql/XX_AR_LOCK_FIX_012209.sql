/************/
update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
4447131,
4447129,
4447125,
4447136,
4447127,
4447124,
4447133,
4447134,
4447128,
4447130,
4447126
)
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



/************/
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
4447131,
4447129,
4447125,
4447136,
4447127,
4447124,
4447133,
4447134,
4447128,
4447130,
4447126
)
and a2.status = 'AR_PLB_INVALID_RECEIPT';



/************/
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
4447131,
4447129,
4447125,
4447136,
4447127,
4447124,
4447133,
4447134,
4447128,
4447130,
4447126
)
and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in 
(
4447131,
4447129,
4447125,
4447136,
4447127,
4447124,
4447133,
4447134,
4447128,
4447130,
4447126
))
;
