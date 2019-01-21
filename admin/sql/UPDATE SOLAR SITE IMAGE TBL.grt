 Update xx_cdh_solar_siteimage b
   set b.internid = '9'||b.internid 
where exists (SELECT 1
                from xx_cdh_solar_conversion_group a
               where a.conversion_rep_id = b.conversion_rep_id
                 and a.conversion_group_id = 'N')
 and b.site_type in ('TARGET','PROSPECT');

COMMIT;
