/************/
--255 Rows to get updated
update ar_payments_interface_all 
set transit_routing_number = NULL, account = NULL
where transmission_request_id in
(
 4822794
,4913403
,4822805
,4913400
,4822798
,4913401
,4822800
,4822803
,4822797
,4822802
,4822795
,4822799
,4822796
,4822801
)
and status in ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');



/************/
--851 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
    a2.invoice2 = null,a2.amount_applied2 = null,
    a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 4822794
,4913403
,4822805
,4913400
,4822798
,4913401
,4822800
,4822803
,4822797
,4822802
,4822795
,4822799
,4822796
,4822801
)
and a2.status = 'AR_PLB_INVALID_RECEIPT';



/************/
--98 Rows to get updated
update ar_payments_interface_all a2
set a2.invoice1 = null,a2.amount_applied1 = null,
  a2.invoice2 = null,a2.amount_applied2 = null,
  a2.invoice3= null, a2.amount_applied3= null
where a2.transmission_request_id in 
(
 4822794
,4913403
,4822805
,4913400
,4822798
,4913401
,4822800
,4822803
,4822797
,4822802
,4822795
,4822799
,4822796
,4822801
)
and a2.batch_name||a2.item_number in 
                    (select a1.batch_name||a1.item_number from ar_payments_interface_all a1 
                      where 
                        a1.status = 'AR_PLB_REMIT_EXCEEDED' 
                        and a1.transmission_request_id in 
(
 4822794
,4913403
,4822805
,4913400
,4822798
,4913401
,4822800
,4822803
,4822797
,4822802
,4822795
,4822799
,4822796
,4822801
))
;
