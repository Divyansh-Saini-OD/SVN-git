create or replace PACKAGE XX_CDH_WEBCONTACTS_BO_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_CDH_WEBCONTACTS_BO_PUB                                                             |
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
-- |1.0       19-Aug-2007 Ramesh Raghupathi  Initial draft version.      		                |
-- |          10-Dec-2007 Yusuf Ali          Modified code for permissions flag.          	        |
-- |          18-Jan-2008 Alok Sahay         Changed Package Name                                       |
-- |                                         Changed Signatures to standarize return error code         |
-- |                                         Add return messages using FND_NEW_MESSAGES                 |
-- |                                         Removed Redundant and commented code                       |
-- |                                         Added Logic to support deprovisionsing                     |
-- |          14-Sep-2008 Kathirvel.P        Changes made to web contact deletion , contact deletion and|
-- |                                         web contact status maintenance.                            |
-- |                                                                                                    |
-- +====================================================================================================+
*/

   PROCEDURE validate_role_resp ( p_orig_system                 IN            VARCHAR2
                                , p_cust_acct_osr               IN            VARCHAR2
                                , p_cust_acct_cnt_osr           IN            VARCHAR2
                                , p_cust_acct_site_osr          IN            VARCHAR2
                                , x_cust_account_id             OUT           NUMBER
                                , x_acct_site_id                OUT           NUMBER
                                , x_party_id                    OUT           NUMBER
                                , x_return_status               OUT           VARCHAR2
                                , x_messages                    OUT NOCOPY    HZ_MESSAGE_OBJ_TBL
                                );

   PROCEDURE validate_role_resp ( p_orig_system                 IN             VARCHAR2
                                , p_cust_acct_osr               IN             VARCHAR2
                                , p_cust_acct_cnt_osr           IN             VARCHAR2
                                , p_cust_acct_site_osr          IN             VARCHAR2
                                , x_cust_account_id             OUT            NUMBER
                                , x_acct_site_id                OUT            NUMBER
                                , x_party_id                    OUT            NUMBER
                                , x_return_status               OUT NOCOPY     VARCHAR2
                                , x_msg_count                   OUT            NUMBER
                                , x_msg_data                    OUT NOCOPY     VARCHAR2
                                );

   PROCEDURE save_role_resp ( p_orig_system                 IN            VARCHAR2
                            , p_cust_acct_osr               IN            VARCHAR2
                            , p_cust_acct_cnt_osr           IN            VARCHAR2
                            , p_cust_acct_site_osr          IN            VARCHAR2
                            , p_record_type                 IN            VARCHAR2 DEFAULT NULL
                            , p_permission_flag             IN            VARCHAR2
                            , p_action                      IN            VARCHAR2
			    , p_web_contact_id              IN            VARCHAR2
                            , px_cust_account_id            IN OUT        NUMBER
                            , px_ship_to_acct_site_id       IN OUT        NUMBER
                            , px_bill_to_acct_site_id       IN OUT        NUMBER
                            , px_party_id                   IN OUT        NUMBER
			    , x_web_user_status             OUT           VARCHAR2
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
			    , p_web_contact_id              IN             VARCHAR2
                            , px_cust_account_id            IN OUT         NUMBER
                            , px_ship_to_acct_site_id       IN OUT         NUMBER
                            , px_bill_to_acct_site_id       IN OUT         NUMBER
                            , px_party_id                   IN  OUT        NUMBER
			    , x_web_user_status             OUT            VARCHAR2
                            , x_return_status               OUT NOCOPY     VARCHAR2
                            , x_msg_count                   OUT            NUMBER
                            , x_msg_data                    OUT NOCOPY     VARCHAR2
                            );

END XX_CDH_WEBCONTACTS_BO_PUB;

/

SHOW ERRORS;
