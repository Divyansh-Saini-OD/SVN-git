DROP MATERIALIZED VIEW APPS.DLXM_GROUP_MBR_INFO_MV;

CREATE MATERIALIZED VIEW APPS.DLXM_GROUP_MBR_INFO_MV
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  DISABLE QUERY REWRITE
  AS (
SELECT distinct
  CAST(REP.group_member_id AS NUMBER) group_member_id,
  CAST(REP.resource_id AS NUMBER) resource_id,
  CAST(REP.resource_name AS VARCHAR2(360)) resource_name,
  CAST(REP.resource_number AS VARCHAR(30)) resource_number,
  CAST(REP.source_phone AS VARCHAR2(2000)) source_phone,
  CAST(REP.source_email AS VARCHAR2(2000)) source_email,
  CAST(REP.user_id AS NUMBER) user_id,
  CAST(REP.group_id AS NUMBER) group_id,
  CAST(REP.group_name AS VARCHAR2(60)) group_name,
  CAST(REP.group_number AS VARCHAR2(30)) group_number,
  CAST(REP.role_id AS NUMBER) role_id,
  CAST(REP.role_code AS VARCHAR2(30))  role_code,
  CAST(REP.role_name AS VARCHAR2(60)) role_name,
  CAST(REP.role_desc AS VARCHAR2(120)) role_desc,
  CAST(REP.legacy_sales_id AS VARCHAR2(150)) legacy_sales_id,
  CAST(REP.source_first_name AS VARCHAR2(360)) source_first_name,
  CAST(REP.source_last_name  AS VARCHAR2(360)) source_last_name,  
  CAST(REP.member_flag AS VARCHAR2(1)) member_flag,
  CAST(REP.admin_flag AS VARCHAR2(1)) admin_flag,
  CAST(REP.manager_flag AS VARCHAR2(1)) manager_flag,
  CAST(REP.lead_flag AS VARCHAR2(1)) lead_flag,
  CAST(REP.attribute14 AS VARCHAR2(150)) role,
  CAST(REP.attribute15 AS VARCHAR2(150)) div,
  CAST(REP.start_date_active AS DATE) start_date_active,
  CAST(REP.end_date_active AS DATE) end_date_active,
  CAST(DSM.start_date_active AS DATE) m1_start_date_active,
  CAST(DSM.end_date_active AS DATE) m1_end_date_active,
  CAST(RSD.start_date_active AS DATE) m2_start_date_active,
  CAST(RSD.end_date_active AS DATE) m2_end_date_active,
  CAST(REP.role_relate_id AS NUMBER) role_relate_id,
  CAST(REP.rrowid AS NUMBER) rrowid,
  CAST(DSM.attribute14 AS VARCHAR2(150)) m1_role,
  CAST(DSM.attribute15 AS VARCHAR2(150)) m1_div,
  CAST(DSM.resource_id AS NUMBER) m1_resource_id,
  CAST(DSM.resource_name AS VARCHAR2(360)) m1_resource_name,
  CAST(DSM.resource_number AS VARCHAR2(30)) m1_resource_number,
  CAST(DSM.source_emaiL AS VARCHAR2(2000)) m1_source_email,
  CAST(RSD.group_id AS NUMBER) m2_group_id,
  CAST(RSD.resource_id AS NUMBER) m2_resource_id,
  CAST(RSD.resource_name AS VARCHAR2(360)) m2_resource_name,
  CAST(RSD.resource_number AS VARCHAR2(30))m2_resource_number,
  CAST(RSD.source_emaiL AS VARCHAR2(2000)) m2_source_email,
  CAST(RSD.attribute14 AS VARCHAR2(150)) m2_role,
  CAST(RSD.attribute15 AS VARCHAR2(150)) m2_div,
  CAST(VP.group_id AS NUMBER) m3_group_id,
  CAST(VP.resource_id AS NUMBER) m3_resource_id,
  CAST(VP.resource_name AS VARCHAR2(360)) m3_resource_name,
  CAST(VP.resource_number AS VARCHAR2(30))m3_resource_number,
  CAST(VP.source_emaiL AS VARCHAR2(2000)) m3_source_email,
  CAST(VP.attribute14 AS VARCHAR2(150)) m3_role,
  CAST(VP.attribute15 AS VARCHAR2(150)) m3_div,
  CAST(RVP.group_id AS NUMBER) m4_group_id,
  CAST(RVP.resource_id AS NUMBER) m4__resource_id,
  CAST(RVP.resource_name AS VARCHAR2(360)) m4_resource_name,
  CAST(RVP.resource_number AS VARCHAR2(30))m4_resource_number,
  CAST(RVP.source_emaiL AS VARCHAR2(2000)) m4_source_email,
  CAST(RVP.attribute14 AS VARCHAR2(150)) m4_role,
  CAST(RVP.attribute15 AS VARCHAR2(150)) m4_div  
from
(
select
    mem.group_member_id,
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    gs.group_name,
    gs.group_number,
    rol.role_id,
    rol.role_code,
    rol.role_name,
    rol.role_desc,
    rol.member_flag,
    rol.admin_flag,
    rol.manager_flag,
    rol.lead_flag,
    rol.attribute14,
    rol.attribute15,
    rrl.start_date_active,
    rrl.end_date_active,
    rrl.role_relate_id,
    null rrowid,
    rrl.attribute15 legacy_sales_id,
    rs.source_first_name,
    rs.source_last_name
  FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs,
    apps.XX_TM_NAM_TERR_CURR_ASSIGN_V ass
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND mem.resource_id = ass.resource_id
    AND rol.role_id = ass.resource_role_id
    AND mem.group_id = ass.group_id
   AND rrl.role_resource_type = 'RS_GROUP_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND ( rol.member_flag = 'Y' or rol.manager_flag = 'Y')
   AND nvl(rrl.end_date_active, sysdate + 1) <= sysdate
union
select
    mem.group_member_id,
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    gs.group_name,
    gs.group_number,
    rol.role_id,
    rol.role_code,
    rol.role_name,
    rol.role_desc,
    rol.member_flag,
    rol.admin_flag,
    rol.manager_flag,
    rol.lead_flag,
    rol.attribute14,
    rol.attribute15,
    rrl.start_date_active,
    rrl.end_date_active,
    rrl.role_relate_id,
    null rrowid,
    rrl.attribute15 legacy_sales_id,
    rs.source_first_name,
    rs.source_last_name
  FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND rrl.role_resource_type = 'RS_GROUP_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND ( rol.member_flag = 'Y' or rol.manager_flag = 'Y')
   AND nvl(rrl.end_date_active, sysdate + 1) > sysdate
)  REP,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    max(rrl.start_date_active) start_date_active,
    max(rrl.end_date_active) end_date_active
  FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND rrl.role_resource_type = 'RS_GROUP_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND rol.manager_flag = 'Y'
   AND nvl(rrl.end_date_active, sysdate + 1) > sysdate
   group by
mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15
) DSM,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id related_group_id,
    max(rrl.start_date_active) start_date_active,
    max(rrl.end_date_active) end_date_active
   FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs
     ,apps.jtf_rs_grp_relations_vl pg
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND rrl.role_resource_type = 'RS_GROUP_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND rol.manager_flag = 'Y'
   AND nvl(rrl.end_date_active, sysdate + 1) > sysdate
   AND mem.group_id = pg.related_group_id
   AND pg.relation_type  (+) = 'PARENT_GROUP'
   AND nvl(pg.end_date_active,  sysdate + 1) > sysdate
   AND nvl(pg.delete_flag,    'N') <> 'Y'
      group by
       mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) RSD,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id related_group_id,
    max(rrl.start_date_active) start_date_active,
    max(rrl.end_date_active) end_date_active
   FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs
     ,apps.jtf_rs_grp_relations_vl pg
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND rrl.role_resource_type = 'RS_GROUP_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND rol.manager_flag = 'Y'
   AND nvl(rrl.end_date_active, sysdate + 1) > sysdate
   AND mem.group_id = pg.related_group_id
   AND pg.relation_type  (+) = 'PARENT_GROUP'
   AND nvl(pg.end_date_active,  sysdate + 1) > sysdate
   AND nvl(pg.delete_flag,    'N') <> 'Y'
      group by
       mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) VP,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id related_group_id,
    max(rrl.start_date_active) start_date_active,
    max(rrl.end_date_active) end_date_active
   FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs
     ,apps.jtf_rs_grp_relations_vl pg
  WHERE mem.group_member_id = rrl.role_resource_id
   AND rrl.role_id = rol.role_id
   AND mem.resource_id = rs.resource_id
   AND mem.group_id = gs.group_id
   AND rrl.role_resource_type = 'RS_group_MEMBER'
   AND(nvl(rol.role_type_code,   'SALES') IN('SALES',   'TELESALES'))
   AND nvl(mem.delete_flag,   'N') <> 'Y'
   AND nvl(rrl.delete_flag,   'N') <> 'Y'
   AND rol.manager_flag = 'Y'
   AND nvl(rrl.end_date_active, sysdate + 1) > sysdate
   AND mem.group_id = pg.related_group_id
   AND pg.relation_type  (+) = 'PARENT_GROUP'
   AND nvl(pg.end_date_active,  sysdate + 1) > sysdate
   AND nvl(pg.delete_flag,    'N') <> 'Y'
      group by
       mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_email,
    mem.group_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) RVP
WHERE REP.group_id = DSM.group_id (+)
  AND REP.group_id = RSD.related_group_id(+)
  AND RSD.group_id = VP.related_group_id(+)
  AND VP.group_id = RVP.related_group_id(+)
);
 
grant ALL on apps.DLXM_GROUP_MBR_INFO_MV to XXCRM;
/