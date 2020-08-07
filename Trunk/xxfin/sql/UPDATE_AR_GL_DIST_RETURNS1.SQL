update apps.ra_cust_trx_line_gl_dist_all a
set a.attribute6 = 'N'
where exists
   (select 'x'
    from apps.ra_customer_trx_lines_all b
    where b.sales_order in
(
'195633403003009',
'195633403003010',	
'195633403003017',	
'583073302001005'	
)
and b.customer_trx_line_id = a.customer_trx_line_id)
and a.account_class = 'REV'
and a.attribute_category = 'SALES_ACCT'
and a.attribute6 = 'Y'
and a.gl_posted_date is not NULL;