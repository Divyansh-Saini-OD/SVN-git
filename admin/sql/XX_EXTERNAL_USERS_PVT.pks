create or replace PACKAGE xx_external_users_pvt AS

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
-- |2.0		  20-July-21  Sreedhar Mohan	 NAIT-190252 JIT (Just In Time) Provisioning changes in EBS
-- +====================================================================================================+
*/
    TYPE external_user_rec_type IS RECORD ( ext_user_rowid ROWID,
    ext_user_id xx_external_users.ext_user_id%TYPE,
    userid xx_external_users.userid%TYPE,
    password xx_external_users.password%TYPE,
    person_first_name xx_external_users.person_first_name%TYPE,
    person_middle_name xx_external_users.person_middle_name%TYPE,
    person_last_name xx_external_users.person_last_name%TYPE,
    email xx_external_users.email%TYPE,
    party_id xx_external_users.party_id%TYPE,
    status xx_external_users.status%TYPE,
    orig_system xx_external_users.orig_system%TYPE,
    contact_osr xx_external_users.contact_osr%TYPE,
    acct_site_osr xx_external_users.acct_site_osr%TYPE,
    webuser_osr xx_external_users.webuser_osr%TYPE,
    fnd_user_name xx_external_users.fnd_user_name%TYPE,
    access_code xx_external_users.access_code%TYPE,
    permission_flag xx_external_users.permission_flag%TYPE,
    site_key xx_external_users.site_key%TYPE,
    end_date xx_external_users.end_date%TYPE,
    load_status xx_external_users.load_status%TYPE,
    user_locked xx_external_users.user_locked%TYPE,
    created_by xx_external_users.created_by%TYPE,
    creation_date xx_external_users.creation_date%TYPE,
    last_update_date xx_external_users.last_update_date%TYPE,
    last_updated_by xx_external_users.last_updated_by%TYPE,
    last_update_login xx_external_users.last_update_login%TYPE,
    ext_upd_timestamp xx_external_users.ext_upd_timestamp%TYPE );
    TYPE fnd_user_rec_type IS RECORD ( fnd_user_rowid ROWID,
    user_id fnd_user.user_id%TYPE,
    user_name fnd_user.user_name%TYPE,
    description fnd_user.description%TYPE,
    customer_id fnd_user.customer_id%TYPE );
    PROCEDURE set_apps_context (
        p_system_name          IN VARCHAR2,
        p_user_name            IN VARCHAR2,
        p_responsibility_key   IN VARCHAR2,
        p_organization_name    IN VARCHAR2 DEFAULT NULL,
        x_apps_user_id         OUT NOCOPY NUMBER,
        x_resp_id              OUT NOCOPY NUMBER,
        x_resp_appl_id         OUT NOCOPY NUMBER,
        x_security_group_id    OUT NOCOPY NUMBER,
        x_org_id               OUT NOCOPY NUMBER,
        x_return_status        OUT NOCOPY VARCHAR2,
        x_msg_count            OUT NOCOPY NUMBER,
        x_msg_data             OUT NOCOPY VARCHAR2
    );

    PROCEDURE get_entity_id (
        p_orig_system          IN hz_orig_sys_references.orig_system%TYPE,
        p_orig_sys_reference   IN hz_orig_sys_references.orig_system_reference%TYPE,
        p_owner_table_name     IN hz_orig_sys_references.owner_table_name%TYPE,
        x_owner_table_id       OUT hz_orig_sys_references.owner_table_id%TYPE,
        x_return_status        OUT VARCHAR2,
        x_msg_count            OUT NUMBER,
        x_msg_data             OUT VARCHAR2
    );

    PROCEDURE get_contact_id (
        p_orig_system         IN VARCHAR2,
        p_cust_acct_cnt_osr   IN VARCHAR2,
        x_party_id            OUT NUMBER,
        x_return_status       OUT NOCOPY VARCHAR2,
        x_msg_count           OUT NUMBER,
        x_msg_data            OUT NOCOPY VARCHAR2
    );

    PROCEDURE get_account_org (
        p_cust_acct_id     IN NUMBER,
        p_acct_site_id     IN NUMBER,
        p_org_contact_id   IN NUMBER,
        x_org_id           OUT NUMBER,
        x_return_status    OUT NOCOPY VARCHAR2,
        x_msg_count        OUT NUMBER,
        x_msg_data         OUT NOCOPY VARCHAR2
    );

    PROCEDURE get_account_org (
        p_cust_acct_id     IN NUMBER,
        p_acct_site_id     IN NUMBER,
        p_org_contact_id   IN NUMBER,
        px_org_id          OUT NUMBER,
        x_org_name         OUT NOCOPY VARCHAR2,
        x_return_status    OUT NOCOPY VARCHAR2,
        x_msg_count        OUT NUMBER,
        x_msg_data         OUT NOCOPY VARCHAR2
    );

    PROCEDURE update_fnd_user (
        p_cur_extuser_rec   IN xx_external_users_pvt.external_user_rec_type,
        p_new_extuser_rec   IN xx_external_users_pvt.external_user_rec_type,
        p_fnd_user_rec      IN xx_external_users_pvt.fnd_user_rec_type,
        x_return_status     OUT NOCOPY VARCHAR2,
        x_msg_count         OUT NUMBER,
        x_msg_data          OUT NOCOPY VARCHAR2
    );

    PROCEDURE update_new_fnd_user (
        p_fnd_user_id     IN NUMBER DEFAULT NULL,
        p_fnd_user_name   IN VARCHAR2 DEFAULT NULL,
        x_return_status   OUT NOCOPY VARCHAR2,
        x_msg_count       OUT NUMBER,
        x_msg_data        OUT NOCOPY VARCHAR2
    );

    FUNCTION get_messages (
        p_return_status   IN VARCHAR2,
        p_msg_count       IN NUMBER,
        p_msg_data        IN VARCHAR2
    ) RETURN hz_message_obj_tbl;

    PROCEDURE xx_oid_raise_be (
        p_user_name IN VARCHAR2
    );

    PROCEDURE save_external_user (
        p_site_key          IN VARCHAR2,
        p_userid            IN VARCHAR2,
        p_action_type       IN VARCHAR2,
        p_new_extuser_rec   IN xx_external_users_pvt.external_user_rec_type,
        x_cur_extuser_rec   OUT NOCOPY xx_external_users_pvt.external_user_rec_type,
        x_return_status     OUT NOCOPY VARCHAR2,
        x_msg_count         OUT NUMBER,
        x_msg_data          OUT NOCOPY VARCHAR2
    );

    PROCEDURE get_contact_level (
        p_system_name       IN VARCHAR2,
        p_permission_flag   IN VARCHAR2,
        x_contact_level     OUT VARCHAR2,
        x_return_status     OUT VARCHAR2,
        x_msg_count         OUT NUMBER,
        x_msg_data          OUT VARCHAR2
    );

    PROCEDURE get_resp_id (
        p_orig_system           IN VARCHAR2,
        p_orig_system_access    IN VARCHAR2,
        p_org_name              IN VARCHAR2,
        x_resp_id               OUT NUMBER,
        x_appl_id               OUT NUMBER,
        x_responsibility_name   OUT NOCOPY VARCHAR2,
        x_return_status         OUT NOCOPY VARCHAR2,
        x_msg_count             OUT NUMBER,
        x_msg_data              OUT NOCOPY VARCHAR2
    );
--NAIT-190252 changes start
    PROCEDURE get_user_prefix (
        p_system_name     IN VARCHAR2,
        x_site_key        OUT VARCHAR2,
        x_return_status   OUT VARCHAR2,
        x_msg_count       OUT NUMBER,
        x_msg_data        OUT VARCHAR2
    );
 
    procedure provision_fnd_user (
        p_fnd_user_name     IN VARCHAR2,
        p_userid            IN VARCHAR2,
        p_user_first_name   IN VARCHAR2,
        p_user_last_name    IN VARCHAR2,
        p_access_code       IN VARCHAR2,
        p_email             IN VARCHAR2,
        p_phone_nbr         IN VARCHAR2,
        aops_customer_id    IN VARCHAR2,
        contact_id          IN VARCHAR2
    );
 --NAIT-190252 changes end

END xx_external_users_pvt;
/
show error;