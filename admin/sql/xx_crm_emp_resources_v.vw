create or replace view apps.xx_crm_emp_resources_v
as
  SELECT a.* ,case
when a.end_date_active < sysdate
Then 'I' 
else 
'A' end status 
  FROM   apps.jtf_rs_resource_extns_vl  a   
  WHERE EXISTS ( SELECT 1
  			FROM apps.jtf_rs_roles_vl c,
    			apps.jtf_rs_group_mbr_role_vl d,
    			apps.per_jobs pj,
    			apps.jtf_rs_job_roles jrjr,
    			apps.per_all_assignments_f af
  			WHERE d.resource_id        = a.resource_id
  			AND c.role_id              = d.role_id
  			AND c.role_type_code      IN ('SALES', 'TELESALES')
  			AND pj.job_id              = jrjr.job_id
  			AND jrjr.role_id           = c.role_id
  			AND NVL(c.active_flag,'N') = 'Y'
  			AND pj.job_id              =af.job_id
  			AND af.person_id           = a.source_id
                )
     and  ascii(substr(source_number, 0,1))>=48
    and  ascii(substr(source_number, 0,1))<=57
   AND  a.source_number IS NOT NULL;