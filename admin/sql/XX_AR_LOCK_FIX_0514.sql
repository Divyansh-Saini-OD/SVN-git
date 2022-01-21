/************/
--754 Rows to get updated
update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
 5026442
,5026431
,5026445
,5026450
,5026440
,5026439
,5026444
,5026441
,5026443
,5026434
,5026446
)
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



/************/
--1058 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 5026442
,5026431
,5026445
,5026450
,5026440
,5026439
,5026444
,5026441
,5026443
,5026434
,5026446
)
and a2.status = 'AR_PLB_INVALID_RECEIPT';



/************/
--1836 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 5026442
,5026431
,5026445
,5026450
,5026440
,5026439
,5026444
,5026441
,5026443
,5026434
,5026446
)
and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in 
(
 5026442
,5026431
,5026445
,5026450
,5026440
,5026439
,5026444
,5026441
,5026443
,5026434
,5026446
))
;
