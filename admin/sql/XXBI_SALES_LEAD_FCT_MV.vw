-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXBI_SALES_LEAD_FCT_MV
  BUILD DEFERRED
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SALES_LEAD_FCT_MV.vw                          |
-- | Description :  Sales Leads Fact MV                                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
        lds.LEAD_FCT_ID,
	lds.SALES_LEAD_ID,
	lds.LEAD_NUMBER,
	lds.LEAD_NAME,
	lds.CUSTOMER_ID,
	lds.ADDRESS_ID,
	NVL(lds.SOURCE_PROMOTION_ID,-1) SOURCE_PROMOTION_ID,
        P_DIM.VALUE SOURCE_PROMOTION_ID_DSC,
	NVL(lds.STATUS_CATEGORY,'XX') STATUS_CATEGORY,
        SCAT_DIM.VALUE  STATUS_CATEGORY_DSC,
	NVL(lds.STATUS_CODE,'XX') STATUS_CODE,
        SCODE_DIM.VALUE  STATUS_CODE_DSC,
	NVL(lds.CHANNEL_CODE,'XX') CHANNEL_CODE,
        C_DIM.VALUE CHANNEL_CODE_DSC,
	NVL(lds.LEAD_RANK_CODE,-1) LEAD_RANK_CODE,
        R_DIM.VALUE LEAD_RANK_CODE_DSC,
	NVL(lds.CLOSE_REASON,'XX') CLOSE_REASON,
        CLOSE_DIM.VALUE  CLOSE_REASON_DSC,
	lds.CURRENCY_CODE,
	NVL(lds.STATE,'XX') STATE,
	NVL(lds.CITY,'XX') CITY,
	NVL(lds.PROVINCE,'XX') PROVINCE,
	NVL(lds.STATE_PROVINCE,'XX') STATE_PROVINCE,
        lds.address1,
        lds.address2,
	lds.COUNTRY,
        CASE WHEN lds.country = 'US' THEN 
                          lds.address1
                          || '.'
                          || lds.address2
                          || '.'
                          || lds.city
                          || '.'
                          || lds.state
                          || '.'
                          || lds.postal_code
       WHEN lds.country = 'CA' THEN
                          lds.address1
                          || '.'
                          || lds.address2
                          || '.'
                          || lds.city
                          || '.'
                          || lds.province
                          || '.'
                          || lds.postal_code
        END  formatted_address,
	lds.METHODOLOGY_ID,
	lds.STAGE_ID,
	lds.SOURCE_LANG,
	lds.MARGIN_AMOUNT,
	lds.LEAD_CONVERSION_DATE,
	lds.OPPORTUNITY_ID,
	lds.ORG_ID,
	lds.LEAD_CREATION_DATE,
	lds.LEAD_CREATED_BY,
	lds.LEAD_LAST_UPDATE_DATE,
	lds.LEAD_LAST_UPDATED_BY,
	lds.LEAD_CREATION_MONTH,
	lds.LEAD_CREATION_QTR,
	lds.LEAD_CREATION_YEAR,
	lds.LEAD_UPDATION_MONTH,
	lds.LEAD_UPDATION_QTR,
	lds.LEAD_UPDATION_YEAR,
	lds.CREATION_DATE,
	lds.CREATED_BY,
	lds.LAST_UPDATE_DATE,
	lds.LAST_UPDATED_BY,
	lds.TOTAL_AMOUNT,
	lds.ATTRIBUTE_CATEGORY,
	lds.N_ATTRIBUTE1,
	lds.N_ATTRIBUTE2,
	lds.N_ATTRIBUTE3,
	lds.N_ATTRIBUTE4,
	lds.N_ATTRIBUTE5,
	lds.N_ATTRIBUTE6,
	lds.N_ATTRIBUTE7,
	lds.N_ATTRIBUTE8,
	lds.N_ATTRIBUTE9,
	lds.N_ATTRIBUTE10,
	lds.C_ATTRIBUTE1,
	lds.C_ATTRIBUTE2,
	lds.C_ATTRIBUTE3,
	lds.C_ATTRIBUTE4,
	lds.C_ATTRIBUTE5,
	lds.C_ATTRIBUTE6,
	lds.C_ATTRIBUTE7,
	lds.C_ATTRIBUTE8,
	lds.C_ATTRIBUTE9,
	lds.C_ATTRIBUTE10,
	lds.D_ATTRIBUTE1,
	lds.D_ATTRIBUTE2,
	lds.D_ATTRIBUTE3,
	lds.D_ATTRIBUTE4,
	lds.D_ATTRIBUTE5,
	lds.D_ATTRIBUTE6,
	lds.D_ATTRIBUTE7,
	lds.D_ATTRIBUTE8,
	lds.D_ATTRIBUTE9,
	lds.D_ATTRIBUTE10,
        p.party_name,
       	p.attribute13 customer_type,
       	TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) AGE,
       	lkup.lookup_code AGE_BUCKET,
       	CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 7   THEN lds.TOTAL_AMOUNT
       	     WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  7   THEN 0 END TOTAL_AMOUNT_WTD,
       	CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 30  THEN lds.TOTAL_AMOUNT
       	     WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  30  THEN 0 END TOTAL_AMOUNT_MTD,
        CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 365 THEN lds.TOTAL_AMOUNT
             WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  365 THEN 0 END TOTAL_AMOUNT_YTD,       
        CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 7   THEN 1
             WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  7   THEN 0 END LEAD_WTD,
        CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 30  THEN 1
             WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  30  THEN 0 END LEAD_MTD,
        CASE WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) <= 365 THEN 1
             WHEN TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) >  365 THEN 0 END LEAD_YTD
FROM xxcrm.xxbi_sales_leads_fct lds, 
     hz_parties p, 
     fnd_lookup_values lkup,
     XXBI_SALES_CHANNEL_DIM_V C_DIM,
     XXBI_SOURCE_PROMOTIONS_DIM_V P_DIM,
     XXBI_LEAD_RANK_DIM_V R_DIM,
     XXBI_LEAD_STATUS_DIM_V SCODE_DIM,
     XXBI_LEAD_CLOSE_REASON_DIM_V CLOSE_DIM,
     XXBI_STATUS_CATEGORY_DIM_V SCAT_DIM
WHERE p.party_id = lds.customer_id
AND lkup.lookup_type = 'XXBI_LEAD_AGE_BUCKET'
AND NVL(lds.SOURCE_PROMOTION_ID,-1) = P_DIM.ID
AND NVL(lds.LEAD_RANK_CODE,-1) = R_DIM.ID
AND NVL(lds.CHANNEL_CODE,'XX') = C_DIM.ID
AND NVL(lds.STATUS_CODE,'XX')  = SCODE_DIM.ID
AND NVL(lds.CLOSE_REASON,'XX') = CLOSE_DIM.ID
AND NVL(lds.STATUS_CATEGORY,'XX') = SCAT_DIM.ID
AND TRUNC(SYSDATE) - TRUNC(lds.LEAD_CREATION_DATE) 
BETWEEN substr(lkup.tag,0,instr(lkup.tag,'-')-1) AND substr(lkup.tag,instr(lkup.tag,'-')+1,LENGTH(lkup.tag));

----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_SALES_LEAD_FCT_MV TO XXCRM;

SHOW ERRORS;
EXIT;