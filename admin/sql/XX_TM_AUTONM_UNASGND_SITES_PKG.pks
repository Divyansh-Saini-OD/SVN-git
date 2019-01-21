SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_TM_AUTONM_UNASGND_SITES_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_TM_AUTONM_UNASGND_SITES_PKG                                       |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |                                                                                |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT1A   10-JUL-2009 Nabarun Ghosh             Initial draft Version.          |
-- +================================================================================+

 
 PROCEDURE fetch_wining_resources   ( p_party_site_id IN hz_party_sites.party_site_id%TYPE 
                                     ,p_postal_code   IN hz_locations.postal_code%TYPE
                                     ,x_bulk_winners_rec_type OUT NOCOPY JTF_TERR_ASSIGN_PUB.bulk_winners_rec_type
                                    ) ;


  -- -----------------------------------------------------------------------------------------
  -- Declaring public procedures
  --------------------------------------------------------------------------------------------
 PROCEDURE Unasgnd_Party_Sites_Main
                                 ( x_errbuf              OUT NOCOPY  VARCHAR2 
          		          ,x_retcode             OUT NOCOPY  NUMBER
          		          ,p_party_type          IN hz_party_sites.attribute13%TYPE
          		          ,p_gdw_enriched        IN VARCHAR2
          		          ,p_from_party_site_id  IN VARCHAR2 
          		          ,p_to_party_site_id    IN VARCHAR2 
          		          ,p_chk_assignment_rule IN VARCHAR2
          		         ) ;
          		         
END XX_TM_AUTONM_UNASGND_SITES_PKG;
/
SHOW ERRORS;
--EXIT;
