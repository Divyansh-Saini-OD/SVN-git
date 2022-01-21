/************/
--588 Rows to get updated
update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
 4744623
,4744624
,4744625
,4744626
,4744627
,4744628
,4744629
,4744632
,4744633
,4744634
,4744639
)
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



/************/
--598 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 4744623
,4744624
,4744625
,4744626
,4744627
,4744628
,4744629
,4744632
,4744633
,4744634
,4744639
)
and a2.status = 'AR_PLB_INVALID_RECEIPT';



/************/
--1298 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 4744623
,4744624
,4744625
,4744626
,4744627
,4744628
,4744629
,4744632
,4744633
,4744634
,4744639
)
and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in 
(
 4744623
,4744624
,4744625
,4744626
,4744627
,4744628
,4744629
,4744632
,4744633
,4744634
,4744639
))
;
