BEGIN

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