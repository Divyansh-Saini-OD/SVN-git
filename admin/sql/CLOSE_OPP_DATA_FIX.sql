set serverout on size 1000000
spool fix_asgnmnt_history.lst

DECLARE

 l_access_profile_rec_type   AS_ACCESS_PUB.access_profile_rec_type;
 l_sales_team_rec_type       AS_ACCESS_PUB.sales_team_rec_type;  
 l_access_id                 PLS_INTEGER;
 
 l_return_status    varchar2(5);
 l_msg_count        number;
 l_msg_index_out    number;
 l_msg_data         varchar2(2000);
 lc_delete varchar2(2) := null;
 l_application_id     pls_integer;
 l_responsibility_id  pls_integer;
 l_user_id            pls_integer;
 l_global_user_id            pls_integer;

  cursor c_leads is
 select /*+ no_merge(m) */  lead_id
from
(
SELECT  distinct
       lead.lead_id
      ,lead.lead_number 
      ,lead.description opportunity
      ,lead.status
      ,lead.customer_id
      ,lead.address_id
      ,hzps.party_site_id
      ,hp.party_id
      ,hp.party_name
      ,lead.owner_salesforce_id
      ,(
        SELECT source_name
      	FROM   apps.jtf_rs_resource_extns
      	WHERE  resource_id = lead.owner_salesforce_id
      	AND    TRUNC(SYSDATE) BETWEEN NVL(TRUNC(start_date_active),TRUNC(SYSDATE)-1)
      	AND     NVL(TRUNC(end_date_active),TRUNC(SYSDATE)+1)
       )                      resource_name
      ,JTGRP.group_id        resource_group_id
      ,JTGRP.group_name      resource_group_name
      ,lead.owner_sales_group_id
      ,asosctypes.name sales_credit_type
      ,credit.person_id
      ,credit.salesgroup_id  
      ,credit.sales_credit_id
FROM   apps.as_leads_all     lead
      ,apps.as_sales_credits credit
      ,apps.oe_sales_credit_types asosctypes
      ,apps.hz_party_sites   hzps
      ,apps.hz_parties         hp
      ,apps.jtf_rs_group_members_vl jtgm
      ,apps.jtf_rs_groups_tl        jtgrp
      ,apps.jtf_rs_roles_b        jrole
      ,apps.jtf_rs_role_relations   JTRR           
WHERE  lead.lead_id = credit.lead_id
AND    lead.owner_salesforce_id = credit.salesforce_id
AND    credit.salesgroup_id IS NULL
AND    credit.credit_type_id    = asosctypes.sales_credit_type_id
AND    nvl(jtgm.delete_flag,'N')='N'
AND   JTGM.resource_id         = lead.owner_salesforce_id
AND   JTGM.group_id = JTGRP.group_id
AND    jrole.role_type_code  = 'SALES'
and    jrole.member_flag = 'Y'
AND   nvl(JTRR.delete_flag,'N')='N'
AND   TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
                         AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
and    jrole.role_id = JTRR.role_id
AND    JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
AND    JTRR.role_resource_id    = JTGM.group_member_id
AND    lead.address_id = hzps.party_site_id(+)
AND    hzps.party_id = hp.party_id(+)
ORDER BY lead.lead_id
) m;

BEGIN


     select application_id
           ,responsibility_id
     into   l_application_id   
           ,l_responsibility_id 
     from   fnd_responsibility_tl
     where  responsibility_name = 'OD (US) Sales Operations User'
     and    language = userenv('LANG');
     
     select user_id
     into   l_user_id
     from   fnd_user
     where  user_name ='ODSFA';
     
    begin 
     fnd_global.apps_initialize(l_user_id,l_responsibility_id,l_application_id);
    end;
    
    l_global_user_id := fnd_global.user_id;
    
    dbms_output.put_line('User_Id :'||l_global_user_id);

    l_sales_team_rec_type.owner_flag  := 'Y';
    l_sales_team_rec_type.prm_keep_flag := 'Y';
  
Begin
   for lead_rec in c_leads loop


  begin
  SELECT      
         OpportunityAccessEO.access_id,     
         OpportunityAccessEO.lead_id,
         OpportunityAccessEO.salesforce_id,
         OpportunityAccessEO.person_id,
         OpportunityAccessEO.customer_id,
         OpportunityAccessEO.last_update_date  ,
         jtgm.group_id     resource_sales_group_id
  INTO
         l_sales_team_rec_type.access_id
        ,l_sales_team_rec_type.lead_id 
        ,l_sales_team_rec_type.salesforce_id
        ,l_sales_team_rec_type.person_id
        ,l_sales_team_rec_type.customer_id
        ,l_sales_team_rec_type.last_update_date             
        ,l_sales_team_rec_type.sales_group_id
  FROM  apps.jtf_rs_resource_extns jrb,
        apps.as_accesses_all  OpportunityAccessEO,
        apps.jtf_rs_group_members_vl jtgm,
        apps.jtf_rs_groups_tl        jtgrp,
        apps.jtf_rs_roles_b        jrole,
        apps.jtf_rs_role_relations   JTRR
  WHERE OpportunityAccessEO.salesforce_id = jrb.resource_id
  AND   jrb.category = 'EMPLOYEE'
  AND   OpportunityAccessEO.owner_flag = 'Y'
  AND   OpportunityAccessEO.lead_id = lead_rec.lead_id
 AND    OpportunityAccessEO.salesforce_id = JTGM.resource_id
  AND   JTGM.group_id = JTGRP.group_id
  AND   jrole.role_type_code  = 'SALES'
  and   jrole.member_flag = 'Y'
  AND   nvl(JTRR.delete_flag,'N')='N'
  AND   TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
                           AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
  and    jrole.role_id = JTRR.role_id
  AND    JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
  AND    JTRR.role_resource_id    = JTGM.group_member_id;
  exception
    when no_data_found then
     l_sales_team_rec_type.access_id  := null;
     l_sales_team_rec_type.lead_id := null;
     l_sales_team_rec_type.salesforce_id:= null;
     l_sales_team_rec_type.person_id:= null;
     l_sales_team_rec_type.customer_id:= null;
     l_sales_team_rec_type.last_update_date:= null;
     lc_delete := 'N';
    when others then 
     l_sales_team_rec_type.access_id  := null;
     l_sales_team_rec_type.lead_id := null;
     l_sales_team_rec_type.salesforce_id:= null;
     l_sales_team_rec_type.person_id:= null;
     l_sales_team_rec_type.customer_id:= null;
     l_sales_team_rec_type.last_update_date:= null;
     lc_delete := 'N';
end;     



 
  AS_ACCESS_PUB.Update_SalesTeam
  (       p_api_version_number             => 2.0,
          p_init_msg_list                  => FND_API.G_FALSE,
          p_commit                         => FND_API.G_TRUE,
  	  p_validation_level		   => 90, 
          p_access_profile_rec	           => l_access_profile_rec_type,
  	  p_check_access_flag              => 'Y',
  	  p_admin_flag                     => 'N',
  	  p_admin_group_id                 => NULL,
  	  p_identity_salesforce_id         => l_sales_team_rec_type.salesforce_id,
          p_sales_team_rec                 => l_sales_team_rec_type,
          x_return_status                  => l_return_status,
          x_msg_count                      => l_msg_count,
          x_msg_data                       => l_msg_data,
          x_access_id                       => l_access_id
  );

 dbms_output.put_line('Update_SalesTeam l_return_status:  '||l_return_status);
 dbms_output.put_line('Update_SalesTeam l_msg_count:  '||l_msg_count);

 IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
   COMMIT;
 ELSE
        FOR k IN 1 .. l_msg_count
        LOOP
           l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
                             
           If l_msg_data IS NULL Then
	      EXIT;
	   else
              dbms_output.put_line('Update_SalesTeam Error :'||l_msg_data);
           end if;
           
        END LOOP;
 
 END IF;  
        END LOOP;
END;
END;
/