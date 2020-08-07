update apps.ra_customer_trx_all set attribute11=null
where trx_date between '01-jan-2009' and '30-jan-2009';
/
commit;
/