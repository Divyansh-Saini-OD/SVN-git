-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_JTF_RSC_ROLE_ASSIGNMENTS.vw                            |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This database view is the base table for the form                        |
-- | XX_JTF_PROXY_ASSIGNMENTS.fmb.                                            |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       23-SEP-2009  Phil Price         Initial version                 |
-- +==========================================================================+

create or replace view apps.xx_jtf_rsc_role_assignments as
select 
-- Subversion Info:
--   $HeadURL$
--       $Rev$
--      $Date$
       rrel.rowid row_id,
       rsc.resource_id,
       rsc.resource_name,
       rol.role_type_code,
       lu.meaning             role_type_meaning,
       rol.role_code,
       rol.role_name,
       grp.group_id,
       grp.group_name,
       grpm.group_member_id,
       rrel.role_relate_id,
       rrel.start_date_active     role_rel_start_date,
       rrel.end_date_active       role_rel_end_date,
       rrel.delete_flag           role_rel_delete_flag,
       rrel.object_version_number role_rel_obj_ver_num,
       rrel.attribute15           rep_id,
       rrel.creation_date,
       rrel.created_by,
       rrel.last_update_date,
       rrel.last_updated_by,
       rrel.last_update_login
  from jtf_rs_resource_extns_vl rsc,
       jtf_rs_group_members     grpm,
       jtf_rs_groups_vl         grp,
       jtf_rs_role_relations    rrel,
       jtf_rs_roles_vl          rol,
       fnd_lookups              lu
 where rsc.resource_id         = grpm.resource_id
   and grpm.group_id           = grp.group_id
   and grpm.group_member_id    = rrel.role_resource_id
   and rrel.role_id            = rol.role_id
   and rol.role_type_code      = lu.lookup_code
   and lu.lookup_type          = 'JTF_RS_ROLE_TYPE'
   and rrel.role_resource_type = 'RS_GROUP_MEMBER'
   and grpm.delete_flag        = 'N'
   and rrel.delete_flag        = 'N'
   and rol.active_flag         = 'Y'
   and trunc(sysdate)          between trunc(nvl(rsc.start_date_active,  sysdate -1))
                                   and trunc(nvl(rsc.end_date_active,    sysdate +1))
   and trunc(sysdate)          between trunc(nvl(grp.start_date_active,  sysdate -1))
                                   and trunc(nvl(grp.end_date_active,    sysdate +1))
/
