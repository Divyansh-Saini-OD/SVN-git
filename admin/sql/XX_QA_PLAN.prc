INSERT INTO apps.qa_plans
      ( plan_id,
	organization_id,
	last_update_date,
	last_updated_by,
	creation_date,
	created_by,
	name,
	description,
	plan_type_code,
	import_view_name,
	instructions,
	view_name,
	effective_from,
	effective_to,
	spec_assignment_type,
	esig_mode)
SELECT  apps.qa_plans_s.nextval,
	c.organization_id,
    a.last_update_date,
    33963,
    a.creation_date,
    33963,
    a.name,
    a.description,
    a.plan_type_code,
    a.import_view_name,
    a.instructions,
    a.view_name,
    a.effective_from,
    a.effective_to,
    a.spec_assignment_type,
    a.esig_mode
  FROM    apps.hr_all_organization_units c,
    apps.hr_all_organization_units@GSIPRD01.NA.ODCORP.NET b,
    apps.qa_plans@GSIPRD01.NA.ODCORP.NET a
 WHERE  a.name like 'OD%'
   AND  b.organization_id=a.organization_id
   AND  c.name=b.name
   and not exists (select 'x' from apps.qa_plans where name=a.name);
commit;
