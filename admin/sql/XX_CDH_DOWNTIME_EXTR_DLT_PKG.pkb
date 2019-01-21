create or replace
package  body XX_CDH_DOWNTIME_EXTR_DLT_PKG
as
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_DOWNTIME_EXTR_DLT_PKG                                              |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   27-May-2013     Sreedhar Mohan       Initial draft version                    |
-- |1.1        05-Jan-2016     Manikant Kasu        Removed schema alias as part of GSCC     | 
-- |                                                R12.2.2 Retrofit                         |
-- |1.2        25-May-2016     Havish Kasina        Removed schema names as part of GSCC     | 
-- |                                                R12.2.2 Retrofit                         |
-- +=========================================================================================+

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

FUNCTION get_cont_osr(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
  p_orig_system_reference   IN VARCHAR2                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
) RETURN VARCHAR2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
IS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
ln_cont_osr       VARCHAR2(30);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
BEGIN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
select hoc.orig_system_reference                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   INTO   ln_cont_osr                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
from   hz_org_contacts hoc,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
       hz_relationships rel,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
       hz_cust_accounts acct                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
where     acct.party_id = rel.object_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
   and    rel.relationship_code='CONTACT_OF'                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
   and    rel.relationship_type='CONTACT'                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   and    rel.directional_flag='F'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
   and    rel.relationship_id = hoc.party_relationship_id                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   and    acct.orig_system_reference = p_orig_system_reference                                                                                                                                                                                                                                                                                                                                                                                                                                                      
   and    rownum < 2;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   RETURN ln_cont_osr;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
EXCEPTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    WHEN TOO_MANY_ROWS THEN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
	    --return a dummy contact for OD                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
        RETURN '00000016997442';                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    WHEN OTHERS THEN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	    --return a dummy contact for OD                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
        RETURN '00000016997442';                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
END get_cont_osr; 

  --Procedure for extracting Customer Data in the source system
  --into existing CDH staging tables
 PROCEDURE extractCustomer  (errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2)
 IS
  ln_batch_id number;
  ln_cust_account_id number;
  lc_downtime_time_st VARCHAR2(255):= FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START');

  cursor C1
   is
     SELECT unique ACCT.CUST_ACCOUNT_ID,
            ACCT.PARTY_ID PARTY_ID,
            ACCT.orig_system_reference
     FROM   CS_INCIDENTS_ALL_B INC,
            HZ_CUST_ACCOUNTS ACCT
     WHERE  INC.CUSTOMER_ID = ACCT.PARTY_ID
     AND    ACCT.ATTRIBUTE18 = 'DIRECT'
   AND    (INC.CREATION_DATE > TO_DATE(lc_downtime_time_st, 'DD-MON-YYYY HH24:MI:SS') );
   
   cursor C2 (p_cust_account_id IN NUMBER)
   is
   select cust_acct_site_id, orig_system_reference 
   from   hz_cust_acct_sites_all 
   where cust_account_id = p_cust_account_id;

   cursor C3 (p_cust_acct_site_id IN NUMBER)
   is
   select site_use_id 
   from   hz_cust_site_uses_all 
   where  cust_acct_site_id = p_cust_acct_site_id;
   
   cursor C_REL(p_party_id IN NUMBER)
   is
   select relationship_id, party_id, subject_id, object_id
   from   hz_relationships
   where  subject_id=p_party_id;

   cursor C_rel_party(p_object_id in number)
   is
   select *
   from   hz_relationships
   where  object_id = p_object_id
   and    RELATIONSHIP_CODE = 'CONTACT_OF'
   and    RELATIONSHIP_TYPE = 'CONTACT'  
   and    directional_flag = 'F';
   
   cursor C_CP(p_rel_party_id IN NUMBER)
   is
   select *
   from   hz_contact_points
   where  owner_table_name = 'HZ_PARTIES'
   and    owner_table_id = p_rel_party_id;   
   
begin
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'START');

  select HZ_IMP_BATCH_SUMMARY_S.nextval
  into   ln_batch_id from dual;
  
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER','ln_batch_id: ' || ln_batch_id);
  
  for i_rec in C1
  LOOP
  
    --extract party
    INSERT INTO HZ_IMP_PARTIES_INT
      (BATCH_ID,
      PARTY_ORIG_SYSTEM,
      PARTY_ORIG_SYSTEM_REFERENCE,
      PARTY_TYPE,
      ATTRIBUTE4,
      ATTRIBUTE9,
      ATTRIBUTE13,
      ORGANIZATION_NAME,
      GSA_INDICATOR_FLAG,
      CREATED_BY_MODULE)
      select ln_batch_id,
             'A0',
             orig_system_reference,
             party_type,
             attribute4,
             attribute9,
             attribute13,
             party_name,
             gsa_indicator_flag,
             created_by_module
      from   hz_parties
      where  party_id = i_rec.party_id;

      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After HZ_IMP_PARTIES_INT');
      
      --extract address
       INSERT  INTO   HZ_IMP_ADDRESSES_INT
            (BATCH_ID,
            PARTY_ORIG_SYSTEM,
            PARTY_ORIG_SYSTEM_REFERENCE,
            SITE_ORIG_SYSTEM,
            SITE_ORIG_SYSTEM_REFERENCE,
            ADDRESS1,
            ADDRESS2,
            ADDRESS3,
            ADDRESS4,
            ADDRESS_LINES_PHONETIC,
            CITY,
            COUNTRY,
            COUNTY,
            POSTAL_CODE,
            PROVINCE,
            STATE,
            ATTRIBUTE1,
            ATTRIBUTE2,
            CREATED_BY_MODULE,
            PRIMARY_FLAG,
            PARTY_ID)
            (
          SELECT ln_batch_id,
                 'A0',
                 i_rec.ORIG_SYSTEM_REFERENCE,
                 'A0',
                 ps.ORIG_SYSTEM_REFERENCE,
                 hl.ADDRESS1,
                 hl.ADDRESS2,
                 hl.ADDRESS3,
                 hl.ADDRESS4,
                 hl.ADDRESS_LINES_PHONETIC,
                 hl.CITY,
                 hl.COUNTRY,
                 hl.COUNTY,
                 hl.POSTAL_CODE,
                 hl.PROVINCE,
                 hl.STATE,
                 hl.ADDRESS_KEY,
                 ps.party_site_name,
                 ps.CREATED_BY_MODULE,
                 ps.IDENTIFYING_ADDRESS_FLAG,
                 ps.PARTY_ID
           from  hz_party_sites  ps,
                 hz_locations    hl
           where ps.party_id = i_rec.party_id
           and   ps.location_id = hl.location_id
      );
      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After HZ_IMP_ADDRESSES_INT');
      --extract party_site_uses
      INSERT INTO HZ_IMP_ADDRESSUSES_INT
             (BATCH_ID,
              PARTY_ORIG_SYSTEM,
              PARTY_ORIG_SYSTEM_REFERENCE,
              SITE_ORIG_SYSTEM,
              SITE_ORIG_SYSTEM_REFERENCE,
              SITE_USE_TYPE,
              CREATED_BY_MODULE,
              PRIMARY_FLAG)
      (SELECT ln_batch_id,
             'A0',
              i_rec.ORIG_SYSTEM_REFERENCE,
              'A0',
              ps.ORIG_SYSTEM_REFERENCE,      
              su.SITE_USE_TYPE,
              su.created_by_module,
              su.primary_per_type
        from  hz_party_sites     ps,
              hz_party_site_uses su,
              hz_parties         hp
        where hp.party_id = i_rec.party_id
        and   ps.party_site_id = su.party_site_id
        and   hp.party_id = ps.party_id
      );
      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After HZ_IMP_ADDRESSUSES_INT');
      
      --extract cust_account
      INSERT INTO XXOD_HZ_IMP_ACCOUNTS_STG
            (BATCH_ID,
            RECORD_ID,
            PARTY_ORIG_SYSTEM,
            PARTY_ORIG_SYSTEM_REFERENCE,
            ACCOUNT_ORIG_SYSTEM,
            ACCOUNT_ORIG_SYSTEM_REFERENCE,
            CUSTOMER_ATTRIBUTE_CATEGORY,
            CUSTOMER_ATTRIBUTE1,
            CUSTOMER_ATTRIBUTE2,
            CUSTOMER_ATTRIBUTE3,
            CUSTOMER_ATTRIBUTE4,
            CUSTOMER_ATTRIBUTE5,
            CUSTOMER_ATTRIBUTE6,
            CUSTOMER_ATTRIBUTE7,
            CUSTOMER_ATTRIBUTE8,
            CUSTOMER_ATTRIBUTE9,
            CUSTOMER_ATTRIBUTE10,
            CUSTOMER_ATTRIBUTE11,
            CUSTOMER_ATTRIBUTE12,
            CUSTOMER_ATTRIBUTE13,
            CUSTOMER_ATTRIBUTE14,
            CUSTOMER_ATTRIBUTE15,
            CUSTOMER_ATTRIBUTE16,
            CUSTOMER_ATTRIBUTE17,
            CUSTOMER_ATTRIBUTE18,
            CUSTOMER_ATTRIBUTE19,
            CUSTOMER_ATTRIBUTE20,
            CUSTOMER_CLASS_CODE,
            ACCOUNT_NAME,
            CUSTOMER_STATUS,
            CUSTOMER_TYPE,
            CUST_TAX_CODE,
            SALES_CHANNEL_CODE)
      (SELECT   ln_batch_id,
                XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL,
                'A0',
                ORIG_SYSTEM_REFERENCE,
                'A0',
                ORIG_SYSTEM_REFERENCE,
                ATTRIBUTE_CATEGORY,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                ATTRIBUTE11,
                ATTRIBUTE12,
                ATTRIBUTE13,
                ATTRIBUTE14,
                ATTRIBUTE15,
                ATTRIBUTE16,
                ATTRIBUTE17,
                ATTRIBUTE18,
                ATTRIBUTE19,
                ATTRIBUTE20,
                CUSTOMER_CLASS_CODE,
                ACCOUNT_NAME,
                STATUS,
                CUSTOMER_TYPE,
                TAX_CODE,
                SALES_CHANNEL_CODE
       from     HZ_CUST_ACCOUNTS
       WHERE    PARTY_ID = i_rec.party_id);

      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After XXOD_HZ_IMP_ACCOUNTS_STG');
       
       select cust_account_id
       into   ln_cust_account_id
       from   hz_cust_accounts
       where  party_id = i_rec.party_id;

      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After XXOD_HZ_IMP_ACCOUNTS_STG, ln_cust_account_id: ' || ln_cust_account_id);

      --extract cust_acct_sites and extract cust_sites_uses_all
      for csite_rec in C2(ln_cust_account_id)
      loop
      --extract cust_acct_site
          INSERT INTO XXOD_HZ_IMP_ACCT_SITES_STG
            (BATCH_ID,
            RECORD_ID,
            PARTY_ORIG_SYSTEM,
            PARTY_ORIG_SYSTEM_REFERENCE,
            ACCOUNT_ORIG_SYSTEM,
            ACCOUNT_ORIG_SYSTEM_REFERENCE,
            PARTY_SITE_ORIG_SYSTEM,
            ADDRESS_ATTRIBUTE_CATEGORY,
            ADDRESS_ATTRIBUTE1,
            ADDRESS_ATTRIBUTE2,
            ADDRESS_ATTRIBUTE3,
            ADDRESS_ATTRIBUTE4,
            ADDRESS_ATTRIBUTE5,
            ADDRESS_ATTRIBUTE6,
            ADDRESS_ATTRIBUTE7,
            ADDRESS_ATTRIBUTE8,
            ADDRESS_ATTRIBUTE9,
            ADDRESS_ATTRIBUTE10,
            ADDRESS_ATTRIBUTE11,
            ADDRESS_ATTRIBUTE12,
            ADDRESS_ATTRIBUTE13,
            ADDRESS_ATTRIBUTE14,
            ADDRESS_ATTRIBUTE15,
            ADDRESS_ATTRIBUTE16,
            ADDRESS_ATTRIBUTE17,
            ADDRESS_ATTRIBUTE18,
            ADDRESS_ATTRIBUTE19,
            ADDRESS_ATTRIBUTE20,
            ADDRESS_CATEGORY_CODE,
            ACCT_SITE_ORIG_SYSTEM,
            ACCT_SITE_ORIG_SYS_REFERENCE,
            PARTY_SITE_ORIG_SYS_REFERENCE,
            ORG_ID)
      (select ln_batch_id,
              XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL,
              'A0',
              ORIG_SYSTEM_REFERENCE,
              'A0',
              ORIG_SYSTEM_REFERENCE,     
              'A0', 
              ATTRIBUTE_CATEGORY,
              ATTRIBUTE1,
              ATTRIBUTE2,
              ATTRIBUTE3,
              ATTRIBUTE4,
              ATTRIBUTE5,
              ATTRIBUTE6,
              ATTRIBUTE7,
              ATTRIBUTE8,
              ATTRIBUTE9,
              ATTRIBUTE10,
              ATTRIBUTE11,
              ATTRIBUTE12,
              ATTRIBUTE13,
              ATTRIBUTE14,
              ATTRIBUTE15,
              ATTRIBUTE16,
              ATTRIBUTE17,
              ATTRIBUTE18,
              ATTRIBUTE19,
              ATTRIBUTE20,
              CUSTOMER_CATEGORY_CODE,
              'A0',
              ORIG_SYSTEM_REFERENCE,
              ORIG_SYSTEM_REFERENCE,
              ORG_ID
        from   hz_cust_acct_sites_all
      where  cust_acct_site_id=csite_rec.cust_acct_site_id  );

      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After XXOD_HZ_IMP_ACCT_SITES_STG, cust_acct_site_id: ' || csite_rec.cust_acct_site_id);

        --extract cust_site_uses_all
        for cs_user_rec in C3(csite_rec.cust_acct_site_id)
        loop
              INSERT INTO XXOD_HZ_IMP_ACCT_SITE_USES_STG
                (batch_id,
                RECORD_ID,
                PARTY_ORIG_SYSTEM,
                PARTY_ORIG_SYSTEM_REFERENCE,
                ACCOUNT_ORIG_SYSTEM,
                ACCOUNT_ORIG_SYSTEM_REFERENCE,
                ACCT_SITE_ORIG_SYSTEM,
                ACCT_SITE_ORIG_SYS_REFERENCE,
                PRIMARY_FLAG,
                SITE_USE_ATTRIBUTE_CATEGORY,
                SITE_USE_ATTRIBUTE1,
                SITE_USE_ATTRIBUTE2,
                SITE_USE_ATTRIBUTE3,
                SITE_USE_ATTRIBUTE4,
                SITE_USE_ATTRIBUTE5,
                SITE_USE_ATTRIBUTE6,
                SITE_USE_ATTRIBUTE7,
                SITE_USE_ATTRIBUTE8,
                SITE_USE_ATTRIBUTE9,
                SITE_USE_ATTRIBUTE10,
                SITE_USE_CODE,
                ORG_ID,
                LOCATION)
          (select ln_batch_id,
                 XXOD_HZ_IMP_ACCOUNTS_S.NEXTVAL,
                 'A0',
                 substr(i_rec.ORIG_SYSTEM_REFERENCE,1,17),
                 'A0',
                 substr(i_rec.ORIG_SYSTEM_REFERENCE,1,17),
                 'A0',
                 substr(csite_rec.ORIG_SYSTEM_REFERENCE,1,17),
                PRIMARY_FLAG,
                ATTRIBUTE_CATEGORY,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                SITE_USE_CODE,
                ORG_ID,
                LOCATION
          from  hz_cust_site_uses_all
          where site_use_id=cs_user_rec.site_use_id);

          log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After XXOD_HZ_IMP_ACCT_SITE_USES_STG, site_use_id: ' || cs_user_rec.site_use_id);
        
        end loop;
      end loop;  
        --extract org_contact
        for rel_rec in C_rel(i_rec.party_id)
        loop
          INSERT INTO  HZ_IMP_CONTACTS_INT
              (BATCH_ID,
              CONTACT_ORIG_SYSTEM,
              CONTACT_ORIG_SYSTEM_REFERENCE,
              SUB_ORIG_SYSTEM,
              SUB_ORIG_SYSTEM_REFERENCE,
              OBJ_ORIG_SYSTEM,
              OBJ_ORIG_SYSTEM_REFERENCE,
              RELATIONSHIP_TYPE,
              RELATIONSHIP_CODE,
              START_DATE,
              END_DATE,
              CREATED_BY_MODULE)
          (select ln_batch_id,
                  'A0',
                  (select ORIG_SYSTEM_REFERENCE from hz_parties where party_id=subject_id),
                  'A0',
                  (select ORIG_SYSTEM_REFERENCE from hz_parties where party_id=subject_id),
                  'A0',
                  (select ORIG_SYSTEM_REFERENCE from hz_parties where party_id=object_id),
                  'CONTACT_OF',
                  'CONTACT',
                  START_DATE,
                  END_DATE,
                  CREATED_BY_MODULE
           from   hz_relationships
          where   relationship_id = rel_rec.relationship_id
          and     directional_flag = 'F');

          log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After HZ_IMP_CONTACTS_INT, rel_rec.relationship_id: ' || rel_rec.relationship_id);

          --Extract Person Parties for contacts

            INSERT INTO HZ_IMP_PARTIES_INT
            (BATCH_ID,
             PARTY_ORIG_SYSTEM,
             PARTY_ORIG_SYSTEM_REFERENCE,
             PARTY_TYPE,
             SALUTATION,
             PERSON_FIRST_NAME,
             PERSON_LAST_NAME,
             PERSON_MIDDLE_NAME)
            (SELECT  ln_batch_id,
                     'A0',
                     ORIG_SYSTEM_REFERENCE,
                     PARTY_TYPE,
                     SALUTATION,
                     PERSON_FIRST_NAME,
                     PERSON_LAST_NAME,
                     PERSON_MIDDLE_NAME
             from    HZ_PARTIES
             where   party_id = rel_rec.object_id );

          --extract contact_point
          INSERT INTO HZ_IMP_CONTACTPTS_INT
               (BATCH_ID,
                CP_ORIG_SYSTEM,
                CP_ORIG_SYSTEM_REFERENCE,
                PARTY_ORIG_SYSTEM,
                PARTY_ORIG_SYSTEM_REFERENCE,
                SITE_ORIG_SYSTEM,
                SITE_ORIG_SYSTEM_REFERENCE,
                CONTACT_POINT_TYPE,
                CONTACT_POINT_PURPOSE,
                EDI_ECE_TP_LOCATION_CODE,
                EDI_ID_NUMBER,
                EDI_PAYMENT_FORMAT,
                EDI_PAYMENT_METHOD,
                EDI_REMITTANCE_INSTRUCTION,
                EDI_REMITTANCE_METHOD,
                EDI_TP_HEADER_ID,
                EDI_TRANSACTION_HANDLING,
                EFT_PRINTING_PROGRAM_ID,
                EFT_SWIFT_CODE,
                EFT_TRANSMISSION_PROGRAM_ID,
                EFT_USER_NUMBER,
                EMAIL_ADDRESS,
                EMAIL_FORMAT,
                PHONE_AREA_CODE,
                PHONE_COUNTRY_CODE,
                PHONE_EXTENSION,
                PHONE_LINE_TYPE,
                PHONE_NUMBER,
                RAW_PHONE_NUMBER,
                PHONE_CALLING_CALENDAR,
                TELEX_NUMBER,
                URL,
                WEB_TYPE,
                PRIMARY_FLAG,
                ATTRIBUTE_CATEGORY,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                ATTRIBUTE11,
                ATTRIBUTE12,
                ATTRIBUTE13,
                ATTRIBUTE14,
                ATTRIBUTE15,
                ATTRIBUTE16,
                ATTRIBUTE17,
                ATTRIBUTE18,
                ATTRIBUTE19,
                ATTRIBUTE20)
          (select ln_batch_id,
                'A0',
                ORIG_SYSTEM_REFERENCE,
                'A0',
                i_rec.ORIG_SYSTEM_REFERENCE,
                'A0',
                i_rec.ORIG_SYSTEM_REFERENCE,
                CONTACT_POINT_TYPE,
                CONTACT_POINT_PURPOSE,
                EDI_ECE_TP_LOCATION_CODE,
                EDI_ID_NUMBER,
                EDI_PAYMENT_FORMAT,
                EDI_PAYMENT_METHOD,
                EDI_REMITTANCE_INSTRUCTION,
                EDI_REMITTANCE_METHOD,
                EDI_TP_HEADER_ID,
                EDI_TRANSACTION_HANDLING,
                EFT_PRINTING_PROGRAM_ID,
                EFT_SWIFT_CODE,
                EFT_TRANSMISSION_PROGRAM_ID,
                EFT_USER_NUMBER,
                EMAIL_ADDRESS,
                EMAIL_FORMAT,
                PHONE_AREA_CODE,
                PHONE_COUNTRY_CODE,
                PHONE_EXTENSION,
                PHONE_LINE_TYPE,
                PHONE_NUMBER,
                RAW_PHONE_NUMBER,
                PHONE_CALLING_CALENDAR,
                TELEX_NUMBER,
                URL,
                WEB_TYPE,
                PRIMARY_FLAG,
                ATTRIBUTE_CATEGORY,
                ATTRIBUTE1,
                ATTRIBUTE2,
                ATTRIBUTE3,
                ATTRIBUTE4,
                ATTRIBUTE5,
                ATTRIBUTE6,
                ATTRIBUTE7,
                ATTRIBUTE8,
                ATTRIBUTE9,
                ATTRIBUTE10,
                ATTRIBUTE11,
                ATTRIBUTE12,
                ATTRIBUTE13,
                ATTRIBUTE14,
                ATTRIBUTE15,
                ATTRIBUTE16,
                ATTRIBUTE17,
                ATTRIBUTE18,
                ATTRIBUTE19,
                ATTRIBUTE20
           from   hz_contact_points
           where  owner_table_name='HZ_PARTIES'
           AND    owner_table_id=rel_rec.party_id);

          log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'After HZ_IMP_CONTACTPTS_INT, rel_rec.party_id: ' || rel_rec.party_id);

      end loop;      
  END LOOP;
  
  COMMIT;
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'END');
 EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMER', 'EXTRACTCUSTOMER_ERROR: ' || SQLERRM);
 END extractCustomer;
 
 --Procedure for extracting TDS Customer in the source system                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  --into a staging table                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
 PROCEDURE EXTRACT_TDS_CUSTOMER(errbuf  OUT NOCOPY VARCHAR2                                                                                                                                                                                                                                                                                                                                                                                                                                                         
                              , retcode OUT NOCOPY VARCHAR2)                                                                                                                                                                                                                                                                                                                                                                                                                                                        
 IS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    cursor c1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    is                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    select                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
           inc.incident_number                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
          ,inc.customer_ticket_number                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
          ,acct.orig_system_reference                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
          ,acct.creation_date                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
          ,acct.last_update_date                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
          ,acct.attribute6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
          ,org.organization_name                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
          ,hzl.address1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,hzl.address2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,hzl.city                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
          ,hzl.state                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
          ,hzl.county                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
          ,hzl.postal_code                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
          ,hzl.address_key                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
          ,hzl.address_lines_phonetic                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
          ,hps.party_site_name                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
          ,null   as CONT_PERSON_SALUTATION                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
          ,substrb(inc.incident_attribute_5, 1, instr(inc.incident_attribute_5, ' ')) as cont_person_first_name                                                                                                                                                                                                                                                                                                                                                                                                     
          ,substrb(inc.incident_attribute_5, instr(inc.incident_attribute_5, ' '), length(inc.incident_attribute_5)) as  cont_person_last_name                                                                                                                                                                                                                                                                                                                                                                      
          ,trim(inc.Tier_version) as CONT_ORIG_SYS_REFERENCE                                                                                                                                                                                                                                                                                                                                                                                                                                                        
          ,inc.incident_attribute_8               CONT_EMAIL_ADDRESS                                                                                                                                                                                                                                                                                                                                                                                                                                                
          ,inc.incident_attribute_14              CONT_RAW_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,SUBSTRB(inc.incident_attribute_14,0,1) CONT_PHONE_COUNTRY_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                           
          ,SUBSTRB(inc.incident_attribute_14,2,3) CONT_PHONE_AREA_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                              
          ,SUBSTRB(inc.incident_attribute_14,4,LENGTH(inc.incident_attribute_14)) CONT_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                 
   from    cs_incidents_all_b       inc                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,hz_cust_accounts         acct                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
          ,hz_party_sites           hps                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,hz_locations             hzl                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
          ,hz_organization_profiles org                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
   where  inc.customer_id = acct.party_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   and    inc.bill_to_site_id = hps.party_site_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
   and    acct.party_id = org.party_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
   and    acct.party_id   = hps.party_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
   and    hps.location_id = hzl.location_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   --and    inc.customer_ticket_number is not null                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
   --and    inc.problem_code like 'TDS%'                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
   --AND    ACCT.ATTRIBUTE18 = 'DIRECT'                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
   --AND    ACCT.global_attribute20 is null                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   --AND    ACCT.created_by_module='BO_API'                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   AND    (INC.CREATION_DATE between to_date(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START'),'DD-MON-YYYY HH24:MI:SS')                                                                                                                                                                                                                                                                                                                                                                                              
           and  TO_DATE(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_END'), 'DD-MON-YYYY HH24:MI:SS'));                                                                                                                                                                                                                                                                                                                                                                                                                  
   --AND  (acct.creation_date between to_date(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START'),'DD-MON-YYYY HH24:MI:SS')                                                                                                                                                                                                                                                                                                                                                                                             
   --        and  TO_DATE(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_END'), 'DD-MON-YYYY HH24:MI:SS'));                                                                                                                                                                                                                                                                                                                                                                                                                

   l_record_id                     number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_user_id                       number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_responsibility_id             number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_responsibility_appl_id        number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_cont_osr                      varchar2(30);                                                                                                                                                                                                                                                                                                                                                                                                                                                                    

  BEGIN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACT_TDS_CUSTOMER','START');                                                                                                                                                                                                                                                                                                                                                                                                                                       
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
    log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.CREATE_TDS_CUSTOMER','Exception in initializing : ' || SQLERRM);                                                                                                                                                                                                                                                                                                                                                                                                    
   end;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACT_TDS_CUSTOMER','After context setting');                                                                                                                                                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  for i_rec in C1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
  loop                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    l_record_id := XX_CDH_TDS_CUSTOMER_S.nextval;                                                                                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    IF (i_rec.CONT_ORIG_SYS_REFERENCE is NULL) THEN                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
      l_cont_osr := get_cont_osr(i_rec.ORIG_SYSTEM_REFERENCE);                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ELSE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
      l_cont_osr := i_rec.CONT_ORIG_SYS_REFERENCE;                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    END IF;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    INSERT INTO XX_CDH_TDS_CUSTOMER_STG (                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
     RECORD_ID                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    ,ORIG_SYSTEM_REFERENCE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    ,ORGANIZATION_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    ,INCIDENT_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
    ,CUSTOMER_TICKET_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ,CREATION_DATE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
    ,CREATED_BY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    ,ADDRESS1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    ,ADDRESS2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    ,CITY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    ,STATE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    ,POSTAL_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    ,COUNTY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ,ADDRESS_KEY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    ,ADDRESS_LINES_PHONETIC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ,PARTY_SITE_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
    ,CONT_ORIG_SYS_REFERENCE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    ,CONT_PERSON_SALUTATION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ,CONT_PERSON_FIRST_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    ,CONT_PERSON_LAST_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    ,CONT_ROLE_TYPE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ,CONT_PHONE_OSR                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ,CONT_PHONE_COUNTRY_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    ,CONT_PHONE_AREA_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
    ,CONT_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
    ,CONT_RAW_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    ,CONT_EMAIL_OSR                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
    ,CONT_EMAIL_ADDRESS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
    ,ATTRIBUTE6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    ,INTERFACE_STATUS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
	VALUES (                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
	  L_RECORD_ID                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 ,i_rec.ORIG_SYSTEM_REFERENCE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 ,i_rec.ORGANIZATION_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
	 ,i_rec.INCIDENT_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
	 ,i_rec.CUSTOMER_TICKET_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
	 ,SYSDATE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
	 ,l_user_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
	 ,i_rec.ADDRESS1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
	 ,i_rec.ADDRESS2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
	 ,i_rec.CITY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
	 ,i_rec.STATE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 ,i_rec.POSTAL_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	 ,i_rec.COUNTY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
	 ,i_rec.ADDRESS_KEY                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	 ,i_rec.ADDRESS_LINES_PHONETIC                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
	 ,i_rec.PARTY_SITE_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
	 ,l_cont_osr                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
	 ,i_rec.CONT_PERSON_SALUTATION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
	 ,i_rec.CONT_PERSON_FIRST_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
	 ,i_rec.CONT_PERSON_LAST_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 ,'FIRST_CONTACT'                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
	 ,'P' || l_cont_osr                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	 ,i_rec.CONT_PHONE_COUNTRY_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	 ,i_rec.CONT_PHONE_AREA_CODE                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
	 ,i_rec.CONT_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
	 ,i_rec.CONT_RAW_PHONE_NUMBER                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	 ,'E' || l_cont_osr                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	 ,i_rec.CONT_EMAIL_ADDRESS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
   ,i_rec.ATTRIBUTE6                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
	 ,1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
	);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	COMMIT;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  END LOOP;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
 EXCEPTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
  WHEN OTHERS THEN                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
    log_error('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACT_TDS_CUSTOMER', 'EXTRACT_TDS_CUSTOMER_ERROR: ' || SQLERRM);                                                                                                                                                                                                                                                                                                                                                                                                      
 END EXTRACT_TDS_CUSTOMER;              

  --Procedure for extracting Org_Cust_BO in the source system
  --into a staging table
 PROCEDURE extractCustomerBO(errbuf  OUT NOCOPY VARCHAR2
                           , retcode OUT NOCOPY VARCHAR2)
 IS
    ln_organization_id           NUMBER;                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
   lc_organization_os           hz_orig_sys_references.orig_system%TYPE := 'A0';                                                                                                                                                                                                                                                                                                                                                                                                                                    
   lc_organization_osr          hz_orig_sys_references.orig_system_reference%TYPE;                                                                                                                                                                                                                                                                                                                                                                                                                                  
   lo_org_cust_obj              HZ_ORG_CUST_BO := HZ_ORG_CUST_BO(null, null,HZ_CUST_ACCT_BO_TBL());                                                                                                                                                                                                                                                                                                                                                                                                                 
   lc_return_status             VARCHAR2(1);                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
   ln_msg_count                 NUMBER;                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
   lc_msg_data                  VARCHAR2(2000);                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
   l_err_msg                    VARCHAR2(2000);                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
   lc_downtime_time_st          VARCHAR2(255):= FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START');                                                                                                                                                                                                                                                                                                                                                                                                                    
   l_hz_org_cust_bo_payload     sys.XMLTYPE;                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
   l_user_id                       number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_responsibility_id             number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
   l_responsibility_appl_id        number;                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
   cursor c1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
   is                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
   /*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
   SELECT distinct ACCT.CUST_ACCOUNT_ID,                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
          INC.CUSTOMER_ID PARTY_ID,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
          ACCT.orig_system_reference,                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
          ACCT.account_name,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
          INC.CREATION_DATE,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        

		  INC.INCIDENT_ATTRIBUTE_14 CONT_PH_NUMBER,                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
		  INC.INCIDENT_ATTRIBUTE_8  CONT_EMAIL_ADDR   FROM   CS_INCIDENTS_ALL_B INC,                                                                                                                                                                                                                                                                                                                                                                                                                                 
          HZ_CUST_ACCOUNTS ACCT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
   WHERE  INC.CUSTOMER_ID = ACCT.PARTY_ID                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    ACCT.ATTRIBUTE18 = 'DIRECT'                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
   AND    ACCT.global_attribute20 is null                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    ACCT.created_by_module='BO_API'                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    (INC.CREATION_DATE between to_date(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_START'),'DD-MON-YYYY HH24:MI:SS')                                                                                                                                                                                                                                                                                                                                                                                              
           and  TO_DATE(FND_PROFILE.VALUE('XX_CDH_DOWNTIME_TIME_END'), 'DD-MON-YYYY HH24:MI:SS'));                                                                                                                                                                                                                                                                                                                                                                                                                  
   */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
   SELECT distinct ACCT.CUST_ACCOUNT_ID,                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
          INC.CUSTOMER_ID PARTY_ID,     
          ACCT.orig_system_reference,
          ACCT.account_name,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
          INC.CREATION_DATE,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
     		  INC.INCIDENT_ATTRIBUTE_14 CONT_PH_NUMBER,                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
		      INC.INCIDENT_ATTRIBUTE_8  CONT_EMAIL_ADDR                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
   FROM   CS_INCIDENTS_ALL_B INC,                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
          HZ_CUST_ACCOUNTS ACCT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
   WHERE  INC.CUSTOMER_ID = ACCT.PARTY_ID                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    ACCT.ATTRIBUTE18 = 'DIRECT'                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
   AND    ACCT.global_attribute20 is null                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    ACCT.created_by_module='BO_API'                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
   AND    (INC.CREATION_DATE between to_date('20-JAN-2014 08:46:26','DD-MON-YYYY HH24:MI:SS')                                                                                                                                                                                                                                                                                                                                                                                                                       
           and  TO_DATE('20-JAN-2014 11:46:26', 'DD-MON-YYYY HH24:MI:SS')); 

 BEGIN
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO','START');
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
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO','After context setting');
 
 for i_rec in C1
  loop

    --get org_cust_bo based on the cust_account_id
    HZ_ORG_CUST_BO_PUB.get_org_cust_bo(
      p_init_msg_list       => fnd_api.g_false,
      p_organization_id     => i_rec.party_id,
      p_organization_os     => lc_organization_os,
      p_organization_osr    => i_rec.orig_system_reference,
      x_org_cust_obj        => lo_org_cust_obj,
      x_return_status       => lc_return_status,
      x_msg_count           => ln_msg_count,    
      x_msg_data            => lc_msg_data     
    );
    
    log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO','OSR:' || 
                   i_rec.orig_system_reference || ', Party_ID: ' || 
                   i_rec.party_id || ', return_status:' || lc_return_status);

    l_err_msg := '';

    if lc_return_status <> 'S' then
      IF(ln_msg_count >= 1) THEN 
        FOR I IN 1..ln_msg_count LOOP 
          l_err_msg := l_err_msg || FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE ); 
        END LOOP; 
      ELSE 
        l_err_msg := lc_msg_data; 

      END IF; 
      log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO','OSR:' || 
               i_rec.orig_system_reference || ', Party_ID: ' || 
               i_rec.party_id || ', Error:' || l_err_msg);
    end if;
    
    --get the BO into XML
    l_hz_org_cust_bo_payload     := XMLTYPE(lo_org_cust_obj);
    
    --Dump the payload into database with the interface_status = 1 (inserted) in XX_CDH_CUST_BO_STG table
    insert into XX_CDH_CUST_BO_STG 
    (   BPEL_PROCESS_ID      ,
        CUST_ACCOUNT_ID      ,
        PARTY_ID             ,
        ORG_CUST_BO_PAYLOAD  ,
        INTERFACE_STATUS     ,
        ORIG_SYSTEM_REFERENCE, 
        CREATION_DATE        ,
        CREATED_BY           
    ) values
    (
        XX_CDH_CUSTOMER_BO_PROC_ID_S.nextval,
        i_rec.cust_account_id       ,
        i_rec.party_id              ,
        l_hz_org_cust_bo_payload    , 
        1                           ,
        i_rec.orig_system_reference ,
        SYSDATE                     ,
        FND_GLOBAL.user_id          
    );
    
    commit;
  end loop;
  
  log_debug_msg('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO', 'END');
 EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_EXTR_DLT_PKG.EXTRACTCUSTOMERBO', 'EXTRACTCUSTOMERBO_ERROR: ' || SQLERRM);
 END EXTRACTCUSTOMERBO;

 PROCEDURE CLEANUP_STAGING(errbuf  OUT NOCOPY VARCHAR2
                         , retcode OUT NOCOPY VARCHAR2
                         , p_time  IN         VARCHAR2)
 IS

 BEGIN

  DELETE FROM
  XX_CDH_CUST_BO_STG
  where  creation_date > p_time;

  commit;
 EXCEPTION
  WHEN OTHERS THEN
    log_error('XX_CDH_DOWNTIME_EXTR_DLT_PKG.CLEANUP_STAGING', 'CLEANUP_STAGING_ERROR: ' || SQLERRM);
 END CLEANUP_STAGING;

end XX_CDH_DOWNTIME_EXTR_DLT_PKG;
/
SHOW ERRORS