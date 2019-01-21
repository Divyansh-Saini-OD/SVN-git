create or replace PACKAGE BODY XXCCRM_OPPTY_FIX_PKG
-- +=====================================================================================+
-- |                  Office Depot - Project Simplify  Rel 1.2                           |
-- +=====================================================================================+
-- |                                                                                     |
-- | Name             : Update_Opportunities                                             |
-- |                                                                                     |
-- | Description      : Fix the opportunities as per Defect - 4487                       |
-- |                                                                                     |
-- |Change Record:                                                                       |
-- |===============                                                                      |
-- |Version   Date        Author                       Remarks                           |
-- |=======   ==========  ====================         ==================================|
-- |Draft 1.0 04-APR-10   Nabarun Ghosh                Draft version                     |
-- |											 |
-- |											 |
-- +=====================================================================================+
AS


PROCEDURE Update_Opportunities (  p_errbuf    OUT NOCOPY VARCHAR2
                                 ,p_retcode   OUT NOCOPY VARCHAR2
                                 ,p_opportunity_number  IN VARCHAR2
                                 )
AS


	 lb_status                   BOOLEAN;
         lc_lead_number              VARCHAR2(30);
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

	 cursor c_leads (p_in_oppty_num IN VARCHAR2) is
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
	      ,acces.sales_group_id access_sales_group_id
	FROM   apps.as_leads_all     lead
	      ,as_accesses_all       acces
	      ,apps.as_sales_credits credit
	      ,apps.oe_sales_credit_types asosctypes
	      ,apps.hz_party_sites   hzps
	      ,apps.hz_parties         hp
	      ,apps.jtf_rs_group_members_vl jtgm
	      ,apps.jtf_rs_groups_tl        jtgrp
	      ,apps.jtf_rs_roles_b        jrole
	      ,apps.jtf_rs_role_relations   JTRR           
	WHERE  (   lead.lead_number  = p_in_oppty_num
		 OR p_in_oppty_num IS NULL)
	AND    lead.lead_id = acces.lead_id
	AND    lead.lead_id = credit.lead_id
	AND    lead.owner_salesforce_id = credit.salesforce_id
	AND    acces.sales_group_id IS NULL
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

 
     
     lc_lead_number := p_opportunity_number;
     
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Parameter : Opportunity Number: '||lc_lead_number);
     
     /*
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
    */
    
    l_global_user_id := fnd_global.user_id;
    
    FND_FILE.PUT_LINE (FND_FILE.LOG,'User_Id :'||l_global_user_id);

    --l_sales_team_rec_type.owner_flag  := 'Y';
    l_sales_team_rec_type.prm_keep_flag := 'Y';
  
 
    FOR lead_rec IN c_leads (
                              p_in_oppty_num => lc_lead_number
                            ) 
    LOOP

             
	    BEGIN
		  SELECT      
			 OpportunityAccessEO.access_id,     
			 OpportunityAccessEO.lead_id,
			 OpportunityAccessEO.salesforce_id,
			 OpportunityAccessEO.person_id,
			 OpportunityAccessEO.customer_id,
			 OpportunityAccessEO.address_id,
			 OpportunityAccessEO.last_update_date  ,
			 jtgm.group_id     resource_sales_group_id
		  INTO
			 l_sales_team_rec_type.access_id
			,l_sales_team_rec_type.lead_id 
			,l_sales_team_rec_type.salesforce_id
			,l_sales_team_rec_type.person_id
			,l_sales_team_rec_type.customer_id
			,l_sales_team_rec_type.address_id
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
		  AND   OpportunityAccessEO.sales_group_id IS NULL
		  --AND   OpportunityAccessEO.owner_flag = 'Y'
		  AND   OpportunityAccessEO.lead_id = lead_rec.lead_id
		  AND    OpportunityAccessEO.salesforce_id = JTGM.resource_id
		  AND   JTGM.group_id = JTGRP.group_id
		  AND   jrole.role_type_code  = 'SALES'
		  and   jrole.member_flag = 'Y'
		  AND   nvl(JTRR.delete_flag,'N')='N'
		  AND   TRUNC(SYSDATE) BETWEEN NVL(TRUNC(JTRR.start_date_active),TRUNC(SYSDATE)-1)
					   AND     NVL(TRUNC(JTRR.end_date_active),TRUNC(SYSDATE)+1)
		  AND    jrole.role_id = JTRR.role_id
		  AND    JTRR.role_resource_type  = 'RS_GROUP_MEMBER'
		  AND    JTRR.role_resource_id    = JTGM.group_member_id;
	    EXCEPTION
	      WHEN NO_DATA_FOUND THEN
	       l_sales_team_rec_type.access_id  := null;
	       l_sales_team_rec_type.lead_id := null;
	       l_sales_team_rec_type.salesforce_id:= null;
	       l_sales_team_rec_type.person_id:= null;
	       l_sales_team_rec_type.customer_id:= null;
	       l_sales_team_rec_type.last_update_date:= null;
	       l_sales_team_rec_type.sales_group_id := null;
	       l_sales_team_rec_type.address_id := null;
	       lc_delete := 'N';
	      WHEN OTHERS THEN 
	       l_sales_team_rec_type.access_id  := null;
	       l_sales_team_rec_type.lead_id := null;
	       l_sales_team_rec_type.salesforce_id:= null;
	       l_sales_team_rec_type.person_id:= null;
	       l_sales_team_rec_type.customer_id:= null;
	       l_sales_team_rec_type.last_update_date:= null;
	       l_sales_team_rec_type.sales_group_id := null;
	       l_sales_team_rec_type.address_id := null;
	       lc_delete := 'N';
	    END;
	    
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'lead_id :'||lead_rec.lead_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'access_id :'||l_sales_team_rec_type.access_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'lead_id  :'||l_sales_team_rec_type.lead_id );
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'salesforce_id :'||l_sales_team_rec_type.salesforce_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'person_id :'||l_sales_team_rec_type.person_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'customer_id :'||l_sales_team_rec_type.customer_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'address_id :'||l_sales_team_rec_type.address_id);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'last_update_date :'||l_sales_team_rec_type.last_update_date);
	    FND_FILE.PUT_LINE (FND_FILE.LOG,'sales_group_id :'||l_sales_team_rec_type.sales_group_id);
	    
	    
	    

	    AS_ACCESS_PUB.Update_SalesTeam
	    (       p_api_version_number             => 2.0,
		    p_init_msg_list                  => FND_API.G_FALSE,
		    p_commit                         => FND_API.G_TRUE,
		    p_validation_level		     => 90, 
		    p_access_profile_rec	     => l_access_profile_rec_type,
		    p_check_access_flag              => 'Y',
		    p_admin_flag                     => 'N',
		    p_admin_group_id                 => NULL,
		    p_identity_salesforce_id         => l_sales_team_rec_type.salesforce_id,
		    p_sales_team_rec                 => l_sales_team_rec_type,
		    x_return_status                  => l_return_status,
		    x_msg_count                      => l_msg_count,
		    x_msg_data                       => l_msg_data,
		    x_access_id                      => l_access_id
	     );

            FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'No of messages:  '||l_msg_count||'  '||'Error Descriptions :  '||l_msg_data||'  '||' access_id updated:  '||l_access_id);
	    
	    
	    IF l_return_status = FND_API.G_RET_STS_SUCCESS THEN
	       COMMIT;
	       
	       FND_FILE.PUT_LINE (FND_FILE.LOG,'AS_ACCESS_PUB.Update_SalesTeam API Return Status:  '||l_return_status||'  '||'Commit Success ');
	    
	    ELSE
		FOR k IN 1 .. l_msg_count
		LOOP
		   l_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);

		   If l_msg_data IS NULL Then
		      EXIT;
		   else
		      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Descriptions :'||l_msg_data);
		   end if;

		END LOOP;

	    END IF;  
    END LOOP;
 
EXCEPTION
    WHEN OTHERS THEN
      lb_status := FND_CONCURRENT.SET_COMPLETION_STATUS ('ERROR', NULL);
      FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unexpected Errors: Update_Opportunities: ' ||SUBSTR(SQLERRM, 1, 255));

END Update_Opportunities;         

END XXCCRM_OPPTY_FIX_PKG;
/
SHOW ERRORS
EXIT;
