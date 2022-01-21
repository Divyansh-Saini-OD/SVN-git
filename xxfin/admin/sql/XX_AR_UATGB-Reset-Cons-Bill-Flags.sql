declare
begin
update apps.ar_cons_inv_all
   set attribute2 =NULL
      ,attribute4 =NULL
      ,attribute10 =NULL
where customer_id IN 
(
16332
,25057
,192840
,23588
,292182
,294632
,282880
,285237
,9661
,259495
,89896
,83233
,169451
,17288
,68703
,18325
,188006
)
and trunc(creation_date) >='15-JUL-08';
commit;
exception
 when others then
  dbms_output.put_line(sqlerrm);
  rollback;
end;
/