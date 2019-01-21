/*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAC Consulting Organization                 |
-- +===================================================================+
-- | Name        :  XX_EXTERNAL_USERS_PKG.pkb                          |
-- | Description : Package for E1328_BSD_iReceivables_interface        |
-- |               This package performs the following                 |
-- |              1. Setup the contact at a bill to level              |
-- |              2. Insert the web user detail into xx_external_users |
-- |              3. Assign responsibilites and party id               |
-- |                 when the webuser is created in fnd_user           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  19-Aug-2007 Ramesh Raghupathi Initial draft version      |
-- |          10-Dec-2007 Yusuf Ali         Changed procedures to      |
-- |                                        accept permissions_flag    |
-- +===================================================================+
*/
create or replace PACKAGE XX_EXTERNAL_USERS_PKG
AS

  -- Site key to be appended to bsd web userid to make the user unique 
  -- in OID 
  gcn_site_key  CONSTANT varchar2(20) := '001'; 
  -- responsibility id for iReceivables US  responsibility 
  gcn_us_resp   CONSTANT number       := 50778;
  -- responsibility id for iReceivables Canaduan responsibility 
  gcn_ca_resp   CONSTANT number       := 50779;
  gcn_null_resp CONSTANT number       := 0; 


  PROCEDURE get_site_use_id
  ( p_orig_system        IN  hz_orig_sys_references.orig_system%TYPE
  , p_orig_sys_reference IN  hz_orig_sys_references.orig_system_reference%TYPE
  , p_owner_table_name   IN  hz_orig_sys_references.owner_table_name%TYPE
  , x_owner_table_id     OUT hz_orig_sys_references.owner_table_id%TYPE
  );

   PROCEDURE create_role_resp (
      p_cust_acct_cnt_os     IN       VARCHAR2,
      p_cust_acct_cnt_osr    IN       VARCHAR2,
      p_cust_acct_site_osr   IN       VARCHAR2,
      p_action               IN       VARCHAR2,
      p_permission_flag      IN       VARCHAR2,
      x_party_id             OUT      NUMBER,
      x_retcode              OUT      VARCHAR2
   );

  FUNCTION decipher ( p_encrypted_string in varchar2 )
  RETURN varchar2;                    

  PROCEDURE process_oid ( p_username IN  VARCHAR2
                        , x_retcode  OUT NUMBER 
                        ); 

  PROCEDURE update_fnd_user ( p_username        IN  VARCHAR2
                            , p_end_date        IN  DATE     DEFAULT NULL
                            , p_action          IN  VARCHAR2
                            , p_org_id          IN  NUMBER   DEFAULT NULL
                            , p_bsd_access_code IN  NUMBER   DEFAULT NULL
                            , x_retcode         OUT VARCHAR2
                            );

  PROCEDURE save_ext_user ( p_userid           IN  VARCHAR2
                          , p_password         IN  VARCHAR2
                          , p_first_name       IN  VARCHAR2
                          , p_middle_initial   IN  VARCHAR2
                          , p_last_name        IN  VARCHAR2
                          , p_email            IN  VARCHAR
                          , p_status           IN  VARCHAR2 DEFAULT '0'
                          , p_contact_osr      IN  VARCHAR2
                          , p_acct_site_osr    IN  VARCHAR2 DEFAULT NULL
                          , p_site_key         IN  VARCHAR2 DEFAULT NULL
                          , p_avolent_code     IN  VARCHAR2 DEFAULT NULL
                          , p_bsd_access_code  IN  NUMBER   DEFAULT NULL
                          , p_permission_flag  IN  VARCHAR  DEFAULT NULL
                          , p_resp_key         IN  NUMBER   DEFAULT NULL
                          , p_party_id         IN  NUMBER   DEFAULT NULL
                          , x_retcode          OUT VARCHAR2
                          );

  PROCEDURE insert_ext_user( p_userid           IN  VARCHAR2
                           , p_password         IN  VARCHAR2
                           , p_first_name       IN  VARCHAR2
                           , p_middle_initial   IN  VARCHAR2
                           , p_last_name        IN  VARCHAR2
                           , p_email            IN  VARCHAR
                           , p_party_id         IN  HZ_PARTIES.PARTY_ID%TYPE
                           , p_status           IN  VARCHAR2
                           , p_contact_osr      IN  VARCHAR2
                           , p_acct_site_osr    IN  VARCHAR2
                           , p_site_key         IN  VARCHAR2 
                           , p_avolent_code     IN  VARCHAR2
                           , p_bsd_access_code  IN  NUMBER
                           , p_permission_flag  IN  VARCHAR2
                           , p_resp_key         IN  NUMBER
                           );

  
  PROCEDURE update_ext_user ( p_userid            IN   VARCHAR2
                            , p_bsd_access_code   IN   NUMBER
                            ); 

/*  
  PROCEDURE insert_shipto_map ( p_userid        IN   VARCHAR2
                              , p_acct_site_osr IN   VARCHAR2
                              , p_end_date      IN   DATE default null
                              );

*/
  FUNCTION get_fnd_create_event ( p_subscription_guid IN RAW
                                , p_event     IN OUT NOCOPY WF_EVENT_T
                                )
  RETURN VARCHAR2;
  
  PROCEDURE upd_pwd ( p_userid  IN   VARCHAR2
                    , p_pwd     IN   VARCHAR2
                    );

  PROCEDURE get_resp_id ( p_org_name        IN VARCHAR2
                        , p_bsd_access_code IN NUMBER
                        , x_resp_id         OUT NUMBER
                        , x_appl_id         OUT NUMBER
                        );

END XX_EXTERNAL_USERS_PKG;
/
