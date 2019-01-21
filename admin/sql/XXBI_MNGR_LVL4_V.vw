SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace view XXBI_MNGR_LVL4_V as
select distinct m4_resource_id as id, m4_resource_name || ' (' || m4_role_name || ')' as value
from XXBI_GROUP_MBR_INFO_MV 
where manager_flag = 'Y'
and m4_resource_id is not null
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