--Update script to fix Lockbox issue


update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
 '4358690'
)
    and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where 
    a2.transmission_request_id in 
(
'4358690'
)
    and a2.status = 'AR_PLB_INVALID_RECEIPT';

