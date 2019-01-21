-- $Id: XXBI_SALES_LEADS_FCT_V.vw 120362 2010-11-15 16:56:22Z Kishore Jena $
-- $Rev: 120362 $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_SALES_LEADS_FCT_V.vw $
-- $Author: Kishore Jena $
-- $Date: 2010-11-15 22:26:22 +0530 (Mon, 15 Nov 2010) $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_SALES_LEADS_FCT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SALES_LEADS_FCT_V.vw                          |
-- | Description :  Sales Leads Fact View to restrict data by sales    |
-- |                Rep.                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |1.1       27-Mar-2010 Luis Mazuera       MV's now based on fast    |
-- |                                         reresh version            |
-- |1.2       14-Jul-2010   Lokesh Kumar     Replaced rank code with ID|
-- |1.3       16-Jul-2010 Lokesh Kumar       Added column              |
-- |                                         lead_number_filter_id     |
-- |1.4       24-Dec-2010 Gokila T           Modified as part CPD CR.  |
-- |                                                                   |
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
  mv.store_number   store_number_filter_id   -- Added as part of CPD CR.
FROM XXBI_SALES_LEADS_FCT_MV mv,
     XXBI_GROUP_MBR_INFO_V repsmv,
     XXBI_SALES_CHANNEL_DIM_V C_DIM,
     XXBI_SOURCE_PROMOTIONS_DIM_V P_DIM,
     XXBI_LEAD_RANK_DIM_V R_DIM,
     XXBI_LEAD_STATUS_DIM_V SCODE_DIM,
     XXBI_STATUS_CATEGORY_DIM_V SCAT_DIM,
     APPS.XXBI_PARTY_SITE_USES_DIM_V USES,
     APPS.XXBI_CUST_CLASSIFICATION_DIM_V CLS
WHERE
    mv.resource_id = repsmv.resource_id
AND mv.role_id = repsmv.role_id
AND mv.group_id = repsmv.group_id
-- function to filter records assigned to active res/role/grp for a rep
-- and all records for a manager
/*AND xxbi_utility_pkg.check_active_res_role_grp(fnd_global.user_id,
                                               repsmv.resource_id,
                                               repsmv.role_id,
                                               repsmv.group_id
                                              ) = 'Y'*/  -- Commented By Gokila
AND mv.SOURCE_PROMOTION_ID = P_DIM.ID(+)
AND mv.LEAD_RANK_ID = R_DIM.ID(+)
AND mv.CHANNEL_CODE = C_DIM.ID(+)
AND mv.STATUS_CODE  = SCODE_DIM.ID(+)
AND mv.status_category = SCAT_DIM.ID(+)
AND MV.customer_type = CLS.id(+)
AND MV.site_use_id = USES.id(+);
/
SHOW ERRORS;
EXIT;