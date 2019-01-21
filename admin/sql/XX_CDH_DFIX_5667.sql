--Script to generate new cust doc id sequence and update the
--combo doc's cust doc id with this sequence, so that the 
--duplicate issue is combo docs will be resolved
declare

cursor c1
is
select /*+ parallel (a,4) */ *
from   apps.xx_cdh_cust_acct_ext_b a
where  attr_group_id=166
and    (c_ext_attr13 is not null and c_ext_attr13 <> 'CR');

begin

  for i in c1
  loop
    update apps.xx_cdh_cust_acct_ext_b
	set    n_ext_attr2 = XX_CDH_CUST_DOC_ID_S.nextval,
	       c_ext_attr19 = i.n_ext_attr2
	where  extension_id = i.extension_id;
	
  end loop;

  commit;
  
exception
  when others then
    dbms_output.put_line('Exception :' || SQLERRM);
end;	
/

