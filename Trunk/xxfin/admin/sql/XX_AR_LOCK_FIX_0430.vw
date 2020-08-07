update apps.ar_payment_schedules_all set cons_inv_id = null where cons_inv_id >= 594065;
update apps.ar_adjustments_all set cons_inv_id = null  where cons_inv_id >= 594065;
update apps.ar_receivable_applications_all set cons_inv_id = null  where cons_inv_id >= 594065;

delete apps.ar_cons_inv_trx_lines_all where cons_inv_id >= 594065;

delete apps.ar_cons_inv_trx_all where cons_inv_id >= 594065;

delete apps.ar_cons_inv_all where cons_inv_id >= 594065;


/*delete apps.ar_cons_inv_trx_lines_all 
where cons_inv_id in 
(select cons_inv_id 
from apps.ar_cons_inv_all
where attribute14='6680315');

delete apps.ar_cons_inv_trx_all 
where cons_inv_id in 
(select cons_inv_id from apps.ar_cons_inv_all
where attribute14='6680315');

delete apps.ar_cons_inv_all 
where cons_inv_id in 
(select cons_inv_id from apps.ar_cons_inv_all
where attribute14='6680315');
*/
--drop table "XXFIN"."XX_AR_INTERIM_CUST_ACCT_ID";

--drop SYNONYM APPS.xx_ar_interim_cust_acct_id;

commit;