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

   PROCEDURE save_ext_user( p_userid                 IN          VARCHAR2
                          , p_password               IN          VARCHAR2
                          , p_first_name             IN          VARCHAR2
                          , p_middle_initial         IN          VARCHAR2
                          , p_last_name              IN          VARCHAR2
                          , p_email                  IN          VARCHAR
                          , p_ext_upd_time           IN          TIMESTAMP
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_action_type            IN          VARCHAR2 DEFAULT 'U'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_webuser_osr            IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          VARCHAR2 DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT NOCOPY  VARCHAR2
                          , x_messages               OUT NOCOPY  HZ_MESSAGE_OBJ_TBL
                          );

   PROCEDURE save_ext_user( p_userid                 IN          VARCHAR2
                          , p_password               IN          VARCHAR2
                          , p_first_name             IN          VARCHAR2
                          , p_middle_initial         IN          VARCHAR2
                          , p_last_name              IN          VARCHAR2
                          , p_email                  IN          VARCHAR
                          , p_ext_upd_time           IN          TIMESTAMP
                          , p_status                 IN          VARCHAR2 DEFAULT '0'
                          , p_action_type            IN          VARCHAR2 DEFAULT 'U'
                          , p_orig_system            IN          VARCHAR2 DEFAULT NULL
                          , p_cust_acct_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_contact_osr            IN          VARCHAR2
                          , p_acct_site_osr          IN          VARCHAR2 DEFAULT NULL
                          , p_webuser_osr            IN          VARCHAR2 DEFAULT NULL
                          , p_record_type            IN          VARCHAR2 DEFAULT NULL
                          , p_access_code            IN          VARCHAR2 DEFAULT NULL
                          , p_permission_flag        IN          VARCHAR  DEFAULT NULL
                          , p_cust_account_id        IN          NUMBER
                          , p_ship_to_acct_site_id   IN          NUMBER
                          , p_bill_to_acct_site_id   IN          NUMBER
                          , p_party_id               IN          NUMBER   DEFAULT NULL
                          , x_return_status          OUT NOCOPY  VARCHAR2
                          , x_msg_count              OUT         NUMBER
                          , x_msg_data               OUT NOCOPY  VARCHAR2
                          );


  FUNCTION get_fnd_create_event ( p_subscription_guid IN RAW
                                , p_event     IN OUT NOCOPY WF_EVENT_T
                                )
  RETURN VARCHAR2;

  PROCEDURE update_ext_user_password ( p_userid          IN         VARCHAR2
                                     , p_password        IN         VARCHAR2
                                     , p_ext_upd_time    IN         TIMESTAMP
                                     , x_return_status   OUT NOCOPY VARCHAR2
                                     , x_msg_count       OUT        NUMBER
                                     , x_msg_data        OUT NOCOPY VARCHAR2
                                     );

END XX_EXTERNAL_USERS_BO_PUB;

/

SHOW ERRORS;
