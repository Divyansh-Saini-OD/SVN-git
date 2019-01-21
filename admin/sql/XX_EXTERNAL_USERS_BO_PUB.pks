create or replace PACKAGE XX_EXTERNAL_USERS_BO_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_BO_PUB                                                             |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.      			 	                    |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.          		        |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant and commented code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |                                                                                                    |
-- +====================================================================================================+
*/


   TYPE external_user_rec_type IS RECORD (
      ext_user_rowid            ROWID
    , ext_user_id               NUMBER(10)
    , userid                    VARCHAR2(100)
    , password                  VARCHAR2(10)
    , person_first_name         VARCHAR2(150)
    , person_middle_name        VARCHAR2(60)
    , person_last_name          VARCHAR2(150)
    , email                     VARCHAR2(100)
    , party_id                  NUMBER(15)
    , status                    VARCHAR2(1)
    , orig_system               VARCHAR2(50)
    , contact_osr               VARCHAR2(50)
    , acct_site_osr             VARCHAR2(50)
    , access_code               NUMBER(3)
    , permission_flag           VARCHAR2(1)
    , site_key                  VARCHAR2(100)
    , end_date                  DATE
    , load_status               VARCHAR2(30)
    , user_locked               VARCHAR2(1)
    , created_by                NUMBER
    , creation_date             DATE
    , last_update_date          DATE
    , last_updated_by           NUMBER
    , last_update_login         NUMBER
    );


   TYPE fnd_user_rec_type IS RECORD (
      fnd_user_rowid                      ROWID
    , user_id                             NUMBER(15)
    , user_name                           VARCHAR2(100)
    , description                         VARCHAR2(240)
    , customer_id                         NUMBER(15)
    );

   PROCEDURE get_entity_id (
      p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE
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

   PROCEDURE save_role_resp ( p_orig_system                 IN            VARCHAR2
                            , p_cust_acct_osr               IN            VARCHAR2
                            , p_cust_acct_cnt_osr           IN            VARCHAR2
                            , p_cust_acct_site_osr          IN            VARCHAR2
                            , p_record_type                 IN            VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN            VARCHAR2
                            , p_action                      IN            VARCHAR2
                            , x_cust_account_id             OUT           NUMBER
                            , x_ship_to_acct_site_id        OUT           NUMBER
                            , x_bill_to_acct_site_id        OUT           NUMBER
                            , x_party_id                    OUT           NUMBER
                            , x_return_status               OUT           VARCHAR2
                            , x_messages                    OUT NOCOPY    HZ_MESSAGE_OBJ_TBL
                            );

   PROCEDURE save_role_resp ( p_orig_system                 IN             VARCHAR2
                            , p_cust_acct_osr               IN             VARCHAR2
                            , p_cust_acct_cnt_osr           IN             VARCHAR2
                            , p_cust_acct_site_osr          IN             VARCHAR2
                            , p_record_type                 IN             VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN             VARCHAR2
                            , p_action                      IN             VARCHAR2
                            , x_cust_account_id             OUT            NUMBER
                            , x_ship_to_acct_site_id        OUT            NUMBER
                            , x_bill_to_acct_site_id        OUT            NUMBER
                            , x_party_id                    OUT            NUMBER
                            , x_return_status               OUT NOCOPY     VARCHAR2
                            , x_msg_count                   OUT            NUMBER
                            , x_msg_data                    OUT NOCOPY     VARCHAR2
                            );

   PROCEDURE save_ext_user( p_userid                 IN          VARCHAR2
                          , p_password               IN          VARCHAR2
                          , p_first_name             IN          VARCHAR2
                          , p_middle_initial         IN          VARCHAR2
                          , p_last_name              IN          VARCHAR2
                          , p_email                  IN          VARCHAR
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          NUMBER   DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT         VARCHAR2
                          , x_messages               OUT NOCOPY  HZ_MESSAGE_OBJ_TBL
                          );

   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_BO_PUB.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_BO_PUB.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         );

   PROCEDURE save_ext_user( p_userid                 IN       VARCHAR2
                          , p_password               IN       VARCHAR2
                          , p_first_name             IN       VARCHAR2
                          , p_middle_initial         IN       VARCHAR2
                          , p_last_name              IN       VARCHAR2
                          , p_email                  IN       VARCHAR
                          , p_status                 IN       VARCHAR2 DEFAULT '0'
                          , p_orig_system            IN       VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN       VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN       VARCHAR2
                          , p_acct_site_osr          IN       VARCHAR2 DEFAULT NULL
                          , p_record_type            IN       VARCHAR2 DEFAULT NULL
                          , p_access_code            IN       NUMBER   DEFAULT NULL
                          , p_permission_flag        IN       VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN       NUMBER
                          , p_ship_to_acct_site_id   IN       NUMBER
                          , p_bill_to_acct_site_id   IN       NUMBER
                          , p_party_id               IN       NUMBER   DEFAULT NULL
                          , x_return_status          OUT      VARCHAR2
                          , x_msg_count              OUT      NUMBER
                          , x_msg_data               OUT      VARCHAR2
                          );


  FUNCTION get_fnd_create_event ( p_subscription_guid IN RAW
                                , p_event     IN OUT NOCOPY WF_EVENT_T
                                )
  RETURN VARCHAR2;

  PROCEDURE update_ext_user_password ( p_userid          IN         VARCHAR2
                                     , p_password        IN         VARCHAR2
                                     , x_return_status   OUT NOCOPY VARCHAR2
                                     , x_msg_count       OUT        NUMBER
                                     , x_msg_data        OUT NOCOPY VARCHAR2
                                     );

/*
   FUNCTION decipher ( p_encrypted_string in varchar2 )
   RETURN varchar2;


  PROCEDURE process_oid ( p_username IN  VARCHAR2
                        , x_retcode  OUT NUMBER
                        );

*/

END XX_EXTERNAL_USERS_BO_PUB;

/

SHOW ERRORS;
