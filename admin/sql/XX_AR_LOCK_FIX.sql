update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in ('4188129','4188127','4188133','4189212','4188142','4189231','4189177','4188128'
,'4189209','4189206','4189232')
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');

--850 rows should get updated.

update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where 
  a2.transmission_request_id in ('4188129','4188127','4188133','4189212','4188142','4189231','4189177','4188128','4189209','4189206','4189232')
 and a2.status = 'AR_PLB_INVALID_RECEIPT' ;

--1187 rows should get updated.

