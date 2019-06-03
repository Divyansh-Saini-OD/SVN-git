INSERT INTO apps.qa_plan_char_value_lookups
      (
	plan_id,
	char_id,
	short_code,
	attribute14,
	last_update_date,
	last_updated_by,
	creation_date,
	created_by,
	description
      )
SELECT  b.plan_id,
	f.char_id,
	a.short_code,
	a.attribute14,
	a.last_update_date,
	33963,
	a.creation_date,
	33963,
	a.description
  FROM  apps.qa_chars f,
        apps.qa_chars@GSIPRD01.NA.ODCORP.NET e,
        apps.qa_plans b,
        apps.qa_plans@GSIPRD01.NA.ODCORP.NET d,
	apps.qa_plan_char_value_lookups@GSIPRD01.NA.ODCORP.NET a	
 WHERE  d.plan_id=a.plan_id
   AND  b.name=d.name
   AND  d.name like 'OD%'
   AND  e.char_id=a.char_id
   AND  f.name=e.name;
commit;
