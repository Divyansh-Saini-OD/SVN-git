 update jtf_rs_groups_b jrgb
 set    jrgb.attribute15 = 
 (
 SELECT      papf.person_id
      FROM    jtf_rs_groups_vl jrgv
      ,       per_all_people_f papf
      WHERE   substr(JRGV.group_name,instr(JRGV.group_name,'_',8)+1,10)  = papf.employee_number
      and     jrgv.group_id = (select min(group_id) from jtf_rs_groups_vl jrgv1 where  substr(JRGV1.group_name,instr(JRGV1.group_name,'_',8)+1,10)  = papf.employee_number)
      and     jrgv.group_id = jrgb.group_id
)
where   jrgb.group_id in
( SELECT     jrgv.group_id
      FROM    jtf_rs_groups_vl jrgv
      ,       per_all_people_f papf
      WHERE   substr(JRGV.group_name,instr(JRGV.group_name,'_',8)+1,10)  = papf.employee_number
      and     jrgv.group_id = (select min(group_id) from jtf_rs_groups_vl jrgv1 where  substr(JRGV1.group_name,instr(JRGV1.group_name,'_',8)+1,10)  = papf.employee_number)  
); 


