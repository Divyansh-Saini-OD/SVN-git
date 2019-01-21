update xxcnv.xx_cdh_solar_contactimage b
set b.internid = '9'||b.internid
where exists(SELECT 1
               FROM xxcnv.xx_cdh_solar_siteimage a,
	            xxcnv.xx_cdh_solar_conversion_group c
              WHERE a.conversion_rep_id = c.conversion_rep_id
	      and a.internid = '9'||b.internid 
              AND c.conversion_group_id = 'N');

COMMIT;