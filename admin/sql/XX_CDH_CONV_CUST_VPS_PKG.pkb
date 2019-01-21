create or replace PACKAGE BODY      XX_CDH_CONV_CUST_VPS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_CDH_CONV_CUST_VPS_PKG                                                     	    |
  -- |                                                                                            |
  -- |  Description:  This package is used to create VPS customers for vendor sites.        	    |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         01-JUNE-2017  Thejaswini Rajula    Initial version                             |
  -- +============================================================================================+
  
g_conc_request_id                       NUMBER:= fnd_global.conc_request_id;
g_total_records                         NUMBER;
--Procedure for logging debug log
PROCEDURE log_debug_msg (
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2
                         ,p_error_message_code IN VARCHAR2)
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

PROCEDURE Update_Requestid
IS
BEGIN

    UPDATE xx_cdh_vps_customer_stg
       SET request_id             = g_conc_request_id
    WHERE request_id          IS NULL
      AND NVL(record_status,'N') ='N';
    g_total_records           := SQL%ROWCOUNT;
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Request Id :'||fnd_global.conc_request_id);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Records Selected from xx_cdh_vps_customer_stg :'||SQL%ROWCOUNT);
    COMMIT;
END Update_Requestid;

procedure Create_Contacts(p_contact_fname           IN VARCHAR2
                          ,p_contact_lname          IN VARCHAR2
                          ,p_contact_job_title      IN VARCHAR2
                          ,p_contact_email          IN VARCHAR2
                          ,p_contact_phone          IN VARCHAR2
                          ,p_party_id               IN NUMBER
                          ,p_cust_account_id        IN NUMBER
                          ,p_bill_cust_acct_site_id IN NUMBER
						  )
IS
        lv_cp_record                   hz_party_v2pub.person_rec_type;
        lv_cp_party_id                 NUMBER;
        lv_cp_party_number             VARCHAR2(50);
        lv_cp_profile_id               NUMBER;
        lv_corg_contact_rec            hz_party_contact_v2pub.org_contact_rec_type;
        lv_corg_contact_id             NUMBER;
        lv_corg_party_rel_id           NUMBER;
        lv_corg_party_id               NUMBER;
        lv_corg_party_number           VARCHAR2(50);
        lv_cporg_contact_point_rec     hz_contact_point_v2pub.contact_point_rec_type;
        lv_cporg_email_rec             hz_contact_point_v2pub.email_rec_type;
        lv_cporg_phone_rec             hz_contact_point_v2pub.phone_rec_type;
        lv_cporg_contact_point_id      NUMBER;
        lv_ceorg_contact_point_rec     hz_contact_point_v2pub.contact_point_rec_type;
        lv_ceorg_email_rec             hz_contact_point_v2pub.email_rec_type;
        lv_ceorg_phone_rec             hz_contact_point_v2pub.phone_rec_type;
        lv_ceorg_contact_point_id      NUMBER;
        lv_corg_acct_role_rec          hz_cust_account_role_v2pub.cust_account_role_rec_type;
        lv_corg_acct_role_id           NUMBER;
        lv_corg_role_resp_rec          hz_cust_account_role_v2pub.role_responsibility_rec_type;
        lv_corg_responsibility_id      NUMBER;
        lv_error_flag                   VARCHAR2 (1);
        lv_reject_msg_out               VARCHAR2 (1000);
        lv_init_msg_list                VARCHAR2 (1) := 'T';
        lv_msg_count                    NUMBER;
        lv_msg_index_out                NUMBER;
        lv_output                       VARCHAR2(4000);
        lv_return_status                VARCHAR2(1);
        lv_msg_data                     VARCHAR2 (2000);
        lv_msg_dummy                    VARCHAR2 (2000);
        lv_err_msg                      VARCHAR2 (2000);
BEGIN
        lv_cp_party_id             := NULL;
        lv_cp_party_number         := NULL;
        lv_cp_profile_id           := NULL;
        lv_corg_contact_rec        := NULL;
        lv_corg_contact_id         := NULL;
        lv_corg_party_rel_id       := NULL;
        lv_corg_party_id           := NULL;
        lv_corg_party_number       := NULL;
        lv_cporg_contact_point_rec := NULL;
        lv_cporg_email_rec         := NULL;
        lv_cporg_phone_rec         := NULL;
        lv_cporg_contact_point_id  := NULL;
        lv_ceorg_contact_point_rec := NULL;
        lv_ceorg_email_rec         := NULL;
        lv_ceorg_phone_rec         := NULL;
        lv_ceorg_contact_point_id  := NULL;
        lv_corg_acct_role_rec      := NULL;
        lv_corg_acct_role_id       := NULL;
        lv_corg_role_resp_rec      := NULL;
        lv_corg_responsibility_id  := NULL;
        lv_error_flag              := NULL;
        lv_reject_msg_out          := NULL;
        lv_init_msg_list           := NULL;
        lv_msg_count               := NULL;
        lv_msg_dummy               := NULL;
        lv_output                  := NULL;
        lv_return_status           := NULL;
        lv_msg_data                := NULL;
	--Create Person
          lv_cp_record.person_first_name  := p_contact_fname;
          lv_cp_record.person_middle_name := fnd_api.g_miss_char;
          lv_cp_record.person_last_name   := p_contact_lname;
          lv_cp_record.person_name_suffix := fnd_api.g_miss_char;
          lv_cp_record.created_by_module  := 'TCA_V2_API';
         hz_party_v2pub.create_person (p_init_msg_list =>      lv_init_msg_list
                                      ,p_person_rec =>         lv_cp_record
                                      ,x_party_id =>           lv_cp_party_id
                                      ,x_party_number =>       lv_cp_party_number
                                      ,x_profile_id =>         lv_cp_profile_id
                                      ,x_return_status =>      lv_return_status
                                      ,x_msg_count =>          lv_msg_count
                                      ,x_msg_data =>           lv_msg_data);
            --If API fails
            IF lv_return_status <> 'S' THEN
              lv_error_flag     :='Y';
              FOR i IN 1 .. lv_msg_count
              LOOP
                fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
              END LOOP;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'ContactPerson: ' || lv_output);
            ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create ContactPerson: ' || lv_cp_party_id);
          --Link person to organization
                lv_corg_contact_rec.job_title_code                   := NULL;
                lv_corg_contact_rec.job_title                        := p_contact_job_title; 
                lv_corg_contact_rec.created_by_module                := 'TCA_V2_API';
                lv_corg_contact_rec.party_rel_rec.subject_id         := lv_cp_party_id;
                lv_corg_contact_rec.party_rel_rec.subject_type       := 'PERSON';
                lv_corg_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                lv_corg_contact_rec.party_rel_rec.object_id          := p_party_id;
                lv_corg_contact_rec.party_rel_rec.object_type        := 'ORGANIZATION';
                lv_corg_contact_rec.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                lv_corg_contact_rec.party_rel_rec.relationship_code  := 'CONTACT_OF';
                lv_corg_contact_rec.party_rel_rec.relationship_type  := 'CONTACT';
                lv_corg_contact_rec.party_rel_rec.start_date         := SYSDATE;
                hz_party_contact_v2pub.create_org_contact
                              (p_init_msg_list =>        lv_init_msg_list
                              ,p_org_contact_rec =>      lv_corg_contact_rec
                              ,x_org_contact_id =>       lv_corg_contact_id
                              ,x_party_rel_id =>         lv_corg_party_rel_id
                              ,x_party_id =>             lv_corg_party_id
                              ,x_party_number =>         lv_corg_party_number
                              ,x_return_status =>        lv_return_status
                              ,x_msg_count =>            lv_msg_count
                              ,x_msg_data =>             lv_msg_data);
                  --If API fails
                IF lv_return_status <> 'S' THEN
                  lv_error_flag     :='Y';
                  FOR i IN 1 .. lv_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                    lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                  END LOOP;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'OrgContact: ' || lv_output);
                ELSE
                  --Create Phone Contact Point
                    lv_cporg_contact_point_rec.contact_point_type    := 'PHONE';
                    lv_cporg_contact_point_rec.owner_table_name      := 'HZ_PARTIES';
                    lv_cporg_contact_point_rec.owner_table_id        := lv_corg_party_id;
                    lv_cporg_contact_point_rec.contact_point_purpose := 'BUSINESS';
                    lv_cporg_contact_point_rec.created_by_module     := 'TCA_V2_API';
                    lv_cporg_email_rec.email_format                  := 'MAILHTML';
                    lv_cporg_email_rec.email_address                 := p_contact_email;
                    --  lv_bill_phone_rec.phone_area_code               := stg_tbl_rec.phone_area_code;
                    --  l_phone_rec.phone_country_code               := stg_tbl_rec.phone_country_code;
                    --  lv_corg1_phone_rec.phone_number                  := stg_tbl_rec.contact_phone1;
                    lv_cporg_phone_rec.raw_phone_number                :=p_contact_phone;
                    lv_cporg_phone_rec.phone_line_type                 :='GEN';
                    --   l_phone_rec.phone_extension                  := stg_tbl_rec.phone_extension;
                    HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
                                             (p_init_msg_list          => 'T',
                                            p_contact_point_rec      => lv_cporg_contact_point_rec,
                                            p_edi_rec                => null,
                                            p_email_rec              => lv_cporg_email_rec,
                                            p_phone_rec              => lv_cporg_phone_rec,
                                            p_telex_rec              => null,
                                            p_web_rec                => null,
                                            x_contact_point_id       => lv_cporg_contact_point_id  ,
                                            x_return_status          => lv_return_status,
                                            x_msg_count              => lv_msg_count,
                                            x_msg_data               => lv_msg_data
                                             );
                    IF lv_return_status <> 'S' THEN
                      lv_error_flag     :='Y';
                      FOR i IN 1 .. lv_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                        lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                      END LOOP;
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' Phone ContactPoint: ' || lv_output);
                    ELSE
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Phone ContactPoint : ' || lv_cporg_contact_point_id);
                    END IF;
                --Create Email Contact Point
                    lv_ceorg_contact_point_rec.contact_point_type := 'EMAIL';
                    lv_ceorg_contact_point_rec.owner_table_name   := 'HZ_PARTIES';
                    lv_ceorg_contact_point_rec.owner_table_id     := lv_corg_party_id;
                    lv_ceorg_contact_point_rec.contact_point_purpose := 'BUSINESS';
                    lv_ceorg_contact_point_rec.created_by_module     := 'TCA_V2_API';
                    lv_ceorg_email_rec.email_format                  := 'MAILHTML';
                    lv_ceorg_email_rec.email_address                 := p_contact_email;
                   HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
                               (p_init_msg_list          => 'T',
                              p_contact_point_rec      => lv_ceorg_contact_point_rec,
                              p_edi_rec                => null,
                              p_email_rec              => lv_ceorg_email_rec,
                              p_phone_rec              => lv_ceorg_phone_rec,
                              p_telex_rec              => null,
                              p_web_rec                => null,
                              x_contact_point_id       => lv_ceorg_contact_point_id  ,
                              x_return_status          => lv_return_status,
                              x_msg_count              => lv_msg_count,
                              x_msg_data               => lv_msg_data
                               );
                  IF lv_return_status <> 'S' THEN
                    lv_error_flag     :='Y';
                    FOR i IN 1 .. lv_msg_count
                    LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                    lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                    END LOOP;
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ContactPoint: ' || lv_output);
                  ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Email ContactPoint : ' || lv_ceorg_contact_point_id);
                  -- Link organization to customer account BILL TO site
                      lv_corg_acct_role_rec.created_by_module := 'TCA_V2_API';
                      lv_corg_acct_role_rec.party_id          := lv_corg_party_id;  --Party id from org contact
                      lv_corg_acct_role_rec.cust_account_id   := p_cust_account_id; -- value of cust_account_id
                      lv_corg_acct_role_rec.cust_acct_site_id := p_bill_cust_acct_site_id;
                      lv_corg_acct_role_rec.role_type         := 'CONTACT';
                      lv_corg_acct_role_rec.status            := 'A';
                      HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list     =>  'T'       ,
                                         p_cust_account_role_rec => lv_corg_acct_role_rec,
                                         x_cust_account_role_id=> lv_corg_acct_role_id,
                                         x_return_status     =>  lv_return_status    ,
                                         x_msg_count         =>  lv_msg_count        ,
                                         x_msg_data          =>  lv_msg_data);
                IF lv_return_status <> 'S' THEN
                  lv_error_flag     :='Y';
                  FOR i IN 1 .. lv_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                    lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                  END LOOP;
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'ContactCustAcctRole: ' || lv_output);
                ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'Create ContactCustAcctRole: ' || lv_corg_acct_role_id );
                END IF;
              END IF;
            END IF;
          END IF;
END;


PROCEDURE Create_Attribute_Groups (p_cust_account_id            IN NUMBER,
                                    p_vps_cust_type             IN VARCHAR2,
                                    p_vps_ar_sup_site_cat       IN VARCHAR2,
                                    p_vps_billing_frequency     IN VARCHAR2,
                                    p_vps_billing_exception     IN VARCHAR2,
                                    p_vps_sensitive_vendor_flag IN VARCHAR2,
                                    p_vps_vendor_report_flag    IN VARCHAR2,
                                    p_vps_vendor_report_fmt     IN VARCHAR2,
                                    p_vps_inv_backup            IN VARCHAR2,
                                    p_vps_tiered_program        IN VARCHAR2,
                                    p_vps_fob_dest_origin       IN VARCHAR2,
                                    p_vps_post_audit_tf         IN VARCHAR2,
                                    p_vps_supplier_site_pay_grp IN VARCHAR2,
                                    p_vps_ap_netting_exception  IN VARCHAR2 )
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
   lv_vps_billing_exception                       :=NULL;
   lv_vps_sensitive_vendor_flag                   :=NULL;
   lv_vps_vendor_report_flag                      :=NULL;
   lv_vps_inv_backup                              :=NULL;
   lv_vps_tiered_program                          :=NULL;
   lv_vps_ap_netting_exception                    :=NULL;
--Assign Default values
SELECT decode(upper(P_VPS_BILLING_EXCEPTION),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_billing_exception
  FROM DUAL;
  SELECT decode(upper(P_VPS_SENSITIVE_VENDOR_FLAG),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_sensitive_vendor_flag
  FROM DUAL;
  SELECT decode(upper(P_VPS_VENDOR_REPORT_FLAG),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_vendor_report_flag
  FROM DUAL;
  SELECT decode(upper(P_VPS_INV_BACKUP),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_inv_backup
  FROM DUAL;
  SELECT decode(upper(P_VPS_TIERED_PROGRAM),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_tiered_program
  FROM DUAL;
SELECT decode(upper(P_VPS_AP_NETTING_EXCEPTION),'YES','Y'
                                                ,'NO','N'
                                                ,'N','N'
                                                ,'Y','Y'
                                                ,'N')
  INTO lv_vps_ap_netting_exception
  FROM DUAL;
  

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
                                          attr_value_str       => P_VPS_CUST_TYPE,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_AR_SUP_SIT_CATEGORY',
                                          attr_value_str       => P_VPS_AR_SUP_SITE_CAT,
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
                                          attr_value_str       => P_VPS_VENDOR_REPORT_FMT,
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
                                          attr_value_str       => P_VPS_FOB_DEST_ORIGIN,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_POST_AUDIT_TF',
                                          attr_value_str       => P_VPS_POST_AUDIT_TF,
                                          attr_value_num       => NULL,
                                          attr_value_date      => NULL,
                                          attr_disp_value      => NULL,
                                          attr_unit_of_measure => NULL,
                                          user_row_identifier  => NULL)
                                        , ego_user_attr_data_obj
                                         (row_identifier       => 1,
                                          attr_name            => 'VPS_SUPPLIER_SITE_PAY_GROUP',
                                          attr_value_str       => P_VPS_SUPPLIER_SITE_PAY_GRP,
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

procedure Create_GlobalSupplier_Customer ( global_supplier_number IN         VARCHAR2
                                          ,account_number         OUT        VARCHAR2
                                          ,return_status          OUT NOCOPY VARCHAR2
                                          ,error_message          OUT NOCOPY VARCHAR2
                                         )
as                                         

  lv_init_msg_list              VARCHAR2 (1) := 'T';
  lv_msg_count                  NUMBER;
  lv_msg_data                   VARCHAR2 (2000);
  lv_return_status              VARCHAR2 (1);
  lv_output                     VARCHAR2 (2000);
  lv_msg_dummy                  VARCHAR2 (2000);
  lv_err_msg                    VARCHAR2 (2000);
  lv_error_flag                 VARCHAR2 (1);
  
  lv_cust_account_id            NUMBER;
  lv_cust_party_id              NUMBER;
  lv_cust_profile_id            NUMBER;

  lv_organization_rec           hz_party_v2pub.organization_rec_type;
  lv_cust_account_rec           hz_cust_account_v2pub.cust_account_rec_type;
  lv_customer_profile_rec       hz_customer_profile_v2pub.customer_profile_rec_type;

  lv_cust_account_number        VARCHAR2 (100);
  lv_cust_party_number          VARCHAR2 (100);
  
  cursor c_g_vendors
  is
    select *
    from   ap_suppliers
    where  segment1=global_supplier_number
    ;
begin

    for c_g_rec in c_g_vendors
    loop
      lv_organization_rec.party_rec.party_id := c_g_rec.party_id;
      lv_cust_account_rec.account_name:= c_g_rec.vendor_name;
      lv_cust_account_rec.created_by_module := 'TCA_V2_API';
      lv_cust_account_rec.orig_system := 'VPS';
      lv_cust_account_rec.orig_system_reference := c_g_rec.segment1 || '-VPS';
         
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
       return_status := lv_return_status;
       FND_FILE.PUT_LINE(FND_FILE.LOG,
             'After Create_Cust_Account, lv_return_status: ' || lv_return_status || ', lv_cust_account_number: ' || lv_cust_account_number);
       --If API fails
       IF lv_return_status <> 'S'
          THEN
          lv_error_flag :='Y';
          FOR i IN 1 .. lv_msg_count
          LOOP
            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
            lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
          END LOOP;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'After CREATE_CUST_ACCOUNT, lv_err_msg: ' || lv_err_msg);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Error mesg: ' || lv_output);                
       ELSE
          FND_FILE.PUT_LINE(FND_FILE.LOG,'lv_cust_account_id: ' || lv_cust_account_id);        
       END IF;
       error_message  := lv_output;
       account_number := lv_cust_account_number;
    end loop;
  COMMIT;
exception
  when others then
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception: ' || sqlerrm);
end Create_GlobalSupplier_Customer;

PROCEDURE Print_Customer_Details
   IS
      lv_row_cnt                    NUMBER := 0;
 CURSOR cur_stg_tbl (
         p_request_id   NUMBER)
      IS
         SELECT   *
         FROM     xx_cdh_vps_customer_stg
         WHERE    request_id = p_request_id
         ORDER BY interface_id;
   --
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Print_Customer_Details');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('-',304 , '-'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'VPS Customer Details Report');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 304, '-'));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('Vendor#', 30, ' ') || ' '
                                    || RPAD ('Billing Terms', 12, ' ') || ' '
                                    || RPAD ('Status', 12, ' ') || ' '
                                    || RPAD ('Error Message', 250, ' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 30, '-') || ' '
                                    || RPAD ('-', 12, '-') || ' '
                                    || RPAD ('-', 12, '-') || ' '
                                    || RPAD ('-', 250, '-'));
   FOR stg_tbl_rec IN cur_stg_tbl (g_conc_request_id)
      LOOP
         --
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD (NVL (stg_tbl_rec.vendor_num, ' '), 30, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.vps_billing_frequency, ' '), 12, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.record_status, ' '), 12, ' ') || ' '
                || RPAD (NVL (stg_tbl_rec.error_message, ' '), 250, ' ') 
                );
         lv_row_cnt := lv_row_cnt + 1;
      END LOOP;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Row Count: ' || lv_row_cnt);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 304, '-'));
   EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in Print_Customer_Details: '||SQLERRM);
   END Print_Customer_Details;
--
PROCEDURE main (
      p_errbuf_out              OUT      VARCHAR2
     ,p_retcod_out              OUT      VARCHAR2
   )
 IS
 
CURSOR cur_vendor (p_vendor_site_code varchar2)
IS
  select ssa.location_id
        ,sup.vendor_name
        --,ltrim(NVL(ssa.attribute9,(NVL(ssa.attribute7,NVL(ssa.vendor_site_code_alt,ssa.vendor_site_id)))),'0') as attribute9
        ,ltrim(ssa.vendor_site_code_alt,'0') as attribute9
        ,sup.party_id
        --,ssa.legal_business_name
  from   AP_SUPPLIER_SITES_ALL ssa
        ,AP_SUPPLIERS          sup
  where  1=1
  and    sup.vendor_id = ssa.vendor_id
  --and    ssa.attribute9=LPAD(p_vendor_number, 10, '0')
  and    ssa.vendor_site_code=p_vendor_site_code
  and    ssa.pay_site_flag='Y'
  and    ssa.attribute8 like 'TR%'
  and  	( ssa.inactive_date IS NULL
			 OR  ssa.inactive_date > SYSDATE) 
  ; 
  
CURSOR cur_stg_tbl
IS
  SELECT *
  FROM  xx_cdh_vps_customer_stg
  WHERE 1=1
    AND record_status='N'
	AND request_id=g_conc_request_id;
        lv_org_id                       NUMBER;
        lv_error_flag                   VARCHAR2 (1);
        lv_reject_msg_out               VARCHAR2 (1000);
        lv_stg_rec                      xx_cdh_vps_customer_stg%ROWTYPE;
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
 BEGIN
 log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Start:'||g_conc_request_id,'');
	--Update_Requestid
		Update_Requestid;
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
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in initializing : ' || SQLERRM);
     log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','App Intialization'||sqlerrm,'');
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
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Cust Profile Class : ' || SQLERRM);
     log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Customer Profile'||sqlerrm,'');
   END;
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Creating Customers');
 FOR stg_tbl_rec IN cur_stg_tbl  LOOP
		-- Initialize Variables.
            lv_stg_rec                   := NULL;
            lv_output                    := NULL;
            lv_error_flag                := 'N';
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
/* Vendor is already created. So no need of create_organization */
    open cur_vendor (stg_tbl_rec.vendor_site_code);
    fetch cur_vendor into lv_location_id,lv_vendor_name,lv_vendor_num,lv_parent_party_id;
    close cur_vendor;
    IF lv_vendor_num IS NOT NULL THEN
		----------------------------------------------------------------------------
         --   create organization
		----------------------------------------------------------------------------
      lv_organization_rec.organization_name               := lv_vendor_name||'-'||lv_vendor_num;
      lv_organization_rec.created_by_module               :='TCA_V2_API';
      lv_organization_rec.party_rec.orig_system_reference :=stg_tbl_rec.vendor_num||'-VPS' ;
         hz_party_v2pub.create_organization
                                    (p_init_msg_list =>         lv_init_msg_list
                                    ,p_organization_rec =>      lv_organization_rec
                                    ,x_party_id =>              lv_party_id
                                    ,x_party_number =>          lv_party_number
                                    ,x_profile_id =>            lv_profile_id
                                    ,x_return_status =>         lv_return_status
                                    ,x_msg_count =>             lv_msg_count
                                    ,x_msg_data =>              lv_msg_data);
         /*log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN',
                'After CREATE_ORGANIZATION, lv_return_status: ' || lv_return_status || ', lv_party_id: ' || lv_party_id); */
		 --If API fails
        IF lv_return_status <> 'S' THEN
          lv_error_flag     :='Y';
          FOR i IN 1 .. lv_msg_count
          LOOP
            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
            lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
          END LOOP;
          log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Organization'||lv_output,lv_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Organization: ' || lv_output);
        ELSE
          log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Organization:'||stg_tbl_rec.vendor_num,lv_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Organization: ' || lv_party_id);
        END IF;
  	---------------------------------------------------------------------------- 
		--Create Account
		----------------------------------------------------------------------------
        lv_organization_rec.party_rec.party_id    := lv_party_id;
        --lv_organization_rec.party_rec.party_number:= lv_party_number;
        lv_cust_account_rec.account_name          := lv_vendor_name||'-'||lv_vendor_num;
        lv_cust_account_rec.orig_system           := 'VPS';
        lv_cust_account_rec.orig_system_reference := stg_tbl_rec.vendor_num || '-VPS' ;
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
        /*  log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN',
             'After Create_Cust_Account, lv_return_status: ' || lv_return_status || ', lv_cust_account_id: ' || lv_cust_account_id); */
     --If API fails
          IF lv_return_status <> 'S' THEN
            lv_error_flag     :='Y';
            FOR i IN 1 .. lv_msg_count
            LOOP
              fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
              lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
            END LOOP;
             log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Account'||lv_output,lv_return_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Account Number: ' || lv_output);
          ELSE
            log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Account Number:'||lv_cust_account_number,lv_return_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Account Number: ' || lv_cust_account_number);
          END IF;
      COMMIT;
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
                              lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                            END LOOP;
                             log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Party Site'||lv_output,lv_return_status);
                              --DBMS_OUTPUT.put_line('Error mesg: ' || lv_output);	
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'PartySiteId: ' || lv_output);	
                        ELSE
                            log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Party Site:'||lv_party_site_id,lv_return_status);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create PartySiteId : ' || lv_party_site_id);	
                        END IF;
    ----------------------------------------------------------------------------
    -- Create Cust Acct Site BILL TO 
    ----------------------------------------------------------------------------
         lv_bill_cust_acct_site_rec.cust_account_id       := lv_cust_account_id;
          lv_bill_cust_acct_site_rec.party_site_id         := lv_party_site_id;
          lv_bill_cust_acct_site_rec.orig_system           := 'VPS';
          lv_bill_cust_acct_site_rec.orig_system_reference := stg_tbl_rec.vendor_num||'-01-'||'VPS' ;
          lv_bill_cust_acct_site_rec.created_by_module     :='TCA_V2_API';
         hz_cust_account_site_v2pub.create_cust_acct_site
                                                         (lv_init_msg_list
                                                         ,lv_bill_cust_acct_site_rec
                                                         ,lv_bill_cust_acct_site_id
                                                         ,lv_return_status
                                                         ,lv_msg_count
                                                         ,lv_msg_data);
	
          IF lv_return_status <> 'S' THEN
            lv_error_flag     :='Y';
            FOR i IN 1 .. lv_msg_count
            LOOP
              fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
              lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
            END LOOP;
            log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN','Create CustAcctSite'||lv_output,lv_return_status);
            --log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN','After create_cust_acct_site, lv_err_msg: ' || lv_err_msg);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'CustAcctSiteId: ' || lv_output);
          ELSE
            log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN','Create CustAcctSite'||lv_bill_cust_acct_site_id,lv_return_status);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Create CustAcctSiteId: ' || lv_bill_cust_acct_site_id);
          END IF;
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
		/*log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN',
             'After create_party_site_use, lv_return_status: ' || lv_return_status || ', lv_bill_party_site_use_id: ' || lv_bill_party_site_use_id);*/
     --If API fails
              IF lv_return_status <> 'S' THEN
                lv_error_flag     :='Y';
                FOR i IN 1 .. lv_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                  lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
                END LOOP;
                log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN','Create PartySiteUse'||lv_output,lv_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO PartySiteUseId: ' || lv_output);
              ELSE
                log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN','Create PartySiteUse'||lv_bill_party_site_use_id,lv_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Create BILL_TO PartySiteUseId: ' || lv_bill_party_site_use_id);
              END IF;
    ----------------------------------------------------------------------------
      -- Create Cust site use BILL TO 
    ----------------------------------------------------------------------------
        lv_bill_cust_site_use_rec.cust_acct_site_id     := lv_bill_cust_acct_site_id;
        lv_bill_cust_site_use_rec.site_use_code         := 'BILL_TO';
        lv_bill_cust_site_use_rec.primary_flag          := 'Y';
        lv_bill_cust_site_use_rec.status                := 'A';
        lv_bill_cust_site_use_rec.orig_system           := 'VPS';
        lv_bill_cust_site_use_rec.orig_system_reference := stg_tbl_rec.vendor_num||'-01-VPS-BILL_TO' ;
        lv_bill_cust_site_use_rec.created_by_module     :='TCA_V2_API';
        lv_bill_cust_site_use_rec.location              := stg_tbl_rec.vendor_site_code||'-BILLTO'; 
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
          lv_error_flag     :='Y';
          FOR i IN 1 .. lv_msg_count
          LOOP
            fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
            lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
          END LOOP;
          log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create CustSiteUSe'||lv_output,lv_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO CustSiteUseId: ' || lv_output);
        ELSE
          log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create CustSiteUSe'||lv_bill_site_use_id,lv_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create BILL_TO CustSiteUseId: ' || lv_bill_site_use_id);
        END IF;
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
            --If API fails
            IF lv_return_status <> 'S' THEN
              lv_error_flag     :='Y';
              FOR i IN 1 .. lv_msg_count
              LOOP
                fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
              END LOOP;
              log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Ship To PartySiteUse'||lv_output,lv_return_status);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP_TO PartySiteUseId: ' || lv_output);
            ELSE
              log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Ship To PartySiteUse'||lv_ship_party_site_use_id,lv_return_status);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create SHIP_TO PartySiteUseId: ' || lv_ship_party_site_use_id);
            END IF;
	------------------------------------------------------------------------------
	-- Create Cust site use SHIP TO 
	------------------------------------------------------------------------------
        lv_ship_cust_site_use_rec.cust_acct_site_id     := lv_bill_cust_acct_site_id;
        lv_ship_cust_site_use_rec.site_use_code         := 'SHIP_TO';
        --    lv_ship_cust_site_use_rec.primary_flag := 'Y';
        lv_ship_cust_site_use_rec.status                := 'A';
        lv_ship_cust_site_use_rec.orig_system           := 'VPS';
        lv_ship_cust_site_use_rec.orig_system_reference := stg_tbl_rec.vendor_num||'-01-VPS-SHIP_TO' ;
        lv_ship_cust_site_use_rec.created_by_module     :='TCA_V2_API';
        lv_ship_cust_site_use_rec.location              := stg_tbl_rec.vendor_site_code||'-SHIPTO';
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
                 --If API fails
            IF lv_return_status <> 'S' THEN
              lv_error_flag     :='Y';
              FOR i IN 1 .. lv_msg_count
              LOOP
                fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
                lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
              END LOOP;
              log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create CustSiteUseSHIPTO'||lv_output,lv_return_status);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP_TO CustAcctSiteUseId: ' || lv_output);
            ELSE
              log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create CustSiteUseSHIPTO'||lv_ship_site_use_id,lv_return_status);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Create SHIP_TO CustAcctSiteUseId: ' || lv_ship_site_use_id);
            END IF; 
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
    	 /* log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.MAIN',
                 'After create party relationship, l_return_status: ' || lv_return_status || ', lv_relationship_id : ' || lv_relationship_id );*/
			IF lv_return_status <> 'S'
				THEN
				lv_error_flag :='Y';
				FOR i IN 1 .. lv_msg_count
				LOOP
				  fnd_msg_pub.get (i, fnd_api.g_false, lv_msg_data, lv_msg_dummy);
				  lv_output := (TO_CHAR (i) || ': ' || lv_msg_data);
				END LOOP;
          log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Relationship:'||lv_output,lv_return_status);
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Master vendor relation: ' || lv_output);	
			 ELSE
         log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Create Relationship:'||lv_relationship_id,lv_return_status);
				 FND_FILE.PUT_LINE(FND_FILE.LOG,'Create Master vendor relation: ' || lv_relationship_id );
			END IF;
		----------------------------------------------------------------------------
      -- Create Contacts
    ----------------------------------------------------------------------------
    IF stg_tbl_rec.contact_fname1 IS NOT NULL AND stg_tbl_rec.contact_lname1 IS NOT NULL THEN 
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Start contact_fname1: ' || stg_tbl_rec.contact_fname1 );
         Create_Contacts(stg_tbl_rec.contact_fname1
                          ,stg_tbl_rec.contact_lname1
                          ,stg_tbl_rec.contact_job_title1
                          ,stg_tbl_rec.contact_email1
                          ,stg_tbl_rec.contact_phone1
                          ,lv_party_id
                          ,lv_cust_account_id
                          ,lv_bill_cust_acct_site_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_lname1: ' || stg_tbl_rec.contact_lname1 );
    END IF;
    IF stg_tbl_rec.contact_fname2 IS NOT NULL AND stg_tbl_rec.contact_lname2 IS NOT NULL THEN 
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Start contact_fname2: ' || stg_tbl_rec.contact_fname2 );
         Create_Contacts(stg_tbl_rec.contact_fname2
                          ,stg_tbl_rec.contact_lname2
                          ,stg_tbl_rec.contact_job_title2
                          ,stg_tbl_rec.contact_email2
                          ,stg_tbl_rec.contact_phone2
                          ,lv_party_id
                          ,lv_cust_account_id
                          ,lv_bill_cust_acct_site_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_lname2: ' || stg_tbl_rec.contact_lname2 );
     END IF;
     IF stg_tbl_rec.contact_fname3 IS NOT NULL AND stg_tbl_rec.contact_lname3 IS NOT NULL THEN 
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Start contact_fname3: ' || stg_tbl_rec.contact_fname3 );
         Create_Contacts(stg_tbl_rec.contact_fname3
                          ,stg_tbl_rec.contact_lname3
                          ,stg_tbl_rec.contact_job_title3
                          ,stg_tbl_rec.contact_email3
                          ,stg_tbl_rec.contact_phone3
                          ,lv_party_id
                          ,lv_cust_account_id
                          ,lv_bill_cust_acct_site_id);  
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_lname3: ' || stg_tbl_rec.contact_lname3 );
      END IF;
      IF stg_tbl_rec.contact_fname4 IS NOT NULL AND stg_tbl_rec.contact_lname4 IS NOT NULL THEN 
      FND_FILE.PUT_LINE(FND_FILE.LOG,'STart contact_fname4: ' || stg_tbl_rec.contact_fname4 );
         Create_Contacts(stg_tbl_rec.contact_fname4
                          ,stg_tbl_rec.contact_lname4
                          ,stg_tbl_rec.contact_job_title4
                          ,stg_tbl_rec.contact_email4
                          ,stg_tbl_rec.contact_phone4
                          ,lv_party_id
                          ,lv_cust_account_id
                          ,lv_bill_cust_acct_site_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_lname4: ' || stg_tbl_rec.contact_lname4 );
      END IF;
      IF stg_tbl_rec.contact_fname5 IS NOT NULL AND stg_tbl_rec.contact_lname5 IS NOT NULL THEN 
       FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_fname5: ' || stg_tbl_rec.contact_fname5 );
         Create_Contacts(stg_tbl_rec.contact_fname5
                          ,stg_tbl_rec.contact_lname5
                          ,stg_tbl_rec.contact_job_title5
                          ,stg_tbl_rec.contact_email5
                          ,stg_tbl_rec.contact_phone5
                          ,lv_party_id
                          ,lv_cust_account_id
                          ,lv_bill_cust_acct_site_id);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'End contact_lname5: ' || stg_tbl_rec.contact_lname5 );
      END IF;
    
  
  ------------------------------------------------------------------------------
  --Call Attribute Groups
  ------------------------------------------------------------------------------
  Create_Attribute_Groups ( lv_cust_account_id
                          ,stg_tbl_rec.vps_cust_type
                          ,stg_tbl_rec.vps_ar_sup_site_cat
                          ,stg_tbl_rec.vps_billing_frequency
                          ,stg_tbl_rec.vps_billing_exception
                          ,stg_tbl_rec.vps_sensitive_vendor_flag
                          ,stg_tbl_rec.vps_vendor_report_flag
                          ,stg_tbl_rec.vps_vendor_report_fmt
                          ,stg_tbl_rec.vps_inv_backup	
                          ,stg_tbl_rec.vps_tiered_program
                          ,stg_tbl_rec.vps_fob_dest_origin
                          ,stg_tbl_rec.vps_post_audit_tf
                          ,stg_tbl_rec.vps_supplier_site_pay_grp
                          ,stg_tbl_rec.vps_ap_netting_exception);
  ELSE
      lv_error_flag:='Y';
      lv_output:='No Vendor Found';
  END IF;
		IF lv_error_flag='Y' THEN
			UPDATE xx_cdh_vps_customer_stg
				SET record_status='E'
					,error_message=lv_output
			WHERE interface_id=stg_tbl_rec.interface_id;
		ELSE
			UPDATE xx_cdh_vps_customer_stg
				SET record_status='S'
					,error_message='Created'
			WHERE interface_id=stg_tbl_rec.interface_id;
		END IF;
	END LOOP;
	COMMIT;
  -- Print Customer Details 
      Print_Customer_Details;
  log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','End :'||g_conc_request_id,'');
   FND_FILE.PUT_LINE(FND_FILE.LOG,'End Of Customer Creation'  );
 EXCEPTION
  WHEN OTHERS THEN
     log_debug_msg('XX_CDH_CONV_CUST_VPS_PKG.main','Unexpected Error in VPS Customer Creation: '||g_conc_request_id,sqlerrm);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in VPS Customer Creation: '|| sqlerrm);
 END Main;
 
END XX_CDH_CONV_CUST_VPS_PKG;
/