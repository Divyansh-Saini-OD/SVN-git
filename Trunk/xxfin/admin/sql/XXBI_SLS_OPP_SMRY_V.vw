SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE or REPLACE VIEW XXBI_SLS_OPP_SMRY_V AS
select  
  opp.STATUS_CODE,
  opp.customer_type,
  trunc(sysdate) - opp.oppty_creation_date age,
  opp.age_bucket_id,
  opp.CLOSE_REASON_ID,
  opp.SOURCE_PROMOTION_ID,
  opp.resource_id,
  opp.role_id,
  opp.group_id,
  repsmv.resource_name,
  case when repsmv.m1_resource_name is null then null else  repsmv.m1_resource_name || ' (' || repsmv.m1_role_name || ')' end m1_resource_name,
  repsmv.m1_resource_id,
  case when repsmv.m2_resource_name is null then null else repsmv.m2_resource_name || ' (' || repsmv.m2_role_name || ')' end m2_resource_name,
  repsmv.m2_resource_id,
  case when repsmv.m3_resource_name is null then null else repsmv.m3_resource_name || ' (' || repsmv.m3_role_name || ')' end m3_resource_name,
  repsmv.m3_resource_id,
  opp.win_probability,
  opp.sales_stage_id,
  opp.competitor_party_id,
  opp.lead_line_total_amount,
  opp.forecast_total_amount,
  opp.lead_line_count,
  opp.cls_date_bucket_id,
  opp.srm_bucket_id,
  opp.oppty_created_by,
  opp.amt_range_id,
  opp.forecast_amt_range_id,
  CRTBY.value oppty_created_by_desc
  ,OPP.store_number                store_number_filter_id  -- Added as part of CPD Report
from XXBI_SLS_OPP_SMRY_MV opp,
     XXBI_GROUP_MBR_INFO_V repsmv,
     XXBI_OPP_CREATED_BY_DIM_V CRTBY
WHERE 
    opp.resource_id = repsmv.resource_id
AND opp.role_id = repsmv.role_id
AND opp.group_id = repsmv.group_id
AND opp.oppty_created_by = CRTBY.id(+);


/
SHOW ERRORS;
--EXIT;