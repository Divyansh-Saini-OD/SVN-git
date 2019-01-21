create or replace PACKAGE BODY XX_CDH_RELIABLE_ACCT_UPD_PKG

-- +===========================================================================+
-- |                  Office Depot - Office Max Integration Project            |
-- +===========================================================================+
-- | Name        : XX_CDH_RELIABLE_ACCT_UPD_PKG                                |
-- | RICE        : I3092                                                       |
-- |                                                                           |
-- | Description :                                                             |
-- | This package helps is to update the credit limits and update OMX number   |
-- | for Reliable Customer.                                                    |
-- |                                                                           |
-- | This Package also handles process of importing AP Contact from AOPS       |
-- | (Reliable) to create a role in HZ ROLE RESPONSIBILITY and update job title|
-- | for the contact in HZ ORG CONTACTS                                        |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author            Remarks                             |
-- |======== =========== =============     ====================================|
-- |DRAFT 1  11-MAR-2015 Sreedhar Mohan    Initial draft version               |
-- |V2.0     01-MAY-2015 Manikant Kasu     DEFECT # 34265 - Added Procedure    |
-- |                                       "SET_AP_CONTACTS" for AP Contacts   |
-- |                                       (Reliable)                          |
-- |V3.0     22-OCT-2015 Manikant Kasu     Removed schema alias as part of     |
-- |                                       GSCC R12.2.2 Retrofit               |
-- |                                                                           |
-- +===========================================================================+

AS

g_debug  VARCHAR2(1) := 'N';

--Procedure for logging debug log
PROCEDURE log_debug_msg ( 
                          p_debug_pkg          IN  VARCHAR2
                         ,p_debug_msg          IN  VARCHAR2 )
IS

  ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
  ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;

BEGIN
  IF (g_debug = 'Y') THEN
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
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, p_debug_msg);
  END IF;
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
    FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);
END log_error;

PROCEDURE set_context
(   x_errbuf            OUT NOCOPY VARCHAR2
   ,x_retcode           OUT NOCOPY NUMBER
)
IS
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  
BEGIN
    select user_id,
           responsibility_id,
           responsibility_application_id
    into   l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      from fnd_user_resp_groups 
     where user_id=(select user_id 
                      from fnd_user 
                     where user_name='ODCDH')
     and   responsibility_id=(select responsibility_id 
                                from FND_RESPONSIBILITY 
                               where responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );
EXCEPTION
    when others then
      log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'SET_CONTEXT_ERROR: ' || SQLERRM);
END set_context;

procedure update_ap_contacts_stg ( p_ccu_contact_id in varchar2, p_status in varchar2, p_error_msg in varchar2)
IS
BEGIN
  --
  if (p_status = 'S') then
    UPDATE XX_CDH_RELIABLE_CONTACTS_STG   
    SET    status_flag = p_status
         , last_update_date = SYSDATE
         , last_updated_by = fnd_global.user_id
    WHERE  1 = 1  
    AND    CCU_CONTACT_ID = p_ccu_contact_id
    ;
    COMMIT;
  else
    ROLLBACK TO UPDATE_AP_CONTACT;  
    UPDATE XX_CDH_RELIABLE_CONTACTS_STG   
    SET    status_flag = p_status
         , error_msg   = p_error_msg
         , last_update_date = SYSDATE
         , last_updated_by = fnd_global.user_id
    WHERE 1 = 1  
    AND CCU_CONTACT_ID = p_ccu_contact_id
    ;
    COMMIT;
  end if;	

EXCEPTION
    when others then
      log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'update_ap_contacts_stg_ERROR: ' || SQLERRM);   
END update_ap_contacts_stg; 

PROCEDURE set_credit_limit
(   x_errbuf            OUT NOCOPY VARCHAR2
   ,x_retcode           OUT NOCOPY NUMBER
   ,p_account_number               VARCHAR2
   ,p_credit_limit                 NUMBER
)
IS

  V_RETURN                        varchar2(200);
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  
BEGIN

  --Set the credit limit in US org
  v_Return := XX_FIN_RELS_CREDIT_UPLOAD_PKG.CREDIT_UPDATE(
    P_ACCOUNT_NUMBER  => P_ACCOUNT_NUMBER,
    P_CREDIT_LIMIT    => P_CREDIT_LIMIT,
    P_CURRENCY_CODE   => 'USD'
  );
  
  v_Return := null;
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'v_Return After USD credit limit update = ' || v_Return);
    
  --Set the credit limit to $2 in CA org
  v_Return := XX_FIN_RELS_CREDIT_UPLOAD_PKG.CREDIT_UPDATE(
    P_ACCOUNT_NUMBER  => P_ACCOUNT_NUMBER,
    P_CREDIT_LIMIT    => 2,
    P_CURRENCY_CODE   => 'CAD'
  );
  
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'v_Return After CAD credit limit update = ' || v_Return);

EXCEPTION
  WHEN OTHERS THEN
    log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','XX_CDH_RELIABLE_ACCT_UPD_PKG_set_credit_limit_ERROR, EXCEPTION: ' || SQLERRM);
END set_credit_limit;

PROCEDURE set_Reliable_Acct_Number
(   x_errbuf                      OUT NOCOPY VARCHAR2
   ,x_retcode                     OUT NOCOPY NUMBER
   ,p_Reliable_Acct_Number                   VARCHAR2
   ,p_acct_orig_system_reference             VARCHAR2
   ,p_party_id                               NUMBER
)
IS
  lv_return_status                  VARCHAR2(10);
  ln_msg_count                      NUMBER;
  lv_msg_data                       VARCHAR2(2000);

  l_orig_sys_ref_id                 NUMBER;
  l_osr_ovn                         NUMBER;

  LU_ORIG_SYS_REFERENCE_REC         HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
  LN_ORIG_SYS_REFERENCE_REC         HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;

BEGIN

   LN_ORIG_SYS_REFERENCE_REC                       := null;

   LN_ORIG_SYS_REFERENCE_REC.ORIG_SYSTEM_REF_ID    := null;
   LN_ORIG_SYS_REFERENCE_REC.ORIG_SYSTEM           := 'A0';
   LN_ORIG_SYS_REFERENCE_REC.old_orig_system_reference := p_acct_orig_system_reference;
   LN_ORIG_SYS_REFERENCE_REC.reason_code           := 'OTHER';
   LN_ORIG_SYS_REFERENCE_REC.ORIG_SYSTEM_REFERENCE := p_Reliable_Acct_Number;
   LN_ORIG_SYS_REFERENCE_REC.OWNER_TABLE_NAME      := 'HZ_PARTIES';
   LN_ORIG_SYS_REFERENCE_REC.OWNER_TABLE_ID        := p_party_id;
   LN_ORIG_SYS_REFERENCE_REC.PARTY_ID              := p_party_id;
   LN_ORIG_SYS_REFERENCE_REC.STATUS                := 'A';
   LN_ORIG_SYS_REFERENCE_REC.END_DATE_ACTIVE       := null;
   LN_ORIG_SYS_REFERENCE_REC.created_by_module     := 'BO_API';


   HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference (
      p_orig_sys_reference_rec => LN_ORIG_SYS_REFERENCE_REC,
      x_return_status => LV_RETURN_STATUS,
      X_MSG_COUNT  => LN_MSG_COUNT,
      x_msg_data   => lv_msg_data
   );

   if LV_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS then
       log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Record in hz_orig_sys_references successfully Created...');
       
       --manually update ORIG_SYSTEM_REFERENCE in HZ_PARTIES
       update HZ_PARTIES
       set    ORIG_SYSTEM_REFERENCE = p_Reliable_Acct_Number || '-REL', last_update_date=sysdate, last_updated_by=fnd_global.user_id
       where  party_id = p_party_id
       ;
   ELSE          
       IF ln_msg_count > 0 THEN
         log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference returned Error while creating OSR for party... ');
         FOR counter IN 1..ln_msg_count
         LOOP
          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
         END LOOP;
         FND_MSG_PUB.Delete_Msg;
       END IF;
   END IF;

EXCEPTION
  WHEN OTHERS THEN
    log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','XX_CDH_RELIABLE_ACCT_UPD_PKG_set_Reliable_Acct_Number_ERROR, EXCEPTION: ' || SQLERRM);
END set_Reliable_Acct_Number;

PROCEDURE set_ap_contacts
(
   x_errbuf            OUT NOCOPY VARCHAR2
  ,x_retcode           OUT NOCOPY NUMBER
  ,p_last_run_date     IN  VARCHAR2  
)
IS
  
  l_last_run_date                 DATE := null;
  lc_select_sql                   VARCHAR2(8000) := null;
  lc_dblink_host                  VARCHAR2(255);
  lc_aops_id                      VARCHAR2(255) := null;
--  lc_omx_ref1                     NUMBER:= null;
--  lc_omx_ref2                     NUMBER:= null;
  ln_contact_id                   VARCHAR2(255):= null;
  ln_created_dt                   DATE := null;
  ln_count                        NUMBER;
  lc_acct_orig_system_reference   VARCHAR2(255);
  ln_party_id                     NUMBER := null;
  ln_cust_account_id              NUMBER := null;
  ln_cust_acct_site_id            NUMBER := null;
  
  lc_return_status                VARCHAR2(1000);
  ln_msg_count                    NUMBER;
  lc_msg_data                     VARCHAR2(1000);
  
  l_party_rel_id                  NUMBER := null;
  l_party_id                      NUMBER := null;
  l_party_number                  VARCHAR2(30) := null;

  ln_cust_account_role_id         NUMBER := null;
  ln_org_contact_id               NUMBER := null;
  ln_responsibility_id            NUMBER := null;
  X_CUST_ACCOUNT_ROLE_ID          NUMBER;
  
  ln_cont_object_version_number   NUMBER := null;
  ln_rel_object_version_number    NUMBER := null;
  ln_party_object_version_number  NUMBER := null;
  
  ln_ovn                          NUMBER;
  l_user_id                       NUMBER;
  l_responsibility_id             NUMBER;
  l_responsibility_appl_id        NUMBER;

  P_CONTACT_POINT_ID              NUMBER;
  
  lr_role_responsibility_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.ROLE_RESPONSIBILITY_REC_TYPE;
  lr_org_contact_rec              HZ_PARTY_CONTACT_V2PUB.ORG_CONTACT_REC_TYPE;
  l_party_rel_update_rec          HZ_RELATIONSHIP_V2PUB.RELATIONSHIP_REC_TYPE;
  
  X_CONTACT_POINT_REC             HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
  X_EMAIL_REC                     HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
  P_EMAIL_REC                     HZ_CONTACT_POINT_V2PUB.EMAIL_REC_TYPE;
  P_CONTACT_POINT_REC             HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE;
  X_PHONE_REC                     HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
  P_PHONE_REC                     HZ_CONTACT_POINT_V2PUB.PHONE_REC_TYPE;
  P_CUST_ACCOUNT_ROLE_REC         HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
  X_CUST_ACCOUNT_ROLE_REC         HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;

  REC_DOES_NOT_EXIST              EXCEPTION;
  E_PROCESS_EXCEPTION             EXCEPTION;
  no_acct_site_exception          EXCEPTION;

  TYPE aops_reliable_CurTyp IS REF CURSOR;
  aops_rel_contacts_cur    aops_reliable_CurTyp;
  
  CURSOR cur_chk_contact(p_contact_id VARCHAR2)
  IS
  SELECT org_contact_id 
  FROM   HZ_ORG_CONTACTS
  WHERE  ORIG_SYSTEM_REFERENCE = p_contact_id
  ;
  
  CURSOR c_exist_rel 
  IS
  SELECT *
  FROM   hz_relationships
  WHERE  party_id = l_party_id
  AND    relationship_code = 'CONTACT'
  AND    status = 'A'
  ;
  
  CURSOR c_contact_point(p_contact_id VARCHAR2)
  IS
  select *
  from   HZ_CONTACT_POINTS hcp 
  where  1 = 1
  and    hcp.owner_table_id = (select  hp.party_id
                               from    HZ_PARTIES HP
                                      ,hz_relationships hr
                                      ,HZ_ORG_CONTACTS HOC
                               where   1 = 1
                               and     hr.party_id = hp.party_id
                               and     hr.relationship_id  = hoc.party_relationship_id 
                               and     hr.object_type = 'PERSON'
                               and     hoc.orig_system_reference = p_contact_id
                               )
   ;
   
BEGIN
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','SET_AP_CONTACTS Process Begins....');      

  BEGIN -- this block is to compute l_last_run_date

      IF (p_last_run_date is null) 
      THEN
          select b.actual_start_date 
          into   l_last_run_date
          from  (
                 select rownum as rn, cp.actual_start_date 
                 from (
                       select actual_start_date  
                       from   fnd_concurrent_requests
                       where  concurrent_program_id = (select concurrent_program_id
                                                       from   fnd_concurrent_programs_vl
                                                       where  user_concurrent_program_name = 'OD: CDH Reliable Customers Account Number and Credit Limit Sync'
                                                       )
                       order by actual_start_date desc) cp) b
          where  rn = 2;
                                   
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'l_last_run_date:' || to_char(l_last_run_date, 'DD-MON-RRRR'));
      
      ELSE
      l_last_run_date := to_date(p_last_run_date,'DD-MON-RRRR');  
      END IF;    
  EXCEPTION
  WHEN OTHERS 
  THEN
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'Exception in deriving last_run_date: ' || SQLERRM);
  END;  -- this block is to compute l_last_run_date
    
  BEGIN  -- this block is for DB LINK TO AOPS

    lc_dblink_host := fnd_profile.value('XX_GP_AOPS_HOST');
  
    --Create Dynamic sql using DB Link. Include Errored records also

    lc_select_sql := ' Select a.CCU300F_CUSTOMER_ID                                                          ' ||
                     '       ,a.CCU300F_CONTACT_ID                                                           ' ||
                     '       ,a.CCU300F_CREATE_DT                                                            ' ||
                     ' From   RACOONDTA.CCU300F@'|| lc_dblink_host || '.NA.ODCORP.NET a                      ' ||
                     '       ,RACOONDTA.CCU007F@'|| lc_dblink_host || '.NA.ODCORP.NET b                      ' ||
                     ' Where  1 = 1                                                                          ' ||
                     ' and    a.CCU300F_ROLE_1 = ''RAP''                                                     ' ||
                     ' and    b.CCU007F_AR_FLAG = ''Y''                                                      ' ||          
                     ' and    b.CCU007F_CUSTOMER_ID = a.CCU300F_CUSTOMER_ID                                  ' ||
                     ' and    a.CCU300F_CUSTOMER_ID IN (select distinct CSTIDXRF_AOPS_ID                     ' ||
                     '                                  from   RACOONDTA.CSTIDXRF@'|| lc_dblink_host || '.NA.ODCORP.NET c      ' ||
                     '                                  where  1 = 1                                         ' ||
                     '                                  and    c.CSTIDXRF_AOPS_ID_TYPE = ''ACT''             ' ||  
                     '                                  and    c.CSTIDXRF_REF_CODE = ''RELIABLE'' )          ' ||
                     ' and     TRUNC(a.CCU300F_CREATE_DT) >= to_date(to_char(:l_last_run_date,''DD-MON-RRRR''),''DD-MON-RRRR'')' ||
                     ' and     NOT EXISTS (SELECT   1                                                        ' ||
                     '                        FROM  XX_CDH_RELIABLE_CONTACTS_STG  d                          ' ||
                     '                       WHERE  d.CCU_CONTACT_ID = lpad(a.CCU300F_CONTACT_ID,14,0))      '  
                     ;     
    
    log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'lc_select_sql: ' || lc_select_sql);
    ln_count := 0;

    open aops_rel_contacts_cur 
    FOR lc_select_sql 
    using l_last_run_date;  
    loop
        lc_aops_id := null;
        ln_contact_id := null;
        ln_created_dt := null;

        fetch aops_rel_contacts_cur 
        into lc_aops_id
            ,ln_contact_id
            ,ln_created_dt
        ;  
        EXIT WHEN aops_rel_contacts_cur%NOTFOUND;    
        
        BEGIN  -- FOR INSERT PROCESS
          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'ln_count: ' || ln_count);
          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'AOPS ID: ' || lpad(trim(lc_aops_id),8,'0')  || '-00001-A0');
          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'CONTACT ID: ' || ln_contact_id);
          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'AOPS CREATION DATE: ' || ln_created_dt);
          
          insert into XX_CDH_RELIABLE_CONTACTS_STG (
               CST_AOPS_ACCT_OSR 
              ,CCU_CONTACT_ID
              ,CCU_CREATED_DT
              ,STATUS_FLAG                  
              ,CREATION_DATE              
              ,CREATED_BY                 
              ,LAST_UPDATE_DATE           
              ,LAST_UPDATED_BY               
            )
          values
            (
               lpad(lc_aops_id,8,'0')  || '-00001-A0'
              ,lpad(trim(ln_contact_id),14,'0')
              ,ln_created_dt
              ,'N'
              ,SYSDATE
              ,FND_GLOBAL.User_Id
              ,SYSDATE
              ,FND_GLOBAL.User_Id
            );
        
          ln_count := ln_count + 1;

        EXCEPTION
        WHEN OTHERS THEN
           log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG.SET_AP_CONTACTS', 'ERROR IN UPSERT: ' || SQLERRM);
        END;   -- FOR INSERT PROCESS
    END LOOP;
    CLOSE aops_rel_contacts_cur;
    COMMIT;
    
    -- Opening loop for records in staging table                    
    FOR contact_rec in (SELECT  * 
                        FROM    XX_CDH_RELIABLE_CONTACTS_STG
                        WHERE   STATUS_FLAG IN ('N','E')
                        
                        )
    LOOP
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Beginning the process of calling APIs for :'||contact_rec.CCU_CONTACT_ID);

   
      open cur_chk_contact(contact_rec.CCU_CONTACT_ID);
      fetch cur_chk_contact into ln_org_contact_id;

      BEGIN  --- AFTER CUR_CHK_CONTACT
         
         SAVEPOINT UPDATE_AP_CONTACT;

         IF ln_org_contact_id IS NULL
         THEN
            log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','HZ Org Contact does NOT EXIST for the OSR provided ...:'||contact_rec.CCU_CONTACT_ID);
            RAISE REC_DOES_NOT_EXIST;
           
         ELSE
             -- Get the contact account role ID 
            ln_cust_account_role_id := null;
            BEGIN
            SELECT hcar.cust_account_role_id, hcar.object_version_number
            INTO   ln_cust_account_role_id, ln_ovn
            FROM   hz_cust_account_roles hcar
            WHERE  1 = 1
            AND    hcar.status   = 'A'
            AND    hcar.current_role_state = 'A'
            and    hcar.cust_acct_site_id is null
            AND    hcar.orig_system_reference = contact_rec.CCU_CONTACT_ID
            AND    hcar.cust_account_id = (select cust_account_id from hz_cust_accounts where orig_system_reference=contact_rec.cst_aops_acct_osr)  
            and    rownum < 2
            ;
            EXCEPTION
              WHEN OTHERS THEN
                log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Exception at getting contact account role id:'||SQLERRM);
            END;
            
            --Get Cust Account Role record and update the cust account role record with primary_flag to N, 
            --so that the FIRST_CONTACT created at Account level will be moved to bill_to level
            --
            X_CUST_ACCOUNT_ROLE_REC := null;
            HZ_CUST_ACCOUNT_ROLE_V2PUB.GET_CUST_ACCOUNT_ROLE_REC(
              P_INIT_MSG_LIST => FND_API.G_TRUE,
              P_CUST_ACCOUNT_ROLE_ID => ln_cust_account_role_id,
              X_CUST_ACCOUNT_ROLE_REC => X_CUST_ACCOUNT_ROLE_REC,
              X_RETURN_STATUS => LC_RETURN_STATUS,
              X_MSG_COUNT => LN_MSG_COUNT,
              X_MSG_DATA => LC_MSG_DATA
            );

            X_CUST_ACCOUNT_ROLE_REC.primary_flag := 'N';
            HZ_CUST_ACCOUNT_ROLE_V2PUB.UPDATE_CUST_ACCOUNT_ROLE(
              P_INIT_MSG_LIST => FND_API.G_TRUE,
              P_CUST_ACCOUNT_ROLE_REC => X_CUST_ACCOUNT_ROLE_REC,
              P_OBJECT_VERSION_NUMBER => ln_ovn,
              X_RETURN_STATUS => LC_RETURN_STATUS,
              X_MSG_COUNT => LN_MSG_COUNT,
              X_MSG_DATA => LC_MSG_DATA
            );

            IF lc_return_status = FND_API.G_RET_STS_SUCCESS
            THEN
                log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Contact Role in HZ_CUST_ACCOUNT_ROLES successfully Updated...:'||contact_rec.CCU_CONTACT_ID);
            ELSE          
                IF ln_msg_count > 0 
                THEN
                   log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API HZ_CUST_ACCOUNT_ROLE_V2PUB.UPDATE_CUST_ACCOUNT_ROLE returned Error while Updating to site level... :'||contact_rec.CCU_CONTACT_ID);
                   FOR counter IN 1..ln_msg_count
                   LOOP
                       log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                   END LOOP;
                   FND_MSG_PUB.Delete_Msg;
                END IF;
                update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                RAISE E_PROCESS_EXCEPTION;
            END IF;


            -- Create Cust Account Role
            --First, get cust_account_id for the OSR
            BEGIN
              select cust_account_id
              into   ln_cust_account_id
              from   hz_cust_accounts
              where  orig_system_reference = contact_rec.cst_aops_acct_osr;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE no_acct_site_exception;
            END; 
            --Next, get cust_acct_site_id for the 0001 site

            BEGIN
              select cust_acct_site_id
              into   ln_cust_acct_site_id
              from   hz_cust_acct_sites_all
              where  orig_system_reference = contact_rec.cst_aops_acct_osr;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE no_acct_site_exception;
            END; 
            
            --Next, get the relationship party_id for the contact
            BEGIN
              select  hp.party_id
              into    ln_party_id
              from    HZ_PARTIES HP
                     ,hz_relationships hr
                     ,HZ_ORG_CONTACTS HOC
              where   1 = 1
              and     hr.party_id = hp.party_id
              and     hr.relationship_id  = hoc.party_relationship_id 
              and     hr.object_type = 'PERSON'
              and     hoc.orig_system_reference = contact_rec.ccu_contact_id
              ;
            EXCEPTION
              WHEN OTHERS THEN
                RAISE no_acct_site_exception;
            END; 
            P_CUST_ACCOUNT_ROLE_REC := null;
            --
            -- Create the contact role for the customer account
            --
            P_CUST_ACCOUNT_ROLE_REC.created_by_module := 'BO_API';
            P_CUST_ACCOUNT_ROLE_REC.orig_system := 'A0';
            P_CUST_ACCOUNT_ROLE_REC.orig_system_reference := contact_rec.ccu_contact_id;
            P_CUST_ACCOUNT_ROLE_REC.party_id := ln_party_id;
            -- this is the relationship party w/ name = contact person + company name
            P_CUST_ACCOUNT_ROLE_REC.cust_account_id := ln_cust_account_id;
            P_CUST_ACCOUNT_ROLE_REC.cust_acct_site_id := ln_cust_acct_site_id;
            P_CUST_ACCOUNT_ROLE_REC.role_type := 'CONTACT';
            -- validated from ar_lookups.lookup_type = 'ACCT_ROLE_TYPE'
            P_CUST_ACCOUNT_ROLE_REC.primary_flag := 'Y';

            HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_CUST_ACCOUNT_ROLE(
              P_INIT_MSG_LIST => FND_API.G_TRUE,
              P_CUST_ACCOUNT_ROLE_REC => P_CUST_ACCOUNT_ROLE_REC,
              X_CUST_ACCOUNT_ROLE_ID => X_CUST_ACCOUNT_ROLE_ID,
              X_RETURN_STATUS => LC_RETURN_STATUS,
              X_MSG_COUNT => LN_MSG_COUNT,
              X_MSG_DATA => LC_MSG_DATA
            );
            
            IF lc_return_status = FND_API.G_RET_STS_SUCCESS
            THEN
                log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Contact Role in HZ_CUST_ACCOUNT_ROLES successfully Created...:'||contact_rec.CCU_CONTACT_ID);
            ELSE          
                IF ln_msg_count > 0 
                THEN
                   log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API HZ_CUST_ACCOUNT_ROLE_V2PUB.CREATE_CUST_ACCOUNT_ROLE returned Error while Creating to site level...:'||contact_rec.CCU_CONTACT_ID);
                   FOR counter IN 1..ln_msg_count
                   LOOP
                       log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                   END LOOP;
                   FND_MSG_PUB.Delete_Msg;
                END IF;
                update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                RAISE E_PROCESS_EXCEPTION;
            END IF;
            
            lr_role_responsibility_rec := null;
           
            lr_role_responsibility_rec.cust_account_role_id := X_CUST_ACCOUNT_ROLE_ID;
            lr_role_responsibility_rec.responsibility_type  := 'DUN';
            lr_role_responsibility_rec.created_by_module := 'BO_API';
            lr_role_responsibility_rec.primary_flag := 'Y';

            hz_cust_account_role_v2pub.create_role_responsibility( p_init_msg_list           => FND_API.G_TRUE
                                                                 , p_role_responsibility_rec => lr_role_responsibility_rec
                                                                 , x_responsibility_id       => ln_responsibility_id
                                                                 , x_return_status           => lc_RETURN_STATUS
                                                                 , x_msg_count               => ln_MSG_COUNT
                                                                 , x_msg_data                => lc_msg_data
                                                                 );

        
            IF lc_return_status = FND_API.G_RET_STS_SUCCESS
            THEN
                log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Contact Role in hz_role_responsibility successfully Created...:'||contact_rec.CCU_CONTACT_ID);
            ELSE          
                IF ln_msg_count > 0 
                THEN
                   log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API hz_cust_account_role_v2pub.create_role_responsibility returned Error while creating role for contact...:'||contact_rec.CCU_CONTACT_ID);
                   FOR counter IN 1..ln_msg_count
                   LOOP
                       log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                   END LOOP;
                   FND_MSG_PUB.Delete_Msg;
                END IF;
                update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                RAISE E_PROCESS_EXCEPTION;                
            END IF;

            -- Update Job Title Code as 'AP'
            ln_org_contact_id := null;       
            SELECT ORG_CONTACT_ID
            INTO ln_org_contact_id
            FROM HZ_ORG_CONTACTS HOC
            WHERE 1 = 1
            AND HOC.orig_system_reference = contact_rec.CCU_CONTACT_ID
            ;
                
            -- Get Relationship Party_ID for updating contact_point
            l_party_id := null;
            select p.party_id
            into   l_party_id
            from   hz_parties p
                  ,hz_relationships r
                  ,hz_org_contacts oc
            where  oc.party_relationship_id = r.relationship_id 
            and    r.party_id = p.party_id 
            and    r.object_type = 'PERSON'
            and    oc.org_contact_id = ln_org_contact_id
            ;  
        
            FOR r_exist_rel IN c_exist_rel 
            LOOP
                --Get object_version_number values from HZ_Parties, HZ_Relationships, HZ_org_contacts
                ln_cont_object_version_number    := null;
                ln_rel_object_version_number     := null;
                ln_party_object_version_number   := null;
                SELECT  max(hoc.object_version_number) p_cont_object_version_number
                       ,max(hp.object_version_number) p_party_object_version_number
                       ,max(hr.object_version_number) p_rel_object_version_number
                INTO    ln_cont_object_version_number
                       ,ln_party_object_version_number
                       ,ln_rel_object_version_number
                FROM    hz_parties hp
                       ,hz_relationships hr
                       ,hz_org_contacts hoc
                WHERE   hoc.party_relationship_id = hr.relationship_id  
                AND     hr.party_id = hp.party_id 
                AND     hoc.org_contact_id = ln_org_contact_id
                ;
        
                l_party_rel_update_rec.relationship_id         := r_exist_rel.relationship_id;
                l_party_rel_update_rec.subject_id              := r_exist_rel.subject_id;
                l_party_rel_update_rec.object_id               := r_exist_rel.object_id;
                --l_party_rel_update_rec.status                  := 'A';
                l_party_rel_update_rec.start_date              := r_exist_rel.start_date;
                --l_party_rel_update_rec.end_date                := sysdate;
                l_party_rel_update_rec.relationship_type       := r_exist_rel.relationship_type;
                l_party_rel_update_rec.relationship_code       := r_exist_rel.relationship_code;
                l_party_rel_update_rec.subject_table_name      := r_exist_rel.subject_table_name;
                l_party_rel_update_rec.object_table_name       := r_exist_rel.object_table_name;
                l_party_rel_update_rec.subject_type            := r_exist_rel.subject_type;
                l_party_rel_update_rec.object_type             := r_exist_rel.object_type;
                l_party_rel_update_rec.application_id          := r_exist_rel.application_id;
                --l_party_rel_update_rec.party_rec.status        := 'A';

                lr_org_contact_rec.org_contact_id              := ln_org_contact_id;
                lr_org_contact_rec.party_rel_rec               := l_party_rel_update_rec;
                lr_org_contact_rec.job_title                   := 'AP';
        
                --Update HZ_ORG_CONTACTS.Job_title
                hz_party_contact_v2pub.update_org_contact ( p_init_msg_list                 =>  FND_API.G_TRUE
                                                           ,p_org_contact_rec               =>  lr_org_contact_rec
                                                           ,p_cont_object_version_number    =>  ln_cont_object_version_number
                                                           ,p_rel_object_version_number     =>  ln_rel_object_version_number
                                                           ,p_party_object_version_number   =>  ln_party_object_version_number
                                                           ,x_return_status                 =>  lc_RETURN_STATUS
                                                           ,x_msg_count                     =>  ln_MSG_COUNT
                                                           ,x_msg_data                      =>  lc_msg_data
                                                           );
                     
                IF lc_return_status = FND_API.G_RET_STS_SUCCESS 
                THEN
                    log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Record in hz_org_contacts successfully updated...:'||contact_rec.CCU_CONTACT_ID);
                ELSE          
                    IF ln_msg_count > 0 
                    THEN
                        log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API hz_party_contact_v2pub.update_org_contact returned Error while updating job title for contact...:'||contact_rec.CCU_CONTACT_ID);
                        FOR counter IN 1..ln_msg_count
                        LOOP
                            log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                        END LOOP;
                    FND_MSG_PUB.Delete_Msg;
                    END IF;
                    update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                    RAISE E_PROCESS_EXCEPTION;
                END IF;
            END LOOP;  --c_exist_rel
            
            for contact_point_rec in C_contact_point(contact_rec.ccu_contact_id)           
            LOOP
            -- Get Contact Points Records
            if ( contact_point_rec.contact_point_type = 'EMAIL') then
              X_CONTACT_POINT_REC := null;            
              X_CONTACT_POINT_REC.CONTACT_POINT_ID      := contact_point_rec.contact_point_id;
              X_CONTACT_POINT_REC.contact_point_purpose := 'DUNNING';

              HZ_CONTACT_POINT_V2PUB.UPDATE_EMAIL_CONTACT_POINT(
                P_INIT_MSG_LIST => FND_API.G_TRUE,
                P_CONTACT_POINT_REC => X_CONTACT_POINT_REC,
                P_EMAIL_REC => X_EMAIL_REC,
                P_OBJECT_VERSION_NUMBER => contact_point_rec.OBJECT_VERSION_NUMBER,
                X_RETURN_STATUS => LC_RETURN_STATUS,
                X_MSG_COUNT => LN_MSG_COUNT,
                X_MSG_DATA => LC_MSG_DATA
              );
              
              IF lc_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS 
              THEN
                  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Record from HZ_CONTACT_POINT_V2PUB.UPDATE_EMAIL_CONTACT_POINT successfully updated...:'||contact_rec.CCU_CONTACT_ID);
              ELSE          
                  IF ln_MSG_COUNT > 0 
                  THEN
                      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API HZ_CONTACT_POINT_V2PUB.UPDATE_EMAIL_CONTACT_POINT returned Error while updating contact point records...:'||contact_rec.CCU_CONTACT_ID);
                      FOR counter IN 1..ln_MSG_COUNT
                      LOOP
                          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                      END LOOP;
                  FND_MSG_PUB.Delete_Msg;
                  END IF;
                  update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                  RAISE E_PROCESS_EXCEPTION;
              END IF;              
            ELSIF (contact_point_rec.contact_point_type = 'PHONE') then
              X_CONTACT_POINT_REC := null;   
              X_CONTACT_POINT_REC.contact_point_purpose := 'COLLECTIONS';
              X_CONTACT_POINT_REC.CONTACT_POINT_ID      :=  contact_point_rec.contact_point_id;

              HZ_CONTACT_POINT_V2PUB.UPDATE_PHONE_CONTACT_POINT(
                P_INIT_MSG_LIST => FND_API.G_TRUE,
                P_CONTACT_POINT_REC => X_CONTACT_POINT_REC,
                P_PHONE_REC => X_PHONE_REC,
                P_OBJECT_VERSION_NUMBER => contact_point_rec.OBJECT_VERSION_NUMBER,
                X_RETURN_STATUS => LC_RETURN_STATUS,
                X_MSG_COUNT => LN_MSG_COUNT,
                X_MSG_DATA => LC_MSG_DATA
              );
              
              IF lc_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS 
              THEN
                  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Record from HZ_CONTACT_POINT_V2PUB.UPDATE_PHONE_CONTACT_POINT successfully updated...:'||contact_rec.CCU_CONTACT_ID);
              ELSE          
                  IF ln_MSG_COUNT > 0 
                  THEN
                      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','API HZ_CONTACT_POINT_V2PUB.UPDATE_PHONE_CONTACT_POINT returned Error while updating contact point records...:'||contact_rec.CCU_CONTACT_ID);
                      FOR counter IN 1..ln_MSG_COUNT
                      LOOP
                          log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                      END LOOP;
                  FND_MSG_PUB.Delete_Msg;
                  END IF;
                  update_ap_contacts_stg (contact_rec.ccu_contact_id,'E',substr(lc_msg_data,1,200));
                  RAISE E_PROCESS_EXCEPTION;
              END IF;              
            else
              log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','Contact point type is neither EMAIL nor PHONE :'||contact_rec.CCU_CONTACT_ID);
          end if;                     
            END LOOP;
      END IF;  -- CHECKING IF HZ ORG CONTACTS EXIST
      
      update_ap_contacts_stg ( contact_rec.ccu_contact_id,'S',NULL);
      
      EXCEPTION
      WHEN REC_DOES_NOT_EXIST THEN
          update_ap_contacts_stg ( contact_rec.ccu_contact_id,'E','HZ ORG CONTACT does not exist in EBS : ' || SQLERRM);
          log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG.SET_AP_CONTACTS', 'HZ ORG CONTACT does not exist in EBS : ' || SQLERRM);
      WHEN E_PROCESS_EXCEPTION THEN
          log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG.SET_AP_CONTACTS', 'EXCEPTION IN API CALLS : ' || SQLERRM);
      WHEN OTHERS THEN
          update_ap_contacts_stg ( contact_rec.ccu_contact_id,'E','SET_AP_CONTACTS_ERROR IN API: UNKNOWN ' || SQLERRM);
          log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG.SET_AP_CONTACTS', 'SET_AP_CONTACTS_ERROR IN API: UNKNOWN ' || SQLERRM);
      END; --- END FOR BEGIN AFTER CUR_CHK_CONTACT
    
      close cur_chk_contact;
       
    END LOOP;  -- contact_rec 
          
    log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'XX_CDH_RELIABLE_ACCT_UPD_PKG.set_ap_contacts (-)');
    EXCEPTION
    WHEN OTHERS THEN
    log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'SET_AP_CONTACTS_ERROR: ' || SQLERRM);
  END;
log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG','END of SET_AP_CONTACTS Procedure....');
EXCEPTION
WHEN OTHERS THEN
  log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'Exception SET_AP_CONTACTS_ERROR MAIN in WHEN OTHERS: ' || SQLERRM);
END set_ap_contacts;

PROCEDURE extract_from_aops
(
   x_errbuf            OUT NOCOPY VARCHAR2
  ,x_retcode           OUT NOCOPY NUMBER
  ,p_last_run_date     IN  VARCHAR2  
) IS

  ln_days             NUMBER;
  ln_count            NUMBER;
  l_last_run_date     DATE := null;
  lc_select_sql       VARCHAR2(2000) := null;
  lc_dblink_host      VARCHAR2(255);
  l_rows_processed    NUMBER;
  lc_aops_id          varchar2(20);
  lc_aops_omx_ref     varchar2(20);
  ln_credit_limit     varchar2(20);
  lt_timestamp        timestamp;
  lc_acct_orig_system_reference varchar2(255);
  
  TYPE aops_reliable_CurTyp IS REF CURSOR;
  aops_reliable_Cursor    aops_reliable_CurTyp;
  
  CURSOR C1 (p_acct_orig_system_reference varchar2)
  IS
  select ACCT_ORIG_SYSTEM_REFERENCE
  from   XX_CDH_RELIABLE_ACCOUNTS_STG
  where  ACCT_ORIG_SYSTEM_REFERENCE = p_acct_orig_system_reference
  ;
  
BEGIN
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'XX_CDH_RELIABLE_ACCT_UPD_PKG.extract_from_aops (+)');
  
  --Logic to find last run date
  BEGIN
  
    IF (p_last_run_date is null) THEN
      select b.actual_start_date 
      into   l_last_run_date
      from (
      select rownum as rn, cp.actual_start_date from (
        select actual_start_date
        from   fnd_concurrent_requests
        where  concurrent_program_id = (select concurrent_program_id
                                        from   fnd_concurrent_programs_vl
                                        where  user_concurrent_program_name = 'OD: CDH Reliable Customers Account Number and Credit Limit Sync'
                                       )
      order by actual_start_date desc) cp) b
      where  rn = 2;
                                   
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'l_last_run_date:' || to_char(l_last_run_date, 'DD-MON-YYYY HH24:MI:SS'));
    ELSE
      l_last_run_date := to_date(p_last_run_date,'DD-MON-YYYY HH24:MI:SS');  
    END IF;    
  EXCEPTION
    when others then
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'Exception in deriving last_run_date: ' || SQLERRM);
  END;

  --set the nls timestamp session parameter
  BEGIN
  --execute immediate 'alter session set nls_timestamp_format=''YYYY-DD-MM HH24:MI:SS.FF''';
  execute immediate 'alter session set nls_timestamp_format= ''YYYY-MM-DD-HH24.MI.SS.FF''';
  END;  
  
  BEGIN
  
  lc_dblink_host := fnd_profile.value('XX_GP_AOPS_HOST');
  
  --Create Dynamic sql using DB Link. Include Errored records also
  lc_select_sql :=  ' Select distinct trim(a.CSTIDXRF_AOPS_ID)                                  '  ||
                    '      , trim(a.CSTIDXRF_REF_ID1)                                           '  ||
                    '      , trim(b.CCU007F_AVAIL_CREDIT)                                       '  ||
                    ' From   RACOONDTA.CSTIDXRF@' || lc_dblink_host || '.NA.ODCORP.NET a,       '  ||
                    '        RACOONDTA.CCU007F@'  || lc_dblink_host || '.NA.ODCORP.NET b        '  ||
                    ' where  b.CCU007F_CUSTOMER_ID = a.CSTIDXRF_AOPS_ID                         '  ||
                    ' and    a.CSTIDXRF_REF_CODE = ''RELIABLE''                                 '  ||
                    ' and    a.CSTIDXRF_AOPS_ID_TYPE = ''ACT''                                  '  ||
                    --' and    a.CSTIDXRF_UPDATE_DT  >  to_timestamp(:l_last_run_date,''DD-MON-YYYY HH24:MI:SS.FF'')  '  ||
                    ' and    a.CSTIDXRF_UPDATE_DT  >  to_timestamp(to_date(:L_LAST_RUN_DATE,''RRRR-MM-DD''),''RRRR-MM-DD-HH24.MI.SS.FF'')  '  ||
                    ' union                                                                     '  ||
                    ' Select distinct trim(a.CSTIDXRF_AOPS_ID)                                  '  ||
                    '      , trim(a.CSTIDXRF_REF_ID1)                                           '  ||
                    '      , trim(b.CCU007F_AVAIL_CREDIT)                                       '  ||
                    ' From   RACOONDTA.CSTIDXRF@' || lc_dblink_host || '.NA.ODCORP.NET a,       '  ||
                    '        RACOONDTA.CCU007F@'  || lc_dblink_host || '.NA.ODCORP.NET b,       '  ||
                    '        XX_CDH_RELIABLE_ACCOUNTS_STG c                               '  ||
                    ' where  b.CCU007F_CUSTOMER_ID = a.CSTIDXRF_AOPS_ID                         '  ||
                    ' and    a.CSTIDXRF_REF_CODE = ''RELIABLE''                                 '  ||
                    ' and    a.CSTIDXRF_AOPS_ID_TYPE = ''ACT''                                  '  ||
                    ' and    b.CCU007F_CUSTOMER_ID  = substrb(c.ACCT_ORIG_SYSTEM_REFERENCE,1,8) '  ||
                    ' and    c.status_flag in (''N'',''E'')                                     '  
                    ;  

  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'lc_select_sql: ' || lc_select_sql);
  ln_count := 0;
  
  open aops_reliable_Cursor FOR lc_select_sql using l_last_run_date;  
  
  loop
    lc_aops_id := null;
    lc_aops_omx_ref := null;
    ln_credit_limit := null;
    
    fetch aops_reliable_Cursor into lc_aops_id, lc_aops_omx_ref, ln_credit_limit;  
    EXIT WHEN aops_reliable_Cursor%NOTFOUND;    
    --UPSERT
    BEGIN
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'ln_count: ' || ln_count);
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'lc_acct_orig_system_reference: ' || lpad(trim(lc_aops_id),8,'0')  || '-00001-A0');
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'AOPS ID: ' || lc_aops_id);
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'OMX ID: ' || lc_aops_omx_ref);
      log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'CRED LMY: ' || ln_credit_limit);

      open C1(lc_aops_id || '-00001-A0');
      fetch C1 into lc_acct_orig_system_reference;
      
      IF (C1%NOTFOUND) THEN
      
        insert into XX_CDH_RELIABLE_ACCOUNTS_STG (
          ACCT_ORIG_SYSTEM_REFERENCE 
         ,PARTY_ORIG_SYSTEM_REFERENCE
         ,CREDIT_LIMIT                
         ,STATUS_FLAG                  
         ,CREATION_DATE              
         ,CREATED_BY                 
         ,LAST_UPDATE_DATE           
         ,LAST_UPDATED_BY               
        )
        values
        (
           lpad(trim(lc_aops_id),8,'0')  || '-00001-A0'
          ,lpad(trim(lc_aops_omx_ref),7,'0')
          ,ln_credit_limit
          ,'N'
          ,SYSDATE
          ,FND_GLOBAL.User_Id
          ,SYSDATE
          ,FND_GLOBAL.User_Id
        );
        
      ELSE
        update XX_CDH_RELIABLE_ACCOUNTS_STG
        set    PARTY_ORIG_SYSTEM_REFERENCE = lpad(trim(lc_aops_omx_ref),7,'0'),
               CREDIT_LIMIT = ln_credit_limit,
               LAST_UPDATE_DATE = sysdate,
               LAST_UPDATED_BY = FND_GLOBAL.User_Id
        where  ACCT_ORIG_SYSTEM_REFERENCE = lpad(trim(lc_aops_id),8,'0') || '-00001-A0'
          and  STATUS_FLAG in ('N','E')
        ;
               
      END IF;
      
      COMMIT;
      ln_count := ln_count + 1;
      close C1;
      
    EXCEPTION
      WHEN OTHERS THEN
        log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'ERROR IN UPSERT: ' || SQLERRM);
    END;    
  end loop;
  
  close aops_reliable_Cursor;
  
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'XX_CDH_RELIABLE_ACCT_UPD_PKG.extract_from_aops (-)');

EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG.EXTRACT_FROM_AOPS', 'EXTRACT_FROM_AOPS_ERROR: ' || SQLERRM);
END;    
END extract_from_aops;

PROCEDURE main
(
   x_errbuf                   OUT VARCHAR2
  ,x_retcode                  OUT NUMBER
  ,p_credit_limit_update       IN VARCHAR2  DEFAULT 'Y'
  ,p_reliable_number_update    IN VARCHAR2  DEFAULT 'Y'
  ,p_debug                     IN VARCHAR2  DEFAULT 'N'
  ,p_last_run_date             IN VARCHAR2    
  ,p_ap_contacts_update        IN VARCHAR2  DEFAULT 'Y'

) IS

  ln_party_id      HZ_CUST_ACCOUNTS.PARTY_ID%type;
  lc_acct_number   HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%type;
  
  cursor c1 
  is
  select *
  from   XX_CDH_RELIABLE_ACCOUNTS_STG
  where  status_flag in ('N','E')
  ;
  
  cursor c_party_id (p_acct_orig_system_reference VARCHAR2)
  is
  select party_id, account_number
  from   hz_cust_accounts
  where  orig_system_reference = p_acct_orig_system_reference
  ;
  
BEGIN
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'XX_CDH_RELIABLE_ACCT_UPD_PKG.Main (+)');
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'p_last_run_date: ' || p_last_run_date);  
  g_debug := p_debug;       
  
  -- Set AP Contacts from AOPS
  IF(p_ap_contacts_update = 'Y')
  THEN
    set_ap_contacts ( x_errbuf, x_retcode, p_last_run_date);
  END IF;

  if ( p_reliable_number_update = 'Y' or p_credit_limit_update = 'Y' ) then

    -- Extract data from AOPS
    extract_from_aops ( x_errbuf, x_retcode, p_last_run_date);        
  end if;
		
  -- Update OMX Number
  -- Update credit limits
  for reliable_rec in c1
  loop
  
      ln_party_id     := null;  
      lc_acct_number  := null; 
      
      open c_party_id (reliable_rec.ACCT_ORIG_SYSTEM_REFERENCE);
      fetch c_party_id into ln_party_id, lc_acct_number;

      if (ln_party_id = null) then
        update XX_CDH_RELIABLE_ACCOUNTS_STG
          set  status_flag = 'E', error_msg = 'ACCOUNT NOT FOUND'
        where  ACCT_ORIG_SYSTEM_REFERENCE = reliable_rec.ACCT_ORIG_SYSTEM_REFERENCE
        ;        
      else

        if ( p_reliable_number_update = 'Y' ) then
        
          set_Reliable_Acct_Number
          (   x_errbuf                     => x_errbuf
             ,x_retcode                    => x_retcode
             ,p_Reliable_Acct_Number       => reliable_rec.PARTY_ORIG_SYSTEM_REFERENCE 
             ,p_acct_orig_system_reference => reliable_rec.ACCT_ORIG_SYSTEM_REFERENCE             
             ,p_party_id                   => ln_party_id      
          );    
          update XX_CDH_RELIABLE_ACCOUNTS_STG
            set  status_flag = 'S', last_update_date = sysdate, last_updated_by = fnd_global.user_id
          where  ACCT_ORIG_SYSTEM_REFERENCE = reliable_rec.ACCT_ORIG_SYSTEM_REFERENCE
          ;                    
        end if;

        if ( p_credit_limit_update = 'Y' ) then
         
          set_credit_limit
          (   x_errbuf                => x_errbuf
             ,x_retcode               => x_retcode
             ,p_account_number        => lc_acct_number     
             ,p_credit_limit          => reliable_rec.CREDIT_LIMIT      
          );    
          update XX_CDH_RELIABLE_ACCOUNTS_STG
            set  status_flag = 'S', last_update_date = sysdate, last_updated_by = fnd_global.user_id
          where  ACCT_ORIG_SYSTEM_REFERENCE = reliable_rec.ACCT_ORIG_SYSTEM_REFERENCE
          ;    
           
         end if;        
      end if;
          
    commit;
    close c_party_id;
  end loop;  
  log_debug_msg('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'XX_CDH_RELIABLE_ACCT_UPD_PKG.Main (-)');

EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_RELIABLE_ACCT_UPD_PKG', 'MAIN_ERROR: ' || SQLERRM);
END main;

END XX_CDH_RELIABLE_ACCT_UPD_PKG;
/