SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

grant select on apps.jtf_rs_group_members to XXCRM;
grant select on apps.jtf_rs_role_relations to XXCRM;
grant select on apps.jtf_rs_roles_vl to XXCRM;
grant select on apps.jtf_rs_groups_vl to XXCRM;
grant select on apps.jtf_rs_resource_extns_vl to XXCRM;
grant select on apps.jtf_rs_grp_relations_vl to XXCRM;

SHOW ERRORS;
EXIT;