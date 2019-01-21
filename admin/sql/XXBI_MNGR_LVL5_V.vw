SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace view XXBI_MNGR_LVL5_V as
select distinct m5_resource_id as id, m5_resource_name || ' (' || m5_role_name || ')' as value
from XXBI_GROUP_MBR_INFO_MV 
where manager_flag = 'Y'
and m5_resource_id is not null
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
order by value;  

SHOW ERRORS;
EXIT;