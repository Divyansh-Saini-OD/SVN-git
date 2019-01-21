create or replace
package body XX_CDH_GP_MAINT_PKG AS

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_GP_MAINT_PKG.pkb                                                     |
-- | Description : GP Import                                                                    |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        18-May-2016     Shubashree R        Removed the schema reference for GSCC compliance QC#37898|
-- |2.0        09-Nov-2016     Havish Kasina       Removed schema references for R12.2 GSCC compliance|
-- +============================================================================================+

procedure insert_gp_rec(
    p_init_msg_list           	IN 		        VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			        IN 		        gp_rec_type,
    x_gp_id                     OUT NOCOPY      xx_cdh_gp_master.gp_id%type,
    x_return_status           	OUT NOCOPY   	VARCHAR2,
    x_msg_count               	OUT NOCOPY   	NUMBER,
    x_msg_data                	OUT NOCOPY   	VARCHAR2
   ) IS
   
insert_gp_rec_excep EXCEPTION;   
pragma exception_init(insert_gp_rec_excep, -20994);

TEMP_GP_ID NUMBER;

BEGIN
-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
           FND_MSG_PUB.initialize;
    	END IF;
      x_return_status := FND_API.G_RET_STS_SUCCESS;
     
    if  p_gp_rec.gp_id IS NULL  THEN 
    
    select XX_CDH_GP_MASTER_S.nextval into TEMP_GP_ID from dual;
     
    ELSE 
    
    TEMP_GP_ID :=  p_gp_rec.gp_id ;
    end if;
  insert into XX_CDH_GP_MASTER 
    (
      gp_id						
      ,gp_name						
      ,resource_id					
      ,role_id					
      ,group_id						
      ,legacy_rep_id					
      ,segment                            
      ,revenue_band                       
      ,w_agreement_flag				
      ,notes						
      ,party_id                           
      ,requestor						
      ,status					
      ,status_update_date				
      ,ATTRIBUTE_CATEGORY             		
      ,ATTRIBUTE1                        	                                                                                                                                                                                 
      ,ATTRIBUTE2                  	   	                                                                                                                                                                              
      ,ATTRIBUTE3                         	                                                                                                                                                                                
      ,ATTRIBUTE4                        		                                                                                                                                                                               
      ,ATTRIBUTE5                             	                                                                                                                                                                                
      ,ATTRIBUTE6                             	                                                                                                                                                                                
      ,ATTRIBUTE7                             	                                                                                                                                                                               
      ,ATTRIBUTE8                                                                                                                                                                                                             
      ,ATTRIBUTE9                             	                                                                                                                                                                                 
      ,ATTRIBUTE10                            	                                                                                                                                                                                
      ,ATTRIBUTE11                                                                                                                                                                                                     
      ,ATTRIBUTE12                            	                                                                                                                                                                                
      ,ATTRIBUTE13                            	                                                                                                                                                                                 
      ,ATTRIBUTE14                                                                                                                                                                                                             
      ,ATTRIBUTE15                            	                                                                                                                                                                             
      ,ATTRIBUTE16                                                                                                                                                                                                            
      ,ATTRIBUTE17                            	                                                                                                                                                                                 
      ,ATTRIBUTE18                            	                                                                                                                                                                                
      ,ATTRIBUTE19                            	                                                                                                                                                                               
      ,ATTRIBUTE20                            	         
      ,OBJECT_VERSION_NUMBER                  	
      ,REQUEST_ID                             	 
      ,PROGRAM_ID                                                                                                                                                                                                              
      ,PROGRAM_UPDATE_DATE                    	                                                                                                                                                                                     
      ,PROGRAM_APPLICATION_ID                 	                    
      ,CREATION_DATE                                                                                                                                                                                                                   
      ,CREATED_BY                                                                                                                                                                                                                    
      ,LAST_UPDATE_DATE                       	                                                                                                                                                                                         
      ,LAST_UPDATED_BY                                                                                                     
      ,CREATED_BY_MODULE                      
      ,APPLICATION_ID                         
      )
      values
      (
     TEMP_GP_ID
      ,p_gp_rec.gp_name						
      ,p_gp_rec.resource_id					
      ,p_gp_rec.role_id					
      ,p_gp_rec.group_id						
      ,p_gp_rec.legacy_rep_id					
      ,p_gp_rec.segment                            
      ,p_gp_rec.revenue_band                       
      ,p_gp_rec.w_agreement_flag				
      ,p_gp_rec.notes						
      ,p_gp_rec.party_id                           
      ,p_gp_rec.requestor						
      ,nvl(p_gp_rec.status,'A')
      ,SYSDATE				
      ,p_gp_rec.ATTRIBUTE_CATEGORY             		
      ,p_gp_rec.ATTRIBUTE1                        	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE2                  	   	                                                                                                                                                                              
      ,p_gp_rec.ATTRIBUTE3                         	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE4                        		                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE5                             	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE6                             	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE7                             	                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE8                                                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE9                             	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE10                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE11                                                                                                                                                                                                     
      ,p_gp_rec.ATTRIBUTE12                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE13                            	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE14                                                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE15                            	                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE16                                                                                                                                                                                                            
      ,p_gp_rec.ATTRIBUTE17                            	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE18                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE19                            	                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE20                            	         
      ,p_gp_rec.OBJECT_VERSION_NUMBER                  	
      ,p_gp_rec.REQUEST_ID                             	 
      ,p_gp_rec.PROGRAM_ID                                                                                                                                                                                                              
      ,p_gp_rec.PROGRAM_UPDATE_DATE                    	                                                                                                                                                                                     
      ,p_gp_rec.PROGRAM_APPLICATION_ID                 	                    
      ,HZ_UTILITY_V2PUB.CREATION_DATE                                                                                                                                                                                                                   
      ,HZ_UTILITY_V2PUB.CREATED_BY                                                                                                                                                                                                                    
      ,HZ_UTILITY_V2PUB.LAST_UPDATE_DATE                       	                                                                                                                                                                                         
      ,HZ_UTILITY_V2PUB.LAST_UPDATED_BY                                                                                                   
      ,p_gp_rec.CREATED_BY_MODULE                      
      ,p_gp_rec.APPLICATION_ID  
      ) returning gp_id into x_gp_id ;
EXCEPTION WHEN OTHERS THEN
    RAISE insert_gp_rec_excep;

END insert_gp_rec;
   
procedure update_gp_rec(
    p_init_msg_list           	IN 		        VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			        IN 		        gp_rec_type,
    x_return_status           	OUT NOCOPY   	VARCHAR2,
    x_msg_count               	OUT NOCOPY   	NUMBER,
    x_msg_data                	OUT NOCOPY   	VARCHAR2
   ) IS
update_gp_rec_excep   EXCEPTION;  
pragma exception_init(update_gp_rec_excep, -20995);
BEGIN

-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
        	FND_MSG_PUB.initialize;
    	END IF;
      x_return_status := FND_API.G_RET_STS_SUCCESS;
  
  
  update XX_CDH_GP_MASTER
      set
       gp_name						      = p_gp_rec.gp_name
      ,resource_id					    = p_gp_rec.resource_id
      ,role_id					        = p_gp_rec.role_id
      ,group_id						      = p_gp_rec.group_id
      ,legacy_rep_id				    =	p_gp_rec.legacy_rep_id
      ,segment                  = p_gp_rec.segment        
      ,revenue_band             = p_gp_rec.revenue_band            
      ,w_agreement_flag			    =	p_gp_rec.w_agreement_flag
      ,notes					          =	p_gp_rec.notes
      ,party_id                 = NVL(p_gp_rec.party_id,party_id)
      ,requestor						    = p_gp_rec.requestor
      ,status					          = p_gp_rec.status
      ,status_update_date		    =	p_gp_rec.status_update_date
      ,ATTRIBUTE_CATEGORY       = p_gp_rec.ATTRIBUTE_CATEGORY
      ,ATTRIBUTE1               = p_gp_rec.ATTRIBUTE1            	                                                                                                                                                                                 
      ,ATTRIBUTE2               = p_gp_rec.ATTRIBUTE2      	   	                                                                                                                                                                              
      ,ATTRIBUTE3               = p_gp_rec.ATTRIBUTE3             	                                                                                                                                                                                
      ,ATTRIBUTE4               = p_gp_rec.ATTRIBUTE4            		                                                                                                                                                                               
      ,ATTRIBUTE5               = p_gp_rec.ATTRIBUTE5                 	                                                                                                                                                                                
      ,ATTRIBUTE6               = p_gp_rec.ATTRIBUTE6                 	                                                                                                                                                                                
      ,ATTRIBUTE7               = p_gp_rec.ATTRIBUTE7                 	                                                                                                                                                                               
      ,ATTRIBUTE8               = p_gp_rec.ATTRIBUTE8                                                                                                                                                                                                 
      ,ATTRIBUTE9               = p_gp_rec.ATTRIBUTE9                 	                                                                                                                                                                                 
      ,ATTRIBUTE10              = p_gp_rec.ATTRIBUTE10                 	                                                                                                                                                                                
      ,ATTRIBUTE11              = p_gp_rec.ATTRIBUTE11                                                                                                                                                                                          
      ,ATTRIBUTE12              = p_gp_rec.ATTRIBUTE12                 	                                                                                                                                                                                
      ,ATTRIBUTE13              = p_gp_rec.ATTRIBUTE13                 	                                                                                                                                                                                 
      ,ATTRIBUTE14              = p_gp_rec.ATTRIBUTE14                                                                                                                                                                                                  
      ,ATTRIBUTE15              = p_gp_rec.ATTRIBUTE15                 	                                                                                                                                                                             
      ,ATTRIBUTE16              = p_gp_rec.ATTRIBUTE16                                                                                                                                                                                                 
      ,ATTRIBUTE17              = p_gp_rec.ATTRIBUTE17                	                                                                                                                                                                                 
      ,ATTRIBUTE18              = p_gp_rec.ATTRIBUTE18             	                                                                                                                                                                                
      ,ATTRIBUTE19              = p_gp_rec.ATTRIBUTE19             	                                                                                                                                                                               
      ,ATTRIBUTE20              = p_gp_rec.ATTRIBUTE20             	         
      ,OBJECT_VERSION_NUMBER    = p_gp_rec.OBJECT_VERSION_NUMBER            	
      ,REQUEST_ID               = p_gp_rec.REQUEST_ID             	 
      ,PROGRAM_ID               = p_gp_rec.PROGRAM_ID                                                                                                                                                                                              
      ,PROGRAM_UPDATE_DATE      = p_gp_rec.PROGRAM_UPDATE_DATE             	                                                                                                                                                                                     
      ,PROGRAM_APPLICATION_ID   = p_gp_rec.PROGRAM_APPLICATION_ID            	                    
    --  ,CREATION_DATE            = decode(p_gp_rec.gp_name,null,gp_name,p_gp_rec.gp_name)                                                                                                                                                                                                      
   --   ,CREATED_BY               = decode(p_gp_rec.gp_name,null,gp_name,p_gp_rec.gp_name)                                                                                                                                                                                                    
      ,LAST_UPDATE_DATE         = decode(p_gp_rec.LAST_UPDATE_DATE,null,SYSDATE,p_gp_rec.LAST_UPDATE_DATE)             	                                                                                                                                                                                         
      ,LAST_UPDATED_BY          = decode(p_gp_rec.LAST_UPDATED_BY,null,HZ_UTILITY_V2PUB.LAST_UPDATED_BY,p_gp_rec.LAST_UPDATED_BY)                                                                                          
    --  ,CREATED_BY_MODULE        = decode(p_gp_rec.gp_name,null,gp_name,p_gp_rec.gp_name)             
      ,APPLICATION_ID           =decode(p_gp_rec.APPLICATION_ID,null,APPLICATION_ID,p_gp_rec.APPLICATION_ID)              
      where  gp_id	= p_gp_rec.gp_id;
      
EXCEPTION WHEN OTHERS THEN
    RAISE update_gp_rec_excep;
END update_gp_rec;

PROCEDURE insert_gp_hist_rec (
    p_init_msg_list           	IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec		                IN		          gp_rec_type,
    x_gp_hist_id		            OUT NOCOPY      NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
) IS
insert_gp_hist_rec_excep    EXCEPTION;
pragma exception_init(insert_gp_hist_rec_excep, -20996);
BEGIN
-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
        	FND_MSG_PUB.initialize;
    	END IF;
	x_return_status := FND_API.G_RET_STS_SUCCESS;
  
  insert into XX_CDH_GP_HIST
    (
      gp_hist_id
      ,gp_id						
      ,gp_name						
      ,resource_id					
      ,role_id					
      ,group_id						
      ,legacy_rep_id					
      ,segment                            
      ,revenue_band                       
      ,w_agreement_flag				
      ,notes						
      ,party_id                           
      ,requestor						
      ,status					
      ,status_update_date				
      ,ATTRIBUTE_CATEGORY             		
      ,ATTRIBUTE1                        	                                                                                                                                                                                 
      ,ATTRIBUTE2                  	   	                                                                                                                                                                              
      ,ATTRIBUTE3                         	                                                                                                                                                                                
      ,ATTRIBUTE4                        		                                                                                                                                                                               
      ,ATTRIBUTE5                             	                                                                                                                                                                                
      ,ATTRIBUTE6                             	                                                                                                                                                                                
      ,ATTRIBUTE7                             	                                                                                                                                                                               
      ,ATTRIBUTE8                                                                                                                                                                                                             
      ,ATTRIBUTE9                             	                                                                                                                                                                                 
      ,ATTRIBUTE10                            	                                                                                                                                                                                
      ,ATTRIBUTE11                                                                                                                                                                                                     
      ,ATTRIBUTE12                            	                                                                                                                                                                                
      ,ATTRIBUTE13                            	                                                                                                                                                                                 
      ,ATTRIBUTE14                                                                                                                                                                                                             
      ,ATTRIBUTE15                            	                                                                                                                                                                             
      ,ATTRIBUTE16                                                                                                                                                                                                            
      ,ATTRIBUTE17                            	                                                                                                                                                                                 
      ,ATTRIBUTE18                            	                                                                                                                                                                                
      ,ATTRIBUTE19                            	                                                                                                                                                                               
      ,ATTRIBUTE20                            	         
      ,OBJECT_VERSION_NUMBER                  	
      ,REQUEST_ID                             	 
      ,PROGRAM_ID                                                                                                                                                                                                              
      ,PROGRAM_UPDATE_DATE                    	                                                                                                                                                                                     
      ,PROGRAM_APPLICATION_ID                 	                    
      ,CREATION_DATE                                                                                                                                                                                                                   
      ,CREATED_BY                                                                                                                                                                                                                    
      ,LAST_UPDATE_DATE                       	                                                                                                                                                                                         
      ,LAST_UPDATED_BY                                                                                                     
      ,CREATED_BY_MODULE                      
      ,APPLICATION_ID                         
      )
      values
      (
       XX_CDH_GP_HIST_S.nextval  
      ,p_gp_rec.gp_id						
      ,p_gp_rec.gp_name						
      ,p_gp_rec.resource_id					
      ,p_gp_rec.role_id					
      ,p_gp_rec.group_id						
      ,p_gp_rec.legacy_rep_id					
      ,p_gp_rec.segment                            
      ,p_gp_rec.revenue_band                       
      ,p_gp_rec.w_agreement_flag				
      ,p_gp_rec.notes						
      ,p_gp_rec.party_id                           
      ,p_gp_rec.requestor						
      ,nvl(p_gp_rec.status,'A')					
      ,p_gp_rec.status_update_date				
      ,p_gp_rec.ATTRIBUTE_CATEGORY             		
      ,p_gp_rec.ATTRIBUTE1                        	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE2                  	   	                                                                                                                                                                              
      ,p_gp_rec.ATTRIBUTE3                         	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE4                        		                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE5                             	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE6                             	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE7                             	                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE8                                                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE9                             	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE10                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE11                                                                                                                                                                                                     
      ,p_gp_rec.ATTRIBUTE12                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE13                            	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE14                                                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE15                            	                                                                                                                                                                             
      ,p_gp_rec.ATTRIBUTE16                                                                                                                                                                                                            
      ,p_gp_rec.ATTRIBUTE17                            	                                                                                                                                                                                 
      ,p_gp_rec.ATTRIBUTE18                            	                                                                                                                                                                                
      ,p_gp_rec.ATTRIBUTE19                            	                                                                                                                                                                               
      ,p_gp_rec.ATTRIBUTE20                            	         
      ,p_gp_rec.OBJECT_VERSION_NUMBER                  	
      ,p_gp_rec.REQUEST_ID                             	 
      ,p_gp_rec.PROGRAM_ID                                                                                                                                                                                                              
      ,p_gp_rec.PROGRAM_UPDATE_DATE                    	                                                                                                                                                                                     
      ,p_gp_rec.PROGRAM_APPLICATION_ID                 	                    
      ,HZ_UTILITY_V2PUB.CREATION_DATE                                                                                                                                                                                                                   
      ,HZ_UTILITY_V2PUB.CREATED_BY                                                                                                                                                                                                                    
      ,HZ_UTILITY_V2PUB.LAST_UPDATE_DATE                       	                                                                                                                                                                                         
      ,HZ_UTILITY_V2PUB.LAST_UPDATED_BY                                                                                                      
      ,p_gp_rec.CREATED_BY_MODULE                      
      ,p_gp_rec.APPLICATION_ID  
      ) returning gp_hist_id into x_gp_hist_id;
      
EXCEPTION WHEN OTHERS THEN
    RAISE insert_gp_hist_rec_excep;
    
END;


procedure 	do_update_party_rel ( 
    p_init_msg_list           	IN 		        VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		        gp_rec_type,
    x_return_status           	OUT NOCOPY   	VARCHAR2,
    x_msg_count               	OUT NOCOPY   	NUMBER,
    x_msg_data                	OUT NOCOPY   	VARCHAR2,
    x_profile_id              	OUT NOCOPY   	NUMBER
) IS

l_organization_rec		HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
DO_update_PARTY_excep   EXCEPTION;
l_party_ovn             NUMBER;
l_en_date               DATE;
pragma exception_init(DO_update_PARTY_excep, -20997);

cursor  c_inactivate_parents(gp_party_id HZ_PARTIES.PARTY_ID%TYPE) IS
select  relationship_id, object_id,trunc(start_date) st_date
from    HZ_RELATIONSHIPS
WHERE   subject_id = gp_party_id
and     status = 'A'
and     direction_code = 'P'
and     trunc(NVL(end_date,SYSDATE+1)) > trunc(sysdate)
and     trunc(start_date) <>  trunc(end_date)
and     relationship_type = 'OD_CUST_HIER'
and     relationship_code = 'GRANDPARENT';

BEGIN
/*	l_organization_rec.organization_name    := p_gp_rec.gp_name;
	l_organization_rec.party_rec.party_id := p_gp_rec.party_id;
  
    select  object_version_number into l_party_ovn
    from    hz_parties
    where   party_id = l_organization_rec.party_rec.party_id;
    
    
	HZ_PARTY_V2PUB.update_organization (
    		p_init_msg_list    ,
    		l_organization_rec ,
        l_party_ovn        ,
        x_profile_id       ,
        x_return_status    ,
    		x_msg_count        ,
    		x_msg_data         
	);
	if x_return_status <> fnd_api.g_ret_sts_success THEN
       		RAISE DO_update_PARTY_EXCEP;
  end if;
*/  

  IF p_gp_rec.status = 'I' THEN
    
      for inactivate_parents_rec In c_inactivate_parents( p_gp_rec.party_id) loop
      
        IF inactivate_parents_rec.st_date > TRUNC(SYSDATE) THEN
           l_en_date  := inactivate_parents_rec.st_date;
        ELSE
           l_en_date  := SYSDATE;
        END IF;
      
        XX_CDH_GP_REL_PKG.update_gp_rel(
          p_init_msg_list           => p_init_msg_list,
          p_relationship_id         => inactivate_parents_rec.relationship_id,
          p_parent_id               => inactivate_parents_rec.object_id,
          p_gp_id                   => p_gp_rec.party_id ,
          p_end_date                => l_en_date,
          p_requestor               => p_gp_rec.requestor,
          p_notes                   => p_gp_rec.notes,
          p_status                  => 'A',
          x_ret_status              => x_return_status,
          x_m_count                 => x_msg_count,
          x_m_data                  => x_msg_data );
        
          if x_return_status <> fnd_api.g_ret_sts_success THEN
            RAISE DO_update_PARTY_excep;
          end if;
      end loop;
  
  END IF;
  
EXCEPTION WHEN OTHERS THEN
    RAISE ;
END do_update_party_rel ;

procedure 	do_create_party ( 
    p_init_msg_list           	IN 		VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		gp_rec_type,
    x_return_status           	OUT NOCOPY   	VARCHAR2,
    x_msg_count               	OUT NOCOPY   	NUMBER,
    x_msg_data                	OUT NOCOPY   	VARCHAR2,
    x_party_id                	OUT NOCOPY   	NUMBER,
    x_party_number            	OUT NOCOPY   	VARCHAR2,
    x_profile_id              	OUT NOCOPY   	NUMBER
) IS

l_organization_rec		  HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
DO_CREATE_PARTY_excep   EXCEPTION;
pragma exception_init(DO_CREATE_PARTY_excep, -20998);


BEGIN
	l_organization_rec.organization_name := p_gp_rec.gp_name;
  l_organization_rec.created_by_module := 'XXCRM';
	--l_organization_rec.organization_name := p_gp_rec.gp_name;
	--l_organization_rec.organization_name := p_gp_rec.gp_name;

	HZ_PARTY_V2PUB.create_organization (
    		p_init_msg_list    ,
    		l_organization_rec ,
        x_return_status    ,
    		x_msg_count        ,
    		x_msg_data         ,
    		x_party_id         ,
    		x_party_number     ,
    		x_profile_id       
	);

    
	if x_return_status <> fnd_api.g_ret_sts_success THEN
       		RAISE DO_CREATE_PARTY_excep;
  end if;
  
EXCEPTION WHEN OTHERS THEN
     RAISE ;
END do_create_party ;



PROCEDURE create_gp (
    p_init_msg_list		          IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		          gp_rec_type,
    x_gp_id                	    OUT NOCOPY     	NUMBER,
    x_party_id                	OUT NOCOPY     	NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
) IS

l_api_name                CONSTANT VARCHAR2(100) := 'XX_CDH_GP_MAINT_PKG.create_gp';
l_party_id                HZ_PARTIES.party_id%type ;
l_party_number            HZ_PARTIES.party_number%type;
l_profile_id              HZ_ORGANIZATION_PROFILES.organization_profile_id%type; 
l_init_msg_list		        VARCHAR2(1):= FND_API.G_FALSE;
l_out_ret_status          VARCHAR2(1);
l_out_msg_count           NUMBER   ;
l_out_msg_data            VARCHAR2(2000) ;
l_gp_hist_id              XX_CDH_GP_HIST.gp_hist_id%type;
l_gp_id                   XX_CDH_GP_MASTER.gp_id%type;
do_create_party_excep     EXCEPTION;
insert_gp_rec_excep       EXCEPTION;
insert_gp_hist_rec_excep  EXCEPTION;
l_gp_rec                  gp_rec_type;
pragma exception_init(DO_CREATE_PARTY_excep, -20998);
pragma exception_init(insert_gp_rec_excep, -20995);
pragma exception_init(insert_gp_hist_rec_excep, -20996);
BEGIN

	SAVEPOINT create_gp ;
  
  l_gp_rec := p_gp_rec;

	-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
        	FND_MSG_PUB.initialize;
    	END IF;
	x_return_status := FND_API.G_RET_STS_SUCCESS;

	--create party
  
	do_create_party(
			 l_init_msg_list,
       l_gp_rec,
			 l_out_ret_status,
			 l_out_msg_count,
			 l_out_msg_data,
			 l_party_id,
			 l_party_number,
			 l_profile_id
			);
      
  x_party_id := l_party_id;
   --insert gp
   l_gp_rec.party_id := l_party_id;
   insert_gp_rec(
        l_init_msg_list,
        l_gp_rec,
        l_gp_id,
        l_out_ret_status,
        l_out_msg_count,
        l_out_msg_data
   );
   
   x_gp_id := l_gp_id;
   l_gp_rec.gp_id := l_gp_id;
   l_gp_rec.status_update_date := SYSDATE;
  record_gp_hist (
    l_init_msg_list   ,
    l_gp_rec	        ,
    l_gp_hist_id		  ,
    l_out_ret_status  ,
    l_out_msg_count   ,
    l_out_msg_data                 
    );

EXCEPTION 

WHEN do_create_party_excep THEN

	ROLLBACK TO create_gp ;
	x_return_status := FND_API.G_RET_STS_ERROR;
  x_msg_data := l_out_msg_data;
  x_msg_count := l_out_msg_count;
--	FND_MSG_PUB.Count_And_Get(
--                                  p_encoded => FND_API.G_FALSE,
--                                  p_count => l_out_msg_count,
--                                  p_data  => l_out_msg_data);
                                  
WHEN insert_gp_rec_excep THEN
	ROLLBACK TO create_gp ;
	x_return_status := FND_API.G_RET_STS_ERROR;
  x_msg_data      := 'insert_gp_rec : Exception is ' || sqlerrm ;
	
WHEN insert_gp_hist_rec_excep THEN
	ROLLBACK TO create_gp ;
	x_return_status := FND_API.G_RET_STS_ERROR;
	x_msg_data      := 'record_gp_hist : Exception is ' || sqlerrm;
WHEN OTHERS THEN
	ROLLBACK TO create_gp ;
	x_return_status := FND_API.G_RET_STS_ERROR;
	x_msg_data      := 'create_gp : Exception is ' || sqlerrm || sqlcode;

END create_gp ;

PROCEDURE update_gp (
    p_init_msg_list         	IN		        VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			            IN 		        gp_rec_type,	
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2
) IS

l_api_name              CONSTANT VARCHAR2(100) := 'XX_CDH_GP_MAINT_PKG.update_gp';
l_init_msg_list         VARCHAR2(1):= FND_API.G_FALSE;
l_out_ret_status        VARCHAR2(1);
l_out_msg_count         NUMBER   ;
l_out_msg_data          VARCHAR2(2000) ;
l_gp_hist_id            XX_CDH_GP_HIST.gp_hist_id%TYPE;
do_update_party_excep   EXCEPTION;
update_gp_rec_excep     EXCEPTION; 
insert_gp_hist_rec_excep  EXCEPTION;
l_profile_id            HZ_ORGANIZATION_PROFILES.organization_profile_id%type;
l_gp_rec			          gp_rec_type;
l_db_rec                gp_rec_type;
pragma exception_init(do_update_party_excep, -20997);
pragma exception_init(update_gp_rec_excep, -20995);
pragma exception_init(insert_gp_hist_rec_excep, -20996);

BEGIN


	SAVEPOINT update_gp ;

	-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
        	FND_MSG_PUB.initialize;
    	END IF;

	x_return_status := FND_API.G_RET_STS_SUCCESS;
  
  -- call the update party v2 api
  l_gp_rec := p_gp_rec;
    IF p_gp_rec.party_id IS NULL THEN
    select  party_id into l_gp_rec.party_id
    from    xx_cdh_gp_master
    where   gp_id = p_gp_rec.gp_id;
    --l_organization_rec.party_rec.party_id   := p_gp_rec.party_id;
  END IF;
  
  SELECT NVL(gp_name,'XX'),
         NVL(legacy_rep_id,'XX'),
         NVL(segment,'XX'),
         NVL(revenue_band,'XX'),
         NVL(w_agreement_flag,'N'),
         NVL(notes,'XX'),
         NVL(requestor,-1),
         NVL(status,'A')
  INTO   l_db_rec.gp_name,
         l_db_rec.legacy_rep_id,
         l_db_rec.segment,
         l_db_rec.revenue_band,
         l_db_rec.w_agreement_flag,
         l_db_rec.notes,
         l_db_rec.requestor,
         l_db_rec.status
  FROM xx_cdh_gp_master
  WHERE gp_id = p_gp_rec.gp_id;
  
  
 IF (NVL(l_gp_rec.gp_name,'XX') <> l_db_rec.gp_name OR NVL(l_gp_rec.legacy_rep_id,'XX') <> l_db_rec.legacy_rep_id OR
     NVL(l_gp_rec.segment,'XX') <> l_db_rec.segment OR NVL(l_gp_rec.revenue_band,'XX') <> l_db_rec.revenue_band OR
     NVL(l_gp_rec.w_agreement_flag,'N') <> l_db_rec.w_agreement_flag OR NVL(l_gp_rec.notes,'XX') <> l_db_rec.notes OR
     NVL(l_gp_rec.requestor,-1) <> l_db_rec.requestor OR NVL(l_gp_rec.status,'A') <> l_db_rec.status) THEN
  
  IF  NVL(l_gp_rec.status,'A') <> l_db_rec.status THEN
     l_gp_rec.status_update_date    :=  SYSDATE;
  END IF;
  
  do_update_party_rel(
			 l_init_msg_list,
       l_gp_rec,
			 l_out_ret_status,
			 l_out_msg_count,
			 l_out_msg_data,
			 l_profile_id
			);
  
      
  update_gp_rec(
        l_init_msg_list,
        l_gp_rec,
        l_out_ret_status,
        l_out_msg_count,
        l_out_msg_data
   );
  
  
   
   record_gp_hist (
    l_init_msg_list   ,
    l_gp_rec	        ,
    l_gp_hist_id		  ,
    l_out_ret_status  ,
    l_out_msg_count   ,
    l_out_msg_data                 
    );

  END IF;

EXCEPTION 
  WHEN do_update_party_excep THEN
    ROLLBACK TO update_gp ;
    x_return_status := FND_API.G_RET_STS_ERROR;
    FND_MSG_PUB.Count_And_Get(
                                  p_encoded => FND_API.G_FALSE,
                                  p_count => x_msg_count,
                                  p_data  => x_msg_data);
  WHEN update_gp_rec_excep  THEN
    ROLLBACK TO update_gp ;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'update_gp_rec : Exception is ' || sqlerrm;
  WHEN insert_gp_hist_rec_excep THEN
    ROLLBACK TO update_gp ;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'record_gp_hist : Exception is ' || sqlerrm;
  WHEN OTHERS THEN
    ROLLBACK TO update_gp ;
    x_return_status := FND_API.G_RET_STS_ERROR;
    x_msg_data      := 'update_gp : Exception is ' || sqlerrm;

END update_gp ;


PROCEDURE record_gp_hist (
    p_init_msg_list           	IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec		                IN		          gp_rec_type,
    x_gp_hist_id		            OUT NOCOPY      NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
) IS

l_api_name             CONSTANT VARCHAR2(100) := 'XX_CDH_GP_MAINT_PKG.record_gp_hist';

BEGIN

	SAVEPOINT record_gp_hist ;

	-- initialize message list if p_init_msg_list is set to TRUE.
    	IF FND_API.to_Boolean(p_init_msg_list) THEN
        	FND_MSG_PUB.initialize;
    	END IF;

	x_return_status := FND_API.G_RET_STS_SUCCESS;
  
   insert_gp_hist_rec (
    p_init_msg_list           	,
    p_gp_rec		                ,
    x_gp_hist_id		            ,
    x_return_status             ,
    x_msg_count                 ,
    x_msg_data                  
  );

 EXCEPTION WHEN OTHERS THEN
      ROLLBACK TO record_gp_hist;
      RAISE;

END record_gp_hist ;

procedure copy_rec(p_gp_rec IN T_gp_rec_type,
                  l_gp_rec  IN OUT GP_REC_TYPE) IS

BEGIN

  l_gp_rec.gp_id			       :=  p_gp_rec.gp_id  ;			                        
	l_gp_rec.gp_name		       :=  p_gp_rec.gp_name ;
	l_gp_rec.resource_id			 :=	 p_gp_rec.resource_id ;                 
  l_gp_rec.role_id					 :=  p_gp_rec.role_id ;               
  l_gp_rec.group_id					 :=  p_gp_rec.group_id ;           
  l_gp_rec.legacy_rep_id		 :=  p_gp_rec.legacy_rep_id ;
	l_gp_rec.segment           :=  p_gp_rec.segment_CODE    ;      		  
	l_gp_rec.revenue_band      :=  p_gp_rec.revenue_band ;          		  
	l_gp_rec.w_agreement_flag	 :=  p_gp_rec.w_agreement_flag	;       
	l_gp_rec.notes						 :=  p_gp_rec.notes          ;
	l_gp_rec.party_id          :=  p_gp_rec.party_id ; 
	l_gp_rec.requestor				 :=  p_gp_rec.requestor     ;  
	l_gp_rec.status						 :=  p_gp_rec.status   ;
	l_gp_rec.status_update_date:=  p_gp_rec.status_update_date ;
	l_gp_rec.ATTRIBUTE_CATEGORY:=  p_gp_rec.ATTRIBUTE_CATEGORY;
	l_gp_rec.ATTRIBUTE1        :=  p_gp_rec.ATTRIBUTE1     ;  		  
	l_gp_rec.ATTRIBUTE2        :=  p_gp_rec.ATTRIBUTE2;   		    
	l_gp_rec.ATTRIBUTE3        :=  p_gp_rec.ATTRIBUTE3 ; 		                                                                                                                                                                                   
	l_gp_rec.ATTRIBUTE4        :=  p_gp_rec.ATTRIBUTE4 ;		                                                                                                                                                                                    
	l_gp_rec.ATTRIBUTE5        :=  p_gp_rec.ATTRIBUTE5  ;   	                                                                                                                                                                               
	l_gp_rec.ATTRIBUTE6        :=  p_gp_rec.ATTRIBUTE6 ;   	                                                                                                                                                                                
	l_gp_rec.ATTRIBUTE7        :=  p_gp_rec.ATTRIBUTE7;                                                                                                                                                                               
	l_gp_rec.ATTRIBUTE8        :=	 p_gp_rec.ATTRIBUTE8 ;                                                                                                                                                                                
	l_gp_rec.ATTRIBUTE9        :=  p_gp_rec.ATTRIBUTE9   ;           	                                                                                                                                                                                 
	l_gp_rec.ATTRIBUTE10       :=  p_gp_rec.ATTRIBUTE10   ;                                                                                                                                                                                      
	l_gp_rec.ATTRIBUTE11       :=  p_gp_rec.ATTRIBUTE11  ;       	                                                                                                                                                                                 
	l_gp_rec.ATTRIBUTE12       :=  p_gp_rec.ATTRIBUTE12 ;                                                                                                                                                                                     
	l_gp_rec.ATTRIBUTE13       :=  p_gp_rec.ATTRIBUTE13 ;                                                                                                                                                                                   
	l_gp_rec.ATTRIBUTE14       :=  p_gp_rec.ATTRIBUTE14 ;   	                                                                                                                                                                                 
	l_gp_rec.ATTRIBUTE15       :=  p_gp_rec.ATTRIBUTE15 ; 	                                                                                                                                                                                 
	l_gp_rec.ATTRIBUTE16       :=  p_gp_rec.ATTRIBUTE16  ;                                                                                                                                                                                
	l_gp_rec.ATTRIBUTE17       :=	 p_gp_rec.ATTRIBUTE17    ;                                                                                                                                                                             
	l_gp_rec.ATTRIBUTE18       :=  p_gp_rec.ATTRIBUTE18    ;                                                                                                                                                                          
	l_gp_rec.ATTRIBUTE19       :=  p_gp_rec.ATTRIBUTE19     ;                                                                                                                                                                          
	l_gp_rec.ATTRIBUTE20       :=   p_gp_rec.ATTRIBUTE20   ;
	l_gp_rec.OBJECT_VERSION_NUMBER  :=p_gp_rec.OBJECT_VERSION_NUMBER ;
	l_gp_rec.REQUEST_ID         := p_gp_rec.REQUEST_ID ;
	l_gp_rec.PROGRAM_ID         :=   p_gp_rec.PROGRAM_ID      ;                                                                                                                                                                         
	l_gp_rec.PROGRAM_UPDATE_DATE:=     p_gp_rec.PROGRAM_UPDATE_DATE  ;                                                                                                                                                                          
	l_gp_rec.PROGRAM_APPLICATION_ID   := p_gp_rec.PROGRAM_APPLICATION_ID   ;           
	l_gp_rec.CREATION_DATE            :=   p_gp_rec.CREATION_DATE  ;                                                                                                                                                                              
	l_gp_rec.CREATED_BY               :=  p_gp_rec.CREATED_BY;                                                                                                                                                                          
	l_gp_rec.LAST_UPDATE_DATE         :=  p_gp_rec.LAST_UPDATE_DATE ;                                                                                                                                                                          
	l_gp_rec.LAST_UPDATED_BY          := p_gp_rec.LAST_UPDATED_BY;         	                                                                              
	l_gp_rec.CREATED_BY_MODULE        := p_gp_rec.CREATED_BY_MODULE;      	
	l_gp_rec.APPLICATION_ID           := p_gp_rec.APPLICATION_ID;
END;
PROCEDURE create_gp (
    p_init_msg_list		          IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		          T_gp_rec_type,
    x_gp_id                	    OUT NOCOPY     	NUMBER,
    x_party_id                	OUT NOCOPY     	NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
) IS
l_gp_rec  gp_rec_type;
BEGIN

copy_rec(p_gp_rec,l_gp_rec);
create_gp (
    p_init_msg_list	    =>p_init_msg_list ,
    p_gp_rec			      =>l_gp_rec ,
    x_gp_id             => x_gp_id,
    x_party_id          => x_party_id,
    x_return_status     => x_return_status,
    x_msg_count         => x_msg_count,
    x_msg_data          => x_msg_data
);

EXCEPTION WHEN OTHERS THEN
x_return_status := 'E';
x_msg_data := 'Error in copy_rec';
END;

PROCEDURE update_gp (
    p_init_msg_list         	  IN		          VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		          T_gp_rec_type,	
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
) IS

l_gp_rec  gp_rec_type;
BEGIN

copy_rec(p_gp_rec,l_gp_rec);
update_gp (
    p_init_msg_list         	  => p_init_msg_list,
    p_gp_rec			              => l_gp_rec,	
    x_return_status             => x_return_status,
    x_msg_count                 => x_msg_count,
    x_msg_data                  => x_msg_data
);

EXCEPTION WHEN OTHERS THEN
x_return_status := 'E';
x_msg_data := 'Error in copy_rec';
END update_gp;

end XX_CDH_GP_MAINT_PKG;
/

SHOW ERRORS;