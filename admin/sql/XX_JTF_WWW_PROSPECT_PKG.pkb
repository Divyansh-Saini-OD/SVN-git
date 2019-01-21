-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_JTF_WWW_PROSPECT_PKG.pkb                         |
-- | Description      :I2043 Leads_from_WWW_and_Jmillennia                 |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      15-Feb-2008 David Woods        Initial version                |
-- +=======================================================================+

create or replace package body XX_JTF_WWW_PROSPECT_PKG
AS 
PROCEDURE jtf_prospect_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN         NUMBER
   )
IS
   ln_batch_id             NUMBER;
   ln_CREATED_BY           number;
   ln_parties_int_cnt      number:=0;
   ln_ext_attribs_int_cnt  number:=0;
   ln_addresses_int_cnt    number:=0;
   ln_addressuses_int_cnt  number:=0;
   ln_contactpts_int_cnt   number:=0;

   ln_read_cnt             NUMBER:=0;
   ln_extr_cnt             NUMBER:=0;
   ln_addr_cnt             NUMBER:=0;

   lc_package_name         varchar2(32) := 'XX_JTF_WWW_PROSPECT_PKG';
   lc_procedure_name       varchar2(32) := 'LOAD PROSPECTS';
   lc_sqlerr_code          varchar2(100);
   lc_sqlerr_msg           varchar2(2000);
   lc_source_system        varchar2(10) := 'WWW';
   lc_error_msg            varchar2(2000);

    v_CREATED_BY_MODULE    char(3):='WWW';
    v_PARTY_ORIG_SYSTEM    char(2):='SX';
    v_SITE_ORIG_SYSTEM     char(2):='SX';
    c_ship_to              char(7):='SHIP_TO';
    c_bill_to              char(7):='BILL_TO';
    c_party                char(5):='PARTY';
    c_party_type           char(12):='ORGANIZATION';
    c_Y                    char(1):='Y';
    c_N                    char(1):='N';

    v_SHIPTO_SITE_OSR      varchar2(50);
    v_BILLTO_SITE_OSR      varchar2(50);

    V_PARTY_OSR            varchar2(50);
    V_INTERNID             varchar2(20);
    V_ORGANIZATION_NAME    varchar2(100);
    V_ADDR1                varchar2(50);
    V_CITY                 varchar2(50);
    V_STATE                varchar2(10);
    V_postal_code          varchar2(12);
    V_country              char(2);
    V_ATTRIBUTE24          varchar2(10);
    V_ATTRIBUTE10          number;
    V_EMPLOYEES_TOTAL      number;
    V_PHONE                varchar2(24);
 
    V_CREATION_DATE        date;
    V_ATTRIBUTE_CATEGORY   varchar2(30);

    V_status               varchar2(50);
    V_error_msg            varchar2(100);
    V_staging_column_name  varchar2(32);
    V_staging_column_value varchar2(500);
    V_package_name         varchar(32):='WWW CREATE PROSPECTS';
    V_procedure_name       varchar(32):='VALIDATE WWW DATA';

    Cursor c_API is
      SELECT lpad(INTERNID,10,'0') as INTERNID
            ,ORGANIZATION_NAME
            ,ADDR1
            ,CITY
            ,STATE
            ,postal_code
            ,country
            ,NUM_WC_EMP_OD AS ATTRIBUTE10
            ,REV_BAND as ATTRIBUTE24
            ,PHONE
      FROM XXCRM.XX_JTF_WWW_NEW_PROSPECTS;
--    FROM XXCRM.XX_JTF_WWW_TEST_PROSPECTS;

BEGIN   
   fnd_file.put_line(fnd_file.LOG,' ');
    
   fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                 ||lpad('DATE: ',60,' ')
                                 ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
   fnd_file.put_line(fnd_file.LOG,
     lpad('OD: JTF WWW load PROSPECTS to CV tables',69,' '));
    
   fnd_file.put_line(fnd_file.LOG,' ');

   Ln_batch_id := p_batch_id;
   FND_FILE.put_line(fnd_file.log,
     'batch_id=' || ln_batch_id);   
 
   SELECT FND_GLOBAL.USER_ID 
   Into ln_created_by
   FROM DUAL;
  
   fnd_file.put_line(fnd_file.LOG,' ');
   fnd_file.put_line(fnd_file.LOG,
     ' Started deleting existing records from the table' ||  
     ' XXCRM.XX_JTF_WWW_PROSPECT_EXTR...');
   DELETE FROM XXCRM.XX_JTF_WWW_PROSPECT_EXTR;
   fnd_file.put_line(fnd_file.LOG,
     ' Successfully deleted all the records from the table' || 
     ' XXCRM.XX_JTF_WWW_PROSPECT_EXTR...');

   fnd_file.put_line(fnd_file.LOG,' ');
   fnd_file.put_line(fnd_file.LOG,
     ' Started deleting existing records from the table' ||  
     ' XXCRM.XX_JTF_WWW_PROSPECT_ADDR...');
   DELETE FROM XXCRM.XX_JTF_WWW_PROSPECT_ADDR;
   fnd_file.put_line(fnd_file.LOG,
     ' Successfully deleted all the records from the table' || 
     ' XXCRM.XX_JTF_WWW_PROSPECT_ADDR...');

   For i in c_api
     LOOP
        ln_read_cnt := ln_read_cnt + 1;

        V_internid          := i.INTERNID;
        V_ORGANIZATION_NAME := i.ORGANIZATION_NAME;
        V_ADDR1             := i.ADDR1;
        V_CITY              := i.city;
        V_STATE             := i.state;
        V_postal_code       := i.postal_code;
        V_country           := i.country;
        V_ATTRIBUTE24       := i.ATTRIBUTE24;
        V_ATTRIBUTE10       := i.ATTRIBUTE10;
        V_PHONE             := i.PHONE;
      
        V_party_OSR       := v_internid || '-00001-SX';
        v_SHIPTO_SITE_OSR := v_internid || '-00002-SX';
        v_BILLTO_SITE_OSR := v_internid || '-00001-SX';

        Insert into XXCRM.XX_JTF_WWW_PROSPECT_ADDR
          (BATCH_ID
          ,CREATED_BY_MODULE
          ,PARTY_ORIG_SYSTEM
          ,PARTY_ORIG_SYSTEM_REFERENCE
          ,SITE_ORIG_SYSTEM
          ,SITE_ORIG_SYSTEM_REFERENCE
          ,SITE_USE_TYPE
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE
          ,COUNTRY
          ,PRIMARY_FLAG
          ,DESCRIPTION
          ,CREATED_BY)
        Values 
          (ln_BATCH_ID
          ,v_CREATED_BY_MODULE
          ,v_PARTY_ORIG_SYSTEM
          ,v_PARTY_OSR
          ,v_SITE_ORIG_SYSTEM
          ,v_SHIPTO_SITE_OSR
          ,c_ship_to
          ,v_ADDR1
          ,v_CITY
          ,v_STATE
          ,v_postal_code
          ,v_COUNTRY
          ,c_Y
          ,c_party
          ,ln_CREATED_BY);
   
        Insert into XXCRM.XX_JTF_WWW_PROSPECT_ADDR
          (BATCH_ID
          ,CREATED_BY_MODULE
          ,PARTY_ORIG_SYSTEM
          ,PARTY_ORIG_SYSTEM_REFERENCE
          ,SITE_ORIG_SYSTEM
          ,SITE_ORIG_SYSTEM_REFERENCE
          ,SITE_USE_TYPE
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE
          ,COUNTRY
          ,PRIMARY_FLAG
          ,DESCRIPTION
          ,CREATED_BY)
        Values 
          (ln_BATCH_ID
          ,v_CREATED_BY_MODULE
          ,v_PARTY_ORIG_SYSTEM
          ,v_PARTY_OSR
          ,v_SITE_ORIG_SYSTEM
          ,v_BILLTO_SITE_OSR
          ,c_bill_to
          ,v_ADDR1
          ,v_CITY
          ,v_STATE
          ,v_postal_code
          ,v_COUNTRY
          ,c_N
          ,c_party
          ,ln_CREATED_BY);
       ln_addr_cnt := ln_addr_cnt + 2;
              
       v_attribute_category := v_country;
       
       Insert into XXCRM.XX_JTF_WWW_PROSPECT_EXTR
         (BATCH_ID
         ,PARTY_ORIG_SYSTEM
         ,PARTY_ORIG_SYSTEM_REFERENCE
         ,PARTY_TYPE
         ,CREATED_BY_MODULE
         ,ORGANIZATION_NAME
         ,ATTRIBUTE24
         ,ATTRIBUTE10
         ,CREATED_BY
         ,PHONE
         ,ATTRIBUTE_CATEGORY)
       Values
         (ln_BATCH_ID
         ,v_PARTY_ORIG_SYSTEM
         ,v_PARTY_OSR
         ,C_PARTY_TYPE
         ,v_CREATED_BY_MODULE
         ,v_ORGANIZATION_NAME
         ,v_ATTRIBUTE24
         ,v_ATTRIBUTE10
         ,ln_CREATED_BY
         ,v_PHONE
         ,V_ATTRIBUTE_CATEGORY);
       ln_extr_cnt := ln_extr_cnt + 1;
    END LOOP;
    COMMIT;
    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' total number of prospects in this run: ' || ln_read_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' total number of prospects loaded into stg table' ||
      ' XX_JTF_WWW_PROSPECT_EXTR: ' || ln_extr_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' total number of addresses loaded into stg table' ||
      ' XX_JTF_WWW_PROSPECT_ADDR: ' || ln_addr_cnt);

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting PARTIES data into the table' ||
      ' XXOD_HZ_IMP_PARTIES_INT...');
    INSERT INTO XXOD_HZ_IMP_PARTIES_INT 
      (BATCH_ID
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,PARTY_TYPE
      ,CREATED_BY_MODULE
      ,ORGANIZATION_NAME
      ,ATTRIBUTE10
      ,ATTRIBUTE13
      ,ATTRIBUTE24
      ,EMPLOYEES_TOTAL
      ,CREATED_BY
      ,CREATION_DATE
      ,ATTRIBUTE_CATEGORY)
    SELECT BATCH_ID
          ,PARTY_ORIG_SYSTEM
          ,PARTY_ORIG_SYSTEM_REFERENCE
          ,PARTY_TYPE
          ,CREATED_BY_MODULE
          ,ORGANIZATION_NAME
          ,ATTRIBUTE10
          ,'PROSPECT' as ATTRIBUTE13
          ,ATTRIBUTE24
          ,0 as EMPLOYEES_TOTAL
          ,CREATED_BY
          ,sysdate as CREATION_DATE
          ,ATTRIBUTE_CATEGORY
    FROM XXCRM.XX_JTF_WWW_PROSPECT_EXTR;
    ln_parties_int_cnt := sql%rowcount;

    INSERT INTO XXOD_HZ_IMP_EXT_ATTRIBS_INT
      (BATCH_ID                  
      ,CREATED_BY_MODULE        
      ,ORIG_SYSTEM               
      ,ORIG_SYSTEM_REFERENCE   
      ,INTERFACE_ENTITY_NAME       
      ,INTERFACE_ENTITY_REFERENCE 
      ,ATTRIBUTE_GROUP_CODE     
      ,N_EXT_ATTR8)
    SELECT BATCH_ID
          ,CREATED_BY_MODULE     
          ,PARTY_ORIG_SYSTEM AS ORIG_SYSTEM               
          ,PARTY_ORIG_SYSTEM_REFERENCE AS ORIG_SYSTEM_REFERENCE     
          ,'SITE' AS INTERFACE_ENTITY_NAME     
          ,PARTY_ORIG_SYSTEM_REFERENCE AS INTERFACE_ENTITY_REFERENCE
          ,'SITE_DEMOGRAPHICS' AS ATTRIBUTE_GROUP_CODE      
          ,ATTRIBUTE10 AS N_EXT_ATTR8               
    FROM XXCRM.XX_JTF_WWW_PROSPECT_EXTR;
    ln_ext_attribs_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_parties_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted PARTIES data into the table' || 
      ' XXOD_HZ_IMP_PARTIES_INT...');

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting ADDRESSES data into the table' ||
      ' XXOD_HZ_IMP_ADDRESSES_INT...');
    INSERT INTO XXOD_HZ_IMP_ADDRESSES_INT
      (BATCH_ID
      ,DESCRIPTION
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,SITE_ORIG_SYSTEM
      ,SITE_ORIG_SYSTEM_REFERENCE
      ,CREATED_BY_MODULE
      ,ADDRESS1
      ,CITY
      ,STATE
      ,POSTAL_CODE
      ,COUNTRY
      ,PRIMARY_FLAG
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT BATCH_ID
          ,DESCRIPTION
          ,PARTY_ORIG_SYSTEM
          ,PARTY_ORIG_SYSTEM_REFERENCE
          ,SITE_ORIG_SYSTEM
          ,SITE_ORIG_SYSTEM_REFERENCE
          ,CREATED_BY_MODULE
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE
          ,COUNTRY
          ,PRIMARY_FLAG
          ,CREATED_BY
          ,sysdate as CREATION_DATE
    FROM XXCRM.XX_JTF_WWW_PROSPECT_ADDR;
    ln_addresses_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_addresses_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted ADDRESSSES data into the table' || 
      ' XXOD_HZ_IMP_ADDRESSES_INT...');


    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting ADDRESSUSES data into the table' ||
      ' XXOD_HZ_IMP_ADDRESSUSES_INT...');
    INSERT INTO XXOD_HZ_IMP_ADDRESSUSES_INT
      (BATCH_ID
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,CREATED_BY_MODULE
      ,SITE_ORIG_SYSTEM
      ,SITE_ORIG_SYSTEM_REFERENCE
      ,PRIMARY_FLAG
      ,SITE_USE_TYPE
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT BATCH_ID
          ,PARTY_ORIG_SYSTEM
          ,PARTY_ORIG_SYSTEM_REFERENCE
          ,CREATED_BY_MODULE
          ,SITE_ORIG_SYSTEM
          ,SITE_ORIG_SYSTEM_REFERENCE
          ,PRIMARY_FLAG
          ,SITE_USE_TYPE
          ,CREATED_BY
          ,sysdate as CREATION_DATE
    FROM XXCRM.XX_JTF_WWW_PROSPECT_ADDR;
    ln_addressuses_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_addressuses_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted ADDRESSSUSES data into the table' || 
      ' XXOD_HZ_IMP_ADDRESSUSES_INT...');


    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting CONTACTPTS data into the table' ||
      ' XXOD_HZ_IMP_CONTACTPTS_INT...');
    INSERT INTO XXOD_HZ_IMP_CONTACTPTS_INT
      (BATCH_ID 
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,SITE_ORIG_SYSTEM
      ,SITE_ORIG_SYSTEM_REFERENCE
      ,CP_ORIG_SYSTEM
      ,CP_ORIG_SYSTEM_REFERENCE
      ,CREATED_BY_MODULE
      ,RAW_PHONE_NUMBER
      ,PHONE_LINE_TYPE
      ,CONTACT_POINT_TYPE
      ,CREATED_BY
      ,CREATION_DATE)
   SELECT BATCH_ID
         ,PARTY_ORIG_SYSTEM
         ,PARTY_ORIG_SYSTEM_REFERENCE
         ,PARTY_ORIG_SYSTEM as SITE_ORIG_SYSTEM
         ,PARTY_ORIG_SYSTEM_REFERENCE as SITE_ORIG_SYSTEM_REFERENCE
         ,PARTY_ORIG_SYSTEM as CP_ORIG_SYSTEM
         ,substr(PARTY_ORIG_SYSTEM_REFERENCE,1,11) || 'PHONE' 
            as CP_ORIG_SYSTEM_REFERENCE
         ,CREATED_BY_MODULE
         ,PHONE AS RAW_PHONE_NUMBER
         ,'GEN' as PHONE_LINE_TYPE
         ,'PHONE' as CONTACT_POINT_TYPE
         ,CREATED_BY
         ,sysdate as CREATION_DATE
    FROM XXCRM.XX_JTF_WWW_PROSPECT_EXTR;
    ln_contactpts_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_contactpts_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted CONTACTPTS data into the table' || 
      ' XXOD_HZ_IMP_CONTACTPTS_INT...');

    COMMIT;

    FND_FILE.put_line(fnd_file.log,' ');
    FND_FILE.put_line(fnd_file.log,'Summary report:');
    FND_FILE.PUT_LINE(fnd_file.log,
      '  XXOD_HZ_IMP_PARTIES_INT insert cnt=====>' 
                      || ln_parties_int_cnt);
    FND_FILE.PUT_LINE(fnd_file.log,
      '  XXOD_HZ_IMP_EXT_ATTRIBS_INT insert cnt=>' 
                      || ln_ext_attribs_int_cnt);
    FND_FILE.PUT_LINE(fnd_file.log,
      '  XXOD_HZ_IMP_ADDRESSES_INT insert cnt===>' 
                      || ln_addresses_int_cnt);
    FND_FILE.PUT_LINE(fnd_file.log,
      '  XXOD_HZ_IMP_ADDRESSUSES_INT insert cnt=>' 
                      || ln_addressuses_int_cnt);
    FND_FILE.PUT_LINE(fnd_file.log,
      '  XXOD_HZ_IMP_CONTACTPTS_INT insert cnt==>' 
                      || ln_contactpts_int_cnt);
    FND_FILE.put_line(fnd_file.log,' ');
    FND_FILE.put_line(fnd_file.log,lc_package_name || ' has completed');

EXCEPTION
   WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0031_WWW_PROSPECT_ERR');
      
      lc_error_msg 
        := fnd_message.get || ' ORA ERR:' || SQLCODE || ':' || SQLERRM;
      
      lc_sqlerr_code := SQLCODE;
   
      lc_sqlerr_msg := SQLERRM;
      
      ROLLBACK;
      
      fnd_file.put_line(fnd_file.LOG,' ');      
      fnd_file.put_line(fnd_file.LOG,
        'An error occured. ' || lc_error_msg);      
      fnd_file.put_line(fnd_file.LOG,' ');
      
      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log
        ,oracle_error_code
        ,oracle_error_msg)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg
        ,lc_sqlerr_code
        ,lc_sqlerr_msg);
      
      COMMIT;
      
      x_retcode := 2;

END jtf_prospect_main;

END XX_JTF_WWW_PROSPECT_PKG;
/
Show errors
/
