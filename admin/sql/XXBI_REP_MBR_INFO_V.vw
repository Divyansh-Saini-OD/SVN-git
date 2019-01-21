SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace view XXBI_REP_MBR_INFO_V as
select   
group_member_id,
resource_id,
resource_name,
resource_number,
source_phone,
source_email,
user_id,
group_id,
group_name,
group_number,
role_id,
role_code,
role_name,
role_desc,
legacy_sales_id,
source_first_name,
source_last_name,  
member_flag,
admin_flag,
manager_flag,
lead_flag,
role,
div,
start_date_active,
end_date_active,
role_relate_id,
m1_role,
m1_div,
m1_resource_id,
m1_resource_name,
m1_resource_number,
m1_role_id,
m1_role_name,
m1_source_email,
m1_user_id,
m1_start_date_active,
m1_end_date_active,
m2_group_id,
m2_resource_id,
m2_resource_name,
m2_resource_number,
m2_role_id,
m2_role_name,
m2_source_email,
m2_user_id,
m2_role,
m2_div,
m2_start_date_active,
m2_end_date_active,
m3_group_id,
m3_resource_id,
m3_resource_name,
m3_resource_number,
m3_role_id,
m3_role_name,
m3_source_email,
m3_user_id,
m3_role,
m3_div,
m4_group_id,
m4_resource_id,
m4_resource_name,
m4_resource_number,
m4_role_id,
m4_role_name,
m4_source_email,
m4_user_id,
m4_role,
m4_div,
m5_group_id,
m5_resource_id,
m5_resource_name,
m5_resource_number,
m5_role_id,
m5_role_name,
m5_source_email,
m5_user_id,
m5_role,
m5_div,
m6_group_id,
m6_resource_id,
m6_resource_name,
m6_resource_number,
m6_role_id,
m6_role_name,
m6_source_email,
m6_user_id,
m6_role,
m6_div
from XXBI_GROUP_MBR_INFO_MV where member_flag = 'Y'
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