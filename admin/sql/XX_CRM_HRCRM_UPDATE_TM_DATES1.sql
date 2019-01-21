
-- -------------------------
-- Delete the Resource Roles
-- -------------------------

delete from jtf.JTF_RS_ROLE_RELATIONS --7224 Role
where  role_resource_type = 'RS_INDIVIDUAL'
and	   role_resource_id in 
(
select resource_id 
from   apps.JTF_RS_resource_extns_vl
where  attribute14 is not null
)
;


-- ---------------------------------
-- Delete the Group Membership Roles
-- ---------------------------------

delete from jtf.JTF_RS_ROLE_RELATIONS --7104 Grp Member Roles
where  role_resource_type = 'RS_GROUP_MEMBER'
and	   role_resource_id in 
(
select group_member_id 
from apps.jtf_rs_group_mbr_role_vl 
where resource_id in ( select resource_id 
from   apps.JTF_RS_resource_extns_vl
where  attribute14 is not null
)
)
;

-- -----------------
-- Delete the Groups
-- -----------------

delete from jtf.JTF_RS_ROLE_RELATIONS --4154 Grps 
where  role_resource_type = 'RS_GROUP'
and	   role_resource_id in 
(
select group_id
from   jtf.jtf_rs_group_members
where  resource_id in 
( select resource_id 
from   apps.JTF_RS_resource_extns_vl
where  attribute14 is not null
)
)
;

-- ----------------------------
-- Delete the Group Memberships
-- ----------------------------

delete from jtf.jtf_rs_group_members -- 2057 Grp Membership
where  resource_id in 
( select resource_id 
from   apps.JTF_RS_resource_extns_vl
where  attribute14 is not null
)
;

-- -------------------------------------
-- Delete the Parent Child Relationships
-- -------------------------------------

delete from jtf.jtf_rs_grp_relations -- 182 Hierarchy
where  creation_date > '20-MAR-08' 
;

commit;
