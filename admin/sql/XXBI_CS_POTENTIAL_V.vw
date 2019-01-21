-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_CS_POTENTIAL_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POTENTIAL_V.vw                             |
-- | Description :  View for CS Potentials                             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2009   Sreekanth Rao    Initial version           |
-- |1.1       04-May-2009   Sreekanth Rao    QC#14644 Add PDF version  |
-- |                                         of STAR Report            |
-- |1.2       05-May-2009   Sreekanth Rao    QC#14586 Rank Sorting     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
    rownum SL_NUM,
    SRTDPOTV.POTENTIAL_ID,
    SRTDPOTV.AOPS_CUST_ID,
    SRTDPOTV.AOPS_CUST_ID1,
    SRTDPOTV.AOPS_SHIPTO_ID,
    SRTDPOTV.AOPS_OSR,
    SRTDPOTV.AOPS_OSR_DESC,
    SRTDPOTV.PARTY_ID,
    SRTDPOTV.PARTY_SITE_ID,
    SRTDPOTV.CUST_ACCOUNT_ID,
    SRTDPOTV.CUST_ACCT_SITE_ID,
    SRTDPOTV.ACCT_STATUS,
    SRTDPOTV.ACCT_SITE_STATUS,
    SRTDPOTV.PARTY_NAME,
    SRTDPOTV.ADDRESS,
    SRTDPOTV.SITE_USES,
    SRTDPOTV.CITY,
    SRTDPOTV.STATE_PROVINCE,
    SRTDPOTV.POSTAL_CODE,
    SRTDPOTV.REVENUE_BAND,
    SRTDPOTV.REVENUE_BAND_DESC,
    SRTDPOTV.WCW,
    SRTDPOTV.OD_WCW,
    SRTDPOTV.OD_SIC,
    SRTDPOTV.WCW_RANGE_ID,
    SRTDPOTV.WCW_RANGE,
    SRTDPOTV.SITE_RANK,
    SRTDPOTV.POTENTIAL_TYPE_CD,
    SRTDPOTV.POTENTIAL_TYPE_HLINK,
    SRTDPOTV.MODEL_NAME,
    SRTDPOTV.EFFECTIVE_FISCAL_WEEK_ID,
    SRTDPOTV.WEEKLY_SALES_TO_STD_IND,
    SRTDPOTV.MONTH_SALES_TO_STD_IND,
    SRTDPOTV.WKLY_ORDR_CNT_TO_STD_IND,
    SRTDPOTV.LIKELY_TO_PURCHASE_IND,
    SRTDPOTV.FIRST_ORDER_DT,
    SRTDPOTV.LAST_ORDER_DT,
    SRTDPOTV.SALE_ORDER_52WEEK_CNT,
    SRTDPOTV.ACCT_BUSINESS_NM,
    SRTDPOTV.SITE_BUSINESS_NM,
    SRTDPOTV.COMPARABLE_POTENTIAL_AMT,
    SRTDPOTV.STREET_ADDRESS1,
    SRTDPOTV.STREET_ADDRESS2,
    SRTDPOTV.CITY_NM,
    SRTDPOTV.STATE_CD,
    SRTDPOTV.STATE_NM,
    SRTDPOTV.ZIP_CD,
    SRTDPOTV.COUNTRY,
    SRTDPOTV.CALC_WHITE_COLLAR_WORKER_CNT,
    SRTDPOTV.SIC_GROUP_CD,
    SRTDPOTV.OD_WHITE_COLLAR_WORKER_CNT,
    SRTDPOTV.OD_SIC_GROUP_CD,
    SRTDPOTV.CHARGE_TO_COST_CENTER,
    SRTDPOTV.CURRENCY_CODE,
    SRTDPOTV.SIC_GROUP_NM,
    SRTDPOTV.SALES_TRTRY_ID,
    SRTDPOTV.VIEW_CREATE,
    SRTDPOTV.ENTITY_ID,
    SRTDPOTV.RESOURCE_ID,
    SRTDPOTV.RESOURCE_ROLE_ID,
    SRTDPOTV.GROUP_ID,
    SRTDPOTV.LEGACY_REP_ID,
    SRTDPOTV.RESOURCE_NAME,
    SRTDPOTV.GROUP_NAME,
    SRTDPOTV.ROLE_NAME,
    SRTDPOTV.SOURCE_JOB_TITLE,
    SRTDPOTV.MGR_RESOURCE_NAME,
    SRTDPOTV.MGR_JOB_TITLE,
    SRTDPOTV.MGR_ROLE,
    SRTDPOTV.STAR,
    SRTDPOTV.STAR_PDF,
    SRTDPOTV.QCREATE,
    SRTDPOTV.LAST_ACTIVITY_DATE
FROM    
( SELECT * FROM
(SELECT  
        TO_CHAR(POT.potential_id) POTENTIAL_ID
      , POT.aops_cust_id
      , POT.aops_cust_id  aops_cust_id1
      , POT.aops_shipto_id
      , POT.aops_osr
      , POT.aops_osr aops_osr_desc
      , POT.party_id
      , POT.party_site_id
      , POT.cust_account_id
      , POT.cust_acct_site_id
      , POT.acct_status
      , POT.acct_site_status
      , POT.party_name
      , POT.address
      , POT.site_uses
      , POT.city
      , POT.state_province
      , POT.postal_code
      , POT.revenue_band
      , POT.revenue_band   revenue_band_desc
      , POT.wcw
      , POT.od_wcw
      , POT.od_sic
      , POT.wcw_range_id
      , POT.wcw_range
      , NVL(RNK.new_rank,POT.site_rank) site_rank
      , POT.potential_type_cd
      , POT.potential_type_cd potential_type_hlink
      , decode(POT.potential_type_cd,'LOY','Conversion','RET','Retention','SOW','SOW') model_name
      , POT.effective_fiscal_week_id
      , POT.weekly_sales_to_std_ind
      , POT.month_sales_to_std_ind
      , POT.wkly_ordr_cnt_to_std_ind
      , POT.likely_to_purchase_ind
      , POT.first_order_dt
      , POT.last_order_dt
      , POT.sale_order_52week_cnt
      , POT.acct_business_nm
      , POT.site_business_nm
      , POT.comparable_potential_amt
      , POT.street_address1
      , POT.street_address2
      , POT.city_nm
      , POT.state_cd
      , POT.state_nm
      , POT.zip_cd
      , POT.country
      , POT.calc_white_collar_worker_cnt
      , POT.sic_group_cd
      , POT.od_white_collar_worker_cnt
      , POT.od_sic_group_cd
      , POT.charge_to_cost_center
      , POT.currency_code
      , POT.sic_group_nm
      , POT.sales_trtry_id
      , decode(EXST.entity_type,NULL,'Create','View') view_create
      , nvl(EXST.entity_id,-1) entity_id
      , ASGN.resource_id
      , ASGN.resource_role_id
      , ASGN.group_id
      , ASGN.legacy_rep_id
      , ASGN.resource_name
      , ASGN.group_name
      , ASGN.role_name      
      , ASGN.source_job_title
      , ASGN.mgr_resource_name
      , ASGN.mgr_job_title
      , ASGN.mgr_role
      , 'STAR' star
      , 'PDF' star_pdf
      , 'Feedback' qcreate
      , ACT.last_activity_date
 FROM         
      APPS.XXBI_CS_POTENTIAL_MV             POT
    , APPS.XXBI_SITE_CURR_ASSIGN_MV         ASGN
    , XXCRM.XXSCS_POTENTIAL_NEW_RANK        RNK
    , XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP  EXST
    , XXCRM.XXBI_ACTIVITIES                 ACT
 WHERE    
      POT.party_site_id = ASGN.party_site_id   AND
      POT.party_site_id = RNK.party_site_id(+) AND
      POT.potential_type_cd = RNK.potential_type_cd(+) AND
      POT.potential_id = RNK.potential_id(+) AND      
      ASGN.user_id = fnd_global.user_id AND
      POT.potential_id = EXST.potential_id(+) AND
      POT.potential_type_cd = EXST.potential_type_cd(+) AND
      POT.party_site_id = EXST.party_site_id(+) AND
      ACT.SOURCE_TYPE(+)  =  'PARTY SITE' AND
      ACT.SOURCE_ID(+)    =  POT.party_site_id
UNION      
 SELECT  
        TO_CHAR(POT.potential_id) POTENTIAL_ID
      , to_number(POT.aops_cust_id)   aops_cust_id
      , to_number(POT.aops_cust_id)   aops_cust_id1
      , to_number(POT.aops_shipto_id) aops_shipto_id
      , POT.aops_osr
      , POT.aops_osr aops_osr_desc
      , POT.party_id
      , POT.party_site_id
      , POT.cust_account_id
      , POT.cust_acct_site_id
      , POT.acct_status
      , POT.acct_site_status
      , POT.party_name
      , POT.address
      , POT.site_uses
      , POT.city
      , POT.state_province
      , POT.postal_code
      , POT.revenue_band
      , POT.revenue_band   revenue_band_desc
      , POT.wcw
      , POT.od_wcw
      , POT.od_sic
      , POT.wcw_range_id
      , POT.wcw_range
      , NVL(RNK.new_rank,POT.site_rank) site_rank
      , POT.potential_type_cd
      , POT.potential_type_cd potential_type_hlink
      , 'No Model' model_name
      , POT.effective_fiscal_week_id
      , POT.weekly_sales_to_std_ind
      , POT.month_sales_to_std_ind
      , POT.wkly_ordr_cnt_to_std_ind
      , POT.likely_to_purchase_ind
      , POT.first_order_dt
      , POT.last_order_dt
      , POT.sale_order_52week_cnt
      , POT.acct_business_nm
      , POT.site_business_nm
      , POT.comparable_potential_amt
      , POT.street_address1
      , POT.street_address2
      , POT.city_nm
      , POT.state_cd
      , POT.state_nm
      , POT.zip_cd
      , POT.country
      , POT.calc_white_collar_worker_cnt
      , POT.sic_group_cd
      , POT.od_white_collar_worker_cnt
      , POT.od_sic_group_cd
      , POT.charge_to_cost_center
      , POT.currency_code
      , POT.sic_group_nm
      , POT.sales_trtry_id
      , decode(EXST.entity_type,NULL,'Create','View') view_create
      , nvl(EXST.entity_id,-1) entity_id
      , ASGN.resource_id
      , ASGN.resource_role_id
      , ASGN.group_id
      , ASGN.legacy_rep_id
      , ASGN.resource_name
      , ASGN.group_name
      , ASGN.role_name      
      , ASGN.source_job_title
      , ASGN.mgr_resource_name
      , ASGN.mgr_job_title
      , ASGN.mgr_role
      , 'STAR' star
      , 'PDF' star_pdf
      , 'Feedback' qcreate
      , ACT.last_activity_date
 FROM         
      APPS.XXBI_CS_POTENTIAL_CDH_MV         POT
    , APPS.XXBI_SITE_CURR_ASSIGN_MV         ASGN
    , XXCRM.XXSCS_POTENTIAL_NEW_RANK        RNK
    , XXCRM.XXSCS_TOP_CUST_EXSTNG_LEAD_OPP  EXST
    , XXCRM.XXBI_ACTIVITIES                 ACT
 WHERE    
      POT.party_site_id = ASGN.party_site_id   AND
      POT.party_site_id = RNK.party_site_id(+) AND
      POT.potential_type_cd = RNK.potential_type_cd(+) AND
      POT.potential_id = RNK.potential_id(+) AND      
      ASGN.user_id = fnd_global.user_id AND
      POT.potential_id = EXST.potential_id(+) AND
      POT.potential_type_cd = EXST.potential_type_cd(+) AND
      POT.party_site_id = EXST.party_site_id(+) AND
      ACT.SOURCE_TYPE(+)  =  'PARTY SITE' AND 
      ACT.SOURCE_ID(+)    =  POT.party_site_id
) ORDER BY  SITE_RANK DESC
) SRTDPOTV
/
SHOW ERRORS;
EXIT;