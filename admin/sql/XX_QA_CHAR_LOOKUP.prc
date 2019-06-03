Insert 
  INTO apps.qa_char_value_lookups 
       (char_id,short_code,attribute14,creation_date,created_by,last_updated_by,last_update_date,
	description)
 select a.char_id,b.short_code,b.attribute14,sysdate,33963,33963,sysdate,b.description
  from apps.qa_chars a,
       apps.qa_char_value_lookups@GSIPRD01.NA.ODCORP.NET b,
       apps.qa_chars@GSIPRD01.NA.ODCORP.NET c
 where c.name like 'OD%'
   and b.char_id=c.char_id
   and a.name=c.name
   and not exists (select 'x'
                     from apps.qa_char_value_lookups e,
                          apps.qa_chars f
                   where f.name=a.name
                     and e.char_id=f.char_id
                     and e.short_code=b.short_code);
commit;
