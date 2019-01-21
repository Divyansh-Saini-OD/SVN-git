update ar.ra_cust_trx_line_gl_dist_all a
set a.attribute6 = 'Y'
where a.account_class = 'REV'
and a.attribute_category = 'SALES_ACCT'
and a.gl_posted_date is not null
and trunc(creation_date) <> '01-APR-2008';