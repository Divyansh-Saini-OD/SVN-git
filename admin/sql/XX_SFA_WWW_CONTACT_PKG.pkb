-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_CONTACT_PKG.pkb                          |
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

create or replace package body XX_SFA_WWW_CONTACT_PKG
AS 
PROCEDURE sfa_contact_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN         NUMBER
   )
IS
   ln_batch_id             NUMBER;
   lv_CREATED_BY_MODULE    char(3):='WWW';
   ln_CREATED_BY           number;
   lv_ORIG_SYSTEM          char(2):='SX';
   ln_read_cnt             NUMBER:=0;
   ln_extr_cnt             NUMBER:=0;

   ln_parties_int_cnt      number:=0;
   ln_addresses_int_cnt    number:=0;
   ln_contacts_int_cnt     number:=0;
   ln_contactpts_int_cnt   number:=0;

   lc_package_name         varchar2(32) := 'XX_SFA_WWW_CONTACT_PKG';
   lc_procedure_name       varchar2(32) := 'LOAD CONTACTS';
   lc_sqlerr_code          varchar2(100);
   lc_sqlerr_msg           varchar2(2000);
   lc_source_system        varchar2(10) := 'WWW';
   lc_error_msg            varchar2(2000);

   lv_PARENT_OSR           varchar2(50);
   lv_contact_OSR          varchar2(50);

    V_internid             varchar2(32);
    V_fname                varchar2(50);
    V_lname                varchar2(50);
    V_contact_title        varchar2(50);
    V_load_date            date;
    V_PHONE                varchar2(24);
    V_ADDR1                varchar2(50);
    V_CITY                 varchar2(50);
    V_STATE                varchar2(10);
    V_postal_code          varchar2(12);
    V_country              char(2);

    Cursor c_API is
      SELECT lpad(INTERNID,10,'0') AS internid
            ,Fname
            ,lname
            ,contact_title
            ,load_date
            ,PHONE
            ,ADDR1
            ,CITY
            ,STATE
            ,postal_code
            ,country
      FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
--    FROM XXCRM.XX_SFA_WWW_TEST_PROSPECTS;

BEGIN    
  fnd_file.put_line(fnd_file.LOG,' ');
    
  fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                 ||lpad('DATE: ',60,' ')
                                 ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
  fnd_file.put_line(fnd_file.LOG,
    lpad('OD: SFA WWW load CONTACTS to CV tables',69,' '));
    
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
    ' XXCRM.XX_SFA_WWW_CONTACT_EXTR...');
    
  DELETE FROM XXCRM.XX_SFA_WWW_CONTACT_EXTR;
    
  fnd_file.put_line(fnd_file.LOG,
    ' Successfully deleted all the records from the table' || 
    ' XXCRM.XX_SFA_WWW_CONTACT_EXTR...');

  For i in c_api
    LOOP
        ln_read_cnt := ln_read_cnt + 1;

        V_internid          := i.internid;
        V_fname             := i.FNAME;
        V_lname             := i.LNAME;
        V_contact_title     := i.CONTACT_TITLE;
        V_load_date         := i.LOAD_DATE;
        V_PHONE             := i.PHONE;
        V_ADDR1             := i.ADDR1;
        V_CITY              := i.CITY;
        V_STATE             := i.STATE;
        V_postal_code       := i.POSTAL_CODE;
        V_country           := i.COUNTRY;

        Lv_parent_osr  := v_INTERNID || '-00001-SX';
        Lv_contact_osr := v_INTERNID || '-WWW';

        INSERT INTO XXCRM.XX_SFA_WWW_CONTACT_EXTR 
          (BATCH_ID
          ,PARENT_OSR
          ,CONTACT_OSR
          ,ORIG_SYSTEM
          ,CREATED_BY_MODULE
          ,PERSON_FIRST_NAME
          ,PERSON_LAST_NAME
          ,PERSON_TITLE
          ,START_DATE
          ,PHONE
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE 
          ,COUNTRY   
          ,CREATED_BY)
        Values
          (ln_batch_id 
          ,lv_parent_osr 
          ,lv_contact_osr 
          ,lv_orig_system
          ,lv_created_by_module 
          ,v_FNAME 
          ,v_LNAME 
          ,v_contact_title 
          ,v_load_DATE 
          ,v_phone 
          ,v_ADDR1 
          ,v_city 
          ,v_state 
          ,v_postal_code 
          ,v_COUNTRY 
          ,ln_created_by);
        ln_extr_cnt := ln_extr_cnt + 1;
    END LOOP;
    COMMIT;

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' total number of contacts in this run: ' || ln_read_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' total number of contacts loaded into stg table' ||
      ' XX_SFA_WWW_CONTACT_EXTR: ' || ln_extr_cnt);

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
      ,PERSON_FIRST_NAME
      ,PERSON_LAST_NAME
      ,PERSON_TITLE
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT BATCH_ID
          ,lv_orig_system as PARTY_ORIG_SYSTEM
          ,CONTACT_OSR as PARTY_ORIG_SYSTEM_REFERENCE
          ,'PERSON' AS PARTY_TYPE
          ,CREATED_BY_MODULE
          ,PERSON_FIRST_NAME
          ,PERSON_LAST_NAME
          ,PERSON_TITLE
          ,CREATED_BY
          ,SYSDATE as CREATION_DATE
    FROM XXCRM.XX_SFA_WWW_CONTACT_EXTR;
    ln_parties_int_cnt := sql%rowcount;
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
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,SITE_ORIG_SYSTEM
      ,SITE_ORIG_SYSTEM_REFERENCE
      ,CREATED_BY_MODULE
      ,DESCRIPTION
      ,ADDRESS1
      ,CITY
      ,STATE
      ,POSTAL_CODE
      ,COUNTRY
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT BATCH_ID
          ,ORIG_SYSTEM AS PARTY_ORIG_SYSTEM
          ,CONTACT_OSR AS PARTY_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM AS SITE_ORIG_SYSTEM
          ,CONTACT_OSR AS SITE_ORIG_SYSTEM_REFERENCE
          ,CREATED_BY_MODULE
          ,'CONTACT' AS DESCRIPTION
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE
          ,COUNTRY
          ,CREATED_BY
          ,SYSDATE as CREATION_DATE
    FROM XXCRM.XX_SFA_WWW_CONTACT_EXTR;
    ln_addresses_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_addresses_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted ADDRESSSES data into the table' || 
      ' XXOD_HZ_IMP_ADDRESSES_INT...');


    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting CONTACTS data into the table' ||
      ' XXOD_HZ_IMP_CONTACTS_INT...');
    INSERT INTO XXOD_HZ_IMP_CONTACTS_INT
      (BATCH_ID
      ,CONTACT_ORIG_SYSTEM
      ,CONTACT_ORIG_SYSTEM_REFERENCE
      ,SUB_ORIG_SYSTEM
      ,SUB_ORIG_SYSTEM_REFERENCE
      ,OBJ_ORIG_SYSTEM
      ,OBJ_ORIG_SYSTEM_REFERENCE
      ,RELATIONSHIP_TYPE
      ,RELATIONSHIP_CODE
      ,START_DATE
      ,CREATED_BY_MODULE
      ,CREATED_BY
      ,CREATION_DATE)  
    SELECT BATCH_ID
          ,ORIG_SYSTEM AS CONTACT_ORIG_SYSTEM
          ,CONTACT_OSR AS CONTACT_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM AS SUB_ORIG_SYSTEM
          ,CONTACT_OSR AS SUB_ORIG_SYSTEM_REFERERNCE
          ,ORIG_SYSTEM  AS OBJ_ORIG_SYSTEM
          ,PARENT_OSR AS OBJ_ORIG_SYSTEM_REFERENCE
          ,'CONTACT' as RELATIONSHIP_TYPE
          ,'CONTACT_OF' AS RELATIONSHIP_CODE
          ,START_DATE
          ,CREATED_BY_MODULE
          ,CREATED_BY
          ,SYSDATE as CREATION_DATE
    FROM XXCRM.XX_SFA_WWW_CONTACT_EXTR;
    ln_contacts_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_contacts_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted CONTACTS data into the table' || 
      ' XXOD_HZ_IMP_CONTACTS_INT...');

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting CONTACTPTS data into the table' ||
      ' XXOD_HZ_IMP_CONTACTPTS_INT...');
    INSERT INTO XXOD_HZ_IMP_CONTACTPTS_INT 
      (BATCH_ID
      ,CREATED_BY_MODULE
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,CP_ORIG_SYSTEM
      ,CP_ORIG_SYSTEM_REFERENCE  
      ,CONTACT_POINT_TYPE
      ,RAW_PHONE_NUMBER
      ,PHONE_LINE_TYPE
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT BATCH_ID
          ,CREATED_BY_MODULE
          ,ORIG_SYSTEM AS PARTY_ORIG_SYSTEM
          ,CONTACT_OSR AS PARTY_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM AS CP_ORIG_SYSTEM
          ,CONTACT_OSR || '-GEN' AS CP_ORIG_SYSTEM_REFERENCE
          ,'PHONE' as CONTACT_POINT_TYPE
          ,PHONE as RAW_PHONE_NUMBER
          ,'GEN' as PHONE_LINE_TYPE
          ,CREATED_BY
          ,SYSDATE as CREATION_DATE
    FROM XXCRM.XX_SFA_WWW_CONTACT_EXTR;
    ln_contactpts_int_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_contactpts_int_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted CONTACTPTS data into the table' || 
      ' XXOD_HZ_IMP_CONTACTPTS_INT...');

    COMMIT;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
    FND_FILE.put_line(fnd_file.log,'Summary report:');
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '                               read cnt==>' || ln_read_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '  XXOD_HZ_IMP_PARTIES_INT insert cnt=====>' || ln_parties_int_cnt); 
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '  XXOD_HZ_IMP_ADDRESSES_INT insert cnt===>' || ln_addresses_int_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '  XXOD_HZ_IMP_CONTACTS_INT insert cnt====>' || ln_contacts_int_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '  XXOD_HZ_IMP_CONTACTPTS_INT insert cnt==>' || ln_contactpts_int_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
    FND_FILE.put_line(fnd_file.log,lc_package_name || ' has completed');

EXCEPTION
   WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0032_WWW_CONTACT_ERR');
      
      lc_error_msg := fnd_message.get || ' ORA ERR:' || SQLCODE || ':' || SQLERRM;
      
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

END sfa_contact_main;

END XX_SFA_WWW_CONTACT_PKG;
/
Show errors
/
