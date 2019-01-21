create or replace
PACKAGE BODY xx_crm_wlr_extn_attbt_sync_pkg
 AS

  TYPE LOCAL_INPUT_DATA_REC IS RECORD (
        parameterName                        VARCHAR2(100),
     parameterType			  VARCHAR2(100),
     numberParameterValue		  NUMBER,
     stringParameterValue		  VARCHAR2(100),
     dateParameterValue			  DATE
);

 type local_input_data_table IS TABLE OF local_input_data_rec INDEX BY binary_integer;


 TYPE wlr_acct_rec_type IS RECORD (
        P_CUST_ACCOUNT_ID                       VARCHAR2(50), 
        P_CUST_ACCOUNT_OSR                      VARCHAR2(50), 
        P_MEMBER_ID				NUMBER,
        P_MEMBERSHIP_TYPE			VARCHAR2(50),
        P_SEGMENT_ID				NUMBER,
        P_EMAIL_OPT_OUT				NUMBER,
        P_MAIL_OPT_OUT				NUMBER,
        P_ADDED_DATE				DATE,
        P_ACTIVATED				NUMBER,
        P_CHANGED_DATE				DATE,
        P_TIER					NUMBER,
        P_MASTER_MEMBER_ID			NUMBER,
        P_FIRST_NAME				VARCHAR2(50),
        P_LAST_NAME 				VARCHAR2(50),
        P_COMPANY 				VARCHAR2(50),	
        P_ADDRESS_LINE_1 			VARCHAR2(50),
        P_ADDRESS_LINE_2			VARCHAR2(50),	
        P_CITY 					VARCHAR2(50),
        P_STATE					VARCHAR2(50),
        P_ZIP_CODE				NUMBER,
        P_COUNTRY				VARCHAR2(50),
        P_PHONE					VARCHAR2(50),
        P_EMAIL					VARCHAR2(50),
        P_ADDED_BY				VARCHAR2(50),
        P_ACTIVATED_DATE			DATE,
        P_ACTIVATED_STORE			NUMBER,
        P_LAST_CHANGED_BY			VARCHAR2(50),
        P_SUSPENDED				NUMBER,
        P_SUSPENDED_BY				VARCHAR2(50),
        P_SUSPENDED_DATE			DATE,
        P_SUSPENDED_REASON_ID			NUMBER,
        P_ENROLLMENT_STORE			NUMBER,
        P_ENROLLMENT_TYPE			NUMBER,
        P_BUSINESS_UNIT				VARCHAR2(50),
        P_GROUP_ID				NUMBER,
        P_UNDELIVERABLE				NUMBER,
        P_UNDELIVERABLE_STATUS_CHANGED		DATE,
        P_LAST_ORDERED_DATE			DATE,	
        P_CELEBRATE_MONTH			NUMBER,
        P_CELEBRATE_DAY				NUMBER,
        P_SUPPRESSWORD				NUMBER,
        P_DELETE_FLAG				NUMBER
);

 
 

 PROCEDURE process_account_record(p_cust_account_id IN VARCHAR2,   p_member_id IN NUMBER,   p_membership_type IN VARCHAR2,   p_segment_id IN NUMBER,   p_email_opt_out IN NUMBER,   p_mail_opt_out IN NUMBER,   p_added_date IN DATE,   p_activated IN NUMBER,   p_changed_date IN DATE,   p_tier IN NUMBER,   p_master_member_id IN NUMBER,   p_first_name IN VARCHAR2,   p_last_name IN VARCHAR2,   p_company IN VARCHAR2,   p_address_line_1 IN VARCHAR2,   p_address_line_2 IN VARCHAR2,   p_city IN VARCHAR2,   p_state IN VARCHAR2,   p_zip_code IN NUMBER,   p_country IN VARCHAR2,   p_phone IN VARCHAR2,   p_email IN VARCHAR2,   p_added_by IN VARCHAR2,   p_activated_date IN DATE,   p_activated_store IN NUMBER,   p_last_changed_by IN VARCHAR2,   p_suspended IN NUMBER,   p_suspended_by IN VARCHAR2,   p_suspended_date IN DATE,   p_suspended_reason_id IN NUMBER,   p_enrollment_store IN NUMBER,   p_enrollment_type IN NUMBER,   p_business_unit IN VARCHAR2,   p_group_id IN NUMBER,   p_undeliverable IN NUMBER,   p_undeliverable_status_changed IN DATE,   p_last_ordered_date IN DATE,   p_celebrate_month IN NUMBER,   p_celebrate_day IN NUMBER,   p_suppressword IN NUMBER,   p_delete_flag IN NUMBER,   x_return_status OUT nocopy VARCHAR2,   x_error_code OUT nocopy VARCHAR2,   x_error_message OUT nocopy VARCHAR2)

  IS ---WLR specific variables
  l_cust_account_id VARCHAR2(50);
  l_member_id NUMBER;
  l_membership_type VARCHAR2(50);
  l_segment_id NUMBER;
  l_email_opt_out NUMBER;
  l_mail_opt_out NUMBER;
  l_added_date DATE;
  l_activated NUMBER;
  l_changed_date DATE;
  l_tier NUMBER;
  l_master_member_id NUMBER;
  l_first_name VARCHAR2(100);
  l_last_name VARCHAR2(100);
  l_company VARCHAR2(100);
  l_address_line_1 VARCHAR2(100);
  l_address_line_2 VARCHAR2(100);
  l_city VARCHAR2(100);
  l_state VARCHAR2(100);
  l_zip_code NUMBER;
  l_country VARCHAR2(100);
  l_phone VARCHAR2(100);
  l_email VARCHAR2(100);
  l_added_by VARCHAR2(100);
  l_activated_date DATE;
  l_activated_store NUMBER;
  l_last_changed_by VARCHAR2(100);
  l_suspended NUMBER;
  l_suspended_by VARCHAR2(100);
  l_suspended_date DATE;
  l_suspended_reason_id NUMBER;
  l_enrollment_store NUMBER;
  l_enrollment_type NUMBER;
  l_business_unit VARCHAR2(100);
  l_group_id NUMBER;
  l_undeliverable NUMBER;
  l_undeliverable_status_changed DATE;
  l_last_ordered_date DATE;
  l_celebrate_month NUMBER;
  l_celebrate_day NUMBER;
  l_suppressword NUMBER;
  l_delete_flag NUMBER;
  L_CUST_ACCOUNT_OSR VARCHAR2(50);
  
  --l_cust_account_id NUMBER;
  ln_owner_table_id NUMBER;
  x_owner_table_id NUMBER;
  ln_retcode NUMBER;
  x_retcode NUMBER;
  ln_errbuf VARCHAR2(1000);
  x_errbuf VARCHAR2(1000);
  
  l_local_input_data_table_index NUMBER := 0;
  l_parameter_name VARCHAR2(100) := NULL;
  L_NUMBER_PARAMETER_VALUE                        NUMBER;
  L_VARCHAR_PARAMETER_VALUE                        VARCHAR2(100);
  L_DATE_PARAMETER_VALUE                        DATE;
  
  L_wlr_acct_obj_TBL wlr_acct_obj_TBL := wlr_acct_obj_TBL();
  l_wlr_acct_obj wlr_acct_obj := NULL;
  l_LOCAL_INPUT_DATA_REC LOCAL_INPUT_DATA_REC := null;

  le_api_error        EXCEPTION;

  BEGIN
      
    x_return_status := fnd_api.g_ret_sts_success;

    l_cust_account_id := p_cust_account_id; 
    --p_cust_account_id IS A VARCHAR TO ENSURE AOPS ID WITH 
    --LEADING ZEROS ARE PRESERVED
    l_member_id := p_member_id;

    IF(l_member_id IS NULL) THEN
      x_error_message := 'Required value WLR Member ID is missing.  Please enter WLR Member ID';
      RAISE le_api_error;
    ELSE       
      xx_cdh_conv_master_pkg.get_osr_owner_table_id(p_orig_system => 'A0',   
                                                    p_orig_sys_reference => l_cust_account_id || '-00001-A0',   
                                                    p_owner_table_name => 'HZ_CUST_ACCOUNTS',   
                                                    x_owner_table_id => ln_owner_table_id,   
                                                    x_retcode => ln_retcode,   
                                                    x_errbuf => ln_errbuf);

      
      if (ln_owner_table_id is not null) then
       --VALIDATION PASSED.  PROCEED WITH CREATING/UPDATING OD CUSTOMER'S LOYALTY DATA IN CDH
       SAVE_ACCOUNT_RECORD(
        P_CUST_ACCOUNT_ID => ln_owner_table_id, --P_CUST_ACCOUNT_ID,
        P_CUST_ACCOUNT_OSR => L_CUST_ACCOUNT_OSR,
        P_MEMBER_ID => P_MEMBER_ID,
        P_MEMBERSHIP_TYPE => P_MEMBERSHIP_TYPE,
        P_SEGMENT_ID => P_SEGMENT_ID,
        P_EMAIL_OPT_OUT => P_EMAIL_OPT_OUT,
        P_MAIL_OPT_OUT => P_MAIL_OPT_OUT,
        P_ADDED_DATE => P_ADDED_DATE,
        P_ACTIVATED => P_ACTIVATED,
        P_CHANGED_DATE => P_CHANGED_DATE,
        P_TIER => P_TIER,
        P_MASTER_MEMBER_ID => P_MASTER_MEMBER_ID,
        P_FIRST_NAME => P_FIRST_NAME,
        P_LAST_NAME => P_LAST_NAME,
        P_COMPANY => P_COMPANY,
        P_ADDRESS_LINE_1 => P_ADDRESS_LINE_1,
        P_ADDRESS_LINE_2 => P_ADDRESS_LINE_2,
        P_CITY => P_CITY,
        P_STATE => P_STATE,
        P_ZIP_CODE => P_ZIP_CODE,
        P_COUNTRY => P_COUNTRY,
        P_PHONE => P_PHONE,
        P_EMAIL => P_EMAIL,
        P_ADDED_BY => P_ADDED_BY,
        P_ACTIVATED_DATE => P_ACTIVATED_DATE,
        P_ACTIVATED_STORE => P_ACTIVATED_STORE,
        P_LAST_CHANGED_BY => P_LAST_CHANGED_BY,
        P_SUSPENDED => P_SUSPENDED,
        P_SUSPENDED_BY => P_SUSPENDED_BY,
        P_SUSPENDED_DATE => P_SUSPENDED_DATE,
        P_SUSPENDED_REASON_ID => P_SUSPENDED_REASON_ID,
        P_ENROLLMENT_STORE => P_ENROLLMENT_STORE,
        P_ENROLLMENT_TYPE => P_ENROLLMENT_TYPE,
        P_BUSINESS_UNIT => P_BUSINESS_UNIT,
        P_GROUP_ID => P_GROUP_ID,
        P_UNDELIVERABLE => P_UNDELIVERABLE,
        P_UNDELIVERABLE_STATUS_CHANGED => P_UNDELIVERABLE_STATUS_CHANGED,
        P_LAST_ORDERED_DATE => P_LAST_ORDERED_DATE,
        P_CELEBRATE_MONTH => P_CELEBRATE_MONTH,
        P_CELEBRATE_DAY => P_CELEBRATE_DAY,
        P_SUPPRESSWORD => P_SUPPRESSWORD,
        P_DELETE_FLAG => P_DELETE_FLAG,
        X_RETURN_STATUS => X_RETURN_STATUS,
        X_ERROR_MESSAGE => X_ERROR_MESSAGE
  );
       
      ELSE
       x_error_message := 'Could not find account.';
      RAISE le_api_error;
      end if;
    END IF;

    EXCEPTION
    WHEN le_api_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

    WHEN others THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      x_error_message := x_error_message || sqlerrm;

    END process_account_record;
    
    
    
    
    
    
    
    
    
    
    
    
    

    --Declare
    PROCEDURE save_account_record(
    P_CUST_ACCOUNT_ID IN VARCHAR2,
    P_CUST_ACCOUNT_OSR IN VARCHAR2,
    p_member_id IN NUMBER,   
    p_membership_type IN VARCHAR2,   
    p_segment_id IN NUMBER,   
    p_email_opt_out IN NUMBER,   
    p_mail_opt_out IN NUMBER,   
    p_added_date IN DATE,   
    p_activated IN NUMBER,   
    p_changed_date IN DATE,   
    p_tier IN NUMBER,   
    p_master_member_id IN NUMBER,   
    p_first_name IN VARCHAR2,   
    p_last_name IN VARCHAR2,   
    p_company IN VARCHAR2,   
    p_address_line_1 IN VARCHAR2,   
    p_address_line_2 IN VARCHAR2,   
    p_city IN VARCHAR2,   
    p_state IN VARCHAR2,   
    p_zip_code IN NUMBER,   
    p_country IN VARCHAR2,   
    p_phone IN VARCHAR2,   
    p_email IN VARCHAR2,   
    p_added_by IN VARCHAR2,   
    p_activated_date IN DATE,   
    p_activated_store IN NUMBER,   
    p_last_changed_by IN VARCHAR2,   
    p_suspended IN NUMBER,   
    p_suspended_by IN VARCHAR2,   
    p_suspended_date IN DATE,   
    p_suspended_reason_id IN NUMBER,   
    p_enrollment_store IN NUMBER,   
    p_enrollment_type IN NUMBER,   
    p_business_unit IN VARCHAR2,   
    p_group_id IN NUMBER,   
    p_undeliverable IN NUMBER,   
    p_undeliverable_status_changed IN DATE,   
    p_last_ordered_date IN DATE,   
    p_celebrate_month IN NUMBER,   
    p_celebrate_day IN NUMBER,   
    p_suppressword IN NUMBER,   
    p_delete_flag IN NUMBER,   
    x_return_status OUT nocopy VARCHAR2,  
    x_error_message OUT nocopy VARCHAR2)

     IS

    l_api_version NUMBER;
    l_attributes_row_table ego_user_attr_row_table := ego_user_attr_row_table();
    l_attributes_data_table ego_user_attr_data_table := ego_user_attr_data_table();
    l_change_info_table ego_user_attr_change_table DEFAULT NULL;
    l_entity_id NUMBER DEFAULT NULL;
    l_entity_index NUMBER DEFAULT NULL;
    l_entity_code VARCHAR2(5) DEFAULT NULL;
    l_debug_level NUMBER DEFAULT 0;
    l_init_error_handler VARCHAR2(5) DEFAULT fnd_api.g_true;
    l_write_to_concurrent_log VARCHAR2(5) DEFAULT fnd_api.g_false;
    l_init_fnd_msg_list VARCHAR2(5) DEFAULT fnd_api.g_false;
    l_log_errors VARCHAR2(5) DEFAULT fnd_api.g_true;
    l_add_errors_to_fnd_stack VARCHAR2(5) DEFAULT fnd_api.g_false;
    l_commit VARCHAR2(5) DEFAULT fnd_api.g_false;
    l_failed_row_id_list VARCHAR2(25);
    l_return_status VARCHAR2(5);
    l_errorcode NUMBER;
    l_msg_count NUMBER;
    l_msg_data VARCHAR2(500);
    l_pk_column_values ego_col_name_value_pair_array;
    l_class_code_values ego_col_name_value_pair_array;
    l_user_privileges_on_object ego_varchar_tbl_type;
    ln_retcode NUMBER;
    ln_errbuf VARCHAR2(2000);
    ln_owner_table_id NUMBER;
    l_attr_group_id NUMBER;

    ---WLR specific
    l_cust_account_id NUMBER;
    L_CUST_ACCOUNT_OSR VARCHAR2(50);
    l_member_id NUMBER;
    l_membership_type VARCHAR2(50);
    l_segment_id NUMBER;
    l_email_opt_out NUMBER;
    l_mail_opt_out NUMBER;
    l_added_date DATE;
    l_activated NUMBER;
    l_changed_date DATE;
    l_tier NUMBER;
    l_master_member_id NUMBER;
    l_first_name VARCHAR2(100);
    l_last_name VARCHAR2(100);
    l_company VARCHAR2(100);
    l_address_line_1 VARCHAR2(100);
    l_address_line_2 VARCHAR2(100);
    l_city VARCHAR2(100);
    l_state VARCHAR2(100);
    l_zip_code NUMBER;
    l_country VARCHAR2(100);
    l_phone VARCHAR2(100);
    l_email VARCHAR2(100);
    l_added_by VARCHAR2(100);
    l_activated_date DATE;
    l_activated_store NUMBER;
    l_last_changed_by VARCHAR2(100);
    l_suspended NUMBER;
    l_suspended_by VARCHAR2(100);
    l_suspended_date DATE;
    l_suspended_reason_id NUMBER;
    l_enrollment_store NUMBER;
    l_enrollment_type NUMBER;
    l_business_unit VARCHAR2(100);
    l_group_id NUMBER;
    l_undeliverable NUMBER;
    l_undeliverable_status_changed DATE;
    l_last_ordered_date DATE;
    l_celebrate_month NUMBER;
    l_celebrate_day NUMBER;
    l_suppressword NUMBER;
    l_delete_flag NUMBER;

    l_local_input_data_table_index NUMBER := 0;

    le_api_error

     EXCEPTION;

    BEGIN

      --FND_GLOBAL.APPS_INITIALIZE(1971, 50327, 222);
      --MO_GLOBAL.INIT;
      --MO_GLOBAL.SET_POLICY_CONTEXT('S', 161);
      l_cust_account_id := p_cust_account_id;
      l_member_id := p_member_id;
      l_membership_type := p_membership_type;
       
      BEGIN
        SELECT attr_group_id
        INTO l_attr_group_id
        FROM ego_fnd_dsc_flx_ctx_ext
        WHERE descriptive_flexfield_name = 'XX_CDH_CUST_ACCOUNT'
         AND descriptive_flex_context_code = 'LOYALTY_INFO';

      EXCEPTION
      WHEN others THEN
        x_return_status := fnd_api.g_ret_sts_unexp_error;
        x_error_message := x_error_message || sqlerrm;
      END;
      
      l_attributes_row_table.extend;
      
                l_attributes_row_table(1) := ego_user_attr_row_obj( 1,   --ROW_IDENTIFIER
                                                                    l_attr_group_id,   --ATTR_GROUP_ID
                                                                    NULL,   --ATTR_GROUP_APP_ID
                                                                    'XX_CDH_CUST_ACCOUNT',   --ATTR_GROUP_TYPE
                                                                    'LOYALTY_INFO',   --ATTR_GROUP_NAME
                                                                    NULL,   --DATA_LEVEL_1
                                                                    NULL,   --DATA_LEVEL_2
                                                                    NULL,   --DATA_LEVEL_3
                                                                    NULL --TRANSACTION_TYPE
                                                                  );

      l_attributes_data_table.extend;
      --DO NOT CHECK FOR MEMBER_ID, THIS WAS PERFORMED IN 
      --PROCESS_ACCOUNT_RECORD PROCEDURE
      l_local_input_data_table_index := l_local_input_data_table_index + 1;
      l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
      'MEMBER_ID',   --ATTR_NAME
      NULL,   --ATTR_VALUE_STR
      p_member_id,   --ATTR_VALUE_NUM
      NULL,   --ATTR_VALUE_DATE
      NULL,   --ATTR_DISP_VALUE
      NULL,   --ATTR_UNIT_OF_MEASURE
      NULL --USER_ROW_IDENTIFIER
      );
    
      IF (p_membership_type IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'MEMBERSHIP_TYPE',   --ATTR_NAME
            p_membership_type,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_segment_id IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SEGMENT_ID',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_segment_id,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_email_opt_out IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'EMAIL_OPT_OUT',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_email_opt_out,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_mail_opt_out IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'MAIL_OPT_OUT',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_mail_opt_out,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
       IF (p_added_date IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ADDED_DATE',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            p_added_date,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_activated  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ACTIVATED',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_activated,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_changed_date  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'CHANGED_DATE',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            p_changed_date,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
     
      
      IF (p_tier  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'TIER',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_tier,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
     
      
      IF (p_master_member_id  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'MASTER_MEMBER_ID',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_master_member_id,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_first_name  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'FIRST_NAME',   --ATTR_NAME
            p_first_name,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_last_name   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'LAST_NAME',   --ATTR_NAME
            p_last_name,   --ATTR_VALUE_STR
            NULL ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_company  IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'COMPANY',   --ATTR_NAME
            p_company,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_address_line_1   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ADDRESS_LINE_1',   --ATTR_NAME
            p_address_line_1,   --ATTR_VALUE_STR
            NULL ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_address_line_2   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ADDRESS_LINE_2',   --ATTR_NAME
            p_address_line_2 ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_city   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'CITY',   --ATTR_NAME
            p_city ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_state   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'STATE',   --ATTR_NAME
            p_state ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_zip_code   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ZIP_CODE',   --ATTR_NAME
            NULL,   --ATTR_VALUE_STR
            p_zip_code ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_country   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'COUNTRY',   --ATTR_NAME
            p_country ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_phone   IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'PHONE',   --ATTR_NAME
            p_phone ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_email    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'EMAIL',   --ATTR_NAME
            p_email  ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_added_by    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ADDED_BY',   --ATTR_NAME
            p_added_by,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_activated_date    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ACTIVATED_DATE',   --ATTR_NAME
            NULL  ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            p_activated_date,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_activated_store    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ACTIVATED_STORE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_activated_store ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_last_changed_by    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'LAST_CHANGED_BY',   --ATTR_NAME
            p_last_changed_by  ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_suspended    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SUSPENDED',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_suspended ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_suspended_by    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SUSPENDED_BY',   --ATTR_NAME
            p_suspended_by  ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_suspended_date    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SUSPENDED_DATE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            p_suspended_date ,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_suspended_reason_id    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SUSPENDED_REASON_ID',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_suspended_reason_id ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_enrollment_store    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ENROLLMENT_STORE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_enrollment_store ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_enrollment_type    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'ENROLLMENT_TYPE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_enrollment_type ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_business_unit    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'BUSINESS_UNIT',   --ATTR_NAME
            p_business_unit  ,   --ATTR_VALUE_STR
            NULL,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      IF (p_group_id    IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'GROUP_ID',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_group_id ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      
      
      IF (p_undeliverable     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'UNDELIVERABLE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_undeliverable  ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      
      
      IF (p_undeliverable_status_changed     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'UNDELIVERABLE_STATUS_CHANGED',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            NULL ,   --ATTR_VALUE_NUM
            p_undeliverable_status_changed ,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_last_ordered_date     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'LAST_ORDERED_DATE',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            NULL ,   --ATTR_VALUE_NUM
            p_last_ordered_date ,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_celebrate_month     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'CELEBRATE_MONTH',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_celebrate_month  ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_celebrate_day     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'CELEBRATE_DAY',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_celebrate_day  ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_suppressword     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'SUPPRESSWORD',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_suppressword  ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
      
      IF (p_delete_flag     IS NOT NULL)THEN
            l_attributes_data_table.extend;
            l_local_input_data_table_index := l_local_input_data_table_index + 1;
            l_attributes_data_table(l_local_input_data_table_index) := ego_user_attr_data_obj(1,   --ROW_IDENTIFIER
            'DELETE_FLAG',   --ATTR_NAME
            NULL ,   --ATTR_VALUE_STR
            p_delete_flag  ,   --ATTR_VALUE_NUM
            NULL,   --ATTR_VALUE_DATE
            NULL,   --ATTR_DISP_VALUE
            NULL,   --ATTR_UNIT_OF_MEASURE
            NULL --USER_ROW_IDENTIFIER
            );
      END IF;
   
       --l_pk_column_values := ego_col_name_value_pair_array(ego_col_name_value_pair_obj('CUST_ACCOUNT_ID',   to_char(ln_owner_table_id)));
       l_pk_column_values := ego_col_name_value_pair_array(ego_col_name_value_pair_obj('CUST_ACCOUNT_ID',   l_cust_account_id));

      ego_user_attrs_data_pub.process_user_attrs_data(p_api_version => 1.0,   
                                                      p_object_name => 'XX_CDH_CUST_ACCOUNT',   
                                                      p_attributes_row_table => l_attributes_row_table,   
                                                      p_attributes_data_table => l_attributes_data_table,   
                                                      p_pk_column_name_value_pairs => l_pk_column_values,   
                                                      p_class_code_name_value_pairs => l_class_code_values,   
                                                      p_user_privileges_on_object => l_user_privileges_on_object,   
                                                      p_change_info_table => NULL,   
                                                      p_pending_b_table_name => 'XX_CDH_CUST_ACCT_EXT_B',   
                                                      p_pending_tl_table_name => 'XX_CDH_CUST_ACCT_EXT_TL',   
                                                      p_pending_vl_name => 'XX_CDH_CUST_ACCT_EXT_VL',   
                                                      p_entity_id => l_entity_id,   
                                                      p_entity_index => l_entity_index,   
                                                      p_entity_code => l_entity_code,   
                                                      p_debug_level => l_debug_level,   
                                                      p_init_error_handler => l_init_error_handler,   
                                                      p_write_to_concurrent_log => l_write_to_concurrent_log,   
                                                      p_init_fnd_msg_list => l_init_fnd_msg_list,   
                                                      p_log_errors => l_log_errors,   
                                                      p_add_errors_to_fnd_stack => l_add_errors_to_fnd_stack,   
                                                      p_commit => l_commit,   
                                                      x_failed_row_id_list => l_failed_row_id_list,   
                                                      x_return_status => l_return_status,   
                                                      x_errorcode => l_errorcode,   
                                                      x_msg_count => l_msg_count,   
                                                      x_msg_data => l_msg_data);

      IF(l_return_status <> fnd_api.g_ret_sts_success) THEN
       x_error_message := l_msg_data;
       raise le_api_error;
/*
        IF(l_msg_count > 1) THEN
          FOR i IN 1 .. l_msg_count
          LOOP
            DBMS_OUTPUT.PUT_LINE(fnd_msg_pub.GET(i,   p_encoded => fnd_api.g_false));
          END LOOP;

        ELSE
          DBMS_OUTPUT.PUT_LINE('Msg Data     : ' || l_msg_data);
        END IF;
*/
      END IF;

    EXCEPTION
    WHEN le_api_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

    WHEN others THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;
      x_error_message := sqlerrm;

    END save_account_record;
  END xx_crm_wlr_extn_attbt_sync_pkg;
/
commit;