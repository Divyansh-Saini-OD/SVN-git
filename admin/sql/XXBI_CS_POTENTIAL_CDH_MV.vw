-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXBI_CS_POTENTIAL_CDH_MV
BUILD DEFERRED
REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POTENTIAL_CDH_MV.vw                        |
-- | Description :  Customer Sites with No Model in GDW                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       17-Mar-2009   Sreekanth Rao    Initial version           |
-- |2.0       18-Mar-2009   Sreekanth Rao    Modified to refer OSR from|
-- |                                         OSR table than HZCA table | 
-- +===================================================================+
AS
SELECT
 HZCS.cust_acct_site_id   potential_id
, to_number(substr(HZCS.orig_system_reference,1,instr(HZCS.orig_system_reference,'-',1,1)-1)) AOPS_CUST_ID
, to_number(substr(HZCS.orig_system_reference,instr(HZCS.orig_system_reference,'-',1,1)+1,
                               instr(HZCS.orig_system_reference,'-',1,2)-instr(HZCS.orig_system_reference,'-',1,1)-1)) AOPS_SHIPTO_ID
, HZCS.orig_system_reference AOPS_OSR
, HZP.party_id
, HZPS.party_site_id
, HZCS.cust_account_id
, HZCS.cust_acct_site_id
, HZCA.status acct_status
, HZCS.status acct_site_status
, HZP.party_name
,( CASE NVL(HZL.address_style,'-9X9Y9Z') WHEN 'AS_DEFAULT' THEN                
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address4
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.postal_code                                       
                     WHEN '-9X9Y9Z' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address4
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.postal_code
                     WHEN 'JP' THEN
                             HZL.postal_code
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address_lines_phonetic
                     WHEN 'NE' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.postal_code
                          || '.'
                          || HZL.city
                     WHEN 'POSTAL_ADDR_DEF' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address4
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.province
                          || '.'
                          || HZL.postal_code
                     WHEN 'POSTAL_ADDR_US' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address4
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.postal_code
                     WHEN 'SA' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.province
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.postal_code
                     WHEN 'SE' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.postal_code
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.state
                     WHEN 'UAA' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.postal_code
                 WHEN 'AS_DEFAULT_CA' THEN
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.province
                          || '.'
                          || HZL.postal_code
                 ELSE
                             HZL.address1
                          || '.'
                          || HZL.address2
                          || '.'
                          || HZL.address3
                          || '.'
                          || HZL.address4
                          || '.'
                          || HZL.state
                          || '.'
                          || HZL.county
                          || '.'
                          || HZL.city
                          || '.'
                          || HZL.postal_code
                     END ) address
, hz_utility_v2pub.get_all_purposes(HZPS.party_site_id) site_uses
, nvl(HZL.city,'NE') city
, nvl(decode(HZL.country,'US',HZL.state,HZL.province),'NE') state_province
, nvl(substr(HZL.postal_code,1,5),'NE') postal_code
, decode(HZP.attribute24,NULL,'NE',(HZP.attribute_category||' - '||HZP.attribute24)) revenue_band
, SITE_DEMO.n_ext_attr5 WCW
, SITE_DEMO.n_ext_attr8 OD_WCW
, HZP.category_code     OD_SIC
, WCWR.id               WCW_RANGE_ID
, WCWR.value            WCW_RANGE
, 0                     site_rank
,'NEW'                  potential_type_cd
, -1                    effective_fiscal_week_id
, 'N'                   weekly_sales_to_std_ind
, 'N'                   month_sales_to_std_ind
, 'N'                   wkly_ordr_cnt_to_std_ind
, 'N'                   likely_to_purchase_ind
, to_date('01/01/2020','mm/dd/yyyy')  first_order_dt
, to_date('01/01/2020','mm/dd/yyyy')  last_order_dt
, -1                    sale_order_52week_cnt
, 'NA'                  acct_business_nm
, 'NA'                  site_business_nm
, 0                     comparable_potential_amt
, 'NA'                  street_address1
, 'NA'                  street_address2
, 'NA'                  city_nm
, 'NA'                  state_cd
, 'NA'                  state_nm
, 'NA'                  zip_cd
, 'NA'                  country
, -1                    calc_white_collar_worker_cnt
, 'NA'                  sic_group_cd
, -1                    od_white_collar_worker_cnt
, 'NA'                  od_sic_group_cd
, 'NA'                  charge_to_cost_center
, 'NA'                  currency_code
, 'NA'                  sic_group_nm
, 'NA'                  sales_trtry_id
FROM 
  (SELECT lpad(customer_account_id,8,0)||'-'||lpad(address_id,5,0)||'-A0' GDW_OSR
   FROM XXCRM.XXSCS_POTENTIAL_STG) POT
 ,APPS.HZ_PARTIES                HZP
 ,APPS.HZ_PARTY_SITES            HZPS
 ,APPS.HZ_LOCATIONS              HZL
 ,APPS.HZ_CUST_ACCT_SITES_ALL    HZCS
 ,APPS.HZ_CUST_ACCOUNTS_ALL      HZCA
 ,(select 
        PS_EXT.party_site_id
      , PS_EXT.n_ext_attr5
      , PS_EXT.n_ext_attr8
     from 
        apps.EGO_FND_DSC_FLX_CTX_EXT   ATTRG
       ,apps.HZ_PARTY_SITES_EXT_B      PS_EXT
    where
         attrg.descriptive_flexfield_name = 'HZ_PARTY_SITES_GROUP' 
     and attrg.descriptive_flex_context_code = 'SITE_DEMOGRAPHICS'
     AND PS_EXT.attr_group_id = ATTRG.attr_group_id) SITE_DEMO
  ,APPS.HZ_ORIG_SYS_REFERENCES   HZOS
  ,APPS.XXBI_CUST_WCW_RANGE_MV   WCWR
WHERE
     HZOS.orig_system_reference = POT.GDW_OSR(+)
 AND HZOS.orig_system = 'A0'
 AND HZOS.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
 AND HZOS.status = 'A'
 AND HZCA.status = 'A'
 AND HZCS.status = 'A'
 AND HZP.party_type ='ORGANIZATION'
 AND HZCA.cust_account_id = HZCS.cust_account_id
 AND HZCS.cust_acct_site_id = HZOS.owner_table_id
 AND HZCS.party_site_id = HZPS.party_site_id
 AND HZCA.cust_account_id = HZCS.cust_account_id
 AND HZPS.location_id     = HZL.location_id 
 AND HZPS.party_id        = HZP.party_id
 AND HZPS.party_site_id   = SITE_DEMO.party_site_id (+)
 AND nvl(SITE_DEMO.n_ext_attr8,0) between WCWR.low_val and WCWR.high_val
 AND HZCA.attribute18 = 'CONTRACT'
 AND POT.GDW_OSR IS NULL
 AND substr(HZCS.orig_system_reference,instr(HZCS.orig_system_reference,'-',1,1)+1,
                               instr(HZCS.orig_system_reference,'-',1,2)-instr(HZCS.orig_system_reference,'-',1,1)-1)<>'00001'
 AND HZCS.last_update_date > sysdate-10;


----------------------------------------------------------
-- Grant to XXCRM
----------------------------------------------------------
GRANT ALL ON APPS.XXBI_CS_POTENTIAL_CDH_MV TO XXCRM;

SHOW ERRORS;
EXIT;