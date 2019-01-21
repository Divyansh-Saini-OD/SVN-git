-- $Id: XXBI_USER_SITE_DTL_FCT_V.vw 69444 2010-03-20 10:44:38 -0400Z Kishor Jena $
-- $Rev:  $
-- $HeadURL: https://svn.na.odcorp.net/od/crm/trunk/xxcrm/admin/sql/XXBI_USER_SITE_DTL_FCT_V.vw $
-- $Author: Kishore Jena $
-- $Date: 2010-03-20 10:44:38 -0400 (Thu, 09 Apr 2009) $

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_USER_SITE_DTL_FCT_V.vw                        |
-- | Description :  Customer/Prospect Dashboard View                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       20-Mar-2010 Kishore Jena       Initial draft version     |
-- |1.1       10-Nov-2010 Kishore Jena       Current R/R/G assignment  |
-- |                                                                   | 
-- +===================================================================+

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE VIEW APPS.XXBI_USER_SITE_DTL_FCT_V AS
SELECT ROWNUM rank, x.* FROM
(
SELECT sdtl.rsd_user_id,
       sdtl.sort_id,
       sdtl.resource_id,       
       sdtl.resource_name,
       sdtl.role_id,
       sdtl.role_name,
       sdtl.group_id,
       sdtl.group_name,
       sdtl.m1_resource_id,
       sdtl.m1_resource_name_and_role m1_resource_name,       
       sdtl.m2_resource_id,
       sdtl.m2_resource_name_and_role m2_resource_name,       
       sdtl.m3_resource_id,
       sdtl.m3_resource_name_and_role m3_resource_name,       
       sdtl.m4_resource_id,
       sdtl.m4_resource_name_and_role m4_resource_name,       
       sdtl.m5_resource_id,
       sdtl.m5_resource_name_and_role m5_resource_name,       
       sdtl.m6_resource_id,
       sdtl.m6_resource_name_and_role m6_resource_name,       
       sdtl.party_id,
       sdtl.party_site_id,
       sdtl.location_id,
       sdtl.cust_account_id,
       sdtl.cust_acct_site_id,
       sdtl.parent_party_id,
       sdtl.parent_party_name,
       sdtl.gparent_party_id,
       sdtl.gparent_party_name,
       sdtl.access_id,
       TO_CHAR(sdtl.potential_id) potential_id,
       NVL(sdtl.potential_type_cd, 'NEW') potential_type_cd,
       NVL(sdtl.potential_type_nm, 'No Model') potential_type_nm,
       NVL(sdtl.comparable_potential_amt, 0) comparable_potential_amt,
       sdtl.org_number,
       sdtl.party_id orgname_id,
       sdtl.org_name,
       DECODE(sdtl.org_type, 'XX', NULL, sdtl.org_type)  org_type_id,
       DECODE(sdtl.org_type, 'XX', NULL, sdtl.org_type)  org_type,
       DECODE(sdtl.site_use_id, 'XX', NULL, sdtl.site_use_id) site_use_id,
       DECODE(sdtl.site_use, 'XX', NULL, sdtl.site_use) site_use,
       NVL(sdtl.site_name, '') site_name,
       sdtl.site_address,
       'Menu' additional_dtls,
       decode(sdtl.org_type, 'PROSPECT', NULL, sdtl.create_view_lead_oppty) create_view_lead_oppty,
       sdtl.last_activity_date,
       DECODE(sdtl.od_site_full_sic_code, 'XX', NULL, sdtl.od_site_full_sic_code) od_site_full_sic_code,
       DECODE(sdtl.od_site_sic_code, 'XX', NULL, sdtl.od_site_sic_code) od_site_sic_code,
       DECODE(sdtl.od_site_wcw, -1, NULL, sdtl.od_site_wcw) od_site_wcw,
       DECODE(sdtl.od_site_wcw_range, 'XX', NULL, sdtl.od_site_wcw_range) od_site_wcw_range,
       DECODE(sdtl.city, 'XX', NULL, sdtl.city) city,
       DECODE(sdtl.state_province, 'XX', NULL, sdtl.state_province) state_province,
       DECODE(sdtl.postal_code, 'XX', NULL, sdtl.postal_code) postal_code,
       DECODE(sdtl.cust_loyalty_code, 'XX', NULL, sdtl.cust_loyalty_code) cust_loyalty_code,
       DECODE(sdtl.cust_segment_code, 'XX', NULL, sdtl.cust_segment_code) cust_segment_code,             
       DECODE(sdtl.party_revenue_band,'XX', NULL, sdtl.party_revenue_band) party_revenue_band,
       sdtl.party_site_id org_sitenum_id,
       sdtl.org_site_number,
       sdtl.org_site_status org_status_id,
       sdtl.org_site_status,
       sdtl.contact_title,
       sdtl.contact_name,
       sdtl.contact_phone,
       sdtl.site_rank,
       TO_CHAR(sdtl.party_site_id)  menu_site_id,
       TO_CHAR(sdtl.party_id)       party_id_hl,
       TO_CHAR(sdtl.party_site_id)  party_site_id_hl,
       sdtl.potential_type_cd potential_type_cd_hl,
       TO_CHAR(sdtl.org_contact_id)    org_contact_id_hl,
       TO_CHAR(sdtl.rel_party_id)      rel_party_id_hl, 
       TO_CHAR(sdtl.relationship_id)   relationship_id_hl,
       TO_CHAR(sdtl.per_party_id)      per_party_id_hl
from   xxcrm.xxbi_user_site_dtl sdtl
where  sdtl.rsd_user_id = nvl(xxbi_utility_pkg.get_rsd_user_id(FND_GLOBAL.USER_ID), 9999999999)
  and  sdtl.user_id     = FND_GLOBAL.USER_ID
  and  SYSDATE BETWEEN NVL(sdtl.start_date_active, SYSDATE-1) AND NVL(sdtl.end_date_active, SYSDATE+1)
order by sdtl.sort_id
) x;



WHENEVER SQLERROR CONTINUE;

SET FEEDBACK ON

--EXIT;

REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================


