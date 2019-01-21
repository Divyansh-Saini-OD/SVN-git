create or replace PACKAGE XX_CDH_WEBCONTACTS_PVT
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

   PROCEDURE save_acct_site_ext ( p_operation                 IN         VARCHAR2
                                , p_orig_system               IN         VARCHAR2
                                , p_ship_to_acct_site_id      IN         NUMBER
                                , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_bill_to_acct_site_id      IN         NUMBER
                                , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                , p_contact_party_id          IN         NUMBER
                                , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                , x_return_status             OUT NOCOPY VARCHAR2
                                , x_msg_count                 OUT        NUMBER
                                , x_msg_data                  OUT NOCOPY VARCHAR2
                                );

   PROCEDURE save_ship_to_contact ( p_operation                 IN         VARCHAR2
                                  , p_orig_system               IN         VARCHAR2
                                  , p_ship_to_acct_site_id      IN         NUMBER
                                  , p_ship_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_bill_to_acct_site_id      IN         NUMBER
                                  , p_bill_to_acct_site_osr     IN         VARCHAR2 DEFAULT NULL
                                  , p_contact_party_id          IN         NUMBER
                                  , p_contact_party_osr         IN         VARCHAR2 DEFAULT NULL
                                  , x_bill_to_operation         OUT NOCOPY VARCHAR2
                                  , x_return_status             OUT NOCOPY VARCHAR2
                                  , x_msg_count                 OUT        NUMBER
                                  , x_msg_data                  OUT NOCOPY VARCHAR2
                                  );

   PROCEDURE get_bill_to_site_id ( p_cust_acct_id                    IN            NUMBER
                                 , p_ship_to_cust_acct_site_id       IN            NUMBER
                                 , x_bill_to_cust_acct_site_id       OUT           NUMBER
                                 , x_bill_to_osr                     OUT NOCOPY    VARCHAR2
                                 , x_return_status                   OUT NOCOPY    VARCHAR2
                                 , x_msg_count                       OUT           NUMBER
                                 , x_msg_data                        OUT NOCOPY    VARCHAR2
                                 );

   PROCEDURE save_bill_to_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_ship_to_acct_site_id        IN             NUMBER
                                       , p_bill_to_acct_site_id        IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR2
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE save_account_contact_role ( p_action                      IN             VARCHAR2
                                       , p_parent_obj                  IN             VARCHAR2
                                       , p_orig_system                 IN             VARCHAR
                                       , p_cust_acct_osr               IN             VARCHAR
                                       , p_cust_acct_cnt_osr           IN             VARCHAR
                                       , p_cust_account_id             IN             NUMBER
                                       , p_party_id                    IN             NUMBER
                                       , x_return_status               OUT NOCOPY     VARCHAR2
                                       , x_msg_count                   OUT            NUMBER
                                       , x_msg_data                    OUT NOCOPY     VARCHAR2
                                       );

   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   );

   PROCEDURE check_bill_to_contact ( p_orig_system             IN         VARCHAR2
                                   , p_contact_party_id        IN         NUMBER
                                   , p_contact_party_osr       IN         VARCHAR2
                                   , p_ship_to_acct_site_id    IN         NUMBER
                                   , p_ship_to_acct_site_osr   IN         VARCHAR2
                                   , p_bill_to_acct_site_id    IN         NUMBER
                                   , p_bill_to_acct_site_osr   IN         VARCHAR2
                                   , x_contact_bill_to_exists  OUT        BOOLEAN
                                   , x_return_status           OUT NOCOPY VARCHAR2
                                   , x_msg_count               OUT        NUMBER
                                   , x_msg_data                OUT NOCOPY VARCHAR2
                                   );


END XX_CDH_WEBCONTACTS_PVT;

/

SHOW ERRORS;
