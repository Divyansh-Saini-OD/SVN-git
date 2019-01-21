SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_NMDACC_CREATE_TERR AUTHID CURRENT_USER
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
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |1.0       24-OCT-2007 Nabarun Ghosh              Updated with Modified logic.   |
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
);

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
);

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
	 );


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
);

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
);

END XX_JTF_NMDACC_CREATE_TERR;
/