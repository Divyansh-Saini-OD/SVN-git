--Update script tofix Lockbox issue

UPDATE ar_payments_interface_all 
SET transit_routing_number = NULL, account = NULL
WHERE transmission_request_id IN ('4498464','4498804','4498854','4498840','4498832','4498706','4498873','4498470','4498032','4498785','4498823')
AND status IN ('AR_PLB_CUSTOMER_CONFLICT','AR_PLB_BAD_MICR_NUM','AR_PLB_NEW_MICR_CONFLICT');

--295 rows needs to get updated

UPDATE ar_payments_interface_all a2
SET a2.invoice1 = NULL,a2.amount_applied1 = NULL,
    a2.invoice2 = NULL,a2.amount_applied2 = NULL,
    a2.invoice3= NULL, a2.amount_applied3= NULL
WHERE a2.transmission_request_id in ('4498464','4498804','4498854','4498840','4498832','4498706','4498873','4498470','4498032','4498785','4498823')
AND a2.status = 'AR_PLB_INVALID_RECEIPT';

--464 rows needs to get updated