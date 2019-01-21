SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_STR_LDS_SMRY_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_STR_LDS_SMRY_V.vw                             |
-- | Description :  Store Leads Summary View                           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       19-Apr-2011 Indra Varada       Initial draft version     |
-- +===================================================================+
AS
SELECT
  mv.STATUS_CODE,
  mv.customer_type,
  mv.LEAD_RANK_ID,
  mv.CLOSE_REASON,
  mv.source_promotion_id,
  mv.resource_id,
  mv.role_id,
  mv.group_id,
  repsmv.resource_name,
  repsmv.role_name,
  repsmv.m1_resource_id,
  case when repsmv.m1_resource_name is null then null else repsmv.m1_resource_name || ' (' || repsmv.m1_role_name || ')' end m1_resource_name,
  repsmv.m2_resource_id,
  case when repsmv.m2_resource_name is null then null else repsmv.m2_resource_name  || ' (' || repsmv.m2_role_name || ')' end m2_resource_name,
  repsmv.m3_resource_id,
  case when repsmv.m3_resource_name  is null then null else repsmv.m3_resource_name || ' (' || repsmv.m3_role_name || ')' end m3_resource_name,
  TRUNC(SYSDATE) - TRUNC(mv.LEAD_CREATION_DATE) AGE,
  mv.TOTAL_AMOUNT,
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
  mv.sales_leads_count,
  mv.store_number     store_number_filter_id
FROM XXBI_SLS_LDS_SMRY_MV mv,
     XXBI_GROUP_MBR_INFO_V repsmv,
     XXCRM.XXCRM_REP_STORE_MAP SMAP
WHERE mv.store_number = smap.store_id
AND   smap.resource_id = repsmv.resource_id
AND   TRUNC(SYSDATE) BETWEEN TRUNC(smap.START_DATE_ACTIVE) AND TRUNC(NVL(smap.END_DATE_ACTIVE,TO_DATE('12/31/4712','MM/DD/RRRR')));
/
SHOW ERRORS;
EXIT;