SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_PARTY_BO_WRAP_PUB
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_BO_WRAP_PUB                                            |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+
AS
procedure create_organization (
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_bo_process_id       IN            NUMBER,	
    p_bpel_process_id     IN            NUMBER,
	x_organization_id     OUT  NOCOPY   NUMBER,
	x_return_status       OUT  NOCOPY   VARCHAR2,
	x_errbuf              OUT  NOCOPY   VARCHAR2
);

procedure save_organization (
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_bo_process_id       IN            NUMBER,	
    p_bpel_process_id     IN            NUMBER,
	p_create_update_flag  IN            VARCHAR2,
	x_organization_id     OUT  NOCOPY   NUMBER,
	x_return_status       OUT  NOCOPY   VARCHAR2,
	x_errbuf              OUT  NOCOPY   VARCHAR2	
);

procedure do_create_organization_party (
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_organization_id     OUT  NOCOPY   NUMBER
  );

procedure do_save_organization_party (
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_organization_id     OUT  NOCOPY   NUMBER
  );
procedure do_save_party_site_bo (   
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,   
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_party_site_obj      IN            HZ_PARTY_SITE_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    p_return_obj_flag     IN            VARCHAR2 := fnd_api.g_true,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_messages            OUT NOCOPY    HZ_MESSAGE_OBJ_TBL,
    x_return_obj          OUT NOCOPY    HZ_PARTY_SITE_BO,
    x_party_site_id       OUT NOCOPY    NUMBER,
    x_party_site_os       OUT NOCOPY    VARCHAR2,
    x_party_site_osr      OUT NOCOPY    VARCHAR2,
    px_parent_id          IN OUT NOCOPY NUMBER,
    px_parent_os          IN OUT NOCOPY VARCHAR2,
    px_parent_osr         IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type    IN OUT NOCOPY VARCHAR2
   );
procedure do_create_location ( p_location_obj       IN            HZ_LOCATION_OBJ,
                               p_bo_process_id      IN            NUMBER,
                               p_bpel_process_id    IN            NUMBER,
                               x_location_id        OUT NOCOPY    NUMBER
                              );

procedure do_save_location ( p_location_obj       IN            HZ_LOCATION_OBJ,
                             p_bo_process_id      IN            NUMBER,
                             p_bpel_process_id    IN            NUMBER,
                             x_location_id        OUT NOCOPY    NUMBER
                           );							  

procedure do_create_party_site (
                                 p_party_site_obj    IN           HZ_PARTY_SITE_BO,
                                 p_bo_process_id     IN           NUMBER,
                                 p_bpel_process_id   IN           NUMBER,
                                 p_party_id          IN           NUMBER,
                                 p_location_id       IN           NUMBER,
                                 x_party_site_id        OUT  NOCOPY  NUMBER
                                );

procedure do_save_party_site (
                                 p_party_site_obj    IN           HZ_PARTY_SITE_BO,
                                 p_bo_process_id     IN           NUMBER,
                                 p_bpel_process_id   IN           NUMBER,
                                 p_party_id          IN           NUMBER,
                                 p_location_id       IN           NUMBER,
                                 x_party_site_id        OUT  NOCOPY  NUMBER
                                );

procedure do_create_party_site_uses (  p_party_site_use_objs     IN  HZ_PARTY_SITE_USE_OBJ_TBL,
                                       p_bo_process_id           IN  NUMBER,
                                       p_bpel_process_id         IN  NUMBER,
                                       p_party_site_id           IN  NUMBER,
                                       p_orig_system             IN  VARCHAR2,
                                       p_orig_system_reference   IN  VARCHAR2                                    
                                    );
procedure do_save_party_site_uses (  p_party_site_use_objs     IN  HZ_PARTY_SITE_USE_OBJ_TBL,
                                     p_bo_process_id           IN  NUMBER,
                                     p_bpel_process_id         IN  NUMBER,
                                     p_party_site_id           IN  NUMBER,
                                     p_orig_system             IN  VARCHAR2,
                                     p_orig_system_reference   IN  VARCHAR2                                    
                                    );
procedure do_create_party_sites (
                              p_party_site_objs     IN            HZ_PARTY_SITE_BO_TBL,
                              p_bo_process_id       IN            NUMBER,
                              p_bpel_process_id     IN            NUMBER,
                              p_party_id            IN            NUMBER
                            );
procedure do_save_party_sites (
                              p_party_site_objs     IN            HZ_PARTY_SITE_BO_TBL,
                              p_bo_process_id       IN            NUMBER,
                              p_bpel_process_id     IN            NUMBER,
                              p_party_id            IN            NUMBER
                            );	
PROCEDURE create_classifications(
    p_code_assign_objs           IN            hz_code_assignment_obj_tbl,
    p_bo_process_id              IN            NUMBER,
    p_bpel_process_id            IN            NUMBER,  
    p_owner_table_name           IN            VARCHAR2,
    p_owner_table_id             IN            NUMBER,
    p_orig_system                IN            VARCHAR2,
    p_orig_system_reference      IN            VARCHAR2,
    x_return_status              OUT    NOCOPY VARCHAR2,
    x_msg_count                  OUT    NOCOPY NUMBER,
    x_msg_data                   OUT    NOCOPY VARCHAR2
  );	
PROCEDURE save_classifications(
    p_code_assign_objs           IN            hz_code_assignment_obj_tbl,
    p_bo_process_id              IN            NUMBER,
    p_bpel_process_id            IN            NUMBER,  
    p_owner_table_name           IN            VARCHAR2,
    p_owner_table_id             IN            NUMBER,
    p_orig_system                IN            VARCHAR2,
    p_orig_system_reference      IN            VARCHAR2,
    x_return_status              OUT    NOCOPY VARCHAR2,
    x_msg_count                  OUT    NOCOPY NUMBER,
    x_msg_data                   OUT    NOCOPY VARCHAR2
  );  
procedure do_create_relationships (
    p_relationship_objs       IN     HZ_RELATIONSHIP_OBJ_TBL,
    p_bo_process_id           IN     NUMBER,
    p_bpel_process_id         IN     NUMBER,
    p_organization_id         IN     NUMBER,
    p_orig_system             IN     VARCHAR2,
    p_orig_system_reference   IN     VARCHAR2
  );
procedure do_save_relationships (
    p_relationship_objs       IN     HZ_RELATIONSHIP_OBJ_TBL,
    p_bo_process_id           IN     NUMBER,
    p_bpel_process_id         IN     NUMBER,
    p_organization_id         IN     NUMBER,
    p_orig_system             IN     VARCHAR2,
    p_orig_system_reference   IN     VARCHAR2
  );
procedure do_save_org_contacts(
        p_oc_objs                 IN     HZ_ORG_CONTACT_BO_TBL,
		p_create_update_flag      IN     VARCHAR2,
        p_bo_process_id           IN     NUMBER,
        p_bpel_process_id         IN     NUMBER,
        p_organization_id         IN     NUMBER,
        p_orig_system             IN     VARCHAR2,
        p_orig_system_reference   IN     VARCHAR2
      );
procedure do_save_org_contact_points(
        p_phone_objs              IN     HZ_PHONE_CP_BO_TBL, 
        p_telex_objs              IN     HZ_TELEX_CP_BO_TBL, 
        p_email_objs              IN     HZ_EMAIL_CP_BO_TBL, 
        p_web_objs                IN     HZ_WEB_CP_BO_TBL,   
        p_edi_objs                IN     HZ_EDI_CP_BO_TBL,   
        p_eft_objs                IN     HZ_EFT_CP_BO_TBL,   
		p_create_update_flag      IN     VARCHAR2,
        p_bo_process_id           IN     NUMBER,
        p_bpel_process_id         IN     NUMBER,
        p_organization_id         IN     NUMBER,
        p_orig_system             IN     VARCHAR2,
        p_orig_system_reference   IN     VARCHAR2
      );	  
END XX_CDH_PARTY_BO_WRAP_PUB;
/
SHOW ERRORS;