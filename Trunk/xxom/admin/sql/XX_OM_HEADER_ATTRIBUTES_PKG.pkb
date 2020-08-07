SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE BODY xx_om_header_attributes_pkg 
AS
 
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                        Wipro Technologies                                 |
-- +===========================================================================+
-- | Name         :XX_OM_HEADER_ATTRIBUTES_PKG                                 |
-- | Rice ID      :E1334_OM_Attributes_Setup                                   |
-- | Description  :This package specification is used to Insert, Update        |
-- |               Delete, Lock rows of XX_OM_HEADER_ATTRIBUTES_ALL            |
-- |               Table                                                       |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author           Remarks                             |
-- |=======   ==========  =============    ============================        |
-- |DRAFT 1A  12-JUL-2007 Prajeesh         Initial draft version               |
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+

-- +===================================================================+
-- | Name  : xx_log_exception_proc                                     |
-- | Description:  This procedure is used to invoke Global Exceptions  |
-- |               API xx_om_global_exception_pkg.insert_exception     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
  PROCEDURE xx_log_exception_proc(p_error_code        IN            VARCHAR2
                                 ,p_error_description IN            VARCHAR2
                                 ,p_entity_ref        IN            VARCHAR2
                                 ,p_entity_ref_id     IN            NUMBER
				 ,x_return_status     IN OUT NOCOPY VARCHAR2
				 ,x_errbuf            IN OUT NOCOPY VARCHAR2

                                  )
  IS
  lc_errbuf              VARCHAR2(1000) :='Success';
  lc_return_status       VARCHAR2(40)   :=FND_API.G_RET_STS_SUCCESS;

  BEGIN

             exception_object_type.p_exception_header  :=    G_exception_header;
             exception_object_type.p_track_code        :=    G_track_code;
             exception_object_type.p_solution_domain   :=    G_solution_domain;
             exception_object_type.p_function          :=    G_function;

             exception_object_type.p_error_code        :=    p_error_code;
  	     exception_object_type.p_error_description :=    p_error_description;
  	     exception_object_type.p_entity_ref        :=    p_entity_ref;
   	     exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;


             XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(exception_object_type,
	                                                 lc_errbuf,
							 lc_return_status);
	    x_return_status := lc_return_status;
	    x_errbuf        := lc_errbuf;

  EXCEPTION
  WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
      x_return_status  := FND_API.G_RET_STS_ERROR;
      x_errbuf         := SUBSTR(FND_MESSAGE.GET,1,1000);
  END xx_log_exception_proc;

-- +===================================================================+
-- | Name  : insert_row                                                |
-- | Description:  This procedure is used to invoke Insert row api     |
-- |               to insert into custom table                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE insert_row(p_header_rec    IN OUT NOCOPY XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2)
IS
BEGIN
   INSERT INTO xx_om_header_attributes_all
   (header_id 
   ,comments  
   ,release_number
   ,cost_center_dept
   ,desk_del_addr   
   ,cust_carr_acct_no
   ,catalog_src_cd   
   ,brand            
   ,bmode            
   ,locale           
   ,advantage_card_number
   ,gift_flag            
   ,fax_comments         
   ,track_num            
   ,ship_to_flg          
   ,alt_delv_address     
   ,further_ord_info     
   ,org_cust_name        
   ,created_by_store_id  
   ,paid_at_store_id     
   ,spc_card_number      
   ,aops_salesrep_id     
   ,aops_delivery_code   
   ,created_by_id        
   ,aops_delivery_method 
   ,placement_method_code
   ,legacy_cust_name     
   ,num_cartons          
   ,cust_comm_pref       
   ,cust_pref_email      
   ,cust_pref_fax        
   ,cust_pref_phone      
   ,cust_pref_phextn     
   ,web_user_id          
   ,creation_date        
   ,created_by           
   ,last_update_date     
   ,last_updated_by      
   ,last_update_login    
  )
 VALUES
  (p_header_rec.header_id              
  ,p_header_rec.comments              
  ,p_header_rec.release_number        
  ,p_header_rec.cost_center_dept      
  ,p_header_rec.desk_del_addr         
  ,p_header_rec.cust_carr_acct_no     
  ,p_header_rec.catalog_src_cd        
  ,p_header_rec.brand                 
  ,p_header_rec.bmode                 
  ,p_header_rec.locale                
  ,p_header_rec.advantage_card_number 
  ,p_header_rec.gift_flag             
  ,p_header_rec.fax_comments          
  ,p_header_rec.track_num             
  ,p_header_rec.ship_to_flg           
  ,p_header_rec.alt_delv_address      
  ,p_header_rec.further_ord_info      
  ,p_header_rec.org_cust_name         
  ,p_header_rec.created_by_store_id   
  ,p_header_rec.paid_at_store_id      
  ,p_header_rec.spc_card_number       
  ,p_header_rec.aops_salesrep_id      
  ,p_header_rec.aops_delivery_code    
  ,p_header_rec.created_by_id         
  ,p_header_rec.aops_delivery_method  
  ,p_header_rec.placement_method_code 
  ,p_header_rec.legacy_cust_name      
  ,p_header_rec.num_cartons           
  ,p_header_rec.cust_comm_pref        
  ,p_header_rec.cust_pref_email       
  ,p_header_rec.cust_pref_fax         
  ,p_header_rec.cust_pref_phone       
  ,p_header_rec.cust_pref_phextn      
  ,p_header_rec.web_user_id           
  ,NVL(p_header_rec.creation_date,SYSDATE)         
  ,NVL(p_header_rec.created_by,-1)
  ,NVL(p_header_rec.last_update_date,SYSDATE)      
  ,NVL(p_header_rec.last_updated_by,-1)
  ,p_header_rec.last_update_login     
  );
  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf        := 'Success';
 EXCEPTION
 WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
     
      -- Call the xx_log_exception_proc procedure to insert into Global exception table
      xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                             ,p_error_description => FND_MESSAGE.GET
			     ,p_entity_ref        => 'Header_id'
                             ,p_entity_ref_id     => p_header_rec.header_id
                             ,x_return_status     => x_return_status
                             ,x_errbuf            => x_errbuf);

                                
      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

  
END insert_row;

-- +===================================================================+
-- | Name  : update_row                                                |
-- | Description:  This procedure is used to invoke update row api     |
-- |               to update into custom table                         |
-- |                                                                   |
-- +===================================================================+

PROCEDURE update_row(p_header_rec    IN OUT NOCOPY XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2)
IS
BEGIN
 UPDATE xx_om_header_attributes_all SET
  comments            	 =	p_header_rec.comments                                  
  ,release_number      	 =	p_header_rec.release_number                            
  ,cost_center_dept    	 =	p_header_rec.cost_center_dept                          
  ,desk_del_addr       	 =	p_header_rec.desk_del_addr                             
  ,cust_carr_acct_no   	 =	p_header_rec.cust_carr_acct_no                         
  ,catalog_src_cd      	 =	p_header_rec.catalog_src_cd                            
  ,brand               	 =	p_header_rec.brand                                     
  ,bmode               	 =	p_header_rec.bmode                                     
  ,locale              	 =	p_header_rec.locale                                    
  ,advantage_card_number =	p_header_rec.advantage_card_number                     
  ,gift_flag           	 =	p_header_rec.gift_flag                                 
  ,fax_comments        	 =	p_header_rec.fax_comments                              
  ,track_num           	 =	p_header_rec.track_num                                 
  ,ship_to_flg         	 =	p_header_rec.ship_to_flg                               
  ,alt_delv_address    	 =	p_header_rec.alt_delv_address                          
  ,further_ord_info    	 =	p_header_rec.further_ord_info                          
  ,org_cust_name       	 =	p_header_rec.org_cust_name                             
  ,created_by_store_id 	 =	p_header_rec.created_by_store_id                       
  ,paid_at_store_id    	 =	p_header_rec.paid_at_store_id                          
  ,spc_card_number     	 =	p_header_rec.spc_card_number                           
  ,aops_salesrep_id    	 =	p_header_rec.aops_salesrep_id                          
  ,aops_delivery_code  	 =	p_header_rec.aops_delivery_code                        
  ,created_by_id       	 =	p_header_rec.created_by_id                             
  ,aops_delivery_method	 =	p_header_rec.aops_delivery_method                      
  ,placement_method_code =	p_header_rec.placement_method_code                     
  ,legacy_cust_name    	 =	p_header_rec.legacy_cust_name                          
  ,num_cartons         	 =	p_header_rec.num_cartons                               
  ,cust_comm_pref      	 =	p_header_rec.cust_comm_pref                            
  ,cust_pref_email     	 =	p_header_rec.cust_pref_email                           
  ,cust_pref_fax       	 =	p_header_rec.cust_pref_fax                             
  ,cust_pref_phone     	 =	p_header_rec.cust_pref_phone                           
  ,cust_pref_phextn    	 =	p_header_rec.cust_pref_phextn                          
  ,web_user_id         	 =	p_header_rec.web_user_id                               
  ,creation_date       	 =	NVL(p_header_rec.creation_date,SYSDATE)                
  ,created_by          	 =	NVL(p_header_rec.created_by,-1)      
  ,last_update_date    	 =	NVL(p_header_rec.last_update_date,SYSDATE)             
  ,last_updated_by     	 =	NVL(p_header_rec.last_updated_by,-1)                           
  ,last_update_login   	 =	p_header_rec.last_update_login                         
  WHERE header_id        =      p_header_rec.header_id;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf        := 'Success';

 EXCEPTION

 WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN

      fnd_message.set_name('ONT','OE_LOCK_ROW_ALREADY_LOCKED');
      
      xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                           ,p_error_description => FND_MESSAGE.GET
			   ,p_entity_ref        => 'Header_id'
                           ,p_entity_ref_id     => p_header_rec.header_id
                           ,x_return_status     => x_return_status
                           ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;
    
      
 WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the xx_log_exception_proc procedure to insert into Global exception table
        xx_log_exception_proc (  p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                                ,p_error_description => FND_MESSAGE.GET
				,p_entity_ref        => 'Header_id'
                                ,p_entity_ref_id     => p_header_rec.header_id
                                ,x_return_status     => x_return_status
                                ,x_errbuf            => x_errbuf);


      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

END update_row;

-- +===================================================================+
-- | Name  : lock_row                                                  |
-- | Description:  This procedure is used to invoke lock row api       |
-- |               to lock  custom table                               |
-- |                                                                   |
-- +===================================================================+

PROCEDURE lock_row(p_header_rec     IN OUT NOCOPY    XXOM.XX_OM_HEADER_ATTRIBUTES_T,
                   x_return_status     OUT NOCOPY    VARCHAR2,
		   x_errbuf            OUT NOCOPY    VARCHAR2)
IS
ln_header_id xx_om_header_attributes_all.header_id%TYPE;
BEGIN
  SAVEPOINT lock_row;

  SELECT header_id
  INTO ln_header_id
  FROM xx_om_header_attributes_all
  WHERE header_id = p_header_rec.header_id
  FOR UPDATE NOWAIT;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf        := 'Success';
 EXCEPTION

 WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN
      ROLLBACK to SAVEPOINT lock_row;
      FND_MESSAGE.SET_NAME('ONT','OE_LOCK_ROW_ALREADY_LOCKED');

       xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                    	    ,p_error_description => FND_MESSAGE.GET
			    ,p_entity_ref        => 'Header_id'
                            ,p_entity_ref_id     => p_header_rec.header_id
                            ,x_return_status     => x_return_status
                            ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

      
 WHEN OTHERS THEN
      ROLLBACK to SAVEPOINT lock_row;
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
 
      -- Call the xx_log_exception_proc procedure to insert into Global exception table
         xx_log_exception_proc ( p_error_code        => 'XX_OM_65100_UNEXPECTED_ERROR'
                     		,p_error_description => FND_MESSAGE.GET
				,p_entity_ref        => 'Header_id'
                                ,p_entity_ref_id     => p_header_rec.header_id
                                ,x_return_status     => x_return_status
                                ,x_errbuf            => x_errbuf);


      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;
END lock_row;

-- +===================================================================+
-- | Name  : delete_row                                                |
-- | Description:  This procedure is used to invoke delete row api     |
-- |               to delete  custom table                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE delete_row(p_header_id     IN            xx_om_header_attributes_all.header_id%TYPE,
                     x_return_status OUT NOCOPY    VARCHAR2,
		     x_errbuf        OUT NOCOPY    VARCHAR2)
IS
BEGIN

  DELETE FROM 
  xx_om_header_attributes_all 
  WHERE header_id=p_header_id;

  x_return_status := FND_API.G_RET_STS_SUCCESS ;
  x_errbuf       := 'Success';

 EXCEPTION

  WHEN APP_EXCEPTIONS.RECORD_LOCK_EXCEPTION THEN

      fnd_message.set_name('ONT','OE_LOCK_ROW_ALREADY_LOCKED');
     

      xx_log_exception_proc(p_error_code        => 'OE_LOCK_ROW_ALREADY_LOCKED'
                       	   ,p_error_description => FND_MESSAGE.GET
		           ,p_entity_ref        => 'Header_id'
                           ,p_entity_ref_id     => p_header_id
                           ,x_return_status     => x_return_status
                           ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;

      
   WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      -- Call the xx_log_exception_proc procedure to insert into Global exception table
         xx_log_exception_proc ( p_error_code         => 'XX_OM_65100_UNEXPECTED_ERROR'
                    		 ,p_error_description => FND_MESSAGE.GET
				 ,p_entity_ref        => 'Header_id'
                                 ,p_entity_ref_id     => p_header_id
                                 ,x_return_status     => x_return_status
                                 ,x_errbuf            => x_errbuf);

      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
             
           x_return_status := FND_API.G_RET_STS_ERROR;
           x_errbuf        :=SUBSTR(FND_MESSAGE.GET,1,1000);

      END IF;
 
END delete_row;

END xx_om_header_attributes_pkg;
/

SHOW ERRORS
