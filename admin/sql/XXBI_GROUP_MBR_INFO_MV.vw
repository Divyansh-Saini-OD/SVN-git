-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_GROUP_MBR_INFO_MV.vw $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXCRM.XXBI_GROUP_MBR_INFO_MV
  BUILD IMMEDIATE
  REFRESH FORCE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_GROUP_MBR_INFO_MV.vw                          |
-- | Description :  MV for Sales Hierarlchy                            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2010   Luis Mazuera     Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT distinct
  CAST(REP.group_member_id AS NUMBER) group_member_id,
  CAST(REP.resource_id AS NUMBER) resource_id,
  CAST(REP.resource_name AS VARCHAR2(360)) resource_name,
  CAST(REP.resource_number AS VARCHAR(30)) resource_number,
  CAST(REP.source_number AS VARCHAR(30)) source_number,
  CAST(REP.source_name AS VARCHAR2(360)) source_name,
  CAST(REP.user_name AS VARCHAR2(100)) user_name,
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
  CAST(REP.source_job_title AS VARCHAR2(240)) source_job_title,
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
  CAST(REP.role_relate_id AS NUMBER) role_relate_id,
  CAST(REP.rrowid AS ROWID) rrowid,
  CAST(MAN1.attribute14 AS VARCHAR2(150)) m1_role,
  CAST(MAN1.attribute15 AS VARCHAR2(150)) m1_div,
  CAST(MAN1.resource_id AS NUMBER) m1_resource_id,
  CAST(MAN1.resource_name AS VARCHAR2(360)) m1_resource_name,
  CAST(MAN1.resource_number AS VARCHAR2(30)) m1_resource_number,
  CAST(MAN1.source_number AS VARCHAR(30)) m1_source_number,
  CAST(MAN1.source_name AS VARCHAR2(360)) m1_source_name,
  CAST(MAN1.user_name AS VARCHAR2(100)) m1_user_name,  
  CAST(MAN1.role_id AS NUMBER) m1_role_id,
  CAST(MAN1.role_name AS VARCHAR(60)) m1_role_name,
  CAST(MAN1.source_job_title AS VARCHAR2(240)) m1_source_job_title,
  CAST(MAN1.legacy_sales_id AS VARCHAR2(150)) m1_legacy_sales_id,
  CAST(MAN1.source_phone AS VARCHAR2(2000)) m1_source_phone,
  CAST(MAN1.source_email AS VARCHAR2(2000)) m1_source_email,
  CAST(MAN1.user_id AS NUMBER) m1_user_id,
  CAST(MAN1.start_date_active AS DATE) m1_start_date_active,
  CAST(MAN1.end_date_active AS DATE) m1_end_date_active,
  CAST(MAN2.group_id AS NUMBER) m2_group_id,
  CAST(MAN2.resource_id AS NUMBER) m2_resource_id,
  CAST(MAN2.resource_name AS VARCHAR2(360)) m2_resource_name,
  CAST(MAN2.resource_number AS VARCHAR2(30))m2_resource_number,
  CAST(MAN2.source_number AS VARCHAR(30)) m2_source_number,
  CAST(MAN2.source_name AS VARCHAR2(360)) m2_source_name,
  CAST(MAN2.user_name AS VARCHAR2(100)) m2_user_name,  
  CAST(MAN2.role_id AS NUMBER) m2_role_id,
  CAST(MAN2.role_name AS VARCHAR(60)) m2_role_name,  
  CAST(MAN2.source_job_title AS VARCHAR2(240)) m2_source_job_title,
  CAST(MAN2.legacy_sales_id AS VARCHAR2(150)) m2_legacy_sales_id,
  CAST(MAN2.source_phone AS VARCHAR2(2000)) m2_source_phone,
  CAST(MAN2.source_emaiL AS VARCHAR2(2000)) m2_source_email,
  CAST(MAN2.user_id AS NUMBER) m2_user_id,
  CAST(MAN2.attribute14 AS VARCHAR2(150)) m2_role,
  CAST(MAN2.attribute15 AS VARCHAR2(150)) m2_div,
  CAST(MAN2.start_date_active AS DATE) m2_start_date_active,
  CAST(MAN2.end_date_active AS DATE) m2_end_date_active,
  CAST(MAN3.group_id AS NUMBER) m3_group_id,
  CAST(MAN3.resource_id AS NUMBER) m3_resource_id,
  CAST(MAN3.resource_name AS VARCHAR2(360)) m3_resource_name,
  CAST(MAN3.resource_number AS VARCHAR2(30))m3_resource_number,
  CAST(MAN3.source_number AS VARCHAR(30)) m3_source_number,
  CAST(MAN3.source_name AS VARCHAR2(360)) m3_source_name,
  CAST(MAN3.user_name AS VARCHAR2(100)) m3_user_name,
  CAST(MAN3.role_id AS NUMBER) m3_role_id,
  CAST(MAN3.role_name AS VARCHAR(60)) m3_role_name,  
  CAST(MAN3.source_job_title AS VARCHAR2(240)) m3_source_job_title,
  CAST(MAN3.legacy_sales_id AS VARCHAR2(150)) m3_legacy_sales_id,
  CAST(MAN3.source_phone AS VARCHAR2(2000)) m3_source_phone,
  CAST(MAN3.source_email AS VARCHAR2(2000)) m3_source_email,
  CAST(MAN3.user_id AS NUMBER) m3_user_id,
  CAST(MAN3.attribute14 AS VARCHAR2(150)) m3_role,
  CAST(MAN3.attribute15 AS VARCHAR2(150)) m3_div,
  CAST(MAN3.start_date_active AS DATE) m3_start_date_active,
  CAST(MAN3.end_date_active AS DATE) m3_end_date_active,
  CAST(MAN4.group_id AS NUMBER) m4_group_id,
  CAST(MAN4.resource_id AS NUMBER) m4_resource_id,
  CAST(MAN4.resource_name AS VARCHAR2(360)) m4_resource_name,
  CAST(MAN4.resource_number AS VARCHAR2(30))m4_resource_number,
  CAST(MAN4.source_number AS VARCHAR(30)) m4_source_number,
  CAST(MAN4.source_name AS VARCHAR2(360)) m4_source_name,
  CAST(MAN4.user_name AS VARCHAR2(100)) m4_user_name,
  CAST(MAN4.role_id AS NUMBER) m4_role_id,
  CAST(MAN4.role_name AS VARCHAR(60)) m4_role_name,  
  CAST(MAN4.source_job_title AS VARCHAR2(240)) m4_source_job_title,
  CAST(MAN4.legacy_sales_id AS VARCHAR2(150)) m4_legacy_sales_id,
  CAST(MAN4.source_phone AS VARCHAR2(2000)) m4_source_phone,
  CAST(MAN4.source_emaiL AS VARCHAR2(2000)) m4_source_email,
  CAST(MAN4.user_id AS NUMBER) m4_user_id,
  CAST(MAN4.attribute14 AS VARCHAR2(150)) m4_role,
  CAST(MAN4.attribute15 AS VARCHAR2(150)) m4_div,
  CAST(MAN4.start_date_active AS DATE) m4_start_date_active,
  CAST(MAN4.end_date_active AS DATE) m4_end_date_active,
  CAST(MAN5.group_id AS NUMBER) m5_group_id,
  CAST(MAN5.resource_id AS NUMBER) m5_resource_id,
  CAST(MAN5.resource_name AS VARCHAR2(360)) m5_resource_name,
  CAST(MAN5.resource_number AS VARCHAR2(30))m5_resource_number,
  CAST(MAN5.source_number AS VARCHAR(30)) m5_source_number,
  CAST(MAN5.source_name AS VARCHAR2(360)) m5_source_name,
  CAST(MAN5.user_name AS VARCHAR2(100)) m5_user_name,
  CAST(MAN5.role_id AS NUMBER) m5_role_id,
  CAST(MAN5.role_name AS VARCHAR(60)) m5_role_name,  
  CAST(MAN5.source_job_title AS VARCHAR2(240)) m5_source_job_title,
  CAST(MAN5.legacy_sales_id AS VARCHAR2(150)) m5_legacy_sales_id,
  CAST(MAN5.source_phone AS VARCHAR2(2000)) m5_source_phone,
  CAST(MAN5.source_emaiL AS VARCHAR2(2000)) m5_source_email,
  CAST(MAN5.user_id AS NUMBER) m5_user_id,
  CAST(MAN5.start_date_active AS DATE) m5_start_date_active,
  CAST(MAN5.end_date_active AS DATE) m5_end_date_active,
  CAST(MAN5.attribute14 AS VARCHAR2(150)) m5_role,
  CAST(MAN5.attribute15 AS VARCHAR2(150)) m5_div,
  CAST(MAN6.group_id AS NUMBER) m6_group_id,
  CAST(MAN6.resource_id AS NUMBER) m6_resource_id,
  CAST(MAN6.resource_name AS VARCHAR2(360)) m6_resource_name,
  CAST(MAN6.resource_number AS VARCHAR2(30))m6_resource_number,
  CAST(MAN6.source_number AS VARCHAR(30)) m6_source_number,
  CAST(MAN6.source_name AS VARCHAR2(360)) m6_source_name,
  CAST(MAN6.user_name AS VARCHAR2(100)) m6_user_name,
  CAST(MAN6.role_id AS NUMBER) m6_role_id,
  CAST(MAN6.role_name AS VARCHAR(60)) m6_role_name, 
  CAST(MAN6.source_job_title AS VARCHAR2(240)) m6_source_job_title,
  CAST(MAN6.legacy_sales_id AS VARCHAR2(150)) m6_legacy_sales_id,
  CAST(MAN6.source_phone AS VARCHAR2(2000)) m6_source_phone,
  CAST(MAN6.source_emaiL AS VARCHAR2(2000)) m6_source_email,
  CAST(MAN6.user_id AS NUMBER) m6_user_id,
  CAST(MAN6.attribute14 AS VARCHAR2(150)) m6_role,
  CAST(MAN6.attribute15 AS VARCHAR2(150)) m6_div,  
  CAST(MAN6.start_date_active AS DATE) m6_start_date_active,
  CAST(MAN6.end_date_active AS DATE) m6_end_date_active  
from
(
select
    mem.group_member_id,
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_number,
    rs.source_name,
    rs.user_name,
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
    rs.source_job_title,
    rol.member_flag,
    rol.admin_flag,
    rol.manager_flag,
    rol.lead_flag,
    rol.attribute14,
    rol.attribute15,
    rrl.start_date_active,
    rrl.end_date_active,
    rrl.role_relate_id,
    rs.rowid rrowid,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
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
    rs.source_job_title,
    rol.member_flag,
    rol.admin_flag,
    rol.manager_flag,
    rol.lead_flag,
    rol.attribute14,
    rol.attribute15,
    rrl.start_date_active,
    rrl.end_date_active,
    rrl.role_relate_id,
    rs.rowid rrowid,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15
) MAN1,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) MAN2,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_name,
    rs.user_name,
    rs.source_number,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) MAN3,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) MAN4,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) MAN5,
(
  select
    mem.resource_id,
    rs.resource_name,
    rs.resource_number,
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15 as legacy_sales_id,
    rol.attribute14,
    rol.attribute15,
    pg.group_id related_group_id,
    max(rrl.start_date_active) start_date_active,
    max(rrl.end_date_active) end_date_active
   FROM apps.jtf_rs_group_members mem,
    apps.jtf_rs_role_relations rrl,
    apps.jtf_rs_roles_vl rol,
    apps.jtf_rs_groups_vl gs,
    apps.jtf_rs_resource_extns_vl rs,
    apps.jtf_rs_grp_relations_vl pg
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
    rs.source_number,
    rs.source_name,
    rs.user_name,
    rol.role_id,
    rol.role_name,
    rs.source_job_title,
    rs.source_phone,
    rs.source_email,
    rs.user_id,
    mem.group_id,
    rrl.attribute15,
    rol.attribute14,
    rol.attribute15,
    pg.group_id
) MAN6
WHERE REP.group_id = MAN1.group_id (+)
  AND REP.group_id = MAN2.related_group_id(+)
  AND MAN2.group_id = MAN3.related_group_id(+)
  AND MAN3.group_id = MAN4.related_group_id(+)
  AND MAN4.group_id = MAN5.related_group_id(+)
  AND MAN5.group_id = MAN6.related_group_id(+);

----------------------------------------------------------
-- Grant to APPS
----------------------------------------------------------
GRANT ALL ON XXCRM.XXBI_GROUP_MBR_INFO_MV TO APPS;


SHOW ERRORS;
EXIT;