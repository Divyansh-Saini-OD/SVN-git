-- $Id: XXBI_USER_SUMMARY_FCT_V.vw 69444 2010-03-20 10:44:38 -0400Z Kishor Jena $
-- $Rev:  $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_USER_SUMMARY_FCT_V.vw $
-- $Author: Kishore Jena $
-- $Date: 2010-03-20 10:44:38 -0400 (Thu, 09 Apr 2009) $

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_SUMMARY_FCT_V.vw                         |
-- | Description :  Customer/Prospect Dashboard Summary View           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       20-Mar-2010 Kishore Jena       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW APPS.XXBI_USER_SUMMARY_FCT_V AS
SELECT usm.resource_id,       
       usm.resource_name,
       usm.role_id,
       usm.role_name,
       usm.group_id,
       usm.group_name,
       usm.m1_resource_id,
       usm.m1_resource_name,       
       usm.m2_resource_id,
       usm.m2_resource_name,              
       usm.m3_resource_id,
       usm.m3_resource_name,              
       usm.m4_resource_id,
       usm.m4_resource_name,              
       usm.m5_resource_id,
       usm.m5_resource_name,              
       usm.m6_resource_id,
       usm.m6_resource_name,              
       usm.potential_type_cd,
       usm.potential_type_nm,
       DECODE(usm.org_type, 'XX', NULL, usm.org_type)  org_type,
       DECODE(usm.cust_loyalty_code, 'XX', NULL, usm.cust_loyalty_code) cust_loyalty_code,
       DECODE(usm.party_revenue_band,'XX', NULL, usm.party_revenue_band) party_revenue_band,
       DECODE(usm.city, 'XX', NULL, usm.city) city,
       DECODE(usm.state_province, 'XX', NULL, usm.state_province) state_province,
       DECODE(usm.od_site_full_sic_code, 'XX', NULL, usm.od_site_full_sic_code) od_site_full_sic_code,
       DECODE(usm.od_site_sic_code, 'XX', 0, usm.od_site_sic_code) od_site_sic_code,
       DECODE(usm.od_site_wcw, -1, 0, usm.od_site_wcw) od_site_wcw,
       DECODE(usm.od_site_wcw_range, 'XX', NULL, usm.od_site_wcw_range) od_site_wcw_range,
       DECODE(usm.org_site_status, 'X', usm.org_site_status) org_status_id,
       DECODE(usm.org_site_status, 'X', usm.org_site_status) org_site_status,
       DECODE(usm.site_use_id, 'XX', NULL, usm.site_use_id) site_use_id,
       DECODE(usm.site_use, 'XX', NULL, usm.site_use) site_use,
       SUM(total_potential_amt) total_potential_amt,
       count(1) party_site_count
FROM   xxcrm.xxbi_user_summary_fct_mv  usm,
       apps.xxbi_group_mbr_info_v      gmb
WHERE  usm.resource_id = gmb.resource_id
  AND  usm.role_id     = gmb.role_id
  AND  usm.group_id    = gmb.group_id
GROUP BY usm.resource_id,       
         usm.resource_name,
         usm.role_id,
         usm.role_name,
         usm.group_id,
         usm.group_name,
         usm.m1_resource_id,
         usm.m1_resource_name,       
         usm.m2_resource_id,
         usm.m2_resource_name,              
         usm.m3_resource_id,
         usm.m3_resource_name,              
         usm.m4_resource_id,
         usm.m4_resource_name,              
         usm.m5_resource_id,
         usm.m5_resource_name,              
         usm.m6_resource_id,
         usm.m6_resource_name,              
         usm.potential_type_cd,
         usm.potential_type_nm,
         DECODE(usm.org_type, 'XX', NULL, usm.org_type),
         DECODE(usm.cust_loyalty_code, 'XX', NULL, usm.cust_loyalty_code),
         DECODE(usm.party_revenue_band,'XX', NULL, usm.party_revenue_band),
         DECODE(usm.city, 'XX', NULL, usm.city),
         DECODE(usm.state_province, 'XX', NULL, usm.state_province),
         DECODE(usm.od_site_full_sic_code, 'XX', NULL, usm.od_site_full_sic_code),
         DECODE(usm.od_site_sic_code, 'XX', 0, usm.od_site_sic_code),
         DECODE(usm.od_site_wcw, -1, 0, usm.od_site_wcw),
         DECODE(usm.od_site_wcw_range, 'XX', NULL, usm.od_site_wcw_range),
         DECODE(usm.org_site_status, 'X', usm.org_site_status),
         DECODE(usm.site_use_id, 'XX', NULL, usm.site_use_id),
         DECODE(usm.site_use, 'XX', NULL, usm.site_use);

WHENEVER SQLERROR CONTINUE;

SET FEEDBACK ON

--EXIT;

REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================



