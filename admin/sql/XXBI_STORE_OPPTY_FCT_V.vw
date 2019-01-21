
  CREATE OR REPLACE FORCE VIEW "APPS"."XXBI_STORE_OPPTY_FCT_V" ("OPPTY_ROWID", "LEAD_LINE_ROWID", "LOC_ROWID", "ASSIG_ROWID", "ACT_ROWID", "OPP_ID", "OPP_NUMBER", "OPP_NAME", "CUSTOMER_ID", "PARTY_SITE_ID", "PARTY_ID", "PARTY_NAME", "ADDRESS_LINES_PHONETIC", "SITE_USE_ID", "ADDRESS_ID", "ORG_NUMBER", "CUSTOMER_TYPE", "ADDRESS", "SOURCE_PROMOTION_ID", "STATUS_CODE", "CHANNEL_CODE", "CLOSE_REASON_ID", "CURRENCY_CODE", "ADDRESS1", "CITY", "STATE", "PROVINCE", "STATE_PROVINCE", "POSTAL_CODE", "COUNTRY", "SALES_METHODOLOGY_ID", "SALES_STAGE_ID", "WIN_PROBABILITY", "SOURCE_LANG", "TOTAL_AMOUNT", "ORG_ID", "DECISION_DATE", "DECISION_MONTH", "DECISION_QTR", "DECISION_YEAR", "OPPTY_CREATION_DATE", "OPPTY_LAST_UPDATE_DATE", "OPPTY_CREATION_MONTH", "OPPTY_CREATION_QTR", "OPPTY_CREATION_YEAR", "OPPTY_UPDATION_MONTH", "OPPTY_UPDATION_QTR", "OPPTY_UPDATION_YEAR", "RESOURCE_ID", "ROLE_ID", "GROUP_ID", "TERR_DEFN_START_DATE", "TERR_DEFN_END_DATE", "TERR_RSC_START_DATE", "TERR_RSC_END_DATE", "TERR_ENT_START_DATE", "TERR_ENT_END_DATE", "LAST_ACTIVITY_DATE", "LEAD_LINE_ID", "LEAD_LINE_CREATION_DATE", "LEAD_LINE_LAST_UPDATE_DATE", "INVENTORY_ITEM_ID", "QUANTITY", "LEAD_LINE_TOTAL_AMT", "PRICE", "PRICE_VOLUME_MARGIN", "FORECAST_DATE", "ORGANIZATION_ID", "PRODUCT_CATEGORY_ID", "PRODUCT_CAT_SET_ID", "OPPTY_CREATED_BY", "SRM", "FORECAST_AMT", "COMPETITOR_PARTY_ID", "COMPETITOR_PARTY_NAME", "STORE_NUMBER", "OPP_DIM_ID", "WIN_PROBABILITY_DESC", "ORG_NUMBER_DESC", "ORG_NAME_ID", "ORG_NUMBER_ID", "TOTAL_AMOUNT_DESC", "FORECAST_AMT_DESC", "OPP_NAME_DESC", "CUSTOMER_TYPE_DESC", "SITE_USE_DESC", "SOURCE_NAME", "CLOSE_REASON_DSC", "AGE_BUCKET_ID", "AMT_RANGE_ID", "STATUS_CATEGORY", "STATUS_DESC", "FORECASTABLE", "CHANNEL_DESC", "AGE", "LEGACY_REP_ID", "RESOURCE_NAME", "GROUP_NAME", "REP_SOURCE_NUMBER", "REP_SOURCE_JOB_TITLE", "REP_SOURCE_EMAIL", "REP_SOURCE_PHONE", "REP_ROLE_NAME", "MGR_LEGACY_REP_ID", "MGR_RESOURCE_ID", "MGR_RESOURCE_NAME", "MGR_SOURCE_NUMBER", "MGR_JOB_TITLE", "MGR_EMAIL", "MGR_PHONE", "MGR_ROLE", "MGR2_RESOURCE_ID", "MGR2_RESOURCE_NAME", "MGR3_RESOURCE_ID", "MGR3_RESOURCE_NAME", "OPP_NUMBER_FILTER_ID", "FORECAST_BUCKET_ID", "CLS_DATE_BUCKET_ID", "SRM_BUCKET_ID", "PRODUCT_CATEGORY_DESC", "OPPTY_CREATED_BY_DESC", "SALES_STAGE_DESC", "STORE_NUMBER_FILTER_ID") AS 
  SELECT
         mv."OPPTY_ROWID",mv."LEAD_LINE_ROWID",mv."LOC_ROWID",mv."ASSIG_ROWID",mv."ACT_ROWID",mv."OPP_ID",mv."OPP_NUMBER",mv."OPP_NAME",mv."CUSTOMER_ID",mv."PARTY_SITE_ID",mv."PARTY_ID",mv."PARTY_NAME",mv."ADDRESS_LINES_PHONETIC",mv."SITE_USE_ID",mv."ADDRESS_ID",mv."ORG_NUMBER",mv."CUSTOMER_TYPE",mv."ADDRESS",mv."SOURCE_PROMOTION_ID",mv."STATUS_CODE",mv."CHANNEL_CODE",mv."CLOSE_REASON_ID",mv."CURRENCY_CODE",mv."ADDRESS1",mv."CITY",mv."STATE",mv."PROVINCE",mv."STATE_PROVINCE",mv."POSTAL_CODE",mv."COUNTRY",mv."SALES_METHODOLOGY_ID",mv."SALES_STAGE_ID",mv."WIN_PROBABILITY",mv."SOURCE_LANG",mv."TOTAL_AMOUNT",mv."ORG_ID",mv."DECISION_DATE",mv."DECISION_MONTH",mv."DECISION_QTR",mv."DECISION_YEAR",mv."OPPTY_CREATION_DATE",mv."OPPTY_LAST_UPDATE_DATE",mv."OPPTY_CREATION_MONTH",mv."OPPTY_CREATION_QTR",mv."OPPTY_CREATION_YEAR",mv."OPPTY_UPDATION_MONTH",mv."OPPTY_UPDATION_QTR",mv."OPPTY_UPDATION_YEAR",mv."RESOURCE_ID",mv."ROLE_ID",mv."GROUP_ID",mv."TERR_DEFN_START_DATE",mv."TERR_DEFN_END_DATE",mv."TERR_RSC_START_DATE",mv."TERR_RSC_END_DATE",mv."TERR_ENT_START_DATE",mv."TERR_ENT_END_DATE",mv."LAST_ACTIVITY_DATE",mv."LEAD_LINE_ID",mv."LEAD_LINE_CREATION_DATE",mv."LEAD_LINE_LAST_UPDATE_DATE",mv."INVENTORY_ITEM_ID",mv."QUANTITY",mv."LEAD_LINE_TOTAL_AMT",mv."PRICE",mv."PRICE_VOLUME_MARGIN",mv."FORECAST_DATE",mv."ORGANIZATION_ID",mv."PRODUCT_CATEGORY_ID",mv."PRODUCT_CAT_SET_ID",mv."OPPTY_CREATED_BY",mv."SRM",mv."FORECAST_AMT",mv."COMPETITOR_PARTY_ID",mv."COMPETITOR_PARTY_NAME",mv."STORE_NUMBER"
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
       , MV.store_number  store_number_filter_id
  FROM
      XXCRM.XXBI_SALES_OPPTY_FCT_MV    MV
     ,XXBI_OPPTY_AGE_BUCKETS_MV AGE
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
     ,XXCRM.XXCRM_REP_STORE_MAP SMAP
  WHERE    mv.store_number = smap.store_id
     AND   smap.resource_id = h.resource_id
     AND   TRUNC(SYSDATE) BETWEEN TRUNC(smap.START_DATE_ACTIVE) AND TRUNC(NVL(smap.END_DATE_ACTIVE,TO_DATE('12/31/4712','MM/DD/RRRR')))
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