SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
DROP MATERIALIZED VIEW APPS.XXBI_TASKS_FCT_MV_t;
CREATE MATERIALIZED VIEW APPS.XXBI_TASKS_FCT_MV_t
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_TASKS_FCT_MV.vw                               |
-- | Description :  Tasks Fact Materialized View(for all reps)         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       02/19/2010  Mohan                                        |
-- |                      Kalyanasundaram    Initial draft version     |
-- |2.0       03/29/2010  Anirban C          Added a few columns       | 
-- +===================================================================+
AS
SELECT *
FROM 
  (
  SELECT  /*+ full(fcal.map) full(fcal.ps) full(fcal.app.t) full(fcal.app.b)  full(fcal.bks) full(rse2) parallel(rse2,4) full(rse) parallel(rse,4) full(TSK.b) parallel(TSK.b,4) full(TSK.t) parallel(TSK.t,4) full(TSKTYP.b) parallel(TSKTYP.b,4) full(TSKTYP.t) parallel(TSKTYP.t,4) full(TSKSTAT.b) parallel(TSKSTAT.b,4) full(TSKSTAT.t) parallel(TSKSTAT.t,4) full(LEAD) parallel(LEAD,4) full(OPP) parallel(OPP,4)  */ 
   tsk.task_id task_id  ,
     tsk.created_by,
     rse2.resource_id created_res_id,
     rse2.source_name created_resource_name,
     tsk.creation_date,
     tsk.last_updated_by,
     tsk.last_update_date,
     tsk.task_number ,
     tsk.task_type_id,
     tsktyp.name task_type_name,
     tsk.task_status_id,
     tskstat.name task_status_name,
     tsk.task_priority_id,
     tsk.owner_id ,
     rse.user_id owner_user_id,
     rse.source_name owner_resource_name,
     rse.source_name owner_resource_name_dup,
     tsk.owner_type_code ,
     tsk.planned_start_date,
     tsk.parent_task_id  ,
     tsk.deleted_flag  , 
     tsk.actual_start_date,
     tsk.private_flag,
     tsk.publish_flag,
     tsk.actual_end_date ,
     tsk.source_object_type_code entity_type ,
     tsk.source_object_type_code entity_type_name,
     tsk.source_object_id entity_id,
     tsk.source_object_name ,
     tsk.planned_end_date,
     tsk.scheduled_start_date,
     tsk.scheduled_end_date due_date,
     tsk.calendar_end_date ,
     tsk.task_name,
     tsk.description,
     tsk.open_flag  ,
     fcal.fiscal_week_id task_week_id,
     fcal.fiscal_year_id task_year_id,
     fcal.fiscal_week_number task_week_number,
     fcal.fiscal_week_descr task_week_desc,
     'Update' update_details  ,
     'Create' create_appointment,
     'View Details' view_details,
     opp.lead_number opp_number,
     lead.lead_number,
     opp.description opp_name,
     lead.description lead_name 
   FROM apps.jtf_tasks_vl tsk,
     apps.jtf_task_types_vl tsktyp,
     apps.jtf_task_statuses_vl tskstat,
     apps.as_sales_leads lead,     -- leads
  apps.as_leads_all opp,
     apps.xxbi_od_fiscal_calendar_v fcal
     apps.jtf_rs_resource_extns rse,
     apps.jtf_rs_resource_extns rse2
   WHERE tsktyp.task_type_id = tsk.task_type_id
   AND tskstat.task_status_id = tsk.task_status_id
   AND tsk.source_object_id = opp.lead_id(+)
   AND tsk.source_object_id = lead.sales_lead_id(+)
   AND nvl(lead.deleted_flag,    'N') = 'N'
   AND nvl(opp.deleted_flag,    'N') = 'N'
   AND trunc(fcal.accounting_date) = trunc(nvl(tsk.scheduled_end_date,    sysdate))
   AND tsk.created_by = rse2.user_id(+)
   AND tsk.owner_id = rse.user_id(+) 
  )
tk,
    (SELECT
   /*+ full(psdf) parallel(psdf,4) full(tasg) parallel(tasg,4) full(mmbr) parallel(mmbr,4) full(ts.b) parallel(ts.b,4) full(ts.t) parallel(ts.t,4) full(ts.p) parallel(ts.p,4) */ 
     ts.ts_task_id t_task_id 
   ,  tasg.resource_id assigned_resource_id,
     tasg.resource_id assigned_resource_id_dup,
     mmbr.user_id assigned_user_id,
     mmbr.resource_name assigned_resource_name,
     mmbr.resource_name assigned_resource_name_dup,
     tasg.role_id assigned_role_id,
     mmbr.role_name assigned_role_name,
     tasg.group_id assigned_group_id  ,
     mmbr.m1_resource_id m1_resource_id,
     mmbr.m1_user_id m1_user_id,
     mmbr.m1_resource_name m1_resource_name,
     mmbr.m2_resource_id m2_resource_id,
     mmbr.m2_user_id m2_user_id,
     mmbr.m2_resource_name m2_resource_name,
     mmbr.m3_resource_id m3_resource_id,
     mmbr.m3_user_id m3_user_id,
     mmbr.m3_resource_name m3_resource_name,
     mmbr.m4_resource_id m4_resource_id,
     mmbr.m4_user_id m4_user_id,
     mmbr.m4_resource_name m4_resource_name  ,
     psdf.party_id party_id  , 
     psdf.party_name party_name,
     psdf.party_name party_name_duplicate,
     psdf.party_site_id party_site_id  ,
     psdf.party_site_name party_site_name,
     (CASE NVL(psdf.address_style,'-9X9Y9Z') WHEN 'AS_DEFAULT' THEN                
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address4
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.postal_code                                       
                     WHEN '-9X9Y9Z' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address4
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.postal_code
                     WHEN 'JP' THEN
                             psdf.postal_code
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address_lines_phonetic
                     WHEN 'NE' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.postal_code
                          || '.'
                          || psdf.city
                     WHEN 'POSTAL_ADDR_DEF' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address4
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.province
                          || '.'
                          || psdf.postal_code
                     WHEN 'POSTAL_ADDR_US' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address4
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.postal_code
                     WHEN 'SA' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.province
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.postal_code
                     WHEN 'SE' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.postal_code
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.state
                     WHEN 'UAA' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.postal_code
                 WHEN 'AS_DEFAULT_CA' THEN
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.province
                          || '.'
                          || psdf.postal_code
                 ELSE
                             psdf.address1
                          || '.'
                          || psdf.address2
                          || '.'
                          || psdf.address3
                          || '.'
                          || psdf.address4
                          || '.'
                          || psdf.state
                          || '.'
                          || psdf.county
                          || '.'
                          || psdf.city
                          || '.'
                          || psdf.postal_code
                     END )  party_site_address,
     psdf.org_number org_number,
     psdf.org_number org_number_duplicate,
     psdf.org_type org_type,
     psdf.org_type org_type_duplicate,
     psdf.site_use site_use,
     psdf.site_use site_use_duplicate,
     psdf.site_orig_sys_ref site_orig_sys_ref 
   FROM xxcrm.xxbi_terent_asgnmnt_fct tasg,
     apps.xxbi_group_mbr_info_mv mmbr,
     xxcrm.xxbi_party_site_data_fct psdf,
      (SELECT task_id  ts_task_id ,
       decode(source_object_type_code,    'OD_PARTY_SITE',    'PARTY_SITE',    source_object_type_code) entity_type,
       t.source_object_id entity_id,
       decode(t.source_object_type_code,    'OD_PARTY_SITE',    t.source_object_id,    t.address_id) party_site_id
     FROM apps.jtf_tasks_b t
     WHERE t.source_object_type_code IN('OD_PARTY_SITE',    'LEAD',    'OPPORTUNITY')
     UNION
     SELECT task_id ts_task_id,
       'PARTY_SITE' entity_type,
       source_object_id entity_id,
       p.party_site_id
     FROM apps.jtf_tasks_b t,
       xxcrm.xxbi_party_site_data_fct p
     WHERE t.source_object_type_code = 'PARTY'
     AND t.source_object_id = p.party_id
     AND p.identifying_address_flag = 'Y')  ts
   WHERE mmbr.resource_id = tasg.resource_id
   AND mmbr.group_id = tasg.group_id
   AND mmbr.role_id = tasg.role_id
   AND ts.entity_id = tasg.entity_id
   AND ts.entity_type = tasg.entity_type
   AND ts.party_site_id = psdf.party_site_id) ent
WHERE tk.task_id = ent.t_task_id(+);
SHOW ERRORS;
EXIT;
