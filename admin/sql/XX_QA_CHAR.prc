INSERT INTO apps.qa_chars 
       (char_id,last_update_date,last_updated_by,creation_date,created_by,
	name,char_type_code,char_context_flag,prompt,data_entry_hint,datatype,
	display_length,decimal_precision,default_value,mandatory_flag,
	sql_validation_string,
	enabled_flag,values_exist_flag,sequence_number,
	sequence_prefix,sequence_start,
	sequence_length,sequence_increment,sequence_nextval,
	sequence_zero_pad)
SELECT  apps.qa_chars_s.nextval,sysdate,33963,sysdate,33963,
	a.name,a.char_type_code,a.char_context_flag,a.prompt,a.data_entry_hint,a.datatype,
	a.display_length,a.decimal_precision,a.default_value,a.mandatory_flag,
	a.sql_validation_string,a.enabled_flag,a.values_exist_flag,a.sequence_number,
	a.sequence_prefix,a.sequence_start,
	a.sequence_length,a.sequence_increment,a.sequence_nextval,
	a.sequence_zero_pad
  FROM apps.qa_chars@GSIDEV02.NA.ODCORP.NET a
 WHERE a.name like 'OD%'  
   AND not exists (select 'x'
		     from apps.qa_chars
		    where name=a.name);
commit;
