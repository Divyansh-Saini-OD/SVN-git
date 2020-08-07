create or replace
PACKAGE XX_EXTERNAL_USERS_PVT
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PVT                                                                |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |               4. Check and update OID subscription of the user                                     |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.      			 	                        |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.          		          |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant and commented code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |1.1       24-Sep_2015 Manikant Kasu      Added procedure to raise business event to check and update|
-- |                                         subscription of the user                                   |
-- +====================================================================================================+
*/


   TYPE external_user_rec_type IS RECORD (
      ext_user_rowid            ROWID
    , ext_user_id               XX_EXTERNAL_USERS.ext_user_id%TYPE
    , userid                    XX_EXTERNAL_USERS.userid%TYPE
    , password                  XX_EXTERNAL_USERS.password%TYPE
    , person_first_name         XX_EXTERNAL_USERS.person_first_name%TYPE
    , person_middle_name        XX_EXTERNAL_USERS.person_middle_name%TYPE
    , person_last_name          XX_EXTERNAL_USERS.person_last_name%TYPE
    , email                     XX_EXTERNAL_USERS.email%TYPE
    , party_id                  XX_EXTERNAL_USERS.party_id%TYPE
    , status                    XX_EXTERNAL_USERS.status%TYPE
    , orig_system               XX_EXTERNAL_USERS.orig_system%TYPE
    , contact_osr               XX_EXTERNAL_USERS.contact_osr%TYPE
    , acct_site_osr             XX_EXTERNAL_USERS.acct_site_osr%TYPE
    , webuser_osr               XX_EXTERNAL_USERS.webuser_osr%TYPE
    , fnd_user_name             XX_EXTERNAL_USERS.fnd_user_name%TYPE
    , access_code               XX_EXTERNAL_USERS.access_code%TYPE
    , permission_flag           XX_EXTERNAL_USERS.permission_flag%TYPE
    , site_key                  XX_EXTERNAL_USERS.site_key%TYPE
    , end_date                  XX_EXTERNAL_USERS.end_date%TYPE
    , load_status               XX_EXTERNAL_USERS.load_status%TYPE
    , user_locked               XX_EXTERNAL_USERS.user_locked%TYPE
    , created_by                XX_EXTERNAL_USERS.created_by%TYPE
    , creation_date             XX_EXTERNAL_USERS.creation_date%TYPE
    , last_update_date          XX_EXTERNAL_USERS.last_update_date%TYPE
    , last_updated_by           XX_EXTERNAL_USERS.last_updated_by%TYPE
    , last_update_login         XX_EXTERNAL_USERS.last_update_login%TYPE
    , ext_upd_timestamp         XX_EXTERNAL_USERS.ext_upd_timestamp%TYPE
    );


   TYPE fnd_user_rec_type IS RECORD (
      fnd_user_rowid                      ROWID
    , user_id                             FND_USER.user_id%TYPE
    , user_name                           FND_USER.user_name%TYPE
    , description                         FND_USER.description%TYPE
    , customer_id                         FND_USER.customer_id%TYPE
    );

   PROCEDURE set_apps_context ( p_system_name               IN           VARCHAR2
                              , p_user_name                 IN           VARCHAR2
                              , p_responsibility_key        IN           VARCHAR2
                              , p_organization_name         IN           VARCHAR2    DEFAULT NULL
                              , x_apps_user_id              OUT NOCOPY   NUMBER
                              , x_resp_id                   OUT NOCOPY   NUMBER
                              , x_resp_appl_id              OUT NOCOPY   NUMBER
                              , x_security_group_id         OUT NOCOPY   NUMBER
                              , x_org_id                    OUT NOCOPY   NUMBER
                              , x_return_status             OUT NOCOPY   VARCHAR2
                              , x_msg_count                 OUT NOCOPY   NUMBER
                              , x_msg_data                  OUT NOCOPY   VARCHAR2
                              );


   PROCEDURE get_entity_id ( p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE
                           , p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE
                           , p_owner_table_name   IN  hz_orig_sys_references.owner_table_name%TYPE
                           , x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
                           , x_return_status      OUT VARCHAR2
                           , x_msg_count          OUT NUMBER
                           , x_msg_data           OUT VARCHAR2
                           );

   PROCEDURE get_contact_id ( p_orig_system          IN            VARCHAR2
                            , p_cust_acct_cnt_osr    IN            VARCHAR2
                            , x_party_id             OUT           NUMBER
                            , x_return_status        OUT NOCOPY    VARCHAR2
                            , x_msg_count            OUT           NUMBER
                            , x_msg_data             OUT NOCOPY    VARCHAR2
                            );

   PROCEDURE get_account_org ( p_cust_acct_id                    IN            NUMBER
                             , p_acct_site_id                    IN            NUMBER
                             , p_org_contact_id                  IN            NUMBER
                             , x_org_id                          OUT           NUMBER
                             , x_return_status                   OUT NOCOPY    VARCHAR2
                             , x_msg_count                       OUT           NUMBER
                             , x_msg_data                        OUT NOCOPY    VARCHAR2
                             );

   PROCEDURE get_account_org ( p_cust_acct_id                    IN            NUMBER
                             , p_acct_site_id                    IN            NUMBER
                             , p_org_contact_id                  IN            NUMBER
                             , px_org_id                         OUT           NUMBER
                             , x_org_name                        OUT NOCOPY    VARCHAR2
                             , x_return_status                   OUT NOCOPY    VARCHAR2
                             , x_msg_count                       OUT           NUMBER
                             , x_msg_data                        OUT NOCOPY    VARCHAR2
                             );

   PROCEDURE update_fnd_user ( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                             , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                             , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                             , x_return_status           OUT NOCOPY VARCHAR2
                             , x_msg_count               OUT        NUMBER
                             , x_msg_data                OUT NOCOPY VARCHAR2
                             );

   PROCEDURE update_new_fnd_user ( p_fnd_user_id             IN         NUMBER   DEFAULT NULL
                                 , p_fnd_user_name           IN         VARCHAR2 DEFAULT NULL
                                 , x_return_status           OUT NOCOPY VARCHAR2
                                 , x_msg_count               OUT        NUMBER
                                 , x_msg_data                OUT NOCOPY VARCHAR2
                                 );

  FUNCTION get_messages ( p_return_status  IN VARCHAR2
                        , p_msg_count      IN NUMBER
                        , p_msg_data       IN VARCHAR2
                        ) RETURN HZ_MESSAGE_OBJ_TBL;

  PROCEDURE xx_oid_raise_be  (p_user_name   IN VARCHAR2 );

  PROCEDURE save_external_user ( p_site_key                   IN         VARCHAR2
                               , p_userid                     IN         VARCHAR2
                               , p_action_type                IN         VARCHAR2
                               , p_new_extuser_rec            IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                               , x_cur_extuser_rec            OUT NOCOPY XX_EXTERNAL_USERS_PVT.external_user_rec_type
                               , x_return_status              OUT NOCOPY VARCHAR2
                               , x_msg_count                  OUT        NUMBER
                               , x_msg_data                   OUT NOCOPY VARCHAR2
                               );

   PROCEDURE get_contact_level ( p_system_name     IN  VARCHAR2
                               , p_permission_flag IN  VARCHAR2
                               , x_contact_level   OUT VARCHAR2
                               , x_return_status   OUT VARCHAR2
                               , x_msg_count       OUT NUMBER
                               , x_msg_data        OUT VARCHAR2
                               );

  PROCEDURE get_resp_id ( p_orig_system            IN         VARCHAR2
                        , p_orig_system_access     IN         VARCHAR2
                        , p_org_name               IN         VARCHAR2
                        , x_resp_id                OUT        NUMBER
                        , x_appl_id                OUT        NUMBER
                        , x_responsibility_name    OUT NOCOPY VARCHAR2
                        , x_return_status          OUT NOCOPY VARCHAR2
                        , x_msg_count              OUT NUMBER
                        , x_msg_data               OUT NOCOPY VARCHAR2
                        );


  PROCEDURE get_user_prefix ( p_system_name     IN  VARCHAR2
                            , x_site_key        OUT VARCHAR2
                            , x_return_status   OUT VARCHAR2
                            , x_msg_count       OUT NUMBER
                            , x_msg_data        OUT VARCHAR2
                            );


END XX_EXTERNAL_USERS_PVT;


/

SHOW ERRORS;
