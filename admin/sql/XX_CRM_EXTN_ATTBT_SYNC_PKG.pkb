create or replace
PACKAGE BODY xx_crm_extn_attbt_sync_pkg 

  -- +===================================================================+
  -- |                  Office Depot - Project Simplify                  |
  -- +===================================================================+
  -- | Name        :  XX_CRM_EXTN_ATTBT_SYNC_PKG.pkb                     |
  -- | Description :  CDH Additional Attributes package                  |
  -- |                                                                   |
  -- |                                                                   |
  -- |Change Record:                                                     |
  -- |===============                                                    |
  -- |Version   Date        Author             Remarks                   |
  -- |========  =========== ================== ==========================|
  -- |DRAFT 1a  30-Jul-2007 Kathirvel          Initial draft version     |
  -- |1.1       29-Jan-2008 Kathirvel          Included the procedure    |
  -- |                                         Process_Person_Record for |
  -- |                                         person profile extensible |
  -- |                                         Attribute                 |
  -- |1.2       20-Feb-2008 Kathirvel          Applied Commit statement  |
  -- |                                         as BPEL doest commit      |
  -- |                                         sometimes                 |
  -- |1.3       12-Mar-2008 Yusuf Ali          Provide API call to set   |
  -- |                                         apps context              |
  -- |          14-Mar-2008 Yusuf Ali          Removed API call to set   |
  -- |      				           apps context              |
  -- |1.4       28-Apr-2008 Kathirvel          included OSR table to the |
  -- |                                         person ID in the procedure|
  -- |                                         Process_Person_Record     |
  -- |1.5       18-Jun-2008 Kathirvel          Included status and Orig_ |
  -- |                                         system in the condition on|
  -- |                                         hz_orig_sys_references    |
  -- |1.6       28-May-2009 Yusuf Ali          Made changes to process_account_record|
  -- |                                         for determining if Bill Doc |
  -- |                                         should be updated                 |
  -- |1.7       23-Nov-2009 Kalyan     For De-active Customers,called from       |
  -- |                                 SaveAccount identified by p_account_status|
  -- |                                 =D, no bill docs have to be created.Move  |
  -- |                                 the BILL_DOCS to OLD_BILL_DOCS if exists. |
  -- |1.8       03-Mar-2010 Kalyan     Added who columns during update.    |
  -- |1.9       15-Jul-2011 Dheeraj    Modified process_account_record procedure |
  -- |                                 to inactivate Infodoc Address Exceptions  |
  -- |                                 after Infodoc are moved to OLD_BILLDOCS   |
  -- |                                 as detailed in QC 11524                   |
  -- |1.10      14-Jan-2013 Dheeraj    Code fix for QC 21667             |
  -- |1.10      03-Mar-2013 smohan     Code fix for QC 22379             |
  -- |1.11      23-Oct-2013 Avinash    Modified for R12 Upgrade Retrofit |
  -- |1.12      11-Apr-2014            Added apps initialize to newly created|
  -- |                                 procedure set_context QC 29151    |
  -- |1.13      11-Nov-2015 Havish K   Removed the Schema References as  |
  -- |                                 per R12.2 Retrofit Changes        |
  -- +===================================================================+
  AS

--Defect 22379 - do not remove BILLDOC for a Parent customer
--get party_id from OSR and check whether its a parent
FUNCTION  is_fin_parent(
          p_cust_account_id	        IN	hz_cust_accounts.cust_account_id%TYPE
          )  return varchar2 IS
ln_party_id number(15);
l_exists	varchar2(1) := 'N';
BEGIN

    select  party_id
    into    ln_party_id
    from    hz_cust_accounts
    where   cust_account_id = p_cust_account_id;

	select 	'Y' into l_exists
	from  	hz_relationships
	where 	relationship_type = 'OD_FIN_HIER'
	and   	direction_code = 'P'
	and	status = 'A'
	and	subject_id = ln_party_id
        and     sysdate between start_date and end_date
        AND     rownum = 1;

	return l_exists;

EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		return 'N';
	WHEN OTHERS THEN
		RAISE;
END is_fin_parent;

--Defect 22379 - do not remove BILLDOC for a Parent customer
--check active billdocs (paydoc) exists for the customer
FUNCTION  is_billdoc_exist(
          p_cust_account_id	        IN	hz_cust_accounts.cust_account_id%TYPE
          )  return varchar2 IS
l_billdoc_exists    varchar2(1);
ln_billDoc_count    number;

BEGIN

      SELECT   count(1) 
        INTO   ln_billDoc_count 
        FROM   XX_CDH_CUST_ACCT_EXT_B
        WHERE  CUST_ACCOUNT_ID        = p_cust_account_id
        AND    ATTR_GROUP_ID          = 166
        AND    C_EXT_ATTR2            = 'Y'
        AND    C_EXT_ATTR16           = 'COMPLETE'
        AND    sysdate between D_EXT_ATTR1 and nvl(D_EXT_ATTR2, sysdate+1);

     if ln_billDoc_count < 1 then
       l_billdoc_exists := 'N';
     else
       l_billdoc_exists := 'Y';
     end if;

     return l_billdoc_exists;

EXCEPTION 
	WHEN NO_DATA_FOUND THEN
		return 'N';
	WHEN OTHERS THEN
		RAISE;
end is_billdoc_exist;

/* QC 29151 added set_context procedure -hard coded the user id, resp id and resp apllication id for apps initialize, so that the loss of context doesn't affect processing account record */
-- +===================================================================+
  -- | Name        :  set_context                                      |
  -- | Description :  Sets the context(Apps Initialize) QC 29151       |
  --+=================================================================+
procedure set_context is

l_user_id number(20);
l_responsibility_id number (20);
l_responsibility_appl_id number(20);
x_error_message varchar2(256);

 begin
    select user_id,
           responsibility_id,
           responsibility_application_id
    into   l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      from fnd_user_resp_groups 
     where user_id=(select user_id 
                      from fnd_user 
                     where user_name='ODCRMBPEL')
     and   responsibility_id=(select responsibility_id 
                                from FND_RESPONSIBILITY 
                               where responsibility_key = 'OD_US_CDH_CUSTOM_RESP');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
   exception
    when others then
      x_error_message := 'Exception in initializing : ' || SQLERRM;
      RAISE;
   end set_context;
   
   
  -- +===================================================================+
  -- | Name        :  Process_Account_Record                             |
  -- | Description :  Creates or updates information in extensions tables|
  -- |                for Account.
  -- +===================================================================+
  PROCEDURE process_account_record(p_cust_account_id IN NUMBER
  ,   p_orig_system IN VARCHAR2
  ,   p_orig_sys_reference IN VARCHAR2
  ,   p_account_status IN VARCHAR2
  ,   p_attr_group_type IN VARCHAR2
  ,   p_attr_group_name IN VARCHAR2
  ,   p_attributes_data_table IN ego_user_attr_data_table
  ,   x_return_status OUT nocopy VARCHAR2
  ,   x_error_message OUT nocopy VARCHAR2) IS

  l_change_info_table ego_user_attr_change_table DEFAULT NULL;
  ln_entity_id NUMBER DEFAULT NULL;
  ln_entity_index NUMBER DEFAULT NULL;
  lv_entity_code VARCHAR2(5) DEFAULT NULL;
  ln_debug_level NUMBER DEFAULT 0;
  ln_init_error_handler VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_write_to_concurrent_log VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_init_fnd_msg_list VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_log_errors VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_add_errors_to_fnd_stack VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_commit VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_failed_row_id_list VARCHAR2(25);
  lv_return_status VARCHAR2(5);
  ln_errorcode NUMBER;
  ln_msg_count NUMBER;
  lv_msg_data VARCHAR2(2000);
  lv_error_message VARCHAR2(4000);
  l_pk_column_values ego_col_name_value_pair_array;
  l_class_code_values ego_col_name_value_pair_array;
  l_user_privileges_on_object ego_varchar_tbl_type;

  l_attributes_row_table ego_user_attr_row_table := ego_user_attr_row_table();
  ln_retcode NUMBER;
  ln_errbuf VARCHAR2(2000);
  ln_owner_table_id NUMBER;
  ln_attr_group_id NUMBER;
  ln_old_attr_group_id NUMBER;  --Y. Ali 5/28/2009: used for moving to old BD related to inactive account
  ln_billDoc_count NUMBER;      --Y. Ali 5/28/2009:
  l_errors_tbl error_handler.error_tbl_type;
  lc_createExtensible varchar2(2); --Y. Ali 5/28/2009:

  ln_cust_doc_id NUMBER;
  L_ATTRIBUTES_DATA_TABLE EGO_USER_ATTR_DATA_TABLE;
  
  BEGIN
     
     set_context;  --QC 29151
	 
    x_return_status := 'S';
    L_ATTRIBUTES_DATA_TABLE := p_attributes_data_table;
    lc_createExtensible := 'T'; --Y. Ali 5/28/2009: this variable will determine if any extensible should be created or not

    SELECT XX_CDH_CUST_DOC_ID_S.NEXTVAL
    INTO ln_cust_doc_id
    FROM DUAL;

    IF p_cust_account_id IS NULL THEN
      xx_cdh_conv_master_pkg.get_osr_owner_table_id(p_orig_system => p_orig_system
                                                ,   p_orig_sys_reference => p_orig_sys_reference
                                                ,   p_owner_table_name => 'HZ_CUST_ACCOUNTS'
                                                ,   x_owner_table_id => ln_owner_table_id
                                                ,   x_retcode => ln_retcode
                                                ,   x_errbuf => ln_errbuf);

      IF ln_retcode > 0 THEN
        x_return_status := 'E';
        x_error_message := 'ret code: ' || ln_retcode || ' p_orig_system: ' || p_orig_system || ' p_orig_sys_reference: ' ||
        p_orig_sys_reference || ' ln_errbuf: ' || ln_errbuf;
        RETURN;
      END IF;

    ELSE
      ln_owner_table_id := p_cust_account_id;
    END IF;

    BEGIN
      SELECT attr_group_id
      INTO ln_attr_group_id
      FROM ego_fnd_dsc_flx_ctx_ext
      WHERE descriptive_flexfield_name = p_attr_group_type
       AND descriptive_flex_context_code = p_attr_group_name;


    EXCEPTION
    WHEN others THEN
      x_return_status := 'E';
      x_error_message := 'Attr_Group_ID Does not Exist.';
    END;

    BEGIN --Y. Ali 5/28/2009:CHECK IF AN EXISTING BILL DOC EXIST

      SELECT count(1) INTO ln_billDoc_count FROM XX_CDH_CUST_ACCT_EXT_B
        WHERE cust_account_id = ln_owner_table_id
        AND ATTR_GROUP_ID = ln_attr_group_id;


        IF ln_billDoc_count < 1 THEN --Y. Ali 5/28/2009:set flag to CREATE BILL DOCS
          lc_createExtensible := 'T';
          -- For Deactive Customers, no bill docs to be created. Return without any action.
          -- called from SaveAccount
          IF p_account_status = 'D' THEN
                RETURN ;
          END IF;

        ELSE --Y. Ali 5/28/2009: DETERMINE IF ACCOUNT IS 'A' OR 'I'.  IF 'A' DO NOTHING ELSE MOVE TO OLD BILL DOC AND
          --THEN CREATE NEW BILL DOC
          BEGIN
            IF p_account_status = 'A' THEN
              lc_createExtensible := 'F';
            END IF;

            --Y. Ali 5/28/2009:the following is for getting the attr grp id for old bill docs
              --then update the ext tables with old bill attr grp id
            IF p_attr_group_name = 'BILLDOCS' AND p_account_status != 'A' THEN
              SELECT attr_group_id
                  into  ln_old_attr_group_id
              FROM ego_attr_groups_v
              WHERE application_id = 222
              AND attr_group_name = 'OLD_BILLDOCS'
              AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';
              -- 03/03/10 Added who columns

              --Defect 22379 - do not remove BILLDOC for a Parent customer
              --check active billdocs (paydoc) exists for the customer
              IF( is_fin_parent(ln_owner_table_id) <> 'Y') THEN --Defect 22379
                UPDATE  XX_CDH_CUST_ACCT_EXT_B extb
                SET     attr_group_id     = ln_old_attr_group_id,
                        last_updated_by   = hz_utility_v2pub.last_updated_by,
                        last_update_date  = hz_utility_v2pub.last_update_date
                where cust_account_id = ln_owner_table_id
                and attr_group_id = ln_attr_group_id;
                
                UPDATE  XX_CDH_CUST_ACCT_EXT_TL
                SET     attr_group_id     = ln_old_attr_group_id,
                        last_updated_by   = hz_utility_v2pub.last_updated_by,
                        last_update_date  = hz_utility_v2pub.last_update_date
                where cust_account_id = ln_owner_table_id
                and attr_group_id = ln_attr_group_id;
                -- For De-active Customers, called from SaveAccount identified by
                -- p_account_status = 'D', no bill docs have to be created.
                -- After moving the BILL_DOCS to OLD_BILL_DOCS return.

              END IF; -- End of Defect 22379

              -- QC 21667 Begin

              UPDATE XX_CDH_ACCT_SITE_EXT_B 
              SET C_EXT_ATTR20='N',
                  last_updated_by   = hz_utility_v2pub.last_updated_by,
                  last_update_date  = hz_utility_v2pub.last_update_date,
                  last_update_login = hz_utility_v2pub.last_update_login
              WHERE attr_group_id = ( SELECT attr_group_id 
                                      FROM ego_fnd_dsc_flx_ctx_ext 
                                      WHERE descriptive_flexfield_name = 'XX_CDH_CUST_ACCT_SITE'
                                      AND descriptive_flex_context_code = 'BILLDOCS')
              AND N_EXT_ATTR1  IN   ( SELECT N_EXT_ATTR2 
                                      FROM XX_CDH_CUST_ACCT_EXT_B 
                                      WHERE cust_account_id = ln_owner_table_id
                                      AND NVL(C_EXT_ATTR2,'N')= 'N'
                                      AND attr_group_id IN (SELECT attr_group_id 
                                                            FROM ego_fnd_dsc_flx_ctx_ext
                                                            WHERE descriptive_flexfield_name = 'XX_CDH_CUST_ACCOUNT'
                                                            AND descriptive_flex_context_code = 'OLD_BILLDOCS')
                                    )                       
              AND C_EXT_ATTR20='Y';

              -- QC 21667 End
 
              IF p_account_status = 'D' THEN
                commit;
                RETURN ;
              END IF;

              lc_createExtensible := 'T';
            END IF;--end of p_attr_group_name = 'BILLDOCS' AND p_account_status != 'A'
          END;
        END IF;--ln_billDoc_count < 1

    EXCEPTION
    WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := x_error_message || sqlerrm;
    END;

    IF ( p_attr_group_name = 'BILLDOCS' AND is_billdoc_exist(ln_owner_table_id) = 'Y') THEN
      lc_createExtensible := 'F';
    END IF;

    BEGIN
          IF lc_createExtensible = 'T' THEN
              FOR i IN 1 .. l_attributes_data_table.COUNT
              LOOP
                l_attributes_row_table.extend;
                --added new params by Avinash(v1.11) for R12 Upgrade Retrofit
                l_attributes_row_table(i) := ego_user_attr_row_obj(l_attributes_data_table(i).row_identifier --ROW_IDENTIFIER
                ,   ln_attr_group_id --ATTR_GROUP_ID
                ,   NULL --ATTR_GROUP_APP_ID
                ,   p_attr_group_type --ATTR_GROUP_TYPE
                ,   p_attr_group_name --ATTR_GROUP_NAME
                ,   NULL -- DATA_LEVEL 
                ,   NULL --DATA_LEVEL_1
                ,   NULL --DATA_LEVEL_2
                ,   NULL --DATA_LEVEL_3
                ,   NULL --DATA_LEVEL_4
                ,   NULL --DATA_LEVEL_5
                ,   NULL);

                IF (l_attributes_data_table(i).ATTR_NAME = 'BILLDOCS_CUST_DOC_ID') THEN
                     l_attributes_data_table(i).ATTR_VALUE_NUM := ln_cust_doc_id;
                END IF;
              END LOOP;

              l_pk_column_values := ego_col_name_value_pair_array(ego_col_name_value_pair_obj('CUST_ACCOUNT_ID'
                                                              ,   to_char(ln_owner_table_id)));

	      --changed params by Avinash(v1.11) for R12 Upgrade Retrofit
              ego_user_attrs_data_pub.process_user_attrs_data(p_api_version => 1.0
                                                          ,   p_object_name => 'XX_CDH_CUST_ACCOUNT'
                                                          ,   p_attributes_row_table => l_attributes_row_table
                                                          ,   p_attributes_data_table => l_attributes_data_table
                                                          ,   p_pk_column_name_value_pairs => l_pk_column_values
                                                          ,   p_class_code_name_value_pairs => l_class_code_values
                                                          ,   p_user_privileges_on_object => l_user_privileges_on_object
                                                          --,   p_change_info_table => NULL
                                                          --,   p_pending_b_table_name => 'XX_CDH_CUST_ACCT_EXT_B'
                                                          --,   p_pending_tl_table_name => 'XX_CDH_CUST_ACCT_EXT_TL'
                                                          --,   p_pending_vl_name => 'XX_CDH_CUST_ACCT_EXT_VL'
                                                          ,   p_entity_id => ln_entity_id
                                                          ,   p_entity_index => ln_entity_index
                                                          ,   p_entity_code => lv_entity_code
                                                          ,   p_debug_level => ln_debug_level
                                                          ,   p_init_error_handler => ln_init_error_handler
                                                          ,   p_write_to_concurrent_log => lv_write_to_concurrent_log
                                                          ,   p_init_fnd_msg_list => lv_init_fnd_msg_list
                                                          ,   p_log_errors => lv_log_errors
                                                          ,   p_add_errors_to_fnd_stack => lv_add_errors_to_fnd_stack
                                                          ,   p_commit => lv_commit
                                                          ,   x_failed_row_id_list => lv_failed_row_id_list
                                                          ,   x_return_status => lv_return_status
                                                          ,   x_errorcode => ln_errorcode
                                                          ,   x_msg_count => ln_msg_count
                                                          ,   x_msg_data => lv_msg_data);

              COMMIT;

              IF(lv_return_status <> fnd_api.g_ret_sts_success) THEN

                x_return_status := lv_return_status;
                lv_error_message := lv_msg_data;
                error_handler.get_message_list(l_errors_tbl);
                FOR i IN 1 .. l_errors_tbl.COUNT
                LOOP
                  lv_error_message := lv_error_message || ' ' || l_errors_tbl(i).message_text;
                END LOOP;
              END IF;

              x_error_message := lv_error_message;
          END IF;
EXCEPTION
WHEN OTHERS THEN
      x_return_status := 'E';
      x_error_message := x_error_message || sqlerrm;
END;

  EXCEPTION
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := x_error_message || sqlerrm;

  END process_account_record;

  -- +===================================================================+
  -- | Name        :  Process_Acct_Site_Record                             |
  -- | Description :  Creates or updates information in extensions tables|
  -- |                for Account Site.
  -- +===================================================================+
  PROCEDURE process_acct_site_record(p_acct_site_id IN NUMBER,   p_orig_system IN VARCHAR2,   p_orig_sys_reference IN VARCHAR2,   p_attr_group_type IN VARCHAR2,   p_attr_group_name IN VARCHAR2,   p_attributes_data_table IN ego_user_attr_data_table,   x_return_status OUT nocopy VARCHAR2,   x_error_message OUT nocopy VARCHAR2) IS
  l_change_info_table ego_user_attr_change_table DEFAULT NULL;
  ln_entity_id NUMBER DEFAULT NULL;
  ln_entity_index NUMBER DEFAULT NULL;
  lv_entity_code VARCHAR2(5) DEFAULT NULL;
  ln_debug_level NUMBER DEFAULT 0;
  ln_init_error_handler VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_write_to_concurrent_log VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_init_fnd_msg_list VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_log_errors VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_add_errors_to_fnd_stack VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_commit VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_failed_row_id_list VARCHAR2(25);
  lv_return_status VARCHAR2(5);
  ln_errorcode NUMBER;
  ln_msg_count NUMBER;
  lv_msg_data VARCHAR2(2000);
  lv_error_message VARCHAR2(4000);
  l_pk_column_values ego_col_name_value_pair_array;
  l_class_code_values ego_col_name_value_pair_array;
  l_user_privileges_on_object ego_varchar_tbl_type;

  l_attributes_row_table ego_user_attr_row_table;
  ln_retcode NUMBER;
  ln_errbuf VARCHAR2(2000);
  ln_owner_table_id NUMBER;
  ln_attr_group_id NUMBER;
  l_errors_tbl error_handler.error_tbl_type;
  BEGIN

     set_context;  --QC 29151
    x_return_status := 'S';

    IF p_acct_site_id IS NULL THEN
      xx_cdh_conv_master_pkg.get_osr_owner_table_id(p_orig_system => p_orig_system,   p_orig_sys_reference => p_orig_sys_reference,   p_owner_table_name => 'HZ_CUST_ACCT_SITES_ALL',   x_owner_table_id => ln_owner_table_id,   x_retcode => ln_retcode,   x_errbuf => ln_errbuf);
    ELSE
      ln_owner_table_id := p_acct_site_id;
    END IF;

    BEGIN
      SELECT attr_group_id
      INTO ln_attr_group_id
      FROM ego_fnd_dsc_flx_ctx_ext
      WHERE descriptive_flexfield_name = p_attr_group_type
       AND descriptive_flex_context_code = p_attr_group_name;

    EXCEPTION
    WHEN others THEN
      x_return_status := 'E';
      x_error_message := 'Attr_Group_ID Does not Exist.';
    END;

    FOR i IN 1 .. p_attributes_data_table.COUNT
    LOOP

      l_attributes_row_table.extend;
      --added new params by Avinash(v1.11) for R12 Upgrade Retrofit
      l_attributes_row_table(i) := ego_user_attr_row_obj(p_attributes_data_table(i).row_identifier --ROW_IDENTIFIER
      ,   ln_attr_group_id --ATTR_GROUP_ID
      ,   NULL --ATTR_GROUP_APP_ID
      ,   p_attr_group_type --ATTR_GROUP_TYPE
      ,   p_attr_group_name --ATTR_GROUP_NAME
      ,   NULL -- DATA_LEVEL
      ,   NULL --DATA_LEVEL_1
      ,   NULL --DATA_LEVEL_2
      ,   NULL --DATA_LEVEL_3
      ,   NULL --DATA_LEVEL_4
      ,   NULL --DATA_LEVEL_5
      ,   NULL);

    END LOOP;

    l_pk_column_values := ego_col_name_value_pair_array(ego_col_name_value_pair_obj('CUST_ACCT_SITE_ID',   to_char(ln_owner_table_id)));

    --changed params by Avinash(v1.11) for R12 Upgrade Retrofit
    ego_user_attrs_data_pub.process_user_attrs_data(p_api_version => 1.0,   p_object_name => 'XX_CDH_CUST_ACCT_SITE',   p_attributes_row_table => l_attributes_row_table,   
    p_attributes_data_table => p_attributes_data_table,   p_pk_column_name_value_pairs => l_pk_column_values,   p_class_code_name_value_pairs => l_class_code_values,   
    p_user_privileges_on_object => l_user_privileges_on_object,   
    --p_change_info_table => NULL,   p_pending_b_table_name => 'XX_CDH_ACCT_SITE_EXT_B',   p_pending_tl_table_name => 'XX_CDH_ACCT_SITE_EXT_TL',   p_pending_vl_name => 'XX_CDH_ACCT_SITE_EXT_VL',   
    p_entity_id => ln_entity_id,   p_entity_index => ln_entity_index,   p_entity_code => lv_entity_code,   p_debug_level => ln_debug_level,   p_init_error_handler => ln_init_error_handler,   p_write_to_concurrent_log => lv_write_to_concurrent_log,   p_init_fnd_msg_list => lv_init_fnd_msg_list,   p_log_errors => lv_log_errors,   p_add_errors_to_fnd_stack => lv_add_errors_to_fnd_stack,   p_commit => lv_commit,   x_failed_row_id_list => lv_failed_row_id_list,   x_return_status => lv_return_status,   x_errorcode => ln_errorcode,   x_msg_count => ln_msg_count,   x_msg_data => lv_msg_data);

    COMMIT;

    IF(lv_return_status <> fnd_api.g_ret_sts_success) THEN

      x_return_status := lv_return_status;

      lv_error_message := lv_msg_data;
      error_handler.get_message_list(l_errors_tbl);
      FOR i IN 1 .. l_errors_tbl.COUNT
      LOOP
        lv_error_message := lv_error_message || ' ' || l_errors_tbl(i).message_text;
      END LOOP;
    END IF;

    x_error_message := lv_error_message;

  EXCEPTION
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := x_error_message || sqlerrm;

  END process_acct_site_record;

  -- +===================================================================+
  -- | Name        :  Process_Acct_Site_Use_Record                             |
  -- | Description :  Creates or updates information in extensions tables|
  -- |                for Account Site Use.
  -- +===================================================================+
  PROCEDURE process_acct_site_use_record(p_acct_site_use_id IN NUMBER,   p_orig_system IN VARCHAR2,   p_orig_sys_reference IN VARCHAR2,   p_attr_group_type IN VARCHAR2,   p_attr_group_name IN VARCHAR2,   p_attributes_data_table IN ego_user_attr_data_table,   x_return_status OUT nocopy VARCHAR2,   x_error_message OUT nocopy VARCHAR2) IS
  l_change_info_table ego_user_attr_change_table DEFAULT NULL;
  ln_entity_id NUMBER DEFAULT NULL;
  ln_entity_index NUMBER DEFAULT NULL;
  lv_entity_code VARCHAR2(5) DEFAULT NULL;
  ln_debug_level NUMBER DEFAULT 0;
  ln_init_error_handler VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_write_to_concurrent_log VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_init_fnd_msg_list VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_log_errors VARCHAR2(5) DEFAULT fnd_api.g_true;
  lv_add_errors_to_fnd_stack VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_commit VARCHAR2(5) DEFAULT fnd_api.g_false;
  lv_failed_row_id_list VARCHAR2(25);
  lv_return_status VARCHAR2(5);
  ln_errorcode NUMBER;
  ln_msg_count NUMBER;
  lv_msg_data VARCHAR2(2000);
  lv_error_message VARCHAR2(4000);
  l_pk_column_values ego_col_name_value_pair_array;
  l_class_code_values ego_col_name_value_pair_array;
  l_user_privileges_on_object ego_varchar_tbl_type;

  l_attributes_row_table ego_user_attr_row_table;
  ln_retcode NUMBER;
  ln_errbuf VARCHAR2(2000);
  ln_owner_table_id NUMBER;
  ln_attr_group_id NUMBER;
  l_errors_tbl error_handler.error_tbl_type;
  BEGIN
  
    set_context;  --QC 29151
    x_return_status := 'S';

    IF p_acct_site_use_id IS NULL THEN
      xx_cdh_conv_master_pkg.get_osr_owner_table_id(p_orig_system => p_orig_system,   p_orig_sys_reference => p_orig_sys_reference,   p_owner_table_name => 'HZ_CUST_SITE_USES_ALL',   x_owner_table_id => ln_owner_table_id,   x_retcode => ln_retcode,   x_errbuf => ln_errbuf);
    ELSE
      ln_owner_table_id := p_acct_site_use_id;
    END IF;

    BEGIN
      SELECT attr_group_id
      INTO ln_attr_group_id
      FROM ego_fnd_dsc_flx_ctx_ext
      WHERE descriptive_flexfield_name = p_attr_group_type
       AND descriptive_flex_context_code = p_attr_group_name;

    EXCEPTION
    WHEN others THEN
      x_return_status := 'E';
      x_error_message := 'Attr_Group_ID Does not Exist.';
    END;

    FOR i IN 1 .. p_attributes_data_table.COUNT
    LOOP

      l_attributes_row_table.extend;
      --added new params by Avinash(v1.11) for R12 Upgrade Retrofit
      l_attributes_row_table(i) := ego_user_attr_row_obj(p_attributes_data_table(i).row_identifier --ROW_IDENTIFIER
      ,   ln_attr_group_id --ATTR_GROUP_ID
      ,   NULL --ATTR_GROUP_APP_ID
      ,   p_attr_group_type --ATTR_GROUP_TYPE
      ,   p_attr_group_name --ATTR_GROUP_NAME
      ,   NULL -- DATA_LEVEL
      ,   NULL --DATA_LEVEL_1
      ,   NULL --DATA_LEVEL_2
      ,   NULL --DATA_LEVEL_3
      ,   NULL --DATA_LEVEL_4
      ,   NULL --DATA_LEVEL_5
      ,   NULL);

    END LOOP;

    l_pk_column_values := ego_col_name_value_pair_array(ego_col_name_value_pair_obj('SITE_USE_ID',   to_char(ln_owner_table_id)));

    --changed params by Avinash(v1.11) for R12 Upgrade Retrofit
    ego_user_attrs_data_pub.process_user_attrs_data(p_api_version => 1.0,   p_object_name => 'XX_CDH_ACCT_SITE_USES',   p_attributes_row_table => l_attributes_row_table,   
    p_attributes_data_table => p_attributes_data_table,   p_pk_column_name_value_pairs => l_pk_column_values,   p_class_code_name_value_pairs => l_class_code_values,   
    p_user_privileges_on_object => l_user_privileges_on_object,   
    --p_change_info_table => NULL,   p_pending_b_table_name => 'XX_CDH_SITE_USES_EXT_B',   p_pending_tl_table_name => 'XX_CDH_SITE_USES_EXT_TL',   p_pending_vl_name => 'XX_CDH_SITE_USES_EXT_VL',   
    p_entity_id => ln_entity_id,   p_entity_index => ln_entity_index,   p_entity_code => lv_entity_code,   p_debug_level => ln_debug_level,   p_init_error_handler => ln_init_error_handler,   p_write_to_concurrent_log => lv_write_to_concurrent_log,   p_init_fnd_msg_list => lv_init_fnd_msg_list,   p_log_errors => lv_log_errors,   p_add_errors_to_fnd_stack => lv_add_errors_to_fnd_stack,   p_commit => lv_commit,   x_failed_row_id_list => lv_failed_row_id_list,   x_return_status => lv_return_status,   x_errorcode => ln_errorcode,   x_msg_count => ln_msg_count,   x_msg_data => lv_msg_data);

    COMMIT;

    IF(lv_return_status <> fnd_api.g_ret_sts_success) THEN

      x_return_status := lv_return_status;

      lv_error_message := lv_msg_data;
      error_handler.get_message_list(l_errors_tbl);
      FOR i IN 1 .. l_errors_tbl.COUNT
      LOOP
        lv_error_message := lv_error_message || ' ' || l_errors_tbl(i).message_text;
      END LOOP;
    END IF;

    x_error_message := lv_error_message;

  EXCEPTION
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := x_error_message || sqlerrm;

  END process_acct_site_use_record;

  -- +==========================================================================+
  -- | Name        :  Process_Person_Record                                    |
  -- | Description :  Creates or updates the information in extensions tables  |
  -- |                for Person Profile.                                      |
  -- +==========================================================================+

  PROCEDURE process_person_record(p_person_id IN NUMBER,   p_person_osr IN VARCHAR2,   p_attr_group_type IN VARCHAR2,   p_attr_group_name IN VARCHAR2,   p_attributes_data_table IN ego_user_attr_data_table,   x_return_status OUT nocopy VARCHAR2,   x_error_message OUT nocopy VARCHAR2) IS

  l_api_version NUMBER;
  l_attributes_row_table ego_user_attr_row_table := ego_user_attr_row_table();
  l_failed_row_id_list VARCHAR2(25);
  l_return_status VARCHAR2(5);
  l_errorcode NUMBER;
  l_msg_count NUMBER;
  l_msg_data VARCHAR2(500);
  ln_attr_group_id NUMBER;
  l_errors_tbl error_handler.error_tbl_type;
  ln_msg_text VARCHAR2(2000);
  ln_profile_id NUMBER;
  ln_person_id NUMBER;
  lv_error_message VARCHAR2(4000);

  CURSOR c_party_id IS
  SELECT par.party_id
  FROM hz_orig_sys_references osr,
    hz_parties par
  WHERE osr.orig_system_reference = p_person_osr
   AND osr.owner_table_name = 'HZ_PARTIES'
   AND osr.orig_system = 'A0'
   AND osr.owner_table_id = par.party_id
   AND par.party_type = 'PERSON'
   AND osr.status = 'A';

  CURSOR c_per_profile(person_id NUMBER) IS
  SELECT person_profile_id
  FROM hz_person_profiles
  WHERE party_id = person_id
   AND effective_end_date IS NULL;

  CURSOR c_attbt_group_id IS
  SELECT attr_group_id
  FROM ego_fnd_dsc_flx_ctx_ext
  WHERE descriptive_flexfield_name = p_attr_group_type
   AND descriptive_flex_context_code = p_attr_group_name;

  BEGIN
    set_context;  --QC 29151
    x_return_status := 'S';

    IF p_person_id IS NULL THEN

      OPEN c_party_id;
      FETCH c_party_id
      INTO ln_person_id;
      CLOSE c_party_id;

      IF ln_person_id IS NULL THEN
        x_return_status := 'E';
        x_error_message := 'Person Does not Exist for the OSR ' || p_person_osr || '.';
      END IF;

    ELSE
      ln_person_id := p_person_id;
    END IF;

    OPEN c_per_profile(ln_person_id);
    FETCH c_per_profile
    INTO ln_profile_id;
    CLOSE c_per_profile;

    IF ln_profile_id IS NULL THEN
      x_return_status := 'E';
      x_error_message := x_error_message || ' Profile Does not Exist.';
    END IF;

    OPEN c_attbt_group_id;
    FETCH c_attbt_group_id
    INTO ln_attr_group_id;
    CLOSE c_attbt_group_id;

    IF ln_attr_group_id IS NULL THEN
      x_return_status := 'E';
      x_error_message := x_error_message || ' Attribute Group Does not Exist.';
    END IF;

    IF x_return_status = 'S' THEN

      FOR i IN 1 .. p_attributes_data_table.COUNT
      LOOP

        l_attributes_row_table.extend;
        --added new params by Avinash(v1.11) for R12 Upgrade Retrofit
        l_attributes_row_table(i) := ego_user_attr_row_obj(p_attributes_data_table(i).row_identifier --ROW_IDENTIFIER
        ,   ln_attr_group_id --ATTR_GROUP_ID
        ,   NULL --ATTR_GROUP_APP_ID
        ,   p_attr_group_type --ATTR_GROUP_TYPE
        ,   p_attr_group_name --ATTR_GROUP_NAME
        ,   NULL -- DATA_LEVEL
        ,   NULL --DATA_LEVEL_1
        ,   NULL --DATA_LEVEL_2
        ,   NULL --DATA_LEVEL_3
        ,   NULL --DATA_LEVEL_4
        ,   NULL --DATA_LEVEL_5
        ,   NULL);

      END LOOP;

      hz_extensibility_pub.process_person_record(p_api_version => 1.0,   p_person_profile_id => ln_profile_id,   p_attributes_row_table => l_attributes_row_table,   p_attributes_data_table => p_attributes_data_table,   p_log_errors => fnd_api.g_false,   x_failed_row_id_list => l_failed_row_id_list,   x_return_status => l_return_status,   x_errorcode => l_errorcode,   x_msg_count => l_msg_count,   x_msg_data => l_msg_data);

      COMMIT;

      IF(l_return_status <> fnd_api.g_ret_sts_success) THEN
        x_return_status := l_return_status;
        lv_error_message := l_msg_data;
        error_handler.get_message_list(l_errors_tbl);
        FOR i IN 1 .. l_errors_tbl.COUNT
        LOOP
          lv_error_message := lv_error_message || ' ' || l_errors_tbl(i).message_text;
        END LOOP;

        x_error_message := x_error_message || lv_error_message;
      END IF;

    END IF;

  EXCEPTION
  WHEN others THEN
    x_return_status := 'E';
    x_error_message := x_error_message || sqlerrm;
    CLOSE c_party_id;
    CLOSE c_per_profile;
    CLOSE c_attbt_group_id;
  END process_person_record;

END xx_crm_extn_attbt_sync_pkg;
/
SHOW ERRORS;