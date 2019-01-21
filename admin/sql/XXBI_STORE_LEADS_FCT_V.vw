CREATE OR REPLACE VIEW XXBI_STORE_LEADS_FCT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_STORE_LEADS_FCT_V.vw                          |
-- | Description :  Store Leads Fact View to restrict data by sales    |
-- |                Rep.                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       15-Apr-2011 Indra Varada       Initial draft version     |
-- +===================================================================+
AS
SELECT /*+ index(mv,XXBI_SALES_LEADS_FCT_MV_N1) index(repsmv,XXBI_GROUP_MBR_INFO_MV_N1)  */
  mv.*,
  mv.sales_lead_id sales_lead_dim_id,
  mv.org_number org_number_desc,
  mv.party_id org_name_id,
  mv.party_id org_number_id,
  USES.value PARTY_SITE_USE_DSC,
  CLS.value CUSTOMER_TYPE_DSC,
  P_DIM.VALUE SOURCE_PROMOTION_ID_DSC,
  SCAT_DIM.VALUE  STATUS_CATEGORY_DSC,
  SCODE_DIM.VALUE  STATUS_CODE_DSC,
  C_DIM.VALUE CHANNEL_CODE_DSC,
  R_DIM.VALUE LEAD_RANK_CODE_DSC,
  (select value from XXBI_LEAD_CLOSE_REASON_DIM_V v where mv.close_reason = v.id) CLOSE_REASON_DSC,
  SYSDATE CREATION_DATE,
  hz_utility_v2pub.created_by CREATED_BY,
  SYSDATE LAST_UPDATE_DATE,
  hz_utility_v2pub.last_updated_by LAST_UPDATED_BY,
  TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) AGE,
  (select lookup_code from fnd_lookup_values v where lookup_type = 'XXBI_LEAD_AGE_BUCKET'
    AND TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE)
    BETWEEN substr(v.tag,0,instr(v.tag,'-')-1) AND substr(v.tag,instr(v.tag,'-')+1,LENGTH(v.tag)) ) AGE_BUCKET,
   CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 7   THEN mv.TOTAL_AMOUNT
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  7   THEN 0 END TOTAL_AMOUNT_WTD,
  CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 30  THEN mv.TOTAL_AMOUNT
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  30  THEN 0 END TOTAL_AMOUNT_MTD,
  CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 365 THEN mv.TOTAL_AMOUNT
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  365 THEN 0 END TOTAL_AMOUNT_YTD,
  CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 7   THEN 1
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  7   THEN 0 END LEAD_WTD,
  CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 30  THEN 1
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  30  THEN 0 END LEAD_MTD,
  CASE WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) <= 365 THEN 1
       WHEN TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) >  365 THEN 0 END LEAD_YTD,
  repsmv.resource_name,
  repsmv.role_name,
  repsmv.m1_resource_id,
  case when repsmv.m1_resource_name is null then null else repsmv.m1_resource_name || ' (' || repsmv.m1_role_name || ')' end m1_resource_name,
  repsmv.m2_resource_id,
  case when repsmv.m2_resource_name is null then null else repsmv.m2_resource_name || ' (' || repsmv.m2_role_name || ')' end m2_resource_name,
  repsmv.m3_resource_id,
  case when repsmv.m3_resource_name is null then null else repsmv.m3_resource_name || ' (' || repsmv.m3_role_name || ')' end m3_resource_name,
  mv.sales_lead_id  lead_number_filter_id,
  mv.store_number   store_number_filter_id 
FROM XXBI_SALES_LEADS_FCT_MV mv,
     XXBI_GROUP_MBR_INFO_V repsmv,
     XXBI_SALES_CHANNEL_DIM_V C_DIM,
     XXBI_SOURCE_PROMOTIONS_DIM_V P_DIM,
     XXBI_LEAD_RANK_DIM_V R_DIM,
     XXBI_LEAD_STATUS_DIM_V SCODE_DIM,
     XXBI_STATUS_CATEGORY_DIM_V SCAT_DIM,
     APPS.XXBI_PARTY_SITE_USES_DIM_V USES,
     APPS.XXBI_CUST_CLASSIFICATION_DIM_V CLS,
     XXCRM.XXCRM_REP_STORE_MAP SMAP
WHERE mv.store_number = smap.store_id
AND   smap.resource_id = repsmv.resource_id
AND   TRUNC(SYSDATE) BETWEEN TRUNC(smap.START_DATE_ACTIVE) AND TRUNC(NVL(smap.END_DATE_ACTIVE,TO_DATE('12/31/4712','MM/DD/RRRR')))
AND mv.SOURCE_PROMOTION_ID = P_DIM.ID(+)
AND mv.LEAD_RANK_ID = R_DIM.ID(+)
AND mv.CHANNEL_CODE = C_DIM.ID(+)
AND mv.STATUS_CODE  = SCODE_DIM.ID(+)
AND mv.status_category = SCAT_DIM.ID(+)
AND MV.customer_type = CLS.id(+)
AND MV.site_use_id = USES.id(+);
