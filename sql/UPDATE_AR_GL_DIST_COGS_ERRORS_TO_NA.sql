-- Updates COGS Generated DFF for errors
-- Eliminates the error from appearing on exception report
UPDATE ar.ra_cust_trx_line_gl_dist_all a
   SET a.attribute6         = 'NA'
 WHERE a.account_class      = 'REV'
   AND a.attribute_category = 'SALES_ACCT'
   AND a.attribute6         = 'E';
   
COMMIT;   