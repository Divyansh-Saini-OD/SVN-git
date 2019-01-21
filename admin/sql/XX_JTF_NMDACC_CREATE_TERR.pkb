CREATE OR REPLACE PACKAGE BODY XX_JTF_NMDACC_CREATE_TERR
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_JTF_NMDACC_CREATE_TERR                                     |
-- |                                                                                |
-- | Description:  This is a public package to facilitate inserts into the custom   |
-- |               tables XX_TM_NAM_TERR_DEFN, XX_TM_NAM_TERR_RSC_DTLS and          |
-- |               XX_TM_NAM_TERR_ENTITY_DTLS.                                      |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date         Author                   Remarks                         |
-- |=======   ==========   =============            ================================|
-- |1.0       24-OCT-2007  Nabarun Ghosh            Updated with Modified logic.    |
-- +================================================================================+

-- +================================================================================+
-- | Name        :  Create_Territory                                                |
-- | Description :  This procedure is used to create named account territories if   |
-- |                the parameters passed all the validations.                      |
-- +================================================================================+

PROCEDURE Create_Territory (
      x_errbuf       OUT   VARCHAR2
     ,x_retcode      OUT   NUMBER
     ,p_start_date_active     IN         VARCHAR2
     ,p_resource_id           IN         xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
     ,p_role_id               IN         xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
     ,p_group_id              IN         xx_tm_nam_terr_rsc_dtls.group_id%TYPE
     ,p_entity_type           IN         xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,p_entity_id             IN         xx_tm_nam_terr_entity_dtls.entity_id%TYPE
     ,p_source_system         IN         VARCHAR2
)
IS

l_start_date_active     DATE ;
l_resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  	;
l_role_id               xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE;
l_group_id              xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	;
l_entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
l_entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;
l_source_system        VARCHAR2(20)  ;
l_error_code           VARCHAR2(2000);
l_error_message        VARCHAR2(4000);
l_conc_req_status      BOOLEAN;

BEGIN


    l_start_date_active := TO_DATE(p_start_date_active,'DD-MON-YYYY HH24:MI:SS') ;
    l_resource_id      	:= p_resource_id      ;
    l_role_id          	:= p_role_id          ;
    l_group_id         	:= p_group_id         ;
    l_entity_type      	:= p_entity_type      ;
    l_entity_id        	:= p_entity_id        ;
    l_source_system     := p_source_system    ;

fnd_file.put_line(FND_FILE.log,'l_start_date_active =>'||l_start_date_active);
fnd_file.put_line(FND_FILE.log,'l_resource_id       =>'||l_resource_id);
fnd_file.put_line(FND_FILE.log,'l_role_id           =>'||l_role_id);
fnd_file.put_line(FND_FILE.log,'l_group_id          =>'||l_group_id);
fnd_file.put_line(FND_FILE.log,'l_entity_type       =>'||l_entity_type);
fnd_file.put_line(FND_FILE.log,'l_entity_id         =>'||l_entity_id);
fnd_file.put_line(FND_FILE.log,'l_source_system     =>'||l_source_system);

    XX_JTF_RS_NAMED_ACC_TERR_PUB.Create_Territory
              (
         	p_api_version_number    => 1.0
               ,p_named_acct_terr_id    => NULL
               ,p_named_acct_terr_name  => NULL
               ,p_named_acct_terr_desc  => NULL
               ,p_status                => 'A'
               ,p_start_date_active     => l_start_date_active
               ,p_end_date_active       => NULL
               ,p_full_access_flag      => NULL
               ,p_source_terr_id        => NULL
               ,p_resource_id           => l_resource_id
               ,p_role_id               => l_role_id
               ,p_group_id              => l_group_id
               ,p_entity_type           => l_entity_type
               ,p_entity_id             => l_entity_id
               ,p_source_entity_id      => NULL
               ,p_source_system         => l_source_system
               ,x_error_code            => l_error_code
               ,x_error_message         => l_error_message
  );

  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_code     =>'||l_error_code);
  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_message  =>'||l_error_message);
 
   
IF l_error_code ='E' THEN
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR',l_error_message);   
END IF;   


END Create_Territory;

PROCEDURE Move_Party_Sites (
      x_errbuf                  OUT VARCHAR2
     ,x_retcode                 OUT NUMBER
     ,p_from_named_acct_terr_id  IN xx_tm_nam_terr_defn.named_acct_terr_id%TYPE 
     ,p_to_named_acct_terr_id    IN xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
     ,p_from_start_date_active   IN VARCHAR2                                        --Default SYSDATE
     ,p_from_resource_id         IN xx_tm_nam_terr_rsc_dtls.resource_id%TYPE 
     ,p_to_resource_id  	 IN xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  
     ,p_from_role_id    	 IN xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
     ,p_to_role_id      	 IN xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE
     ,p_from_group_id            IN xx_tm_nam_terr_rsc_dtls.group_id%TYPE
     ,p_to_group_id     	 IN xx_tm_nam_terr_rsc_dtls.group_id%TYPE
     ,p_entity_type              IN xx_tm_nam_terr_entity_dtls.entity_type%TYPE  --Default PARTY_SITE'
     ,p_entity_id                IN xx_tm_nam_terr_entity_dtls.entity_id%TYPE
)
IS
  
  l_from_named_acct_terr_id    xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  l_to_named_acct_terr_id      xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  l_from_start_date_active     DATE;
  l_to_start_date_active       DATE;
  l_from_resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE     ;       
  l_to_resource_id  	       xx_tm_nam_terr_rsc_dtls.resource_id%TYPE     ;
  l_from_role_id    	       xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE;
  l_to_role_id      	       xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE;
  l_from_group_id              xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	    ; 
  l_to_group_id     	       xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	    ;
  l_entity_type                xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
  l_entity_id                  xx_tm_nam_terr_entity_dtls.entity_id%TYPE    ;  
  l_error_code                 VARCHAR2(2000);
  l_error_message              VARCHAR2(4000);
  l_conc_req_status            BOOLEAN;

BEGIN
          
          l_from_named_acct_terr_id := p_from_named_acct_terr_id;
          l_to_named_acct_terr_id   := p_to_named_acct_terr_id  ; 
          l_from_start_date_active  := TO_DATE(p_from_start_date_active,'DD-MON-YYYY HH24:MI:SS') ;
          l_from_resource_id        := p_from_resource_id       ;
          l_to_resource_id  	    := p_to_resource_id  	;
          l_from_role_id    	    := p_from_role_id    	;
          l_to_role_id      	    := p_to_role_id      	;
          l_from_group_id           := p_from_group_id          ;
          l_to_group_id     	    := p_to_group_id     	;
          l_entity_type             := p_entity_type            ;
          l_entity_id               := p_entity_id              ;
          

fnd_file.put_line(FND_FILE.log,'l_from_named_acct_terr_id       =>'||  l_from_named_acct_terr_id);
fnd_file.put_line(FND_FILE.log,'l_to_named_acct_terr_id  	=>'||  l_to_named_acct_terr_id  );
fnd_file.put_line(FND_FILE.log,'l_from_start_date_active 	=>'||  p_from_start_date_active );
fnd_file.put_line(FND_FILE.log,'l_from_resource_id       	=>'||  l_from_resource_id       );
fnd_file.put_line(FND_FILE.log,'l_to_resource_id  	   	=>'||  l_to_resource_id  	);   
fnd_file.put_line(FND_FILE.log,'l_from_role_id    	   	=>'||  l_from_role_id    	);   
fnd_file.put_line(FND_FILE.log,'l_to_role_id      	   	=>'||  l_to_role_id      	);   
fnd_file.put_line(FND_FILE.log,'l_from_group_id          	=>'||  l_from_group_id          );
fnd_file.put_line(FND_FILE.log,'l_to_group_id     	   	=>'||  l_to_group_id     	);   
fnd_file.put_line(FND_FILE.log,'l_entity_type            	=>'||  l_entity_type            );
fnd_file.put_line(FND_FILE.log,'l_entity_id              	=>'||  l_entity_id              );

     XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Party_Sites
         (
           p_api_version_number       => 1.0
          ,p_from_named_acct_terr_id  => l_from_named_acct_terr_id
          ,p_to_named_acct_terr_id    => l_to_named_acct_terr_id
          ,p_from_start_date_active   => l_from_start_date_active
          ,p_to_start_date_active     => l_to_start_date_active
          ,p_from_resource_id         => l_from_resource_id
          ,p_to_resource_id           => l_to_resource_id
          ,p_from_role_id             => l_from_role_id
          ,p_to_role_id               => l_to_role_id
          ,p_from_group_id            => l_from_group_id
          ,p_to_group_id              => l_to_group_id
          ,p_entity_type              => l_entity_type
          ,p_entity_id                => l_entity_id
          ,x_error_code               => l_error_code
          ,x_error_message            => l_error_message
      );			       
  
  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_code     =>'||l_error_code);
  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_message  =>'||l_error_message);
 
   
IF l_error_code ='E' THEN
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR',l_error_message);   
END IF;   


END Move_Party_Sites;

PROCEDURE Move_Resource_Territories
          (
            x_errbuf                  OUT VARCHAR2
           ,x_retcode                 OUT NUMBER
           ,p_from_named_acct_terr_id  IN  xx_tm_nam_terr_defn.named_acct_terr_id%TYPE
           ,p_from_start_date_active   IN  VARCHAR2
	   ,p_from_resource_id         IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  	  
	   ,p_to_resource_id           IN  xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  	  
	   ,p_from_role_id             IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  
	   ,p_to_role_id               IN  xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE  
	   ,p_from_group_id            IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	  
	   ,p_to_group_id              IN  xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	  
	 )

IS
  
  l_from_named_acct_terr_id    xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  l_to_named_acct_terr_id      xx_tm_nam_terr_defn.named_acct_terr_id%TYPE;
  l_from_start_date_active     DATE;
  l_to_start_date_active       DATE;
  l_from_resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE     ;       
  l_to_resource_id  	       xx_tm_nam_terr_rsc_dtls.resource_id%TYPE     ;
  l_from_role_id    	       xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE;
  l_to_role_id      	       xx_tm_nam_terr_rsc_dtls.resource_role_id%TYPE;
  l_from_group_id              xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	    ; 
  l_to_group_id     	       xx_tm_nam_terr_rsc_dtls.group_id%TYPE  	    ;
  l_entity_type                xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
  l_entity_id                  xx_tm_nam_terr_entity_dtls.entity_id%TYPE    ;  
  l_error_code                 VARCHAR2(2000);
  l_error_message              VARCHAR2(4000);
  l_conc_req_status            BOOLEAN;

BEGIN
          
          l_from_named_acct_terr_id := p_from_named_acct_terr_id; 
          l_from_start_date_active  := TO_DATE(p_from_start_date_active,'DD-MON-YYYY HH24:MI:SS') ;
          l_from_resource_id        := p_from_resource_id       ;
          l_to_resource_id  	    := p_to_resource_id  	;
          l_from_role_id    	    := p_from_role_id    	;
          l_to_role_id      	    := p_to_role_id      	;
          l_from_group_id           := p_from_group_id          ;
          l_to_group_id     	    := p_to_group_id     	;
  
fnd_file.put_line(FND_FILE.log,'l_from_named_acct_terr_id       =>'||  l_from_named_acct_terr_id );
fnd_file.put_line(FND_FILE.log,'l_from_start_date_active 	=>'||  p_from_start_date_active );
fnd_file.put_line(FND_FILE.log,'l_from_resource_id       	=>'||  l_from_resource_id       );
fnd_file.put_line(FND_FILE.log,'l_to_resource_id  	   	=>'||  l_to_resource_id  	  );
fnd_file.put_line(FND_FILE.log,'l_from_role_id    	     	=>'||  l_from_role_id    	  );   
fnd_file.put_line(FND_FILE.log,'l_to_role_id      	     	=>'||  l_to_role_id      	  );   
fnd_file.put_line(FND_FILE.log,'l_from_group_id            	=>'||  l_from_group_id           );   
fnd_file.put_line(FND_FILE.log,'l_to_group_id     	   	=>'||  l_to_group_id     	  );



     XX_JTF_RS_NAMED_ACC_TERR_PUB.Move_Resource_Territories
         (
         p_api_version_number         => 1.0                           
        ,p_from_named_acct_terr_id    => l_from_named_acct_terr_id
        ,p_from_start_date_active     => l_from_start_date_active
        ,p_from_resource_id           => l_from_resource_id
        ,p_to_resource_id             => l_to_resource_id  
        ,p_from_role_id               => l_from_role_id    
        ,p_to_role_id                 => l_to_role_id      
        ,p_from_group_id              => l_from_group_id   
        ,p_to_group_id                => l_to_group_id     
        ,x_error_code                 => l_error_code    
        ,x_error_message              => l_error_message 
      );			       


  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_code     =>'||l_error_code);
  FND_FILE.PUT_LINE(FND_FILE.log,'l_error_message  =>'||l_error_message);
 
   
IF l_error_code ='E' THEN
   l_conc_req_status := APPS.FND_CONCURRENT.set_completion_status ('ERROR',l_error_message);   
END IF;   


END Move_Resource_Territories;

-- +================================================================================+
-- | Name        :  Delete_Territory_Entity                                         |
-- | Description :  This procedure is used to delete Entity Records from            |
-- |                XX_TM_NAM_TERR_DEFN                      .                      |
-- +================================================================================+

PROCEDURE Delete_Territory_Entity (
      x_errbuf       OUT   VARCHAR2
     ,x_retcode      OUT   NUMBER
     ,p_territory_id          IN         xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE
     ,p_entity_type           IN         xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,p_entity_id             IN         xx_tm_nam_terr_entity_dtls.entity_id%TYPE
)
IS

l_territory_id          xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE;
l_entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
l_entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;
l_error_code           VARCHAR2(2000);
l_error_message        VARCHAR2(4000);
l_conc_req_status      BOOLEAN;

BEGIN


    l_territory_id      := p_territory_id     ;
    l_entity_type      	:= p_entity_type      ;
    l_entity_id        	:= p_entity_id        ;

    fnd_file.put_line(FND_FILE.log,'l_territory_id      =>'||l_territory_id);
    fnd_file.put_line(FND_FILE.log,'l_entity_type       =>'||l_entity_type);
    fnd_file.put_line(FND_FILE.log,'l_entity_id         =>'||l_entity_id);

    DELETE 
    FROM   xx_tm_nam_terr_entity_dtls
    WHERE  named_acct_terr_id =  l_territory_id
    AND    entity_type        = NVL(l_entity_type,entity_type)
    AND    entity_id          = l_entity_id;
    
    COMMIT;
   

END Delete_Territory_Entity;

-- +================================================================================+
-- | Name        :  Delete_Terr_Resource_Entity                                     |
-- | Description :  This procedure is used to delete Entity Records from all the    |
-- |                Three Custom Named Account Territory tables.                    |
-- +================================================================================+

PROCEDURE Delete_Terr_Resource_Entity (
      x_errbuf       OUT   VARCHAR2
     ,x_retcode      OUT   NUMBER
     ,p_territory_id          IN         xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE
     ,p_resource_id           IN         xx_tm_nam_terr_rsc_dtls.resource_id%TYPE
     ,p_entity_type           IN         xx_tm_nam_terr_entity_dtls.entity_type%TYPE
     ,p_entity_id             IN         xx_tm_nam_terr_entity_dtls.entity_id%TYPE
)
IS

l_territory_id          xx_tm_nam_terr_entity_dtls.named_acct_terr_id%TYPE;
l_resource_id           xx_tm_nam_terr_rsc_dtls.resource_id%TYPE  	;
l_entity_type           xx_tm_nam_terr_entity_dtls.entity_type%TYPE  ;
l_entity_id             xx_tm_nam_terr_entity_dtls.entity_id%TYPE   ;
l_error_code           VARCHAR2(2000);
l_error_message        VARCHAR2(4000);
l_conc_req_status      BOOLEAN;

BEGIN


    l_territory_id      := p_territory_id     ;
    l_resource_id      	:= p_resource_id      ;
    l_entity_type      	:= p_entity_type      ;
    l_entity_id        	:= p_entity_id        ;

    fnd_file.put_line(FND_FILE.log,'l_territory_id      =>'||l_territory_id);
    fnd_file.put_line(FND_FILE.log,'l_resource_id      =>'||l_resource_id);
    fnd_file.put_line(FND_FILE.log,'l_entity_type       =>'||l_entity_type);
    fnd_file.put_line(FND_FILE.log,'l_entity_id         =>'||l_entity_id);

    
    DELETE 
    FROM    xx_tm_nam_terr_defn
    WHERE   named_acct_terr_id  = l_territory_id;
    
    DELETE 
    FROM   xx_tm_nam_terr_rsc_dtls
    WHERE  named_acct_terr_id  = l_territory_id
    AND    resource_id         = l_resource_id; 
    
        
    DELETE 
    FROM   xx_tm_nam_terr_entity_dtls
    WHERE  named_acct_terr_id =  l_territory_id
    --AND    entity_type        = NVL(l_entity_type,entity_type)
    AND    entity_id          = l_entity_id;
    
    COMMIT;
   

END Delete_Terr_Resource_Entity;


END XX_JTF_NMDACC_CREATE_TERR;
/
