BEGIN

 Update xx_cdh_solar_siteimage b
   set b.internid = '9'||b.internid 
where exists (SELECT 1
                from xx_cdh_solar_conversion_group a
               where a.conversion_rep_id = b.conversion_rep_id
                 and a.conversion_group_id = 'N')
 and b.site_type in ('TARGET','PROSPECT');

COMMIT;

update xxcnv.xx_cdh_solar_contactimage b
set b.internid = '9'||b.internid
where exists(SELECT 1
               FROM xxcnv.xx_cdh_solar_siteimage a,
	            xx_cdh_solar_conversion_group c
              WHERE a.conversion_rep_id = c.conversion_rep_id
	      and a.internid = '9'||b.internid 
              AND a.conversion_group_id = 'N');

COMMIT;

update xxcnv.xx_cdh_solar_noteimage b
set b.internid = '9'||b.internid
where exists(SELECT 1
               FROM xxcnv.xx_cdh_solar_siteimage a,
	            xx_cdh_solar_conversion_group c
              WHERE a.conversion_rep_id = c.conversion_rep_id
	      and a.internid = '9'||b.internid 
              AND a.conversion_group_id = 'N');


COMMIT;

update xxcnv.xx_cdh_solar_todoimage b
set b.internid = '9'||b.internid
where exists(SELECT 1
               FROM xxcnv.xx_cdh_solar_siteimage a,
	            xx_cdh_solar_conversion_group c
              WHERE a.conversion_rep_id = c.conversion_rep_id
	      and a.internid = '9'||b.internid 
              AND a.conversion_group_id = 'N');


COMMIT;

update xx_cdh_solar_opporimage b
set b.internid = '9'||b.internid
where exists(SELECT 1
               FROM xxcnv.xx_cdh_solar_siteimage a,
	            xx_cdh_solar_conversion_group c
              WHERE a.conversion_rep_id = c.conversion_rep_id
	      and a.internid = '9'||b.internid 
              AND a.conversion_group_id = 'N');

COMMIT;

END;