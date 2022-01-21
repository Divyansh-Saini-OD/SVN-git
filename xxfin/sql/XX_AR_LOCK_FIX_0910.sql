update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in ('4315552','4315576','4315524','4315535','4315435','4315504','4315485','4315601','4315594','4315566','4315470')
      and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');
-- - 346 rows should get updated.

update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where 
  a2.transmission_request_id in ('4315552','4315576','4315524','4315535','4315435','4315504','4315485','4315601','4315594','4315566','4315470')
 and a2.status = 'AR_PLB_INVALID_RECEIPT';

- - 2982 rows should get updated