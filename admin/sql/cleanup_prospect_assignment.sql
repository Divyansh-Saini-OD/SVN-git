--Delete all the lead and opportunity assignments
delete /*+parallel(terr,8)*/ 
from apps.xx_tm_nam_terr_entity_dtls terr
where entity_type <> 'PARTY_SITE'
/

--Delete all the prospect party site assignments
delete /*+parallel(terr,8)*/ 
from  apps.xx_tm_nam_terr_entity_dtls terr
where terr.entity_type = 'PARTY_SITE'
  and exists (select 1
              from   apps.hz_parties hzp,
                     apps.hz_party_sites hzps
              where  hzps.party_site_id = terr.entity_id
                and  hzp.party_id = hzps.party_id
                and  hzp.party_type = 'ORGANIZATION'
                and  hzp.attribute13 = 'PROSPECT'
             )
/

commit
/

