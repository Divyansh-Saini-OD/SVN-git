-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_SALES_OPPTY_FCT_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SALES_OPPTY_FCT_V.vw                          |
-- | Description :  View for Opportunity Fact for Detailed Reporting   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       18-Mar-2009   Sreekanth Rao    Initial version           |
-- |1.1       21-Mar-2009   Sreekanth Rao    Denormalized vew to get   |
-- |                                         source, channel and       |
-- |                                         close reason values       |
-- |1.0       30-Mar-2010   Luis Mazuera     new fast refresh mv's     |
-- |1.3       21-Jul-2010   Lokesh Kumar     Added duplicate opp_id    |
-- |                                         column for opp. search    |
-- |1.4       21-DEC-2010 Gokila Tamilselvam Added column store_number |
-- |                                         for filter.               |
-- +===================================================================+
AS
 SELECT
         mv.*
       , mv.opp_id opp_dim_id
       , mv.win_probability || '%'  win_probability_desc
       , mv.org_number org_number_desc
       , mv.party_id org_name_id
       , mv.party_id org_number_id
       , mv.total_amount total_amount_desc
       , mv.forecast_amt forecast_amt_desc
       , mv.opp_name opp_name_desc
       , CLS.value customer_type_desc
       , USES.value site_use_desc
       , SRC.value source_name
       , (select value from XXBI_LEAD_CLOSE_REASON_DIM_V v where mv.close_reason_id = v.id) CLOSE_REASON_DSC
       , AGE.id age_bucket_id
       , AMR.id amt_range_id
       , decode(status.opp_open_status_flag,'Y','O','C') status_category
       , STATUS.meaning status_desc
       , STATUS.forecast_rollup_flag forecastable
       , SCNL.value channel_desc
       , ceil(sysdate - MV.oppty_creation_date)  age
       , H.legacy_sales_id legacy_rep_id
       , H.resource_name
       , H.group_name
       , H.source_number     rep_source_number
       , H.source_job_title  rep_source_job_title
       , H.source_email      rep_source_email
       , H.source_phone      rep_source_phone
       , H.role_name         rep_role_name
       , H.m1_legacy_sales_id mgr_legacy_rep_id
       , H.m1_resource_id mgr_resource_id
       , case when H.m1_resource_name is null then null else H.m1_resource_name || ' (' || H.m1_role_name || ')' end mgr_resource_name
       , H.m1_source_number mgr_source_number
       , H.m1_source_job_title mgr_job_title
       , H.m1_source_email mgr_email
       , H.m1_source_phone mgr_phone
       , H.m1_role_name mgr_role
       , H.m2_resource_id mgr2_resource_id
       , case when H.m2_resource_name is null then null else H.m2_resource_name || ' (' || H.m2_role_name || ')' end mgr2_resource_name
       , H.m3_resource_id mgr3_resource_id
       , case when H.m3_resource_name is null then null else H.m3_resource_name  || ' (' || H.m3_role_name || ')' end mgr3_resource_name
       , mv.opp_id  opp_number_filter_id
       , FRCST.id forecast_bucket_id
       , (select id from XXBI_OPP_CLOSE_DATE_RANG_DIM_V CLS_DATE where (MV.decision_date-sysdate)  between CLS_DATE.low_val and CLS_DATE.high_val) cls_date_bucket_id
       , (select id from  XXBI_OPP_SRM_RANG_DIM_V  srm where MV.srm between srm.low_val and srm.high_val) srm_bucket_id
       , PCAT.value product_category_desc
       , CRTBY.value oppty_created_by_desc
       , SLSTG.value sales_stage_desc
       , MV.store_number  store_number_filter_id   -- Added as part of CPD Lead Referal CR.
  FROM
      XXCRM.XXBI_SALES_OPPTY_FCT_MV    MV -- Added XXCRM Gokila
     , XXBI_OPPTY_AGE_BUCKETS_MV AGE
     ,APPS.AS_STATUSES_VL status
     ,APPS.XXBI_GROUP_MBR_INFO_V H
     ,APPS.XXBI_SOURCE_PROMOTIONS_DIM_V  SRC
     ,APPS.XXBI_SALES_CHANNEL_DIM_V     SCNL
     ,APPS.XXBI_CUST_CLASSIFICATION_DIM_V CLS
     ,APPS.XXBI_PARTY_SITE_USES_DIM_V USES
     ,APPS.XXBI_OPPTY_AMT_RANGES_DIM_V AMR
     ,XXBI_OPP_FRCST_AMT_RANG_DIM_V  FRCST
     ,XXBI_OPPTY_PROD_CAT_DIM_V PCAT
     ,XXBI_OPP_CREATED_BY_DIM_V CRTBY
     ,XXBI_SALES_STAGES_DIM_V SLSTG
  WHERE
         MV.resource_id = h.resource_id
     AND MV.role_id = h.role_id
     AND MV.group_id = h.group_id
     -- function to filter records assigned to active res/role/grp for a rep 
     -- and all records for a manager
     AND xxbi_utility_pkg.check_active_res_role_grp(fnd_global.user_id,
                                                    h.resource_id,
                                                    h.role_id,
                                                    h.group_id
                                                   ) = 'Y'
     AND MV.status_code = status.status_code
     AND MV.source_promotion_id = SRC.id(+)
     AND MV.channel_code = SCNL.id(+)
     AND STATUS.opp_flag = 'Y'
     AND MV.customer_type = CLS.id(+)
     AND MV.site_use_id = USES.id(+)
     AND MV.product_category_id = PCAT.id(+)
     AND MV.oppty_created_by = CRTBY.id(+)
     AND MV.sales_stage_id = SLSTG.id(+)
     AND ceil(sysdate-mv.oppty_creation_date) between AGE.low_val and AGE.high_val
     AND MV.lead_line_total_amt between AMR.low_val and AMR.high_val
     AND MV.forecast_amt between FRCST.low_val and FRCST.high_val;
/

SHOW ERRORS;
--EXIT;