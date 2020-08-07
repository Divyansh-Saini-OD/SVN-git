-- $Id: XXBI_LEAD_COUNTRY_DIM_V.vw 97467 2010-03-29 19:29:47Z Luis Mazuera $
-- $Rev: 97467 $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_SLS_LDS_SMRY_V.vw $
-- $Author: Luis Mazuera $
-- $Date: 2010-03-29 15:29:47 -0400 (Mon, 29 Mar 2010) $

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW XXBI_SLS_LDS_SMRY_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_SLS_LDS_SMRY_V.vw                             |
-- | Description :  Country Dimension View                             |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |1.1       06-Apr-2010 Luis Mazuera       New fast refresh MV's     | 
-- |1.2       14-Jul-2010   Lokesh Kumar     Replaced rank code with ID|
-- |1.3       24-Dec-2010 Gokila T           Added store_number column |
-- |                                         as part of CPD CR.        |
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
     XXBI_GROUP_MBR_INFO_V repsmv
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
                                              ) = 'Y';*/ -- Commented by Gokila

/
SHOW ERRORS;
EXIT;