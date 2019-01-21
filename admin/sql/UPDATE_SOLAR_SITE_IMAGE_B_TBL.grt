UPDATE xxcnv.xx_cdh_solar_siteimage b
set b.internid = '9'||b.internid
where exists (SELECT 1
              FROM   xxcnv.xx_cdh_solar_conversion_group a
              WHERE  a.conversion_rep_id = b.conversion_rep_id
              AND    a.conversion_group_id = 'N')
and not exists (Select 1
               FROM   apps.xx_cdh_solar_siteimage c
               WHERE  c.internid = '9'||b.internid
              ) 
and b.site_type in ('SHIPTO');

COMMIT;
