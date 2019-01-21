create or replace trigger xx_fnd_folder 
before insert or update
on fnd_folders FOR EACH ROW
Declare
begin
if (:new.where_clause is null  
or ((upper(:new.where_clause)) like  '%LIKE%')
and nvl(:new.autoquery_flag,'Y')<>'N' )
then
:new.autoquery_flag :='N';
end if ;
end;
/