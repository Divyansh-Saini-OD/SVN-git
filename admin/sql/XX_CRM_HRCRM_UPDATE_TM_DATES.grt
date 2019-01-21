update   jtf.jtf_rs_resource_extns
set 	 attribute14 = to_char(to_date(	attribute14,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YY')
,	   	 attribute15 = to_char(to_date(	attribute15,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YY')  
where  attribute14 is not null 
and	   substr(attribute14,3,1) != '/'
and	   substr(attribute14,5,1) = '/'
;

update   jtf_rs_resource_extns
set		 attribute14 = to_char(to_date(	attribute14,'DD/MM/YYYY'),'DD-MON-YY') 
,	   	 attribute15 = to_char(to_date(	attribute15,'DD/MM/YYYY'),'DD-MON-YY')   
where  attribute14 is not null 
and	   substr(attribute14,3,1) = '/'
and	   substr(attribute14,5,1) != '/'
;

commit;


