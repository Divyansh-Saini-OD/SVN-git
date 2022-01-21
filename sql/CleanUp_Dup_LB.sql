DELETE   APPS.xx_AR_PAYMENTS_INTERFACE
WHERE  process_num  IN 
   (SELECT distinct a.process_num
    FROM APPS.xx_AR_PAYMENTS_INTERFACE  a, 
         apps.AR_TRANSMISSIONS_ALL b 
    WHERE b.transmission_name  = substr(a.file_name, 1, 30)
    AND b.STATUS = 'NB'
    );
  

DELETE APPS.AR_PAYMENTS_INTERFACE_all  a
 WHERE  a.transmission_request_id   IN 
 (SELECT   transmission_request_id
  FROM   apps.AR_TRANSMISSIONS_ALL b 
  WHERE b.STATUS = 'NB'
  );



update AR_INTERIM_CASH_RCPT_LINES_ALL ar
       set ar.payment_amount= (
select amount from AR_INTERIM_CASH_RECEIPTS_ALL ar2
where ar.cash_receipt_id = ar2.cash_receipt_id)
where ar.sold_to_customer = 254212
and   ar.payment_amount = 0;