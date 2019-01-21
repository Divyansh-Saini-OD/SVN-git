update ra_customer_trx_all set BILLING_DATE='15-DEC-18' where bill_to_customer_id in (33595139,24638,54409,
8648155,
233948,
34912541) and creation_date >= sysdate-2 AND attribute15='N' AND BILLING_DATE='22-DEC-18';

COMMIT;   

SHOW ERRORS;

EXIT;