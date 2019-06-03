INSERT INTO apps.qa_plan_chars
      (
	plan_id,
	char_id,
	last_update_date,
	last_updated_by,
	creation_date,
	created_by,
	prompt_sequence,
	prompt,
	enabled_flag,
	mandatory_flag,
	default_value,
	result_column_name,
	values_exist_flag,
	displayed_flag,
	decimal_precision,
	uom_code,
	read_only_flag,
	ss_poplist_flag,
	information_flag 
      )
SELECT 
        b.plan_id,
        f.char_id,
        a.last_update_date,
        33963,
        a.creation_date,
        33963,    
        a.prompt_sequence,
        a.prompt,
        a.enabled_flag,
        a.mandatory_flag,
        a.default_value,
        a.result_column_name,
        a.values_exist_flag,
        a.displayed_flag,
        a.decimal_precision,
        a.uom_code,
        a.read_only_flag,
        a.ss_poplist_flag,
        a.information_flag
  FROM  apps.qa_chars f,
        apps.qa_chars@GSIPRD01.NA.ODCORP.NET e,
        apps.qa_plans b,
        apps.qa_plans@GSIPRD01.NA.ODCORP.NET d,
        apps.qa_plan_chars@GSIPRD01.NA.ODCORP.NET a
 WHERE  d.plan_id=a.plan_id
   AND  b.name=d.name
   AND  d.name like 'OD%'
   AND  e.char_id=a.char_id
   AND  f.name=e.name;

