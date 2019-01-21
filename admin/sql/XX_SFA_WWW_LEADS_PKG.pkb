-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_LEADS_PKG.pkb                            |
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

create or replace package body XX_SFA_WWW_LEADS_PKG
AS 
PROCEDURE sfa_leads_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN         NUMBER
   )
IS
   ln_batch_id            NUMBER;
   ln_created_by          number;
   lc_source_system       char(3):='WWW';
   lc_orig_system_code    char(2):='SX';
   lv_PARTIES_OSR         varchar2(50);
   lv_PARTY_SITES_OSR     varchar2(50);
   lv_CONTACT_OSR         varchar2(50);
   lv_CNT_PTS_OSR         varchar2(50);
   ln_read_cnt             number:=0;
   ln_extr_cnt             number:=0;
   ln_import_interface_cnt number:=0;
   ln_lead_imp_osr_stg_cnt number:=0;
   ln_Imp_int_seq         number;

   lc_package_name         varchar2(32) := 'XX_SFA_WWW_LEADS_PKG';
   lc_procedure_name       varchar2(32) := 'LOAD LEADS';
   lc_sqlerr_code          varchar2(100);
   lc_sqlerr_msg           varchar2(2000);
   lc_error_msg            varchar2(2000);

   V_internid             varchar2(10);
   V_ORGANIZATION_NAME    varchar2(100);
   V_ADDR1                varchar2(50);
   V_CITY                 varchar2(50);
   V_STATE                varchar2(10);
   V_postal_code          varchar2(12);
   V_country              char(2);
   V_fname                varchar2(32);
   V_lname                varchar2(32);
   V_PHONE                varchar2(24);
   V_NUM_WC_EMP_OD        number;
   V_LOAD_DATE            date;

   Cursor c_API is
     SELECT LPAD(INTERNID,10,'0') AS INTERNID
           ,ORGANIZATION_NAME
           ,ADDR1
           ,CITY
           ,STATE
           ,POSTAL_CODE
           ,COUNTRY
           ,FNAME
           ,LNAME
           ,PHONE
           ,NUM_WC_EMP_OD
           ,LOAD_DATE
     FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
--   FROM XXCRM.XX_SFA_WWW_TEST_PROSPECTS;

BEGIN    
   fnd_file.put_line(fnd_file.LOG,' ');
    
   fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                 ||lpad('DATE: ',60,' ')
                                 ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
   fnd_file.put_line(fnd_file.LOG,
     lpad('OD: SFA WWW load LEADS to CV tables',69,' '));
    
   fnd_file.put_line(fnd_file.LOG,' ');
   Ln_batch_id := p_batch_id;
   FND_FILE.put_line(fnd_file.log,'batch_id=' || ln_batch_id);   

   SELECT FND_GLOBAL.USER_ID 
   Into ln_created_by
   FROM DUAL;

   fnd_file.put_line(fnd_file.LOG,' ');
   fnd_file.put_line(fnd_file.LOG,
     ' Started deleting existing records from the table' ||  
     ' XXCRM.XX_SFA_WWW_LEAD_EXTR...');

   DELETE FROM XXCRM.XX_SFA_WWW_LEAD_EXTR;

   fnd_file.put_line(fnd_file.LOG,
     ' Successfully deleted all the records from the table' || 
     ' XXCRM.XX_SFA_WWW_LEAD_EXTR...');

   For i in c_api
     LOOP
       ln_read_cnt := ln_read_cnt + 1;
       V_internid          := i.internid;
       V_ORGANIZATION_NAME := i.ORGANIZATION_NAME;
       V_ADDR1             := i.ADDR1;
       V_CITY              := i.CITY;
       V_STATE             := i.STATE;
       V_postal_code       := i.POSTAL_CODE;
       V_country           := i.COUNTRY;
       V_fname             := i.FNAME;
       V_lname             := i.LNAME;
       V_PHONE             := i.PHONE;
       V_num_wc_emp_od     := i.NUM_WC_EMP_OD;
       V_load_date         := i.LOAD_DATE;
       
       lv_parties_osr     := v_INTERNID || '-00001-SX';
       lv_party_sites_osr := v_INTERNID || '-00001-SX';
       lv_contact_osr     := v_INTERNID || '-WWW';
       lv_cnt_pts_osr     := v_INTERNID || '-WWW-GEN';

       SELECT AS_IMPORT_INTERFACE_S.NEXTVAL  
       Into ln_Imp_int_seq
       FROM DUAL;
        
       INSERT INTO XXCRM.XX_SFA_WWW_LEAD_EXTR
         (BATCH_ID
         ,PARTIES_OSR
         ,PARTY_SITES_OSR
         ,CONTACT_OSR
         ,CNT_PTS_OSR
         ,COMPANY_NAME
         ,ADDRESS1
         ,CITY
         ,STATE
         ,POSTAL_CODE
         ,COUNTRY
         ,FIRST_NAME 
         ,LAST_NAME
         ,PHONE_NUMBER
         ,CREATED_BY
         ,NUM_OF_EMPLOYEES
         ,LOAD_DATE
         ,IMPORT_INTERFACE_ID
         ,orig_system_code)
       values 
         (ln_batch_id 
         ,lv_parties_osr
         ,lv_party_sites_osr 
         ,lv_contact_osr 
         ,lv_cnt_pts_osr 
         ,v_ORGANIZATION_NAME 
         ,v_ADDR1 
         ,v_CITY 
         ,v_STATE 
         ,v_POSTAL_CODE 
         ,v_COUNTRY 
         ,v_FNAME
         ,v_LNAME 
         ,v_PHONE 
         ,ln_created_by 
         ,v_NUM_WC_EMP_OD 
         ,v_LOAD_DATE 
         ,ln_Imp_int_seq
         ,lc_orig_system_code);
    END LOOP;
    
    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' total number of contacts in this run: ' || ln_read_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' total number of leads loaded into stg table' ||
      ' XX_SFA_WWW_LEAD_EXTR: ' || ln_extr_cnt);

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting LEADS into the table' ||
      ' AS_IMPORT_INTERFACE...');
    INSERT INTO AS_IMPORT_INTERFACE
      (BATCH_ID
      ,IMPORT_INTERFACE_ID
      ,ORIG_SYSTEM_CODE
      ,ORIG_SYSTEM_REFERENCE
      ,SOURCE_SYSTEM
      ,ADDRESS1
      ,CITY
      ,STATE
      ,POSTAL_CODE
      ,COUNTRY
      ,CREATION_DATE
      ,FIRST_NAME
      ,LAST_NAME
      ,PHONE_NUMBER
      ,LAST_UPDATE_DATE
      ,LOAD_STATUS
      ,STATUS_CODE
      ,CREATED_BY
      ,LAST_UPDATED_BY
      ,LOAD_DATE
      ,NUM_OF_EMPLOYEES
      ,PHONE_TYPE
      ,DESCRIPTION)
    SELECT BATCH_ID
          ,IMPORT_INTERFACE_ID
          ,ORIG_SYSTEM_CODE
          ,PARTIES_OSR as ORIG_SYSTEM_REFERENCE
          ,lc_source_system as SOURCE_SYSTEM
          ,ADDRESS1
          ,CITY
          ,STATE
          ,POSTAL_CODE
          ,COUNTRY
          ,SYSDATE AS CREATION_DATE
          ,FIRST_NAME
          ,LAST_NAME
          ,PHONE_NUMBER
          ,sysdate AS LAST_UPDATE_DATE 
          ,'STAGED' as LOAD_STATUS
          ,'NEW' as STATUS_CODE
          ,CREATED_BY
          ,CREATED_BY AS LAST_UPDATED_BY 
          ,sysdate as LOAD_DATE 
          ,NUM_OF_EMPLOYEES
          ,'GEN' as PHONE_TYPE  
          ,FIRST_NAME || ' ' || LAST_NAME || ' – WWW' AS DESCRIPTION
    FROM XXCRM.XX_SFA_WWW_LEAD_EXTR;
    ln_import_interface_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_import_interface_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted LEADS into the table' || 
      ' AS_IMPORT_INTERFACE...');

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting LEADS into the table' ||
      ' XX_AS_LEAD_IMP_OSR_STG...');
    INSERT INTO XX_AS_LEAD_IMP_OSR_STG
      (IMPORT_INTERFACE_ID
      ,PARTY_ORIG_SYSTEM
      ,PARTY_ORIG_SYSTEM_REFERENCE
      ,PTY_SITE_ORIG_SYSTEM
      ,PTY_SITE_ORIG_SYSTEM_REFERENCE
      ,CONTACT_ORIG_SYSTEM 
      ,CONTACT_ORIG_SYSTEM_REFERENCE
      ,CNT_PNT_ORIG_SYSTEM  
      ,CNT_PNT_ORIG_SYSTEM_REFERENCE
      ,CREATED_BY
      ,CREATION_DATE)
    SELECT IMPORT_INTERFACE_ID
          ,ORIG_SYSTEM_CODE as PARTY_ORIG_SYSTEM
          ,PARTIES_OSR as PARTY_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM_CODE as PTY_SITE_ORIG_SYSTEM
          ,PARTY_SITES_OSR as PTY_SITE_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM_CODE as CONTACT_ORIG_SYSTEM
          ,CONTACT_OSR as CONTACT_ORIG_SYSTEM_REFERENCE
          ,ORIG_SYSTEM_CODE as CNT_PNT_ORIG_SYSTEM  
          ,CNT_PTS_OSR as CNT_PNT_ORIG_SYSTEM_REFERENCE
          ,CREATED_BY
          ,SYSDATE as CREATION_DATE
    FROM XXCRM.XX_SFA_WWW_LEAD_EXTR;
    ln_lead_imp_osr_stg_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_lead_imp_osr_stg_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted LEADS into the table' || 
      ' XX_AS_LEAD_IMP_OSR_STG...');

    COMMIT;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
    FND_FILE.put_line(fnd_file.log,'Summary report:');
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      '                   read cnt==>' || ln_read_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      'import_interface insert cnt==>' || ln_import_interface_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,
      'lead_imp_osr_stg insert cnt==>' || ln_lead_imp_osr_stg_cnt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
    FND_FILE.put_line(fnd_file.log,lc_package_name || ' has completed');

EXCEPTION
   WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0033_WWW_LEAD_ERR');
      
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
END sfa_leads_main;

END XX_SFA_WWW_LEADS_PKG;
/
Show errors
