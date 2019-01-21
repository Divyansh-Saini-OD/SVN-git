-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_CRM_TD_SITE_INFO_V                                     |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |   $HeadURL$
-- |       $Rev$
-- |      $Date$
-- |                                                                          |
-- |                                                                          |
-- | Description :                                                            |
-- |                                                                          |
-- | This database view returns information related to party sites including  |
-- | sales rep assignments.                                                   |
-- |                                                                          |
-- | The view was created for use by Tech Depot's CRM application.            |
-- | It is accessed remotely from a Tech Depot server.                        |
-- | Do not make changes to this view without notifying Tech Depot IT group.  |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date        Author              Remarks                         |
-- |========  =========== ==================  ================================|
-- |1.0       23-SEP-2009  Phil Price         Initial version                 |
-- +==========================================================================+

create or replace view XX_CRM_TD_SITE_INFO_V as
select
-- Subversion Info:
--   $HeadURL$
--       $Rev$
--      $Date$
       cust.site_orig_system_reference,
       cust.party_id,
       cust.party_site_id,
       cust.party_name,
       cust.party_number,
       cust.party_site_number,
       substr(cust.sic_code2, 1, instr(cust.sic_code2,':')-1)     sic_type,
       ltrim(substr(cust.sic_code2,instr(cust.sic_code2,':')+1))  sic_code,
       cust.duns_number,
       cust.identifying_address_flag,
       cust.address1,
       cust.address2,
       cust.city,
       cust.state,
       cust.province,
       cust.postal_code,
       cust.country,
       rep.legacy_sales_id   rep_id,
       rep.resource_name     rep_full_name,
       rep.source_first_name rep_first_name,
       rep.source_last_name  rep_last_name,
       rep.source_email      rep_email,
       rep.source_phone      rep_phone,
       rep.group_name        rep_group,
       rep.role_name         rep_role_name,
       rep.div               rep_division
  from apps.xxtps_current_assignments_mv cust,
       apps.xxtps_group_mbr_info_mv      rep
 where cust.resource_id = rep.resource_id
   and cust.role_id     = rep.role_id
   and cust.group_id    = rep.group_id
   and cust.channel     = 'CONTRACT'
   and cust.acct_flag   = 'Y'
   and cust.site_orig_system_reference like '%A0'
/
