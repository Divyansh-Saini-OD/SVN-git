-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name        :  XX_CRM_TD_SITE_CONTACTS_V                                 |
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
-- | This database view returns information related to party sites contacts.  |
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

create or replace view XX_CRM_TD_SITE_CONTACTS_V as
select 
-- Subversion Info:
--   $HeadURL$
--       $Rev$
--      $Date$
       hp.party_id,
       hps.party_site_id,
       hpse.extension_id party_site_ext_id,
       hp_cont.party_id  contact_party_id,
       hp_rel.party_id   relationship_party_id,
       hp.party_name,
       hp.party_number,
       hps.identifying_address_flag,
       hp_cont.person_title           contact_title,
       hp_cont.person_first_name      contact_first_name,
       hp_cont.person_last_name       contact_last_name,
       hp_rel.primary_phone_area_code contact_phone_area_code,
       hp_rel.primary_phone_number    contact_phone_number,
       hp_rel.primary_phone_extension contact_phone_extension,
       hp_rel.email_address           contact_email
  from apps.hz_parties               hp,
       apps.hz_party_sites           hps,
       apps.xx_cdh_s_ext_sitecntct_v hpse,
       apps.hz_party_relationships   rel,
       apps.hz_parties               hp_cont,
       apps.hz_parties               hp_rel
 where hp.party_id                    = hps.party_id
   and hps.party_site_id              = hpse.party_site_id
   and hpse.sitecntct_relationship_id = rel.party_relationship_id
   and rel.subject_id                 = hp_cont.party_id
   and rel.party_id                   = hp_rel.party_id
   and hp.status                      = 'A'
   and hps.status                     = 'A'
   and hp_rel.status                  = 'A'
   and hp_cont.status                 = 'A'
   and hpse.sitecntct_status          = 'A'
   and sysdate                        between nvl(hpse.sitecntct_start_dt, sysdate-1)
                                          and nvl(hpse.sitecntct_end_dt,   sysdate+1)
/
