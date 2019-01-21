-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW APPS.XXBI_CS_POTENTIAL_ALL_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CS_POTENTIAL_ALL_V.vw                         |
-- | Description :  View for CS Potentials from GDW and New            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author           Remarks                   |
-- |=======   ==========    =============    ==========================|
-- |1.0       16-Mar-2009   Sreekanth Rao    Initial version           |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT   POT.potential_id
      , POT.site_account aops_cust_id
      , POT.site_sequence aops_shipto_id
      , POT.acct_osr aops_osr
      , POT.party_id
      , POT.party_site_id
      , POT.cust_account_id
      , POT.cust_acct_site_id
      , POT.acct_status
      , POT.acct_site_status
      , POT.party_name
      , POT.address1
      , POT.site_use site_uses
      , POT.city
      , POT.state state_province
      , POT.postal_code
      , POT.potential_type_cd
      , POT.party_name acct_business_nm
      , POT.party_site_name site_business_nm
      , POT.comparable_potential_amt
        ,  gmv.legacy_sales_id sales_trtry_id
 FROM
      xxcrm.xxbi_terent_asgnmnt_fct_mv  sd,
      xxcrm.xxbi_party_site_data_fct_mv  POT,
            xxcrm.XXBI_GROUP_MBR_INFO_MV gmv
      where sd.entity_id=POT.party_site_id
    and   gmv.resource_id=sd.resource_id
      and  gmv.role_id=sd.role_id
      and  gmv.group_id=sd.group_id
      and sd.entity_type='PARTY_SITE';
SHOW ERRORS;
--EXIT;