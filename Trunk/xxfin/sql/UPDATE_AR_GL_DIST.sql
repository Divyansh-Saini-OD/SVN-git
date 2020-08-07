update apps.ra_cust_trx_line_gl_dist_all a
set a.attribute6 = 'N'
where a.account_class = 'REV'
and a.attribute_category = 'SALES_ACCT'
and a.attribute6 = 'Y'
and a.gl_posted_date is not null
and a.org_id = '404'
and exists
   (select 'x'
    from apps.ra_customer_trx_lines_all b,
         apps.ra_customer_trx_all c
    where b.customer_trx_line_id = a.customer_trx_line_id
    and c.customer_trx_id = b.customer_trx_id
--    and c.trx_date = '13-FEB-2008'
    and c.org_id = '404');
