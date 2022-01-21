/************/
--205 Rows to get updated
update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
 5268567
,5268568
,5268569
,5268570
,5268564
)
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



/************/
--301 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 5268567
,5268568
,5268569
,5268570
,5268564
)
and a2.status = 'AR_PLB_INVALID_RECEIPT';



/************/
--105 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 5268567
,5268568
,5268569
,5268570
,5268564
)
and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in 
(
 5268567
,5268568
,5268569
,5268570
,5268564
))
;
