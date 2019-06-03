-- +===================================================================+
-- |                  Office Depot - Projects  Setup                   |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name  :  XX_PROJ_PARTY_UPDATE.SQL                                 |
-- | Description: SCRIPT is to update project parties start date       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      26-Mar-2010  Rama Dwibhashyam    update project parties   |
-- |             |                                                     |
-- +===================================================================+


declare

cursor cur_proj_parties is
select ppa.segment1,ppa.scheduled_start_date,ppf.full_name,ppp.start_date_active,ppf.effective_start_date,
       ppp.project_party_id
from apps.pa_projects_all ppa,
     apps.pa_project_parties ppp,
     apps.per_all_people_f ppf
where ppa.project_id = ppp.project_id   
  and ppp.resource_source_id = ppf.person_id  
  and ppa.scheduled_start_date <> ppp.start_date_active ;
  
  ln_count  number := 0 ;
  
begin

    for proj_parties_rec in cur_proj_parties 
    loop
        ln_count := ln_count + 1 ;
        
        update pa_project_parties
           set start_date_active = proj_parties_rec.scheduled_start_date 
        where  project_party_id  = proj_parties_rec.project_party_id ;
    
    
    end loop ;
    
    dbms_output.put_line ('No of Records updated :'||ln_count) ;
    
    commit ;     

end;  
/