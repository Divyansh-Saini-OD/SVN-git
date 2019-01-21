create or replace
package XX_CDH_GP_MAINT_PKG AS

--Create GrandParent


TYPE gp_rec_type IS RECORD (

	 gp_id						                        NUMBER
	,gp_name					                        varchar2(360)
	,resource_id					                    varchar2(100)
  ,role_id					                        varchar2(100)
  ,group_id					                        varchar2(100)
  ,legacy_rep_id					                  varchar2(100)
	,segment                            		  VARCHAR2(30)
	,revenue_band                       		  VARCHAR2(30)
	,w_agreement_flag				                  VARCHAR2(1)
	,notes						                        VARCHAR2(4000)
	,party_id                           		  NUMBER(15)
	,requestor					                      NUMBER
	,status						                        VARCHAR2(1)
	,status_update_date				                DATE
	,ATTRIBUTE_CATEGORY             		      VARCHAR2(30) 
	,ATTRIBUTE1                        		    VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE2                  	   		      VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE3                         		  VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE4                        		    VARCHAR2(150)                                                                                                                                                                                
	,ATTRIBUTE5                             	VARCHAR2(150)                                                                                                                                                                                
	,ATTRIBUTE6                             	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE7                             	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE8                             	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE9                             	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE10                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE11                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE12                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE13                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE14                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE15                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE16                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE17                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE18                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE19                            	VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE20                            	VARCHAR2(150)         
	,OBJECT_VERSION_NUMBER                  	NUMBER
	,REQUEST_ID                             	NUMBER(15) 
	,PROGRAM_ID                             	NUMBER(15)                                                                                                                                                                                    
	,PROGRAM_UPDATE_DATE                    	DATE                                                                                                                                                                                      
	,PROGRAM_APPLICATION_ID                 	NUMBER(15)                    
	,CREATION_DATE                          	DATE                                                                                                                                                                                          
	,CREATED_BY                             	NUMBER                                                                                                                                                                                        
	,LAST_UPDATE_DATE                       	DATE                                                                                                                                                                                          
	,LAST_UPDATED_BY                        	NUMBER                                                                              
	,CREATED_BY_MODULE                      	VARCHAR2(100)
	,APPLICATION_ID                         	NUMBER 
);

TYPE gp_hist_rec_type IS RECORD (

	gp_hist_id					                    NUMBER
	,gp_id						                      NUMBER	  
	,gp_name					                      varchar2(360)
	,resource_id					                  varchar2(100)
  ,role_id					                      varchar2(100)
  ,group_id					                      varchar2(100)
  ,legacy_rep_id					                varchar2(100)
	,segment                           	 	  VARCHAR2(30)
	,revenue_band                     		  VARCHAR2(30)
	,w_agreement_flag				                VARCHAR2(1)
	,notes						                      VARCHAR2(4000)
	,party_id                       		    NUMBER(15)
	,requestor					                    NUMBER
	,status						                      VARCHAR2(1)
	,status_update_date				              DATE
	,ATTRIBUTE_CATEGORY               		  VARCHAR2(30) 
	,ATTRIBUTE1                       		  VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE2                        		  VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE3                         		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE4                         		VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE5                         		VARCHAR2(150)                                                                                                                                                                                 
	,ATTRIBUTE6                         		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE7                         		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE8                         		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE9                         		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE10                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE11                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE12                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE13                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE14                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE15                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE16                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE17                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE18                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE19                        		VARCHAR2(150)                                                                                                                                                                                  
	,ATTRIBUTE20                        		VARCHAR2(150)         
	,OBJECT_VERSION_NUMBER              		NUMBER
	,REQUEST_ID                         		NUMBER(15) 
	,PROGRAM_ID                         		NUMBER(15)                                                                                                                                                                                     
	,PROGRAM_UPDATE_DATE                		DATE                                                                                                                                                                                       
	,PROGRAM_APPLICATION_ID             		NUMBER(15)                                                                            
	,CREATION_DATE                      		DATE                                                                                                                                                                                           
	,CREATED_BY                         		NUMBER                                                                                                                                                                                         
	,LAST_UPDATE_DATE                   		DATE                                                                                                                                                                                           
	,LAST_UPDATED_BY                    		NUMBER                                                                               
	,CREATED_BY_MODULE                  		VARCHAR2(100)
	,APPLICATION_ID                     		NUMBER 

);


PROCEDURE create_gp (
    p_init_msg_list			IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec				IN 		          gp_rec_type,
    x_gp_id                	    OUT NOCOPY     	NUMBER,
    x_party_id                	OUT NOCOPY     	NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
);

PROCEDURE update_gp (
    p_init_msg_list         	  IN		          VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		          gp_rec_type,	
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
);

PROCEDURE create_gp (
    p_init_msg_list		          IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		      T_gp_rec_type,
    x_gp_id                	    OUT NOCOPY     	NUMBER,
    x_party_id                	OUT NOCOPY     	NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
);

PROCEDURE update_gp (
    p_init_msg_list         	  IN		          VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec			              IN 		        T_gp_rec_type,	
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
);
PROCEDURE record_gp_hist (
    p_init_msg_list           	IN      	      VARCHAR2:= FND_API.G_FALSE,
    p_gp_rec		                IN		          gp_rec_type,
    x_gp_hist_id		            OUT NOCOPY      NUMBER,
    x_return_status             OUT NOCOPY     	VARCHAR2,
    x_msg_count                 OUT NOCOPY     	NUMBER,
    x_msg_data                  OUT NOCOPY     	VARCHAR2
);


end XX_CDH_GP_MAINT_PKG;
/