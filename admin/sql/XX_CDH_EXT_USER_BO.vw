CREATE OR REPLACE TYPE XX_CDH_EXT_USER_BO AS OBJECT(
  userid                NUMBER,
  password              VARCHAR2(255),
  first_name            VARCHAR2(150),
  middle_initial        VARCHAR2(60),
  last_name             VARCHAR2(150),
  email                 VARCHAR2(255),
  status                VARCHAR2(1),
  action_type           VARCHAR2(30),
  orig_system           VARCHAR2(30),
  cust_acct_osr         VARCHAR2(255),
  contact_osr           VARCHAR2(255),
  acct_site_osr         VARCHAR2(255),
  webuser_osr           VARCHAR2(255),
  record_type           VARCHAR2(60),
  access_code           VARCHAR2(30),
  permission_flag       VARCHAR2(30),
  cust_account_id       NUMBER,
  ship_to_acct_site_id  NUMBER,
  bill_to_acct_site_id  NUMBER,
  party_id              NUMBER,
  STATIC FUNCTION create_object(
    p_userid                IN NUMBER   := null,
    p_password              IN VARCHAR2 := null,
    p_first_name            IN VARCHAR2 := null,
    p_middle_initial        IN VARCHAR2 := null,
    p_last_name             IN VARCHAR2 := null,
    p_email                 IN VARCHAR2 := null,
    p_status                IN VARCHAR2 := null,
    p_action_type           IN VARCHAR2 := null,
    p_orig_system           IN VARCHAR2 := null,
    p_cust_acct_osr         IN VARCHAR2 := null,
    p_contact_osr           IN VARCHAR2 := null,
    p_acct_site_osr         IN VARCHAR2 := null,
    p_webuser_osr           IN VARCHAR2 := null,
    p_record_type           IN VARCHAR2 := null,
    p_access_code           IN VARCHAR2 := null,
    p_permission_flag       IN VARCHAR2 := null,
    p_cust_account_id       IN NUMBER   := null,
    p_ship_to_acct_site_id  IN NUMBER   := null,
    p_bill_to_acct_site_id  IN NUMBER   := null,
    p_party_id              IN NUMBER   := null
  )  RETURN xx_cdh_ext_user_bo
);
/
SHOW ERRORS;
CREATE OR REPLACE TYPE BODY xx_cdh_ext_user_bo AS
  STATIC FUNCTION create_object(
    p_userid                IN NUMBER   := null,
    p_password              IN VARCHAR2 := null,
    p_first_name            IN VARCHAR2 := null,
    p_middle_initial        IN VARCHAR2 := null,
    p_last_name             IN VARCHAR2 := null,
    p_email                 IN VARCHAR2 := null,
    p_status                IN VARCHAR2 := null,
    p_action_type           IN VARCHAR2 := null,
    p_orig_system           IN VARCHAR2 := null,
    p_cust_acct_osr         IN VARCHAR2 := null,
    p_contact_osr           IN VARCHAR2 := null,
    p_acct_site_osr         IN VARCHAR2 := null,
    p_webuser_osr           IN VARCHAR2 := null,
    p_record_type           IN VARCHAR2 := null,
    p_access_code           IN VARCHAR2 := null,
    p_permission_flag       IN VARCHAR2 := null,
    p_cust_account_id       IN NUMBER   := null,
    p_ship_to_acct_site_id  IN NUMBER   := null,
    p_bill_to_acct_site_id  IN NUMBER   := null,
    p_party_id              IN NUMBER   := null
  ) RETURN xx_cdh_ext_user_bo AS
  BEGIN
    RETURN xx_cdh_ext_user_bo(
      userid                => p_userid,              
      password              => p_password,           
      first_name            => p_first_name,          
      middle_initial        => p_middle_initial,      
      last_name             => p_last_name,           
      email                 => p_email,               
      status                => p_status,              
      action_type           => p_action_type,         
      orig_system           => p_orig_system,         
      cust_acct_osr         => p_cust_acct_osr,       
      contact_osr           => p_contact_osr,         
      acct_site_osr         => p_acct_site_osr,       
      webuser_osr           => p_webuser_osr,         
      record_type           => p_record_type,         
      access_code           => p_access_code,         
      permission_flag       => p_permission_flag,     
      cust_account_id       => p_cust_account_id,     
      ship_to_acct_site_id  => p_ship_to_acct_site_id,
      bill_to_acct_site_id  => p_bill_to_acct_site_id,
      party_id              => p_party_id                
    );
  END create_object;
END;
/
SHOW ERRORS;
