create or replace PACKAGE BODY XX_CDH_VPS_CREATE_CUSTOMER
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_VPS_CREATE_CUSTOMER                                                         |
  -- |                                                                                            |
  -- |  Description:  This package is used by REST SERVICES to Create VPS Customers.              |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+
  
--Procedure for logging debug log
PROCEDURE log_debug_msg (
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2
                         ,p_error_message_code  IN VARCHAR2)
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;

BEGIN

    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => 'DEBUG'              --------index exists on program_type
      ,p_attribute15             => p_debug_pkg          --------index exists on attribute15
      ,p_program_id              => 0
      ,p_module_name             => 'VPS'                --------index exists on module_name
      ,p_error_message_code      => p_error_message_code
      ,p_error_message           => p_debug_msg
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_debug_msg;

PROCEDURE Create_Attribute_Groups (p_cust_account_id            IN NUMBER
                                     )
IS
   lc_user_table     								              ego_user_attr_row_table;
   lc_data_table     								              ego_user_attr_data_table;
   lv_failed_row_id_list                 			    VARCHAR2(1000);
   lv_return_status                      			    VARCHAR2(1000);
   lv_errorcode                          				  NUMBER;
   lv_msg_count                          				  NUMBER;
   lv_msg_data                           				  VARCHAR2(1000);
   lv_msg_index_out                               NUMBER;
   l_errors_tbl                                   error_handler.error_tbl_type;
   lv_vps_billing_exception                       VARCHAR2(10);
   lv_vps_sensitive_vendor_flag                   VARCHAR2(10);
   lv_vps_vendor_report_flag                      VARCHAR2(10);
   lv_vps_inv_backup                              VARCHAR2(10);
   lv_vps_tiered_program                          VARCHAR2(10);
   lv_vps_ap_netting_exception                    VARCHAR2(10);
BEGIN
   lv_vps_billing_exception         :=NULL;              
   lv_vps_sensitive_vendor_flag     :=NULL;            
   lv_vps_vendor_report_flag        :=NULL;
   lv_vps_inv_backup                :=NULL;             
   lv_vps_tiered_program            :=NULL;              
   lv_vps_ap_netting_exception      :=NULL;             
BEGIN
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_BILLING_EXCEPTION
  INTO lv_vps_billing_exception
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_BILLING_EXCEPTION';
  EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_billing_exception:=NULL;
  END;
  
  BEGIN
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_SENSITIVE_VENDOR_FLAG
  INTO lv_vps_sensitive_vendor_flag
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_SENSITIVE_VENDOR_FLAG';
  EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_sensitive_vendor_flag:=NULL;
  END;
BEGIN  
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_VENDOR_REPORT_FLAG
  INTO lv_vps_vendor_report_flag
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_VENDOR_REPORT_FLAG';
EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_vendor_report_flag:=NULL;

END;

BEGIN  
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_INV_BACKUP
  INTO lv_vps_inv_backup
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_INV_BACKUP';
EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_inv_backup:=NULL;

END;

BEGIN  
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_TIERED_PROGRAM
  INTO lv_vps_tiered_program
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_TIERED_PROGRAM';
EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_tiered_program:=NULL;

END;

BEGIN  
SELECT decode(upper(eav.default_value),NULL,'N'
                              ,'NO','N'
                              ,'YES','Y')VPS_AP_NETTING_EXCEPTION
  INTO lv_vps_ap_netting_exception
  FROM EGO_ATTRS_V eav
 WHERE eav.attr_group_name = 'XX_CDH_VPS_CUST_ATTR'
    AND eav.attr_group_type ='XX_CDH_CUST_ACCOUNT'
    AND eav.attr_name='VPS_AP_NETTING_EXCEPTION';
EXCEPTION
    WHEN OTHERS THEN 
      lv_vps_ap_netting_exception:=NULL;

END;

lc_user_table := ego_user_attr_row_table(ego_user_attr_row_obj
                                        (row_identifier    => 1,
                                         attr_group_id     => NULL,
                                         attr_group_app_id => 222,
                                         attr_group_type   => 'XX_CDH_CUST_ACCOUNT',
                                         attr_group_name   => 'XX_CDH_VPS_CUST_ATTR',
                                         data_level        => NULL, 
                                         data_level_1      => NULL,
                                         data_level_2      => NULL,
                                         data_level_3      => NULL,
                                         data_level_4      => NULL,
                                         data_level_5      => NULL,
                                         transaction_type  => ego_user_attrs_data_pvt.g_sync_mode)); 

lc_data_table := ego_user_attr_data_table(
                                         ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_CUST_TYPE',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_AR_SUP_SIT_CATEGORY',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                          ,ego_user_attr_data_obj
                                     /*    (row_identifier       => 1,
                                          attr_name            => 'VPS_BILLING_FREQUENCY',
                                          attr_value_str       => P_VPS_BILLING_FREQUENCY,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                         , ego_user_attr_data_obj */
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_BILLING_EXCEPTION',
                                          attr_value_str       => lv_vps_billing_exception,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                          , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_SENSITIVE_VENDOR_FLAG',
                                          attr_value_str       => lv_vps_sensitive_vendor_flag,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_VENDOR_REPORT_FLAG',
                                          attr_value_str       => lv_vps_vendor_report_flag,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_VENDOR_REPOTING_FMT',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_INV_BACKUP',
                                          attr_value_str       => lv_vps_inv_backup,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_TIERED_PROGRAM',
                                          attr_value_str       => lv_vps_tiered_program,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_FOB_DEST_ORIGIN',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_POST_AUDIT_TF',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_SUPPLIER_SITE_PAY_GROUP',
                                          attr_value_str       => NULL,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                          , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_AP_NETTING_EXCEPTION',
                                          attr_value_str       => lv_vps_ap_netting_exception,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                          );
XX_CDH_HZ_EXTENSIBILITY_PUB.Process_Account_Record
                        (   p_api_version           => 1.0,
                            p_cust_account_id       => p_cust_account_id,  
                            p_attributes_row_table  => lc_user_table,
                            p_attributes_data_table => lc_data_table,
                            p_log_errors            => FND_API.G_FALSE,
                            x_failed_row_id_list    => lv_failed_row_id_list, 
                            x_return_status         => lv_return_status,
                            x_errorcode             => lv_errorcode,
                            x_msg_count             => lv_msg_count,
                            x_msg_data              => lv_msg_data
                        );				
  FND_FILE.PUT_LINE(FND_FILE.LOG, ' XX_CDH_HZ_EXTENSIBILITY_PUB API Status, Return Status is: '
                         || lv_return_status
                         || ', Mesage Count is: '
                         || lv_msg_count
                         || ' and Error Message is: '
                         || lv_msg_data
                        );
                        
   IF (LENGTH (lv_failed_row_id_list) > 0)
   THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' XX_CDH_HZ_EXTENSIBILITY_PUB Details of rows which failed: '
                            || lv_failed_row_id_list);
    BEGIN
         error_handler.get_message_list (l_errors_tbl);

         FOR i IN 1 .. l_errors_tbl.COUNT
         LOOP
            FND_FILE.PUT_LINE(FND_FILE.LOG,   'API Error : '
                                  || l_errors_tbl (i).MESSAGE_TEXT);
            FND_FILE.PUT_LINE(FND_FILE.LOG,   'Message Type : '
                                  || l_errors_tbl (i).MESSAGE_TYPE);
         END LOOP;
      END;
   END IF;
END;

Procedure Create_Customer( supplier_nbr           IN         VARCHAR2
                          ,freq_cd                IN         VARCHAR2
                          ,return_status          OUT        VARCHAR2
                          ,error_message          OUT        VARCHAR2
                                         )
IS 
        lv_org_id                       NUMBER;
        lv_error_flag                   VARCHAR2 (1);
        lv_reject_msg_out               VARCHAR2 (1000);
        lv_init_msg_list                VARCHAR2 (1) := 'T';
        lv_msg_count                    NUMBER;
        lv_msg_index_out                NUMBER;
        lv_return_status                VARCHAR2 (1);
        lv_location_id                  NUMBER;
        lv_party_id                     NUMBER;
        lv_parent_party_id              NUMBER;
        lv_profile_id                   NUMBER;
        lv_cust_account_id              NUMBER;
        lv_cust_party_id                NUMBER;
        lv_cust_profile_id              NUMBER;
        lv_responsibility_id            NUMBER;
        lv_party_site_id                NUMBER;
        lv_party_site_number            VARCHAR2 (50);
        lv_bill_cust_acct_site_id       NUMBER;
        lv_bill_party_site_use_id       NUMBER;
        lv_bill_site_use_id             NUMBER;
        lv_duns_party_id                NUMBER;
        lv_party_rel_id                 NUMBER;
        lv_cust_account_role_id         NUMBER;
        lv_contact_point_id             NUMBER;
        lv_party_number                 VARCHAR2 (50);
        lv_cust_party_number            VARCHAR2 (100);
        lv_cust_account_number          VARCHAR2 (100);
        lv_party_site_rec               hz_party_site_v2pub.party_site_rec_type;
        lv_relationship_rec_type        hz_relationship_v2pub.relationship_rec_type;
        lv_bill_person_record           hz_party_v2pub.person_rec_type;
        lv_relationship_id              NUMBER;
        lv_rel_party_id                 NUMBER;
        lv_rel_party_number             VARCHAR2 (50);
        lv_bill_party_id                NUMBER;
        lv_bill_party_number            VARCHAR2(50);
        lv_ship_to_party_site_id        NUMBER;
        lv_ship_to_party_site_number    VARCHAR2 (50);
        lv_ship_party_site_use_id       NUMBER;
        lv_ship_site_use_id             NUMBER;
        lv_ship_cust_acct_site_id       NUMBER;
        lv_msg_data                     VARCHAR2 (2000);
        lv_output                       VARCHAR2 (4000);
        lv_msg_dummy                    VARCHAR2 (2000);
        lv_err_msg                      VARCHAR2 (2000);
        lv_bill_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
        lv_ship_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
        lv_organization_rec             hz_party_v2pub.organization_rec_type;
        lv_organization_rec_null        hz_party_v2pub.organization_rec_type;
        lv_cust_account_rec             hz_cust_account_v2pub.cust_account_rec_type;
        lv_customer_profile_rec         hz_customer_profile_v2pub.customer_profile_rec_type;
        lv_profile_class_amt_rec        hz_cust_prof_class_amts%ROWTYPE;
        lv_profile_amt_rec              hz_customer_profile_v2pub.cust_profile_amt_rec_type;
        lv_role_responsibility_rec      hz_cust_account_role_v2pub.role_responsibility_rec_type;
        lv_bill_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
        lv_ship_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
        lv_bill_party_site_use_rec      hz_party_site_v2pub.party_site_use_rec_type;
        lv_ship_party_site_use_rec      hz_party_site_v2pub.party_site_use_rec_type;
        lv_bill_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
        lv_ship_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
        lv_cust_profile_amt_rec         hz_customer_profile_v2pub.cust_profile_amt_rec_type;
        lv_ship_contact_point_id        NUMBER;
        lv_ship_acct_role_id            NUMBER;
        lv_ship_party_id                NUMBER;
        lv_person_record                hz_party_v2pub.person_rec_type;
        lv_ship_party_number            VARCHAR2(50);
        lv_sorg_party_number            VARCHAR2(50);
        lv_ship_contact_id              NUMBER;
        lv_sorg_party_id                NUMBER;
        lv_ship_profile_id              NUMBER;
        lv_ship_party_rel_id            NUMBER;
        lv_prfl_amt_id                  NUMBER;
        lv_object_version_number        NUMBER;
        lv_curr_code                    VARCHAR2 (100);
        lv_collector_id                 NUMBER;
        lv_version_number               NUMBER;
        l_user_id                       NUMBER;
        l_responsibility_id             NUMBER;
        l_responsibility_appl_id        NUMBER;
        lv_vendor_name                  hz_cust_accounts.account_name%type;
        lv_vendor_num                   ap_suppliers.segment1%TYPE;
        lv_profile_class_id             hz_cust_profile_classes.profile_class_id%TYPE;
        lv_prf_status                   hz_cust_profile_classes.status%TYPE;
        lv_credit_check                 hz_cust_profile_classes.credit_checking%TYPE;
        lv_standard_terms               hz_cust_profile_classes.standard_terms%TYPE;
        lv_override_terms               hz_cust_profile_classes.override_terms%TYPE;
        lv_vendor_site_code             ap_supplier_sites_all.vendor_site_code%TYPE;
        lv_sqlerrm                      VARCHAR2(250);
--Create customer through REST Services  
  CURSOR cur_vendor (supplier_nbr varchar2)
IS
  select ssa.location_id
        ,sup.vendor_name
       -- ,ltrim(NVL(ssa.attribute9,(NVL(ssa.attribute7,NVL(ssa.vendor_site_code_alt,ssa.vendor_site_id)))),'0') as attribute9
       ,ltrim(ssa.vendor_site_code_alt,'0') as attribute9
        ,sup.party_id
        ,ssa.vendor_site_code
  from   AP_SUPPLIER_SITES_ALL ssa
        ,AP_SUPPLIERS          sup
  where  1=1
  and    sup.vendor_id = ssa.vendor_id
  and    ltrim(ssa.vendor_site_code_alt,'0')=supplier_nbr
  and    ssa.attribute8 like 'TR%'
  --and ltrim(NVL(ssa.attribute9,(NVL(ssa.attribute7,NVL(ssa.vendor_site_code_alt,vendor_site_id)))),'0')=supplier_nbr
  --and    ssa.vendor_site_code=p_vendor_site_code
  and    ssa.pay_site_flag='Y'
  and  	( ssa.inactive_date IS NULL
			 OR  ssa.inactive_date > SYSDATE); 

BEGIN
log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Start:'||supplier_nbr,return_status);
  	--Start apps intialization
     SELECT organization_id 
      INTO lv_org_id
      FROM hr_operating_units
    WHERE name='OU_US_VPS';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id  : ' || lv_org_id);
		mo_global.set_policy_context('S',lv_org_id); 
 	BEGIN
    SELECT user_id,
           responsibility_id,
           responsibility_application_id
    INTO   l_user_id,
           l_responsibility_id,
           l_responsibility_appl_id
      FROM fnd_user_resp_groups
     WHERE user_id=(SELECT user_id
                      FROM fnd_user
                     WHERE user_name='ODCDH')
     AND   responsibility_id=(SELECT responsibility_id
                                FROM FND_RESPONSIBILITY
                               WHERE responsibility_key = 'OD_US_VPS_CDH_ADMINSTRATOR');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
   EXCEPTION
    WHEN OTHERS THEN
    return_status:='E';
    lv_sqlerrm:=SUBSTR(SQLERRM,1,255);
    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','App Intialization'||lv_sqlerrm,return_status);
   END; ---END apps intialization
 --Cust Profile
 BEGIN
    SELECT profile_class_id
          ,status
          ,credit_checking
          ,standard_terms
          ,override_terms
    INTO  lv_profile_class_id            
        ,lv_prf_status
        ,lv_credit_check                 
        ,lv_standard_terms               
        ,lv_override_terms               
    FROM hz_cust_profile_classes
    WHERE name ='VPS_CUSTOMER'; 
  EXCEPTION
  WHEN OTHERS THEN
    lv_sqlerrm:=SUBSTR(SQLERRM,1,200); 
    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Customer Profile'||lv_sqlerrm,return_status);
   END;
		-- Initialize Variables.
            return_status                := NULL;
            error_message                := NULL;
            lv_reject_msg_out            := NULL;
            lv_msg_count                 := NULL;
            lv_msg_index_out             := NULL;
            lv_return_status             := NULL;
            lv_msg_data                  := NULL;
            lv_output                    := NULL;
            lv_err_msg                   := NULL;
            lv_location_id               := NULL;
            lv_party_id                  := NULL;
            lv_parent_party_id           := NULL;
            lv_profile_id                := NULL;
            lv_cust_account_id           := NULL;
            lv_cust_party_id             := NULL;
            lv_cust_profile_id           := NULL;
            lv_responsibility_id         := NULL;
            lv_bill_cust_acct_site_id    := NULL;
            lv_bill_party_site_use_id    := NULL;
            lv_bill_site_use_id          := NULL;
            lv_duns_party_id             := NULL;
            lv_party_site_number         := NULL;
            lv_party_number              := NULL;
            lv_cust_party_number         := NULL;
            lv_cust_account_number       := NULL;
            lv_bill_party_site_rec       := NULL;
            lv_ship_party_site_rec       := NULL;
            lv_organization_rec          := NULL;
            lv_organization_rec_null     := NULL;
            lv_cust_account_rec          := NULL;
            lv_customer_profile_rec      := NULL;
            lv_profile_class_amt_rec     := NULL;
            lv_profile_amt_rec           := NULL;
            lv_bill_cust_site_use_rec    := NULL;
            lv_ship_cust_site_use_rec    := NULL;
            lv_bill_party_site_use_rec   := NULL;
            lv_ship_party_site_use_rec   := NULL;
            lv_bill_cust_acct_site_rec   := NULL;
            lv_ship_cust_acct_site_rec   := NULL;
            lv_ship_to_party_site_id     := NULL;
            lv_ship_to_party_site_number := NULL;
            lv_ship_party_site_use_id    := NULL;
            lv_ship_site_use_id          := NULL;
            lv_ship_cust_site_use_rec    := NULL;
            lv_vendor_num                := NULL;
            lv_vendor_name               := NULL;
            lv_vendor_site_code          := NULL;

    open cur_vendor (supplier_nbr);
    fetch cur_vendor into lv_location_id,lv_vendor_name,lv_vendor_num,lv_parent_party_id,lv_vendor_site_code;
    close cur_vendor;
    IF lv_vendor_num IS NULL THEN 
      lv_return_status:='E';
      return_status :=  lv_return_status;
      error_message :='No Vendor Found in Oracle';
    ELSE
		----------------------------------------------------------------------------
         --   create organization
		----------------------------------------------------------------------------
      lv_organization_rec.organization_name               := lv_vendor_name||'-'||lv_vendor_num;
      lv_organization_rec.created_by_module               :='TCA_V2_API';
      lv_organization_rec.party_rec.orig_system_reference :=supplier_nbr || '-VPS' ;
         hz_party_v2pub.create_organization
                                    (p_init_msg_list =>         lv_init_msg_list
                                    ,p_organization_rec =>      lv_organization_rec
                                    ,x_party_id =>              lv_party_id
                                    ,x_party_number =>          lv_party_number
                                    ,x_profile_id =>            lv_profile_id
                                    ,x_return_status =>         lv_return_status
                                    ,x_msg_count =>             lv_msg_count
                                    ,x_msg_data =>              lv_msg_data);
		 --If API fails
        IF lv_return_status <> 'S' THEN
          return_status     :=lv_return_status;
          FOR i IN 1 .. lv_msg_count
          LOOP
            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
            error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
          END LOOP;
          log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Organization'||error_message,return_status);
        ELSE
          log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Organization:'||lv_party_id,return_status);
            ---------------------------------------------------------------------------- 
            --Create Account
            ----------------------------------------------------------------------------
                lv_organization_rec.party_rec.party_id    := lv_party_id;
                --lv_organization_rec.party_rec.party_number:= lv_party_number;
                lv_cust_account_rec.account_name          := lv_vendor_name||'-'||lv_vendor_num;
                lv_cust_account_rec.orig_system           := 'VPS';
                lv_cust_account_rec.orig_system_reference := supplier_nbr||'-VPS' ;
                lv_cust_account_rec.created_by_module     := 'TCA_V2_API';
                -- Cust Profile
                lv_customer_profile_rec.profile_class_id  :=lv_profile_class_id;
                lv_customer_profile_rec.status            :=lv_prf_status;
                lv_customer_profile_rec.credit_checking   :=lv_credit_check;
                lv_customer_profile_rec.standard_terms    :=lv_standard_terms;
                lv_customer_profile_rec.override_terms    :=lv_override_terms;
                 hz_cust_account_v2pub.create_cust_account
                                     (p_init_msg_list =>             lv_init_msg_list
                                     ,p_cust_account_rec =>          lv_cust_account_rec
                                     ,p_organization_rec =>          lv_organization_rec
                                     ,p_customer_profile_rec =>      lv_customer_profile_rec
                                     ,p_create_profile_amt =>        'T'
                                     ,x_cust_account_id =>           lv_cust_account_id
                                     ,x_account_number =>            lv_cust_account_number
                                     ,x_party_id =>                  lv_cust_party_id
                                     ,x_party_number =>              lv_cust_party_number
                                     ,x_profile_id =>                lv_cust_profile_id
                                     ,x_return_status =>             lv_return_status
                                     ,x_msg_count =>                 lv_msg_count
                                     ,x_msg_data =>                  lv_msg_data);
             --If API fails
                  IF lv_return_status <> 'S' THEN
                    return_status     :=lv_return_status;
                    FOR i IN 1 .. lv_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                      error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                    END LOOP;
                    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Account'||error_message,return_status);
                  ELSE
                    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Account Number:'||lv_cust_account_number,return_status);
                    ----------------------------------------------------------------------------
                    --Create party site 
                    ----------------------------------------------------------------------------
                          lv_party_site_rec.identifying_address_flag := 'Y';
                          lv_party_site_rec.status                   := 'A';
                          lv_party_site_rec.party_id                 := lv_party_id;
                          lv_party_site_rec.location_id              := lv_location_id;
                          lv_party_site_rec.created_by_module        := 'TCA_V2_API';
                         hz_party_site_v2pub.create_party_site
                                                   (p_init_msg_list =>          lv_init_msg_list
                                                   ,p_party_site_rec =>         lv_party_site_rec
                                                   ,x_party_site_id =>          lv_party_site_id
                                                   ,x_party_site_number =>      lv_party_site_number
                                                   ,x_return_status =>          lv_return_status
                                                   ,x_msg_count =>              lv_msg_count
                                                   ,x_msg_data =>               lv_msg_data);
                     --If API fails
                    IF lv_return_status <> 'S'
                      THEN
                      lv_error_flag :='Y';
                          FOR i IN 1 .. lv_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                            lv_output := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                          END LOOP;
                          log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Party Site'||error_message,return_status);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'PartySiteId: ' || lv_output);	
                    ELSE
                      log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Party Site:'||lv_party_site_id,return_status);
                    ----------------------------------------------------------------------------
                    -- Create Cust Acct Site BILL TO 
                    ----------------------------------------------------------------------------
                         lv_bill_cust_acct_site_rec.cust_account_id       := lv_cust_account_id;
                          lv_bill_cust_acct_site_rec.party_site_id         := lv_party_site_id;
                          lv_bill_cust_acct_site_rec.orig_system           := 'VPS';
                          lv_bill_cust_acct_site_rec.orig_system_reference := supplier_nbr||'-01-'||'VPS' ;
                          lv_bill_cust_acct_site_rec.created_by_module     :='TCA_V2_API';
                         hz_cust_account_site_v2pub.create_cust_acct_site
                                                                         (lv_init_msg_list
                                                                         ,lv_bill_cust_acct_site_rec
                                                                         ,lv_bill_cust_acct_site_id
                                                                         ,lv_return_status
                                                                         ,lv_msg_count
                                                                         ,lv_msg_data);
                     --If API fails
                          IF lv_return_status <> 'S' THEN
                            return_status:=lv_return_status;
                            FOR i IN 1 .. lv_msg_count
                            LOOP
                              fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                              error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                            END LOOP;
                            log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create CustAcctSite'||error_message,return_status);
                          ELSE
                            log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create CustAcctSite OSR:'||lv_bill_cust_acct_site_rec.orig_system_reference,return_status);
                        ----------------------------------------------------------------------------
                          --Create party site use BILL TO 
                        ----------------------------------------------------------------------------
                              lv_bill_party_site_use_rec.site_use_type     := 'BILL_TO';
                              lv_bill_party_site_use_rec.primary_per_type  := 'Y';
                              lv_bill_party_site_use_rec.party_site_id     := lv_party_site_id;
                              lv_bill_party_site_use_rec.status            := 'A';
                              lv_bill_party_site_use_rec.created_by_module :='TCA_V2_API';                            
                             hz_party_site_v2pub.create_party_site_use
                                                     (p_init_msg_list =>           lv_init_msg_list
                                                     ,p_party_site_use_rec =>      lv_bill_party_site_use_rec
                                                     ,x_party_site_use_id =>       lv_bill_party_site_use_id
                                                     ,x_return_status =>           lv_return_status
                                                     ,x_msg_count =>               lv_msg_count
                                                     ,x_msg_data =>                lv_msg_data);
                         --If API fails
                                  IF lv_return_status <> 'S' THEN
                                    return_status:=lv_return_status;
                                    FOR i IN 1 .. lv_msg_count
                                    LOOP
                                      fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                                      error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                                    END LOOP;
                                    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create PartySiteUse'||error_message,return_status);
                                  ELSE
                                   
                                    log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create BILL_TO PartySiteUseId:'||lv_bill_party_site_use_id,return_status);
                                  ----------------------------------------------------------------------------
                                    -- Create Cust site use BILL TO 
                                  ----------------------------------------------------------------------------
                                      lv_bill_cust_site_use_rec.cust_acct_site_id     := lv_bill_cust_acct_site_id;
                                      lv_bill_cust_site_use_rec.site_use_code         := 'BILL_TO';
                                      lv_bill_cust_site_use_rec.primary_flag          := 'Y';
                                      lv_bill_cust_site_use_rec.status                := 'A';
                                      lv_bill_cust_site_use_rec.orig_system           := 'VPS';
                                      lv_bill_cust_site_use_rec.orig_system_reference := supplier_nbr||'-01-VPS-BILL_TO' ;
                                      lv_bill_cust_site_use_rec.created_by_module     :='TCA_V2_API';
                                      lv_bill_cust_site_use_rec.location              := lv_vendor_site_code||'-BILLTO'; 
                                       hz_cust_account_site_v2pub.create_cust_site_use
                                                                                     ('T'
                                                                                     ,lv_bill_cust_site_use_rec
                                                                                     ,NULL
                                                                                     ,'F'
                                                                                     ,'F'
                                                                                     ,lv_bill_site_use_id
                                                                                     ,lv_return_status
                                                                                     ,lv_msg_count
                                                                                     ,lv_msg_data);
                                           --If API fails
                                      IF lv_return_status <> 'S' THEN
                                        return_status:=lv_return_status;
                                        FOR i IN 1 .. lv_msg_count
                                        LOOP
                                          fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                                          error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                                        END LOOP;
                                        log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create CustSiteUSe'||error_message,return_status);
                                        
                                      ELSE
                                        log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create BILL_TO OSR:'||lv_bill_cust_site_use_rec.orig_system_reference,return_status);
                                      ------------------------------------------------------------------
                                      --Create party site use SHIP TO  
                                      -------------------------------------------------------------------
                                            lv_ship_party_site_use_rec.site_use_type     := 'SHIP_TO';
                                            lv_ship_party_site_use_rec.primary_per_type  := 'Y';
                                            lv_ship_party_site_use_rec.party_site_id     := lv_party_site_id ;
                                            lv_ship_party_site_use_rec.status            := 'A';
                                            lv_ship_party_site_use_rec.created_by_module :='TCA_V2_API';                            
                                             hz_party_site_v2pub.create_party_site_use
                                                                     (p_init_msg_list =>           lv_init_msg_list
                                                                     ,p_party_site_use_rec =>      lv_ship_party_site_use_rec
                                                                     ,x_party_site_use_id =>       lv_ship_party_site_use_id
                                                                     ,x_return_status =>           lv_return_status
                                                                     ,x_msg_count =>               lv_msg_count
                                                                     ,x_msg_data =>                lv_msg_data);
                                                IF lv_return_status <> 'S' THEN
                                                  return_status:=lv_return_status;
                                                  FOR i IN 1 .. lv_msg_count
                                                  LOOP
                                                    fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                                                    error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                                                  END LOOP;
                                                  log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create PartySiteUse'||error_message,return_status);
                                                ELSE
                                                  log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create SHIP_TO PartySiteUseId:'||lv_ship_party_site_use_id,return_status);
                                                ------------------------------------------------------------------------------
                                                -- Create Cust site use SHIP TO 
                                                ------------------------------------------------------------------------------
                                                      lv_ship_cust_site_use_rec.cust_acct_site_id     := lv_bill_cust_acct_site_id;
                                                      lv_ship_cust_site_use_rec.site_use_code         := 'SHIP_TO';
                                                      --    lv_ship_cust_site_use_rec.primary_flag := 'Y';
                                                      lv_ship_cust_site_use_rec.status                := 'A';
                                                      lv_ship_cust_site_use_rec.orig_system           := 'VPS';
                                                      lv_ship_cust_site_use_rec.orig_system_reference := supplier_nbr ||'-01-VPS-SHIP_TO' ;
                                                      lv_ship_cust_site_use_rec.created_by_module     :='TCA_V2_API';
                                                      lv_ship_cust_site_use_rec.location              := lv_vendor_site_code||'-SHIPTO';
                                                       hz_cust_account_site_v2pub.create_cust_site_use
                                                                                                     ('T'
                                                                                                     ,lv_ship_cust_site_use_rec
                                                                                                     ,NULL
                                                                                                     ,'F'
                                                                                                     ,'F'
                                                                                                     ,lv_ship_site_use_id
                                                                                                     ,lv_return_status
                                                                                                     ,lv_msg_count
                                                                                                     ,lv_msg_data);
                                                    
                                                          IF lv_return_status <> 'S' THEN
                                                            return_status:=lv_return_status;
                                                            FOR i IN 1 .. lv_msg_count
                                                            LOOP
                                                              fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                                                              error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                                                            END LOOP;
                                                            log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create CustSiteUseSHIPTO'||error_message,return_status);
                                                          ELSE 
                                                            log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create SHIP_TO CustAcctSiteUseId:'||lv_ship_site_use_id,return_status);
                                                          --------------------------------------------------------------------------
                                                            -- Party Relation Ship
                                                            --------------------------------------------------------------------------
                                                           lv_relationship_rec_type.relationship_type  := UPPER ( 'OD_FIN_PAY_WITHIN' ) ;
                                                           lv_relationship_rec_type.relationship_code  := UPPER ( 'PAYER_GROUP_PARENT_OF' ) ;
                                                           lv_relationship_rec_type.subject_id         := lv_parent_party_id; --Parent parent id
                                                           lv_relationship_rec_type.subject_table_name := UPPER ( 'HZ_PARTIES' ) ;
                                                           lv_relationship_rec_type.subject_type       := UPPER ( 'ORGANIZATION' ) ;
                                                           lv_relationship_rec_type.object_id          := lv_party_id; --Child Parent Id
                                                           lv_relationship_rec_type.object_table_name  := UPPER ( 'HZ_PARTIES' ) ;
                                                           lv_relationship_rec_type.object_type        := UPPER ( 'ORGANIZATION' ) ;
                                                           lv_relationship_rec_type.start_date         := SYSDATE;
                                                           lv_relationship_rec_type.created_by_module  := 'TCA_V2_API';
                                                           hz_relationship_v2pub.create_relationship ( 
                                                                                                        p_init_msg_list     => 'T', 
                                                                                                        p_relationship_rec  => lv_relationship_rec_type, 
                                                                                                        x_relationship_id   => lv_relationship_id, 
                                                                                                        x_party_id          => lv_rel_party_id, 
                                                                                                        x_party_number      => lv_rel_party_number, 
                                                                                                        x_return_status     => lv_return_status, 
                                                                                                        x_msg_count         => lv_msg_count, 
                                                                                                        x_msg_data          => lv_msg_data 
                                                                                                     ) ;
                                                            IF lv_return_status <> 'S'
                                                              THEN
                                                              return_status:=lv_return_status;
                                                              FOR i IN 1 .. lv_msg_count
                                                              LOOP
                                                                fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                                                                error_message := (TO_CHAR (i) || ': ' || lv_msg_data)||'|'||SYSDATE;
                                                              END LOOP;
                                                                log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Relationship:'||error_message,return_status);	
                                                             ELSE
                                                                 return_status:=lv_return_status;
                                                                 log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Create Relationship Party Id:'||lv_rel_party_id,return_status);
                                                                 --Calling Ext Attribute
                                                                  Create_Attribute_Groups ( lv_cust_account_id);
                                                            END IF;
                                                          END IF;  
                                                          END IF;
                                                        END IF;
                                                      END IF;
                                                    END IF;
                                                  END IF;
                                              END IF;
                                            END IF;
                                        END IF; -- Vendor Num Existence
                                          
    IF lv_return_status='E' THEN
      return_status :=  'E';
      error_message:=error_message;
      ROLLbACK;
    ELSE
      return_status :=  'S';
      error_message:='Success';
      COMMIT;
    END IF;
  log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','End:'||supplier_nbr,'');
EXCEPTION
  WHEN OTHERS THEN
  return_status :=  'E';
  error_message := SUBSTR(sqlerrm,1,200)||'|'||SYSDATE;
  log_debug_msg('XX_CDH_VPS_CREATE_CUSTOMER.Create_Customer','Unexpected Error:'||error_message,return_status);
END Create_Customer;
END XX_CDH_VPS_CREATE_CUSTOMER;
/