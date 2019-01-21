create or replace
package  body XX_CDH_DOWNTIME_DELTA_PKG
as
  gn_application_id   CONSTANT NUMBER:=222;--AR Account Receivable
--Procedure for logging debug log
PROCEDURE log_debug_msg ( 
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2 )
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
      ,p_module_name             => 'CDH'                --------index exists on module_name
      ,p_error_message           => p_debug_msg
      ,p_error_message_severity  => 'LOG'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_debug_msg;

--Procedure for logging Errors/Exceptions
PROCEDURE log_error ( 
                      p_error_pkg          IN  VARCHAR2
                     ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
BEGIN
    XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXCRM'
      ,p_program_type            => 'ERROR'              --------index exists on program_type
      ,p_attribute15             => p_error_pkg          --------index exists on attribute15
      ,p_program_id              => 0                    
      ,p_module_name             => 'CDH'                --------index exists on module_name
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );

END log_error;

FUNCTION get_owner_table_id(
  p_orig_system_reference   IN VARCHAR2,
  p_orig_system             IN VARCHAR2,
  p_owner_table_name        IN VARCHAR2
) RETURN NUMBER
IS

ln_owner_table_id       NUMBER;

BEGIN

   SELECT owner_table_id
   INTO   ln_owner_table_id
   FROM   hz_orig_sys_references
   WHERE  orig_system_reference = p_orig_system_reference
   AND    orig_system           = p_orig_system
   AND    owner_table_name      = p_owner_table_name
   AND    status                = 'A';

   RETURN ln_owner_table_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END get_owner_table_id;

procedure bumpup_batch_id(
  p_source_batch_id         IN NUMBER
) 
IS

  ln_batch_id               NUMBER;
  ln_dummy_batch_id         NUMBER;

BEGIN

   select max(batch_id)
   into   ln_batch_id
   from   hz_imp_batch_summary;

   if p_source_batch_id > ln_batch_id then
     for i in 1..(p_source_batch_id - ln_batch_id)
     loop
       select HZ_IMP_BATCH_SUMMARY_S.nextval into ln_dummy_batch_id from dual;
     end loop;
   end if;

EXCEPTION
    WHEN OTHERS THEN
        log_error('XX_CDH_DOWNTIME_DELTA_PKG.BUMPUP_BATCH_ID','BUMPUP_BATCH_ID_ERROR: ' || sqlerrm);

END bumpup_batch_id;


  --Procedure for loading Org_Cust_BO which is of XMLTYPE from the source system staging table
  --into a target system staging table
  PROCEDURE loadCustomerBO(errbuf  OUT NOCOPY VARCHAR2
                         , retcode OUT NOCOPY VARCHAR2)
  IS
   ln_organization_id           NUMBER;
   lc_organization_os           hz_orig_sys_references.orig_system%TYPE := 'A0';
   lc_organization_osr          hz_orig_sys_references.orig_system_reference%TYPE;
   lo_org_cust_obj              HZ_ORG_CUST_BO := HZ_ORG_CUST_BO(null, null,HZ_CUST_ACCT_BO_TBL());
   lc_return_status             VARCHAR2(1);
   ln_msg_count                 NUMBER;   
   lc_msg_data                  VARCHAR2(2000);
   lc_downtime_time_st          VARCHAR2(255):= FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START');
   lv_db_link                   VARCHAR2(200) := '@' || fnd_profile.value('XX_CS_STANDBY_DBLINK');

   lv_sql                       VARCHAR2(2000);

   TYPE CustCursorType          IS REF CURSOR;
   cust_cur                     CustCursorType;

   l_bpel_process_id            number;
   l_interface_status           number;
   l_creation_date              date;
   l_last_update_date           date;
   l_hz_org_cust_bo_payload     sys.XMLTYPE;
   l_xx_cdh_acct_ext_bo_payload sys.XMLTYPE; 

  BEGIN
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMERBO','START');
      lv_sql := 'select BPEL_PROCESS_ID,                                                         ' ||
            '       ORG_CUST_BO_PAYLOAD,                                                         ' ||
            '       ORIG_SYSTEM_REFERENCE,                                                       ' ||
            '       INTERFACE_STATUS,                                                            ' ||
            '       CREATION_DATE                                                               ' ||
            ' from  XX_CDH_CUST_BO_STG' || lv_db_link  ||
            ' where creation_date >= to_date(''' || lc_downtime_time_st || ''', ''DD-MON-YYYY HH24:MI:SS'')'; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMERBO','lv_sql: ' || lv_sql);

    --open the cursor
    open cust_cur for lv_sql;
    loop
      --Fetch the cursor values into the temp variables.
      fetch cust_cur into l_bpel_process_id, 
                          l_hz_org_cust_bo_payload,
                          lc_organization_osr,
                          l_interface_status,
                          l_creation_date;
       exit when cust_cur%NOTFOUND; 
      --insert into the target staging table.
      insert into XX_CDH_CUST_BO_STG ( BPEL_PROCESS_ID,  
                                             ORG_CUST_BO_PAYLOAD,  
                                             ORIG_SYSTEM_REFERENCE,
                                             INTERFACE_STATUS,     
                                             CREATION_DATE,        
                                             CREATED_BY 
                                           )
                                  values   ( l_bpel_process_id,  
                                             l_hz_org_cust_bo_payload,  
                                             lc_organization_osr,
                                             l_interface_status,     
                                             l_creation_date,        
                                             FND_GLOBAL.User_ID 
                                           );

    end loop;
    commit;
    close cust_cur;
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMERBO','END');
EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMERBO','LOADCUSTOMERBO_ERROR: ' || sqlerrm);
END loadCustomerBO;

 PROCEDURE loadCustomer  ( errbuf      OUT NOCOPY VARCHAR2
                         , retcode     OUT NOCOPY VARCHAR2
                         , p_batch_id             NUMBER)
 IS

   ln_target_batch_id         NUMBER;
   lv_org_party_sql           VARCHAR2(2000);
   lv_org_address_sql         VARCHAR2(2000);
   lv_address_uses_sql        VARCHAR2(2000);
   lv_account_sql             VARCHAR2(4000);
   lv_acct_sites_sql          VARCHAR2(4000);
   lv_site_uses_sql           VARCHAR2(4000);
   lv_org_contacts_sql        VARCHAR2(6000);
   lv_cont_point_sql          VARCHAR2(8000);
   lv_db_link                 VARCHAR2(200) := '@' || fnd_profile.value('XX_CS_STANDBY_DBLINK'); -- GMILL_STNDBY
   --lv_db_link                 VARCHAR2(200) :=  fnd_profile.value('XX_CS_STANDBY_DBLINK'); -- GMILL_STNDBY -- for Testing

 BEGIN

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','START');

    bumpup_batch_id(p_batch_id);

    select HZ_IMP_BATCH_SUMMARY_S.nextval
    into   ln_target_batch_id from dual;

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','ln_target_batch_id: ' || ln_target_batch_id);

      lv_org_party_sql :=    
                   ' INSERT INTO HZ_IMP_PARTIES_INT ' ||
                   ' (BATCH_ID,                     ' ||
                   ' PARTY_ORIG_SYSTEM,             ' ||
                   ' PARTY_ORIG_SYSTEM_REFERENCE,   ' ||
                   ' PARTY_TYPE,                    ' ||
                   ' ATTRIBUTE4,                    ' ||
                   ' ATTRIBUTE9,                    ' ||
                   ' ATTRIBUTE13,                   ' ||
                   ' ORGANIZATION_NAME,             ' ||
                   ' GSA_INDICATOR_FLAG,            ' ||
                   ' CREATED_BY_MODULE)             ' ||
                   ' (SELECT  ' || ln_target_batch_id || ', ' ||
                   ' PARTY_ORIG_SYSTEM,             ' ||
                   ' PARTY_ORIG_SYSTEM_REFERENCE,   ' ||
                   ' PARTY_TYPE,                    ' ||
                   ' ATTRIBUTE4,                    ' ||
                   ' ATTRIBUTE9,                    ' ||
                   ' ATTRIBUTE13,                   ' ||
                   ' ORGANIZATION_NAME,             ' ||
                   ' GSA_INDICATOR_FLAG,            ' ||
                   ' CREATED_BY_MODULE              ' ||
                   ' FROM HZ_IMP_PARTIES_INT        ' || lv_db_link  ||
                   ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_org_party_sql: ' || lv_org_party_sql);
    execute immediate lv_org_party_sql using p_batch_id;

      lv_org_address_sql :=    
                    'INSERT  INTO   HZ_IMP_ADDRESSES_INT  ' || 
                    '     (BATCH_ID,                      ' || 
                    '     PARTY_ORIG_SYSTEM,              ' || 
                    '     PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    '     SITE_ORIG_SYSTEM,               ' || 
                    '     SITE_ORIG_SYSTEM_REFERENCE,     ' || 
                    '     ADDRESS1,                       ' || 
                    '     ADDRESS2,                       ' || 
                    '     ADDRESS3,                       ' || 
                    '     ADDRESS4,                       ' || 
                    '     ADDRESS_LINES_PHONETIC,         ' || 
                    '     CITY,                           ' || 
                    '     COUNTRY,                        ' || 
                    '     COUNTY,                         ' || 
                    '     POSTAL_CODE,                    ' || 
                    '     PROVINCE,                       ' || 
                    '     STATE,                          ' || 
                    '     ATTRIBUTE1,                     ' || 
                    '     ATTRIBUTE2,                     ' || 
                    '     CREATED_BY_MODULE,              ' || 
                    '     PRIMARY_FLAG,                   ' || 
                    '     PARTY_ID)                       ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '     PARTY_ORIG_SYSTEM,              ' || 
                    '     PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    '     SITE_ORIG_SYSTEM,               ' || 
                    '     SITE_ORIG_SYSTEM_REFERENCE,     ' || 
                    '     ADDRESS1,                       ' || 
                    '     ADDRESS2,                       ' || 
                    '     ADDRESS3,                       ' || 
                    '     ADDRESS4,                       ' || 
                    '     ADDRESS_LINES_PHONETIC,         ' || 
                    '     CITY,                           ' || 
                    '     COUNTRY,                        ' || 
                    '     COUNTY,                         ' || 
                    '     POSTAL_CODE,                    ' || 
                    '     PROVINCE,                       ' || 
                    '     STATE,                          ' || 
                    '     ATTRIBUTE1,                     ' || 
                    '     ATTRIBUTE2,                     ' || 
                    '     CREATED_BY_MODULE,              ' || 
                    '     PRIMARY_FLAG,                   ' || 
                    '     PARTY_ID                        ' || 
                    ' FROM HZ_IMP_ADDRESSES_INT           ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_org_address_sql: ' || lv_org_address_sql);
    execute immediate lv_org_address_sql using p_batch_id;

      lv_address_uses_sql :=    
                    'INSERT INTO HZ_IMP_ADDRESSUSES_INT   ' || 
                    '       (BATCH_ID,                    ' || 
                    '        PARTY_ORIG_SYSTEM,           ' || 
                    '        PARTY_ORIG_SYSTEM_REFERENCE, ' || 
                    '        SITE_ORIG_SYSTEM,            ' || 
                    '        SITE_ORIG_SYSTEM_REFERENCE,  ' || 
                    '        SITE_USE_TYPE,               ' || 
                    '        CREATED_BY_MODULE,           ' || 
                    '        PRIMARY_FLAG)                ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '        PARTY_ORIG_SYSTEM,           ' || 
                    '        PARTY_ORIG_SYSTEM_REFERENCE, ' || 
                    '        SITE_ORIG_SYSTEM,            ' || 
                    '        SITE_ORIG_SYSTEM_REFERENCE,  ' || 
                    '        SITE_USE_TYPE,               ' || 
                    '        CREATED_BY_MODULE,           ' || 
                    '        PRIMARY_FLAG                 ' || 
                    ' FROM HZ_IMP_ADDRESSUSES_INT         ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

      log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_address_uses_sql: ' || lv_address_uses_sql);
      execute immediate lv_address_uses_sql using p_batch_id;

      lv_account_sql :=    
                    'INSERT INTO XXOD_HZ_IMP_ACCOUNTS_STG  ' || 
                    '      (BATCH_ID,                      ' || 
                    '      RECORD_ID,                      ' || 
                    '      PARTY_ORIG_SYSTEM,              ' || 
                    '      PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    '      ACCOUNT_ORIG_SYSTEM,            ' || 
                    '      ACCOUNT_ORIG_SYSTEM_REFERENCE,  ' || 
                    '      CUSTOMER_ATTRIBUTE_CATEGORY,    ' || 
                    '      CUSTOMER_ATTRIBUTE1,            ' || 
                    '      CUSTOMER_ATTRIBUTE2,            ' || 
                    '      CUSTOMER_ATTRIBUTE3,            ' || 
                    '      CUSTOMER_ATTRIBUTE4,            ' || 
                    '      CUSTOMER_ATTRIBUTE5,            ' || 
                    '      CUSTOMER_ATTRIBUTE6,            ' || 
                    '      CUSTOMER_ATTRIBUTE7,            ' || 
                    '      CUSTOMER_ATTRIBUTE8,            ' || 
                    '      CUSTOMER_ATTRIBUTE9,            ' || 
                    '      CUSTOMER_ATTRIBUTE10,           ' || 
                    '      CUSTOMER_ATTRIBUTE11,           ' || 
                    '      CUSTOMER_ATTRIBUTE12,           ' || 
                    '      CUSTOMER_ATTRIBUTE13,           ' || 
                    '      CUSTOMER_ATTRIBUTE14,           ' || 
                    '      CUSTOMER_ATTRIBUTE15,           ' ||
                    '      CUSTOMER_ATTRIBUTE16,           ' || 
                    '      CUSTOMER_ATTRIBUTE17,           ' || 
                    '      CUSTOMER_ATTRIBUTE18,           ' || 
                    '      CUSTOMER_ATTRIBUTE19,           ' || 
                    '      CUSTOMER_ATTRIBUTE20,           ' || 
                    '      CUSTOMER_CLASS_CODE,            ' || 
                    '      ACCOUNT_NAME,                   ' || 
                    '      CUSTOMER_STATUS,                ' || 
                    '      CUSTOMER_TYPE,                  ' || 
                    '      CUST_TAX_CODE,                  ' || 
                    '      SALES_CHANNEL_CODE)             ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '      XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL, ' || 
                    '      PARTY_ORIG_SYSTEM,              ' || 
                    '      PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    '      ACCOUNT_ORIG_SYSTEM,            ' || 
                    '      ACCOUNT_ORIG_SYSTEM_REFERENCE,  ' || 
                    '      CUSTOMER_ATTRIBUTE_CATEGORY,    ' || 
                    '      CUSTOMER_ATTRIBUTE1,            ' || 
                    '      CUSTOMER_ATTRIBUTE2,            ' || 
                    '      CUSTOMER_ATTRIBUTE3,            ' || 
                    '      CUSTOMER_ATTRIBUTE4,            ' || 
                    '      CUSTOMER_ATTRIBUTE5,            ' || 
                    '      CUSTOMER_ATTRIBUTE6,            ' || 
                    '      CUSTOMER_ATTRIBUTE7,            ' || 
                    '      CUSTOMER_ATTRIBUTE8,            ' || 
                    '      CUSTOMER_ATTRIBUTE9,            ' || 
                    '      CUSTOMER_ATTRIBUTE10,           ' || 
                    '      CUSTOMER_ATTRIBUTE11,           ' || 
                    '      CUSTOMER_ATTRIBUTE12,           ' || 
                    '      CUSTOMER_ATTRIBUTE13,           ' || 
                    '      CUSTOMER_ATTRIBUTE14,           ' || 
                    '      CUSTOMER_ATTRIBUTE15,           ' ||
                    '      CUSTOMER_ATTRIBUTE16,           ' || 
                    '      CUSTOMER_ATTRIBUTE17,           ' || 
                    '      CUSTOMER_ATTRIBUTE18,           ' || 
                    '      CUSTOMER_ATTRIBUTE19,           ' || 
                    '      CUSTOMER_ATTRIBUTE20,           ' || 
                    '      CUSTOMER_CLASS_CODE,            ' || 
                    '      ACCOUNT_NAME,                   ' || 
                    '      CUSTOMER_STATUS,                ' || 
                    '      CUSTOMER_TYPE,                  ' || 
                    '      CUST_TAX_CODE,                  ' || 
                    '      SALES_CHANNEL_CODE              ' || 
                    ' FROM XXOD_HZ_IMP_ACCOUNTS_STG        ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_account_sql: ' || lv_account_sql);
    execute immediate lv_account_sql using p_batch_id;

      lv_acct_sites_sql :=    
                    'INSERT INTO XXOD_HZ_IMP_ACCT_SITES_STG  ' || 
                    '  (BATCH_ID,                            ' || 
                    '  RECORD_ID,                            ' || 
                    '  PARTY_ORIG_SYSTEM,                    ' || 
                    '  PARTY_ORIG_SYSTEM_REFERENCE,          ' || 
                    '  ACCOUNT_ORIG_SYSTEM,                  ' || 
                    '  ACCOUNT_ORIG_SYSTEM_REFERENCE,        ' || 
                    '  PARTY_SITE_ORIG_SYSTEM,               ' || 
                    '  ADDRESS_ATTRIBUTE_CATEGORY,           ' || 
                    '  ADDRESS_ATTRIBUTE1,                   ' || 
                    '  ADDRESS_ATTRIBUTE2,                   ' || 
                    '  ADDRESS_ATTRIBUTE3,                   ' || 
                    '  ADDRESS_ATTRIBUTE4,                   ' || 
                    '  ADDRESS_ATTRIBUTE5,                   ' || 
                    '  ADDRESS_ATTRIBUTE6,                   ' || 
                    '  ADDRESS_ATTRIBUTE7,                   ' || 
                    '  ADDRESS_ATTRIBUTE8,                   ' || 
                    '  ADDRESS_ATTRIBUTE9,                   ' || 
                    '  ADDRESS_ATTRIBUTE10,                  ' || 
                    '  ADDRESS_ATTRIBUTE11,                  ' || 
                    '  ADDRESS_ATTRIBUTE12,                  ' || 
                    '  ADDRESS_ATTRIBUTE13,                  ' || 
                    '  ADDRESS_ATTRIBUTE14,                  ' ||
                    '  ADDRESS_ATTRIBUTE15,                  ' || 
                    '  ADDRESS_ATTRIBUTE16,                  ' || 
                    '  ADDRESS_ATTRIBUTE17,                  ' || 
                    '  ADDRESS_ATTRIBUTE18,                  ' || 
                    '  ADDRESS_ATTRIBUTE19,                  ' || 
                    '  ADDRESS_ATTRIBUTE20,                  ' || 
                    '  ADDRESS_CATEGORY_CODE,                ' || 
                    '  ACCT_SITE_ORIG_SYSTEM,                ' || 
                    '  ACCT_SITE_ORIG_SYS_REFERENCE,         ' || 
                    '  PARTY_SITE_ORIG_SYS_REFERENCE,        ' || 
                    '  ORG_ID)                               ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '  XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL,       ' || 
                    '  PARTY_ORIG_SYSTEM,                    ' || 
                    '  PARTY_ORIG_SYSTEM_REFERENCE,          ' || 
                    '  ACCOUNT_ORIG_SYSTEM,                  ' || 
                    '  ACCOUNT_ORIG_SYSTEM_REFERENCE,        ' || 
                    '  PARTY_SITE_ORIG_SYSTEM,               ' || 
                    '  ADDRESS_ATTRIBUTE_CATEGORY,           ' || 
                    '  ADDRESS_ATTRIBUTE1,                   ' || 
                    '  ADDRESS_ATTRIBUTE2,                   ' || 
                    '  ADDRESS_ATTRIBUTE3,                   ' || 
                    '  ADDRESS_ATTRIBUTE4,                   ' || 
                    '  ADDRESS_ATTRIBUTE5,                   ' || 
                    '  ADDRESS_ATTRIBUTE6,                   ' || 
                    '  ADDRESS_ATTRIBUTE7,                   ' || 
                    '  ADDRESS_ATTRIBUTE8,                   ' || 
                    '  ADDRESS_ATTRIBUTE9,                   ' || 
                    '  ADDRESS_ATTRIBUTE10,                  ' || 
                    '  ADDRESS_ATTRIBUTE11,                  ' || 
                    '  ADDRESS_ATTRIBUTE12,                  ' || 
                    '  ADDRESS_ATTRIBUTE13,                  ' || 
                    '  ADDRESS_ATTRIBUTE14,                  ' ||
                    '  ADDRESS_ATTRIBUTE15,                  ' || 
                    '  ADDRESS_ATTRIBUTE16,                  ' || 
                    '  ADDRESS_ATTRIBUTE17,                  ' || 
                    '  ADDRESS_ATTRIBUTE18,                  ' || 
                    '  ADDRESS_ATTRIBUTE19,                  ' || 
                    '  ADDRESS_ATTRIBUTE20,                  ' || 
                    '  ADDRESS_CATEGORY_CODE,                ' || 
                    '  ACCT_SITE_ORIG_SYSTEM,                ' || 
                    '  ACCT_SITE_ORIG_SYS_REFERENCE,         ' || 
                    '  PARTY_SITE_ORIG_SYS_REFERENCE,        ' || 
                    '  ORG_ID                                ' ||  
                    ' FROM XXOD_HZ_IMP_ACCT_SITES_STG        ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_acct_sites_sql: ' || lv_acct_sites_sql);
    execute immediate lv_acct_sites_sql using p_batch_id;

      lv_site_uses_sql :=    
                    'INSERT  INTO   XXOD_HZ_IMP_ACCT_SITE_USES_STG  ' || 
                    ' (batch_id,                      ' || 
                    ' RECORD_ID,                      ' || 
                    ' PARTY_ORIG_SYSTEM,              ' || 
                    ' PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    ' ACCOUNT_ORIG_SYSTEM,            ' || 
                    ' ACCOUNT_ORIG_SYSTEM_REFERENCE,  ' || 
                    ' ACCT_SITE_ORIG_SYSTEM,          ' || 
                    ' ACCT_SITE_ORIG_SYS_REFERENCE,   ' || 
                    ' PRIMARY_FLAG,                   ' || 
                    ' SITE_USE_ATTRIBUTE_CATEGORY,    ' || 
                    ' SITE_USE_ATTRIBUTE1,            ' || 
                    ' SITE_USE_ATTRIBUTE2,            ' || 
                    ' SITE_USE_ATTRIBUTE3,            ' || 
                    ' SITE_USE_ATTRIBUTE4,            ' || 
                    ' SITE_USE_ATTRIBUTE5,            ' || 
                    ' SITE_USE_ATTRIBUTE6,            ' || 
                    ' SITE_USE_ATTRIBUTE7,            ' || 
                    ' SITE_USE_ATTRIBUTE8,            ' || 
                    ' SITE_USE_ATTRIBUTE9,            ' || 
                    ' SITE_USE_ATTRIBUTE10,           ' || 
                    ' SITE_USE_CODE,                  ' || 
                    ' ORG_ID,                         ' ||
                    ' LOCATION)                       ' ||
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '  XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL,       ' || 
                    ' PARTY_ORIG_SYSTEM,              ' || 
                    ' PARTY_ORIG_SYSTEM_REFERENCE,    ' || 
                    ' ACCOUNT_ORIG_SYSTEM,            ' || 
                    ' ACCOUNT_ORIG_SYSTEM_REFERENCE,  ' || 
                    ' ACCT_SITE_ORIG_SYSTEM,          ' || 
                    ' ACCT_SITE_ORIG_SYS_REFERENCE,   ' || 
                    ' PRIMARY_FLAG,                   ' || 
                    ' SITE_USE_ATTRIBUTE_CATEGORY,    ' || 
                    ' SITE_USE_ATTRIBUTE1,            ' || 
                    ' SITE_USE_ATTRIBUTE2,            ' || 
                    ' SITE_USE_ATTRIBUTE3,            ' || 
                    ' SITE_USE_ATTRIBUTE4,            ' || 
                    ' SITE_USE_ATTRIBUTE5,            ' || 
                    ' SITE_USE_ATTRIBUTE6,            ' || 
                    ' SITE_USE_ATTRIBUTE7,            ' || 
                    ' SITE_USE_ATTRIBUTE8,            ' || 
                    ' SITE_USE_ATTRIBUTE9,            ' || 
                    ' SITE_USE_ATTRIBUTE10,           ' || 
                    ' SITE_USE_CODE,                  ' || 
                    ' ORG_ID,                         ' ||
                    ' LOCATION                        ' ||
                    ' FROM XXOD_HZ_IMP_ACCT_SITE_USES_STG           ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_site_uses_sql: ');
    execute immediate lv_site_uses_sql using p_batch_id;

      lv_org_contacts_sql :=    
                    'INSERT  INTO   HZ_IMP_CONTACTS_INT   ' || 
                    '  (BATCH_ID,                         ' || 
                    '  CONTACT_ORIG_SYSTEM,               ' || 
                    '  CONTACT_ORIG_SYSTEM_REFERENCE,     ' || 
                    '  SUB_ORIG_SYSTEM,                   ' || 
                    '  SUB_ORIG_SYSTEM_REFERENCE,         ' || 
                    '  OBJ_ORIG_SYSTEM,                   ' || 
                    '  OBJ_ORIG_SYSTEM_REFERENCE,         ' || 
                    '  RELATIONSHIP_TYPE,                 ' || 
                    '  RELATIONSHIP_CODE,                 ' || 
                    '  START_DATE,                        ' || 
                    '  END_DATE,                          ' || 
                    '  CREATED_BY_MODULE)                 ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '  CONTACT_ORIG_SYSTEM,               ' || 
                    '  CONTACT_ORIG_SYSTEM_REFERENCE,     ' || 
                    '  SUB_ORIG_SYSTEM,                   ' || 
                    '  SUB_ORIG_SYSTEM_REFERENCE,         ' || 
                    '  OBJ_ORIG_SYSTEM,                   ' || 
                    '  OBJ_ORIG_SYSTEM_REFERENCE,         ' || 
                    '  RELATIONSHIP_TYPE,                 ' || 
                    '  RELATIONSHIP_CODE,                 ' || 
                    '  START_DATE,                        ' || 
                    '  END_DATE,                          ' || 
                    '  CREATED_BY_MODULE                  ' || 
                    ' FROM HZ_IMP_CONTACTS_INT            ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_org_contacts_sql: ');
    execute immediate lv_org_contacts_sql using p_batch_id;

      lv_cont_point_sql :=    
                    'INSERT  INTO   HZ_IMP_CONTACTPTS_INT ' || 
                    '     (BATCH_ID,                      ' || 
                    '      CP_ORIG_SYSTEM,                ' || 
                    '      CP_ORIG_SYSTEM_REFERENCE,      ' || 
                    '      PARTY_ORIG_SYSTEM,             ' || 
                    '      PARTY_ORIG_SYSTEM_REFERENCE,   ' || 
                    '      SITE_ORIG_SYSTEM,              ' || 
                    '      SITE_ORIG_SYSTEM_REFERENCE,    ' || 
                    '      CONTACT_POINT_TYPE,            ' || 
                    '      CONTACT_POINT_PURPOSE,         ' || 
                    '      EDI_ECE_TP_LOCATION_CODE,      ' || 
                    '      EDI_ID_NUMBER,                 ' || 
                    '      EDI_PAYMENT_FORMAT,            ' || 
                    '      EDI_PAYMENT_METHOD,            ' || 
                    '      EDI_REMITTANCE_INSTRUCTION,    ' || 
                    '      EDI_REMITTANCE_METHOD,         ' || 
                    '      EDI_TP_HEADER_ID,              ' || 
                    '      EDI_TRANSACTION_HANDLING,      ' || 
                    '      EFT_PRINTING_PROGRAM_ID,       ' || 
                    '      EFT_SWIFT_CODE,                ' || 
                    '      EFT_TRANSMISSION_PROGRAM_ID,   ' || 
                    '      EFT_USER_NUMBER,               ' || 
                    '      EMAIL_ADDRESS,                 ' ||
                    '      EMAIL_FORMAT,                  ' || 
                    '      PHONE_AREA_CODE,               ' || 
                    '      PHONE_COUNTRY_CODE,            ' || 
                    '      PHONE_EXTENSION,               ' || 
                    '      PHONE_LINE_TYPE,               ' || 
                    '      PHONE_NUMBER,                  ' || 
                    '      RAW_PHONE_NUMBER,              ' || 
                    '      PHONE_CALLING_CALENDAR,        ' || 
                    '      TELEX_NUMBER,                  ' || 
                    '      URL,                           ' || 
                    '      WEB_TYPE,                      ' || 
                    '      ATTRIBUTE_CATEGORY,            ' || 
                    '      ATTRIBUTE1,                    ' || 
                    '      ATTRIBUTE2,                    ' || 
                    '      ATTRIBUTE3,                    ' || 
                    '      ATTRIBUTE4,                    ' || 
                    '      ATTRIBUTE5,                    ' || 
                    '      ATTRIBUTE6,                    ' ||
                    '      ATTRIBUTE7,                    ' ||
                    '      ATTRIBUTE8,                    ' ||
                    '      ATTRIBUTE9,                    ' ||
                    '      ATTRIBUTE10,                   ' ||
                    '      ATTRIBUTE11,                   ' ||
                    '      ATTRIBUTE12,                   ' ||
                    '      ATTRIBUTE13,                   ' ||
                    '      ATTRIBUTE14,                   ' ||
                    '      ATTRIBUTE15,                   ' ||
                    '      ATTRIBUTE16,                   ' ||
                    '      ATTRIBUTE17,                   ' ||
                    '      ATTRIBUTE18,                   ' ||
                    '      ATTRIBUTE19,                   ' ||
                    '      ATTRIBUTE20)                   ' || 
                    ' (SELECT  ' || ln_target_batch_id || ', ' ||
                    '      CP_ORIG_SYSTEM,                ' || 
                    '      CP_ORIG_SYSTEM_REFERENCE,      ' || 
                    '      PARTY_ORIG_SYSTEM,             ' || 
                    '      PARTY_ORIG_SYSTEM_REFERENCE,   ' || 
                    '      SITE_ORIG_SYSTEM,              ' || 
                    '      SITE_ORIG_SYSTEM_REFERENCE,    ' || 
                    '      CONTACT_POINT_TYPE,            ' || 
                    '      CONTACT_POINT_PURPOSE,         ' || 
                    '      EDI_ECE_TP_LOCATION_CODE,      ' || 
                    '      EDI_ID_NUMBER,                 ' || 
                    '      EDI_PAYMENT_FORMAT,            ' || 
                    '      EDI_PAYMENT_METHOD,            ' || 
                    '      EDI_REMITTANCE_INSTRUCTION,    ' || 
                    '      EDI_REMITTANCE_METHOD,         ' || 
                    '      EDI_TP_HEADER_ID,              ' || 
                    '      EDI_TRANSACTION_HANDLING,      ' || 
                    '      EFT_PRINTING_PROGRAM_ID,       ' || 
                    '      EFT_SWIFT_CODE,                ' || 
                    '      EFT_TRANSMISSION_PROGRAM_ID,   ' || 
                    '      EFT_USER_NUMBER,               ' || 
                    '      EMAIL_ADDRESS,                 ' ||
                    '      EMAIL_FORMAT,                  ' || 
                    '      PHONE_AREA_CODE,               ' || 
                    '      PHONE_COUNTRY_CODE,            ' || 
                    '      PHONE_EXTENSION,               ' || 
                    '      PHONE_LINE_TYPE,               ' || 
                    '      PHONE_NUMBER,                  ' || 
                    '      RAW_PHONE_NUMBER,              ' || 
                    '      PHONE_CALLING_CALENDAR,        ' || 
                    '      TELEX_NUMBER,                  ' || 
                    '      URL,                           ' || 
                    '      WEB_TYPE,                      ' || 
                    '      ATTRIBUTE_CATEGORY,            ' || 
                    '      ATTRIBUTE1,                    ' || 
                    '      ATTRIBUTE2,                    ' || 
                    '      ATTRIBUTE3,                    ' || 
                    '      ATTRIBUTE4,                    ' || 
                    '      ATTRIBUTE5,                    ' || 
                    '      ATTRIBUTE6,                    ' ||
                    '      ATTRIBUTE7,                    ' ||
                    '      ATTRIBUTE8,                    ' ||
                    '      ATTRIBUTE9,                    ' ||
                    '      ATTRIBUTE10,                   ' ||
                    '      ATTRIBUTE11,                   ' ||
                    '      ATTRIBUTE12,                   ' ||
                    '      ATTRIBUTE13,                   ' ||
                    '      ATTRIBUTE14,                   ' ||
                    '      ATTRIBUTE15,                   ' ||
                    '      ATTRIBUTE16,                   ' ||
                    '      ATTRIBUTE17,                   ' ||
                    '      ATTRIBUTE18,                   ' ||
                    '      ATTRIBUTE19,                   ' ||
                    '      ATTRIBUTE20                    ' || 
                    ' FROM HZ_IMP_CONTACTPTS_INT          ' || lv_db_link  ||
                    ' where batch_id = :1)' ; 

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','lv_cont_point_sql: ');
    execute immediate lv_cont_point_sql using p_batch_id;

    COMMIT;
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','END');

 EXCEPTION
   WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_DELTA_PKG.LOADCUSTOMER','LOADCUSTOMER_ERROR: ' || sqlerrm);
 END loadCustomer;

 PROCEDURE importCustomer  ( errbuf      OUT NOCOPY VARCHAR2
                           , retcode     OUT NOCOPY VARCHAR2
                           , p_batch_id             NUMBER)
 IS

  cursor C1(pn_batch_id NUMBER, p_party_type VARCHAR2) 
  is 
  select * 
  from   HZ_IMP_PARTIES_INT             
  where  batch_id = pn_batch_id
  and    party_type=p_party_type;

  cursor C2(pn_batch_id NUMBER, p_party_orig_system_reference VARCHAR2) 
  is 
  select * 
  from   HZ_IMP_ADDRESSES_INT           
  where batch_id = pn_batch_id 
  and party_orig_system_reference = p_party_orig_system_reference;

  cursor C3(pn_batch_id NUMBER, p_site_orig_system_reference VARCHAR2) 
  is 
  select * 
  from   HZ_IMP_ADDRESSUSES_INT         
  where batch_id = pn_batch_id
  and   site_orig_system_reference = p_site_orig_system_reference;

  cursor C4(pn_batch_id NUMBER, p_acct_orig_system_reference VARCHAR2) 
  is 
  select * 
  from  XXOD_HZ_IMP_ACCOUNTS_STG       
  where batch_id = pn_batch_id
  and   account_orig_system_reference = p_acct_orig_system_reference;

  cursor C5(pn_batch_id NUMBER, p_acct_orig_system_reference VARCHAR2)  
  is 
  select * 
  from   XXOD_HZ_IMP_ACCT_SITES_STG     
  where batch_id = pn_batch_id
  and   account_orig_system_reference = p_acct_orig_system_reference;

  cursor C6(pn_batch_id NUMBER, p_acct_orig_system_reference VARCHAR2)   
  is 
  select * 
  from   XXOD_HZ_IMP_ACCT_SITE_USES_STG 
  where batch_id = pn_batch_id
  and   account_orig_system_reference = p_acct_orig_system_reference;

  cursor C7(pn_batch_id NUMBER, p_obj_orig_system_reference VARCHAR2)
  is 
  select * 
  from   HZ_IMP_CONTACTS_INT            
  where batch_id = pn_batch_id
  and   obj_orig_system_reference = p_obj_orig_system_reference;

  cursor C8(pn_batch_id NUMBER, p_party_orig_system_reference VARCHAR2) 
  is 
  select * 
  from   HZ_IMP_PARTIES_INT             
  where  batch_id = pn_batch_id
  and    party_orig_system_reference=p_party_orig_system_reference;

  cursor C9(pn_batch_id NUMBER, p_party_orig_system_reference VARCHAR2)  
  is 
  select * 
  from   HZ_IMP_CONTACTPTS_INT          
  where batch_id = pn_batch_id
  and    party_orig_system_reference=p_party_orig_system_reference;

  p_init_msg_list       VARCHAR2(200) := 'Y';

  l_party_rec           HZ_PARTY_V2PUB.party_rec_type;
  l_per_party_rec       HZ_PARTY_V2PUB.party_rec_type;

  l_organization_rec    HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
  l_person_rec          HZ_PARTY_V2PUB.PERSON_REC_TYPE;
  l_cust_account_rec    HZ_CUST_ACCOUNT_V2PUB.cust_account_rec_type;                  
  l_party_site_rec      HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  l_party_site_use_rec  HZ_PARTY_SITE_V2PUB.PARTY_SITE_USE_REC_TYPE;
  l_cust_acct_site_rec  HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
  l_cust_site_use_rec   HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE;
  l_location_rec        HZ_LOCATION_V2PUB.LOCATION_REC_TYPE;
  l_org_contact_rec     HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
  l_contact_point_rec   HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
  l_email_rec           HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
  l_phone_rec           HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
  ln_contact_point_id   NUMBER;

  l_return_status       VARCHAR2(200);
  l_msg_count           NUMBER;
  l_msg_data            VARCHAR2(200);

  ln_org_party_id       NUMBER;
  lc_org_party_number   VARCHAR2(200);
  ln_org_profile_id     NUMBER;
  ln_per_party_id       NUMBER;
  ln_rel_party_id       NUMBER;
  ln_party_rel_id       NUMBER;

  lc_per_party_number   VARCHAR2(200);
  lc_rel_party_number   VARCHAR2(200);
  ln_per_profile_id     NUMBER;

  ln_cust_account_id    NUMBER;
  ln_cust_acct_site_id  NUMBER;
  ln_cust_site_use_id   NUMBER;
  lc_account_number     VARCHAR2(200);
  ln_location_id        NUMBER;
  ln_org_contact_id     NUMBER;

  ln_party_site_id      NUMBER;
  ln_party_site_use_id  NUMBER;
  lc_party_site_number  VARCHAR2(200);

  l_err_msg             varchar2(2000);

  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;

 BEGIN
   log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER','START');

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
    dbms_output.put_line('Exception in initializing : ' || SQLERRM);
   end;

   for hp_rec in C1(p_batch_id, 'ORGANIZATION')
   loop

       l_party_rec                   := null;
       l_per_party_rec               := null;
       l_organization_rec            := null;
       l_person_rec                  := null;
       l_cust_account_rec            := null;
       l_party_site_rec              := null;
       l_party_site_use_rec          := null;
       l_location_rec                := null;

       l_return_status    := null;
       l_msg_count        := null;
       l_msg_data         := null;
       ln_org_party_id    := null;
       lc_org_party_number:= null;
       ln_org_profile_id  := null;
       ln_per_party_id    := null;
       lc_per_party_number:= null;
       ln_per_profile_id  := null;  
     
       log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER', 'Party_Orig_System_Reference: ' || hp_rec.party_orig_system_reference);

       if (get_owner_table_id(hp_rec.party_orig_system_reference, hp_rec.party_orig_system, 'HZ_PARTIES') is NULL) then

         l_party_rec.orig_system := hp_rec.party_orig_system;
         l_party_rec.orig_system_reference := hp_rec.party_orig_system_reference;
         l_organization_rec.organization_type := hp_rec.party_type;
         l_organization_rec.attribute4 := hp_rec.attribute4;
         l_organization_rec.attribute9 := hp_rec.attribute9;
         l_organization_rec.attribute13 := hp_rec.attribute13;
         l_organization_rec.organization_name := hp_rec.organization_name;
         l_organization_rec.created_by_module := 'BO_API';
         l_organization_rec.party_rec := l_party_rec;
         
         ------------------------------------
         -- Create a new Organization Party
         ------------------------------------
         
         HZ_PARTY_V2PUB.CREATE_ORGANIZATION(
           P_INIT_MSG_LIST    => fnd_api.g_true,
           P_ORGANIZATION_REC => l_organization_rec,
           X_RETURN_STATUS    => l_return_status,
           X_MSG_COUNT        => l_msg_count,
           X_MSG_DATA         => l_msg_data,
           X_PARTY_ID         => ln_org_party_id,
           X_PARTY_NUMBER     => lc_org_party_number,
           X_PROFILE_ID       => ln_org_profile_id
         );
         log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
                'After CREATE_ORGANIZATION, l_return_status: ' || l_return_status || ', ln_org_party_id: ' || ln_org_party_id);

         if (l_return_status = 'S') then
           commit;
         end if;
         
         --l_organization_rec := null;
         
         for acct_rec in C4 (p_batch_id, hp_rec.party_orig_system_reference)
         loop
         
           l_organization_rec.created_by_module := 'BO_API';
           l_organization_rec.application_id := gn_application_id;
           l_organization_rec.party_rec.party_id    := ln_org_party_id;
           l_organization_rec.party_rec.party_number:= lc_org_party_number;
         
           l_cust_account_rec.orig_system := acct_rec.party_orig_system;
           l_cust_account_rec.orig_system_reference := acct_rec.party_orig_system_reference;
           l_cust_account_rec.account_name := acct_rec.account_name;
           l_cust_account_rec.status := 'A';
           l_cust_account_rec.customer_type := acct_rec.customer_type;
           l_cust_account_rec.attribute1  := acct_rec.customer_attribute1;
           l_cust_account_rec.attribute2  := acct_rec.customer_attribute2;
           l_cust_account_rec.attribute3  := acct_rec.customer_attribute3;
           l_cust_account_rec.attribute4  := acct_rec.customer_attribute4;
           l_cust_account_rec.attribute5  := acct_rec.customer_attribute5;
           l_cust_account_rec.attribute6  := acct_rec.customer_attribute6;
           l_cust_account_rec.attribute7  := acct_rec.customer_attribute7;
           l_cust_account_rec.attribute8  := acct_rec.customer_attribute8;
           l_cust_account_rec.attribute9  := acct_rec.customer_attribute9;
           l_cust_account_rec.attribute10 := acct_rec.customer_attribute10;
           l_cust_account_rec.attribute11 := acct_rec.customer_attribute11;
           l_cust_account_rec.attribute12 := acct_rec.customer_attribute12;
           l_cust_account_rec.attribute13 := acct_rec.customer_attribute13;
           l_cust_account_rec.attribute14 := acct_rec.customer_attribute14;
           l_cust_account_rec.attribute15 := acct_rec.customer_attribute15;
           l_cust_account_rec.attribute16 := acct_rec.customer_attribute16;
           l_cust_account_rec.attribute17 := acct_rec.customer_attribute17;
           l_cust_account_rec.attribute18 := acct_rec.customer_attribute18;
           l_cust_account_rec.attribute19 := acct_rec.customer_attribute19;
           l_cust_account_rec.attribute20 := acct_rec.customer_attribute20;
           l_cust_account_rec.tax_code := acct_rec.cust_tax_code;
           l_cust_account_rec.sales_channel_code := acct_rec.sales_channel_code;
           l_cust_account_rec.created_by_module := 'BO_API';
         
           l_return_status    := null;
           l_msg_count        := null;
           l_msg_data         := null;
           ----------------------------
           -- Create a new Account
           ----------------------------
           HZ_CUST_ACCOUNT_V2PUB.CREATE_CUST_ACCOUNT(
             P_INIT_MSG_LIST         => fnd_api.g_true,
             P_CUST_ACCOUNT_REC      => l_cust_account_rec,
             P_ORGANIZATION_REC      => l_organization_rec,
             P_CUSTOMER_PROFILE_REC  => null,
             P_CREATE_PROFILE_AMT    => FND_API.G_FALSE,
             X_CUST_ACCOUNT_ID       => ln_cust_account_id,
             X_ACCOUNT_NUMBER        => lc_account_number,
             X_PARTY_ID              => ln_org_party_id,
             X_PARTY_NUMBER          => lc_org_party_number,
             X_PROFILE_ID            => ln_org_profile_id,
             X_RETURN_STATUS         => l_return_status,
             X_MSG_COUNT             => l_msg_count,
             X_MSG_DATA              => l_msg_data
           );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After Create_Cust_Account, l_return_status: ' || l_return_status || ', ln_cust_account_id: ' || ln_cust_account_id);

           if (l_return_status = 'S') then
             commit;
           end if;
           l_err_msg :='';
           IF(l_msg_count >= 1) THEN 
             FOR I IN 1..20 LOOP 
                 l_err_msg := l_err_msg || FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ); 
             END LOOP; 
           ELSE 
             l_err_msg := l_msg_data; 
           END IF;

           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After Create_Cust_Account, l_err_msg: ' || l_err_msg);
         
         end loop; --end of acct_rec
         
         for site_rec in C2 (p_batch_id, hp_rec.party_orig_system_reference)
         loop
           l_location_rec.address1 := site_rec.address1;
           l_location_rec.address2 := site_rec.address2;
           l_location_rec.address3 := site_rec.address3;
           l_location_rec.address4 := site_rec.address4;
           l_location_rec.city     := site_rec.city;
           l_location_rec.state    := site_rec.state;
           l_location_rec.address_lines_phonetic := site_rec.address_lines_phonetic;
           l_location_rec.county   := site_rec.county;
           l_location_rec.country  := site_rec.country;
           l_location_rec.postal_code := site_rec.postal_code;
           l_location_rec.attribute1 := site_rec.attribute1;
           l_location_rec.attribute2 := site_rec.attribute2;
           l_location_rec.created_by_module := site_rec.created_by_module;
         
           ----------------------------
           -- Create a new Location
           ----------------------------
           l_return_status    := null;
           l_msg_count        := null;
           l_msg_data         := null;
           HZ_LOCATION_V2PUB.CREATE_LOCATION(
             P_INIT_MSG_LIST   => fnd_api.g_true,
             P_LOCATION_REC    => l_location_rec,
             X_LOCATION_ID     => ln_location_id,
             X_RETURN_STATUS   => l_return_status,
             X_MSG_COUNT       => l_msg_count,
             X_MSG_DATA        => l_msg_data
           );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER', 
             'After create_location, l_return_status: ' || l_return_status || ', ln_location_id: ' || ln_location_id);

           if (l_return_status = 'S') then
             commit;
           end if;
         
           l_party_site_rec.orig_system           := site_rec.site_orig_system;
           l_party_site_rec.orig_system_reference := site_rec.site_orig_system_reference;
           l_party_site_rec.identifying_address_flag := site_rec.primary_flag;
           l_party_site_rec.status                := 'A';
           l_party_site_rec.party_id              := ln_org_party_id;
           l_party_site_rec.location_id           := ln_location_id;
         
           l_return_status    := null;
           l_msg_count        := null;
           l_msg_data         := null;
           
           ----------------------------
           -- Create a new Party site
           ----------------------------
           HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE(
             P_INIT_MSG_LIST      => fnd_api.g_true,
             P_PARTY_SITE_REC     => l_party_site_rec,
             X_PARTY_SITE_ID      => ln_party_site_id,
             X_PARTY_SITE_NUMBER  => lc_party_site_number,
             X_RETURN_STATUS      => l_return_status,
             X_MSG_COUNT          => l_msg_count,
             X_MSG_DATA           => l_msg_data
           );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After create_party_site, l_return_status: ' || l_return_status 
             || ', ln_party_site_id: ' || ln_party_site_id || ', site_orig_system_reference: ' || site_rec.site_orig_system_reference);

           if (l_return_status = 'S') then
             commit;
           end if;

         
           for site_use_rec in C3 (p_batch_id, site_rec.site_orig_system_reference)
           loop
              l_party_site_use_rec.site_use_type  := site_use_rec.site_use_type;
              l_party_site_use_rec.primary_per_type  := site_use_rec.primary_flag;
              l_party_site_use_rec.created_by_module  := 'BO_API';
              l_party_site_use_rec.status        := 'A';
              
              l_return_status    := null;
              l_msg_count        := null;
              l_msg_data         := null;
              --------------------------------
              -- Create a new Party site Use
              --------------------------------
              HZ_PARTY_SITE_V2PUB.CREATE_PARTY_SITE_USE(
                P_INIT_MSG_LIST        => fnd_api.g_true,
                P_PARTY_SITE_USE_REC   => l_party_site_use_rec,
                X_PARTY_SITE_USE_ID    => ln_party_site_use_id,
                X_RETURN_STATUS        => l_return_status,
                X_MSG_COUNT            => l_msg_count,
                X_MSG_DATA             => l_msg_data
              );
         
              log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
                'After CREATE_PARTY_SITE_USE, l_return_status: ' || l_return_status 
                || ', ln_party_site_use_id: ' || ln_party_site_use_id  || ', site_orig_system_reference: ' 
                || site_rec.site_orig_system_reference || ', site_use_type: ' || site_use_rec.site_use_type);

              if (l_return_status = 'S') then
                commit;
              end if;
         
           end loop; --end of site_use_rec
         
         end loop;--end of site_rec
         
         for acct_site_rec in C5(p_batch_id, hp_rec.party_orig_system_reference)
         loop
         
           l_cust_acct_site_rec.cust_account_id           := ln_cust_account_id;  
           l_cust_acct_site_rec.party_site_id             := ln_party_site_id;   
           l_cust_acct_site_rec.orig_system               := acct_site_rec.acct_site_orig_system;          
           l_cust_acct_site_rec.orig_system_reference     := acct_site_rec.acct_site_orig_sys_reference; 
           l_cust_acct_site_rec.attribute_category        := acct_site_rec.address_attribute_category; 
           l_cust_acct_site_rec.attribute1                := acct_site_rec.address_attribute1;          
           l_cust_acct_site_rec.attribute2                := acct_site_rec.address_attribute2;          
           l_cust_acct_site_rec.attribute3                := acct_site_rec.address_attribute3;          
           l_cust_acct_site_rec.attribute4                := acct_site_rec.address_attribute4;         
           l_cust_acct_site_rec.attribute5                := acct_site_rec.address_attribute5;          
           l_cust_acct_site_rec.attribute6                := acct_site_rec.address_attribute6;          
           l_cust_acct_site_rec.attribute7                := acct_site_rec.address_attribute7;          
           l_cust_acct_site_rec.attribute8                := acct_site_rec.address_attribute8;          
           l_cust_acct_site_rec.attribute9                := acct_site_rec.address_attribute9;          
           l_cust_acct_site_rec.attribute10               := acct_site_rec.address_attribute10;         
           l_cust_acct_site_rec.attribute11               := acct_site_rec.address_attribute11;         
           l_cust_acct_site_rec.attribute12               := acct_site_rec.address_attribute12;         
           l_cust_acct_site_rec.attribute13               := acct_site_rec.address_attribute13;         
           l_cust_acct_site_rec.attribute14               := acct_site_rec.address_attribute14;         
           l_cust_acct_site_rec.attribute15               := acct_site_rec.address_attribute15;         
           l_cust_acct_site_rec.attribute16               := acct_site_rec.address_attribute16;         
           l_cust_acct_site_rec.attribute17               := acct_site_rec.address_attribute17;         
           l_cust_acct_site_rec.attribute18               := acct_site_rec.address_attribute18;         
           l_cust_acct_site_rec.attribute19               := acct_site_rec.address_attribute19;         
           l_cust_acct_site_rec.attribute20               := acct_site_rec.address_attribute20;         
           l_cust_acct_site_rec.status                    := 'A';                
         
           l_return_status    := null;
           l_msg_count        := null;
           l_msg_data         := null;
           ------------------------------
           -- Create a new account site
           ------------------------------
           HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_ACCT_SITE
               (
                   p_init_msg_list         => FND_API.G_TRUE,
                   p_cust_acct_site_rec    => l_cust_acct_site_rec,
                   x_cust_acct_site_id     => ln_cust_acct_site_id,
                   x_return_status         => l_return_status,
                   x_msg_count             => l_msg_count,
                   x_msg_data              => l_msg_data
               );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After CREATE_CUST_ACCT_SITE, l_return_status: ' || l_return_status 
             || ', ln_cust_acct_site_id: ' || ln_cust_acct_site_id || ', orig_system_reference: ' || acct_site_rec.acct_site_orig_sys_reference  );

           if (l_return_status = 'S') then
             commit;
           end if;
         
         end loop; -- create account site  
         
         for cust_site_use_rec in C6 (p_batch_id, hp_rec.party_orig_system_reference)
         loop
         
           l_cust_site_use_rec.cust_acct_site_id    :=  ln_cust_acct_site_id                ;
           l_cust_site_use_rec.location             :=  cust_site_use_rec.location          ;  
           l_cust_site_use_rec.tax_reference        :=  cust_site_use_rec.site_use_tax_reference     ;
           l_cust_site_use_rec.tax_code             :=  cust_site_use_rec.site_use_tax_code          ;
           l_cust_site_use_rec.attribute_category   :=  cust_site_use_rec.site_use_attribute_category;
           l_cust_site_use_rec.attribute1           :=  cust_site_use_rec.site_use_attribute1        ;
           l_cust_site_use_rec.attribute2           :=  cust_site_use_rec.site_use_attribute2        ;
           l_cust_site_use_rec.attribute3           :=  cust_site_use_rec.site_use_attribute3        ;
           l_cust_site_use_rec.attribute4           :=  cust_site_use_rec.site_use_attribute4        ;
           l_cust_site_use_rec.attribute5           :=  cust_site_use_rec.site_use_attribute5        ;
           l_cust_site_use_rec.attribute6           :=  cust_site_use_rec.site_use_attribute6        ;
           l_cust_site_use_rec.attribute7           :=  cust_site_use_rec.site_use_attribute7        ;
           l_cust_site_use_rec.attribute8           :=  cust_site_use_rec.site_use_attribute8        ;
           l_cust_site_use_rec.attribute9           :=  cust_site_use_rec.site_use_attribute9        ;
           l_cust_site_use_rec.attribute10          :=  cust_site_use_rec.site_use_attribute10       ;
           l_cust_site_use_rec.site_use_code        :=  cust_site_use_rec.site_use_code     ;
           l_cust_site_use_rec.status               :=  'A'                                 ;
           l_cust_site_use_rec.created_by_module    := 'BO_API'                             ;
           l_cust_site_use_rec.application_id       := gn_application_id                    ;
         
           l_return_status    := null;
           l_msg_count        := null;
           l_msg_data         := null;
           -----------------------------------
           -- Create a new account site use
           -----------------------------------
           HZ_CUST_ACCOUNT_SITE_V2PUB.CREATE_CUST_SITE_USE
               (
                   p_init_msg_list           => FND_API.G_TRUE,
                   p_cust_site_use_rec       => l_cust_site_use_rec,
                   p_customer_profile_rec    => NULL,
                   p_create_profile          => FND_API.G_FALSE,
                   p_create_profile_amt      => FND_API.G_FALSE,
                   x_site_use_id             => ln_cust_site_use_id,
                   x_return_status           => l_return_status,
                   x_msg_count               => l_msg_count,
                   x_msg_data                => l_msg_data
               );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After CREATE_PARTY_SITE_USE, l_return_status: ' || l_return_status 
             || ', ln_cust_site_use_id: ' || ln_cust_site_use_id  || ', cust_site_use_orig_system_reference: ' 
             || cust_site_use_rec.acct_site_orig_sys_reference || ', cust_site_use_code: ' || cust_site_use_rec.site_use_code);

           if (l_return_status = 'S') then
             commit;
           end if;
         
         end loop; -- acct_site_use
         
         for cont_rec in C7 (p_batch_id, hp_rec.party_orig_system_reference)
         loop
           for person_rec in C8 (p_batch_id, cont_rec.obj_orig_system_reference)
           loop
           
             l_per_party_rec.orig_system            := person_rec.party_orig_system;
             l_per_party_rec.orig_system_reference  := person_rec.party_orig_system_reference;
             l_person_rec.person_first_name         := person_rec.person_first_name;
             l_person_rec.person_middle_name        := person_rec.person_middle_name;
             l_person_rec.person_last_name          := person_rec.person_last_name;
             l_person_rec.person_initials           := person_rec.person_initials;
             l_person_rec.created_by_module         := 'BO_API';
             l_person_rec.party_rec                 := l_per_party_rec;
             
             l_return_status    := null;
             l_msg_count        := null;
             l_msg_data         := null;
         
             HZ_PARTY_V2PUB.CREATE_PERSON(
               P_INIT_MSG_LIST   => fnd_api.g_true,
               P_PERSON_REC      => l_person_rec,
               X_PARTY_ID        => ln_per_party_id,
               X_PARTY_NUMBER    => lc_per_party_number,
               X_PROFILE_ID      => ln_per_profile_id,
               X_RETURN_STATUS   => l_return_status,
               X_MSG_COUNT       => l_msg_count,
               X_MSG_DATA        => l_msg_data
             );
           
             log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
                  'After CREATE_PERSON, l_return_status: ' || l_return_status || ', ln_per_party_id: ' || ln_per_party_id);
         
             if (l_return_status = 'S') then
               commit;
             end if;

             l_org_contact_rec.created_by_module := 'BO_API';
             l_org_contact_rec.party_rel_rec.subject_id := ln_per_party_id;
             l_org_contact_rec.party_rel_rec.subject_type := 'PERSON';
             l_org_contact_rec.party_rel_rec.subject_table_name := 'HZ_PARTIES';
             l_org_contact_rec.party_rel_rec.object_id := ln_org_party_id;
             l_org_contact_rec.party_rel_rec.object_type := 'ORGANIZATION';
             l_org_contact_rec.party_rel_rec.object_table_name := 'HZ_PARTIES';
             l_org_contact_rec.party_rel_rec.relationship_code := 'CONTACT_OF';
             l_org_contact_rec.party_rel_rec.relationship_type := 'CONTACT';
             l_org_contact_rec.party_rel_rec.start_date := cont_rec.start_date;
             l_org_contact_rec.party_rel_rec.end_date := cont_rec.end_date;
         
             l_return_status    := null;
             l_msg_count        := null;
             l_msg_data         := null;
         
             HZ_PARTY_CONTACT_V2PUB.CREATE_ORG_CONTACT
                                    (p_init_msg_list        => 'T',
                                     p_org_contact_rec      => l_org_contact_rec,
                                     x_org_contact_id       => ln_org_contact_id,
                                     x_party_rel_id         => ln_party_rel_id, 
                                     x_party_id             => ln_rel_party_id,     
                                     x_party_number         => lc_rel_party_number, 
                                     x_return_status        => l_return_status,
                                     x_msg_count            => l_msg_count,    
                                     x_msg_data             => l_msg_data     
                                    );
         
           log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
             'After CREATE_ORG_CONTACT, l_return_status: ' || l_return_status || ', ln_org_contact_id: ' || ln_org_contact_id); 

           if (l_return_status = 'S') then
             commit;
           end if;

         
             for cp_rec in C9(p_batch_id, hp_rec.party_orig_system_reference)
             loop
         
               l_contact_point_rec.contact_point_type    := cp_rec.contact_point_type;
               l_contact_point_rec.owner_table_name      := 'HZ_PARTIES';
               l_contact_point_rec.owner_table_id        := ln_rel_party_id;
                                                         
               l_contact_point_rec.primary_flag          := cp_rec.primary_flag;
               
               l_contact_point_rec.contact_point_purpose := cp_rec.contact_point_purpose;
               l_contact_point_rec.created_by_module     := 'BO_API';
               l_email_rec.email_format                  := cp_rec.email_format;
               l_email_rec.email_address                 := cp_rec.email_address;
         
               l_phone_rec.phone_area_code               := cp_rec.phone_area_code;
               l_phone_rec.phone_country_code            := cp_rec.phone_country_code;
               l_phone_rec.phone_number                  := cp_rec.phone_number;
               l_phone_rec.phone_line_type               := cp_rec.phone_line_type;
               l_phone_rec.phone_extension               := cp_rec.phone_extension;
               
               l_return_status    := null;
               l_msg_count        := null;
               l_msg_data         := null;
               HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT
                                   (p_init_msg_list          => 'T',
                                    p_contact_point_rec      => l_contact_point_rec,
                                    p_edi_rec                => null,
                                    p_email_rec              => l_email_rec,
                                    p_phone_rec              => l_phone_rec,
                                    p_telex_rec              => null,
                                    p_web_rec                => null,
                                    x_contact_point_id       => ln_contact_point_id,
                                    x_return_status          => l_return_status,
                                    x_msg_count              => l_msg_count,
                                    x_msg_data               => l_msg_data
                                   );
         
               log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER',
                 'After CREATE_CONTACT_POINT, l_return_status: ' || l_return_status || ', ln_contact_point_id: ' || ln_contact_point_id); 

               if (l_return_status = 'S') then
                 commit;
               end if;
         
             end loop; -- end of cp_rec         
         
           end loop; --end of person_rec
         end loop; -- end of cont_rec
       end if; -- get_owner_table_id condition
   end loop; --end of hp_rec

   log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER','END');
  
 EXCEPTION
   WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMER','IMPORTCUSTOMER_ERROR: ' || sqlerrm);
 END importCustomer;

  PROCEDURE IMPORTCUSTOMERBO(errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2)
  is

  l_org_cust_bo            HZ_ORG_CUST_BO := HZ_ORG_CUST_BO(null, null,HZ_CUST_ACCT_BO_TBL());
  l_org_cust_xml_payload   sys.XMLTYPE;
  l_return_status          VARCHAR2(1);
  l_msg_count              NUMBER;
  l_msg_data               VARCHAR2(2000);
  l_party_id               number;
  l_organization_id        NUMBER;

   lc_msg_data                  VARCHAR2(2000);
   l_err_msg                    VARCHAR2(2000);

  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;

  cursor C_MSG
  is
  select bpel_process_id
  from   XX_CDH_CUST_BO_STG
  where  interface_status = 1;

  BEGIN
   log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','START');
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
    dbms_output.put_line('Exception in initializing : ' || SQLERRM);
   end;
   log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','After Setting the context'); 
  for i_rec in C_MSG
  loop
    select party_id,
           org_cust_bo_payload
    into   l_party_id,
           l_org_cust_xml_payload
    --into   l_org_cust_bo
    from   XX_CDH_CUST_BO_STG
    where  bpel_process_id = i_rec.bpel_process_id;

    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','Before converting XMLTYPE to BO'); 
    --l_org_cust_xml_payload := i_rec.org_cust_bo_payload;
    l_org_cust_xml_payload.toObject( l_org_cust_bo);
    
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','Before Calling save_org_cust_bo: ' || l_party_id); 

    HZ_ORG_CUST_BO_PUB.save_org_cust_bo(
                                         p_init_msg_list        => fnd_api.g_false, 
                                         p_validate_bo_flag     => fnd_api.g_false,
                                         p_org_cust_obj         => l_org_cust_bo,
                                         p_created_by_module    => 'BO_API',
                                         x_return_status        => l_return_status,
                                         x_msg_count            => l_msg_count,
                                         x_msg_data             => l_msg_data,
                                         x_organization_id      => l_organization_id
                                       );
  l_err_msg := '';
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','l_return_status: ' || l_return_status || ', l_msg_count: ' || l_msg_count); 
  if l_return_status = 'S' then
    COMMIT;
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','l_return_status: ' || l_return_status || ', l_msg_count: ' || l_msg_count);
  else
      IF(l_msg_count >= 1) THEN 
        FOR I IN 1..20 LOOP 
            l_err_msg := l_err_msg || FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ); 
        END LOOP; 
      ELSE 
        l_err_msg := l_msg_data; 
      END IF;
    log_debug_msg('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO','Error for ' || l_organization_id || ': ' || l_err_msg);
  end if;

  end loop;

  EXCEPTION 
    when others then
      Log_error('XX_CDH_DOWNTIME_DELTA_PKG.IMPORTCUSTOMERBO', 'IMPORTCUSTOMERBO_EXCEPTION' || SQLERRM);
  END IMPORTCUSTOMERBO;
  
end XX_CDH_DOWNTIME_DELTA_PKG;
/
SHOW ERRORS