SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace view XXBI_SALES_HIERARCHY_V as
select 
distinct 
mv.resource_id,
mv.resource_name,
mv.resource_number,
mv.source_phone,
mv.source_email,
mv.user_id,
mv.source_first_name,
mv.source_last_name, 
mv.group_id,
mv.m1_resource_id,
mv.m1_resource_name,
mv.m1_resource_number,
mv.m1_source_email,
mv.m1_user_id,
mv.m2_group_id,
mv.m2_resource_id,
mv.m2_resource_name,
mv.m2_resource_number,
mv.m2_source_email,
mv.m2_user_id,
mv.m3_group_id,
mv.m3_resource_id,
mv.m3_resource_name,
mv.m3_resource_number,
mv.m3_source_email,
mv.m3_user_id,
mv.m4_group_id,
mv.m4_resource_id,
mv.m4_resource_name,
mv.m4_resource_number,
mv.m4_source_email,
mv.m4_user_id,
mv.m5_group_id,
mv.m5_resource_id,
mv.m5_resource_name,
mv.m5_resource_number,
mv.m5_source_email,
mv.m5_user_id,
mv.m6_group_id,
mv.m6_resource_id,
mv.m6_resource_name,
mv.m6_resource_number,
mv.m6_source_email,
mv.m6_user_id
from XXBI_GROUP_MBR_INFO_MV mv, 
(
  select resource_id, max(m1_resource_id) as m1_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by resource_id
) x1,
(
  select m1_resource_id, max(m2_resource_id) as m2_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by m1_resource_id
) x2,
(
  select m2_resource_id, max(m3_resource_id) as m3_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by m2_resource_id
) x3,
(
  select m3_resource_id, max(m4_resource_id) as m4_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by m3_resource_id
) x4,
(
  select m4_resource_id, max(m5_resource_id) as m5_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by m4_resource_id
) x5,
(
  select m5_resource_id, max(m6_resource_id) as m6_resource_id
  from XXBI_GROUP_MBR_INFO_MV 
  group by m5_resource_id
) x6
where mv.resource_id = x1.resource_id 
and mv.m1_resource_id = x1.m1_resource_id
and mv.m2_resource_id = x2.m2_resource_id (+)
and mv.m3_resource_id = x3.m3_resource_id (+)
and mv.m4_resource_id = x4.m4_resource_id (+)
and mv.m5_resource_id = x5.m5_resource_id (+)
and mv.m6_resource_id = x6.m6_resource_id (+)
and nvl(mv.admin_flag, 'N') = 'N'
and 
(
  user_id = FND_GLOBAL.USER_ID
  or m1_user_id = FND_GLOBAL.USER_ID
  or m2_user_id = FND_GLOBAL.USER_ID
  or m3_user_id = FND_GLOBAL.USER_ID
  or m4_user_id = FND_GLOBAL.USER_ID
  or m5_user_id = FND_GLOBAL.USER_ID
  or m6_user_id = FND_GLOBAL.USER_ID
)
/
SHOW ERRORS;
EXIT;