update apps.ra_cust_trx_line_gl_dist_all a
set a.attribute6 = 'N'
where exists
   (select 'x'
    from apps.ra_customer_trx_lines_all b
    where b.sales_order in
('424702168001',
'424988887001',	
'425136763001',	
'425140322001',	
'425132965001',	
'425142036001',	
'425128365001',	
'425128365001',	
'425128365001',	
'425105718001',	
'425121064001',	
'425103882001',	
'425103882001',	
'425103882001',	
'425103882001',	
'900002869001',	
'900003137001',	
'900003137001',	
'900003137001',	
'900002868001')
and b.customer_trx_line_id = a.customer_trx_line_id)
and a.account_class = 'REV'
and a.attribute_category = 'SALES_ACCT'
and a.attribute6 = 'Y'
and a.gl_posted_date is not NULL;