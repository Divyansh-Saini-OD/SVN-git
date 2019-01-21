-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_VALIDATE_PKG.pkb                         |
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

create or replace package body XX_SFA_WWW_VALIDATE_PKG
AS 
PROCEDURE sfa_validate_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_end_date            IN         VARCHAR2
  )
IS
    ln_batch_id             NUMBER;
    ln_batch_descr          VARCHAR2(50);
    lc_error_msg            VARCHAR2(2000);
    lc_batch_error_msg      VARCHAR2(2000);
    lc_process_name         varchar2(32) := 'SFA WWW VALIDATE';
    lc_source_system        varchar2(10) := 'WWW';
    lc_package_name         varchar2(32) := 'XX_SFA_WWW_VALIDATE_PKG';
    lc_procedure_name       varchar2(32) := 'VALIDATE DATA';
    lc_staging_table_name   varchar2(32) := 'XX_SFA_WWW_PROSPECTIMAGE';
    lc_sqlerr_code          varchar2(100);
    lc_sqlerr_msg           varchar2(2000);
    lc_program_name         varchar2(32);
    ln_conc_request_id      NUMBER;

    lc_end_date             char(08);

    le_batch_id_error       EXCEPTION;
    le_invalid_end_date     EXCEPTION;
    le_submit_request_failed EXCEPTION;

    ln_prospectimage_cnt    number:=0;
    ln_newprospect_cnt      number:=0;
    ln_archive_cnt          number:=0;
    ln_exception_cnt        number:=0; 
    ln_delete_cnt           number:=0;
    ln_newprospect_net_cnt  number:=0;

    lc_validate_status      VARCHAR2(32);
    lc_STAGING_COLUMN_NAME  VARCHAR2(32);
    lc_staging_column_value VARCHAR2(32);

    V_internid              VARCHAR2(32);
    v_org_name              VARCHAR2(50);
    V_fname                 VARCHAR2(32);
    V_lname                 VARCHAR2(32);
    V_load_date             DATE;
    V_PHONE                 VARCHAR2(32);
    V_ADDR1                 VARCHAR2(32);
    V_CITY                  VARCHAR2(32);
    V_STATE                 VARCHAR2(32);
    V_COUNTRY               VARCHAR2(32);
    V_rev_band              VARCHAR2(32);

    Cursor c_API is
      SELECT INTERNID
            ,organization_name as org_name
            ,Fname
            ,lname
            ,load_date
            ,PHONE
            ,ADDR1
            ,CITY
            ,STATE
            ,REV_BAND
            ,COUNTRY  
        FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;

BEGIN    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                 ||lpad('DATE: ',60,' ')
                                 ||to_char(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,
      lpad('OD: SFA WWW validate input data',69,' '));
    XX_SFA_WWW_CONV_PKG.get_batch_id
      (  p_process_name      => lc_process_name
        ,p_group_id          => 'N/A'
        ,x_batch_descr       => ln_batch_descr
        ,x_batch_id          => ln_batch_id
        ,x_error_msg         => lc_batch_error_msg
      );

    fnd_file.put_line (fnd_file.log,
      'batch_id=' || ln_batch_id || ', batch_name=' || ln_batch_descr); 

    if lc_batch_error_msg is null then
        INSERT INTO XXCRM.XX_SFA_WWW_BATCH_ID
          (batch_id
          ,batch_descr
          ,create_date)
        Values 
          (ln_batch_id
          ,ln_batch_descr
          ,sysdate);
        COMMIT;
    else
        RAISE le_batch_id_error;
    end if;

    fnd_file.put_line (fnd_file.log, 
      'batch_id process completed-no errors');
    
 
    FND_FILE.put_line(fnd_file.log,
      'input end date=' || p_end_date);   
    If p_end_date is null then
        Lc_end_date := to_char(sysdate,'YYYYMMDD');
    else
        if  length(p_end_date) = 8
        and substr(p_end_date,1,4) between '2000' and '2010'
        and substr(p_end_date,5,2) between '01' and '12'
        and substr(p_end_date,7,2) between '01' and '31' then 
            Lc_end_date := p_end_date;
        Else
            RAISE le_invalid_end_date;
        End if;
    End if;
    FND_FILE.put_line(fnd_file.log,
      'end date successfully validated, value=' || lc_end_date);  
    
 
    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started deleting existing records from the table' ||  
      ' XXCRM.XX_SFA_WWW_PROSPECTIMAGE...');
    DELETE FROM XXCRM.XX_SFA_WWW_PROSPECTIMAGE;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully deleted all the records from table' || 
      ' XXCRM.XX_SFA_WWW_PROSPECTIMAGE...');
   

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting data into the table' ||
      ' XXCRM.XX_SFA_WWW_PROSPECTIMAGE...');
    INSERT INTO XXCRM.XX_SFA_WWW_PROSPECTIMAGE
       (INTERNID	
       ,ID	     
       ,NAME	     
       ,ADDR1	     
       ,CITY	     
       ,STATE	     
       ,ZIP     	
       ,PHONE	     
       ,NUM_WC_EMP_OD	
       ,DUNS_ID	
       ,SIC_CODE	
       ,SITE_TYPE	
       ,SOURCE	
       ,REV_BAND	
       ,FNAME	     
       ,LNAME
       ,CONTACT_TITLE)
    Select "_INTERNID"
          ,"_ID" 	     
          ,trim("_NAME")
          ,trim("_ADDR1")
          ,trim("_CITY")	     
          ,trim("_STATE")
          ,trim("_ZIP")
          ,trim("_PHONE")
          ,"_NUM_WC_EMP_OD"
          ,"_DUNS_ID"
          ,"_SIC_CODE"	
          ,trim("_SITE_TYPE")
          ,trim("_SOURCE")
          ,trim("_REV_BAND")
          ,trim("_FNAME")	    
          ,trim("_LNAME")
          ,trim("_CONTACT_TITLE")
    From prospect@avenue
    where "_ID" > '20070101'
      and "_ID" <= lc_end_date;
    ln_prospectimage_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Inserted Count: ' || ln_prospectimage_cnt);
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted data into table' || 
      ' XXCRM.XX_SFA_WWW_PROSPECTIMAGE' ||
      ' via transparent gateway...');
   

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started deleting existing records from the table' ||  
      ' XXCRM.XX_SFA_WWW_NEW_NEW_PROSPECTS...');
    DELETE FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully deleted all the records from the table' || 
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
   

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting data into the table' ||
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
    INSERT INTO XXCRM.XX_SFA_WWW_NEW_PROSPECTS   
       (INTERNID	
       ,LOAD_DATE     
       ,ORGANIZATION_NAME
       ,FNAME	     
       ,LNAME	
       ,CONTACT_TITLE    
       ,ADDR1	     
       ,CITY	     
       ,STATE	
       ,COUNTRY
       ,POSTAL_CODE
       ,PHONE
       ,REV_BAND
       ,NUM_WC_EMP_OD	
       ,VALIDATION_BATCH_ID)
    SELECT LPAD(A.INTERNId,10,0) AS INTERNID
          ,TO_DATE(A.ID,'YYYYMMDD') AS LOAD_DATE
          ,A.NAME AS ORGANIZATION_NAME
          ,A.FNAME	     
          ,A.LNAME  
          ,A.CONTACT_TITLE   
          ,A.ADDR1	    
          ,A.CITY	     
          ,A.STATE	     
          ,X.COUNTRY
          ,A.ZIP AS POSTAL_CODE
          ,A.PHONE
          ,A.REV_BAND 
          ,A.NUM_WC_EMP_OD
          ,ln_batch_id as VALIDATION_BATCH_ID
      FROM XXCRM.XX_SFA_WWW_PROSPECTIMAGE A
          ,XXCNV.XX_CDH_SOLAR_STATE_COUNTRY X
     WHERE A.STATE = X.STATE(+)
       AND INTERNID NOT IN (SELECT distinct INTERNID 
                            FROM XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE);
    ln_newprospect_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted data into table' || 
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
    
 
    -- validate data in new prospects 
    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started validation of data in table' ||  
      ' XXCRM.XX_SFA_WWW_NEW_NEW_PROSPECTS...'); 

    For i in c_api
    LOOP
        V_internid       := i.internid;
        v_org_name       := i.ORG_NAME;
        V_fname          := i.FNAME;
        V_lname          := i.LNAME;
        V_load_date      := i.LOAD_DATE;
        V_PHONE          := i.PHONE;
        V_ADDR1          := i.ADDR1;
        V_CITY           := i.CITY;
        V_STATE          := i.STATE;
        V_COUNTRY        := i.COUNTRY;
        V_rev_band       := i.REV_BAND;

        lc_STAGING_COLUMN_NAME := null;
        lc_staging_column_value := null;

        if v_LOAD_DATE IS NULL then 
            lc_validate_status := 'LOAD_DATE IS NULL';
            lc_STAGING_COLUMN_NAME := 'LOAD_DATE';
        elsif v_ORG_NAME IS NULL then
            lc_validate_status := 'ORGANIZATION NAME IS NULL';
            lc_STAGING_COLUMN_NAME := 'ORGANIZATION_NAME';
        elsif v_ADDR1 IS NULL then
            lc_validate_status := 'ADDR1 IS NULL';
            lc_STAGING_COLUMN_NAME := 'ADDR1';
        elsif v_CITY IS NULL then
            lc_validate_status := 'CITY IS NULL';
            lc_STAGING_COLUMN_NAME := 'CITY';
        elsif v_FNAME IS NULL AND v_LNAME IS NULL then
            lc_validate_status := 'FNAME AND LNAME IS NULL';
            lc_STAGING_COLUMN_NAME := 'FNAME / LNAME';
        elsif v_STATE IS NULL then
            lc_validate_status := 'STATE IS NULL';
            lc_STAGING_COLUMN_NAME := 'STATE';
        elsif v_country is null or v_country <> 'US' then 
            lc_validate_status := 'INVALID STATE CODE';
            lc_STAGING_COLUMN_NAME := 'STATE';
            lc_staging_column_value := v_STATE;
        elsif v_phone IS NULL then
            lc_validate_status := 'PHONE IS NULL';
            lc_STAGING_COLUMN_NAME := 'PHONE';
        elsif v_REV_BAND IS NULL then
            lc_validate_status := 'REV BAND IS NULL';
            lc_STAGING_COLUMN_NAME := 'REV_BAND';
        elsif v_REV_BAND NOT IN ('KEY1', 'KEY2', 'KEY3', 'KEY4', 
                                 'MAJOR1', 'MAJOR2', 'MAJOR3', 
                                 'STANDARD') then
            lc_validate_status := 'INVALID REV BAND';
            lc_STAGING_COLUMN_NAME := 'REV_BAND';
            lc_staging_column_value := v_REV_BAND;
        else
            lc_VALIDATE_STATUS := 'OK';
        end if;
        update XXCRM.XX_SFA_WWW_NEW_PROSPECTS
         set validate_status = lc_validate_status
            ,staging_column_name = lc_staging_column_name
            ,staging_column_value = lc_staging_column_value
         where internid = v_internid;
    END LOOP;

    fnd_file.put_line(fnd_file.LOG,
      ' Successfully validated data in table' ||  
      ' XXCRM.XX_SFA_WWW_NEW_NEW_PROSPECTS...');
    

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting data into the table' ||
      ' XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE...');
    INSERT INTO XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE
       (INTERNID	
       ,LOAD_DATE     
       ,ORGANIZATION_NAME
       ,FNAME	     
       ,LNAME	
       ,CONTACT_TITLE    
       ,ADDR1	     
       ,CITY	     
       ,STATE	     
       ,POSTAL_CODE
       ,COUNTRY
       ,PHONE
       ,REV_BAND
       ,NUM_WC_EMP_OD	
       ,VALIDATE_STATUS
       ,VALIDATION_BATCH_ID)
    select INTERNID	
          ,LOAD_DATE     
          ,ORGANIZATION_NAME
          ,FNAME	     
          ,LNAME	
          ,CONTACT_TITLE    
          ,ADDR1	     
          ,CITY	     
          ,STATE	     
          ,POSTAL_CODE
          ,COUNTRY
          ,PHONE
          ,REV_BAND
          ,NUM_WC_EMP_OD	
          ,VALIDATE_STATUS
          ,VALIDATION_BATCH_ID
    FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
    ln_archive_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted data into table' || 
      ' XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE...');
    

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started deleting existing records from the table' ||  
      ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
    DELETE FROM XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully deleted all rows from table' || 
      ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
     

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting data into the table' ||
      ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
    INSERT INTO XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS
       (BATCH_ID
       ,EXCEPTION_ID  
       ,LOG_DATE       
       ,PACKAGE_NAME         
       ,PROCEDURE_NAME              
       ,SOURCE_SYSTEM_REF
       ,STAGING_TABLE_NAME            
       ,STAGING_COLUMN_NAME           
       ,STAGING_COLUMN_VALUE
       ,SOURCE_SYSTEM_CODE            
       ,ORACLE_ERROR_MSG
       ,LOAD_DATE)
    SELECT ln_batch_id as batch_id
          ,XXCOMN.XX_EXCEPTION_ID_S1.NEXTVAL AS EXCEPTION_ID  
          ,TO_CHAR(SYSDATE,'DD-MON-YYYY') AS LOG_DATE       
          ,lc_package_name AS PACKAGE_NAME         
          ,lc_procedure_name AS PROCEDURE_NAME              
          ,INTERNID as SOURCE_SYSTEM_REF
          ,lc_staging_table_name AS STAGING_TABLE_NAME          
          ,STAGING_COLUMN_NAME           
          ,STAGING_COLUMN_VALUE
          ,lc_source_system AS SOURCE_SYSTEM_CODE            
          ,VALIDATE_STATUS as ORACLE_ERROR_MSG
          ,LOAD_DATE
      from XXCRM.XX_SFA_WWW_NEW_PROSPECTS
     where validate_status <> 'OK';
    ln_exception_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted data into table' || 
      ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
    

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started inserting data into the table' ||
      ' XX_COM_EXCEPTIONS_LOG_CONV...');
    INSERT INTO XX_COM_EXCEPTIONS_LOG_CONV
       (BATCH_ID
       ,EXCEPTION_ID  
       ,LOG_DATE       
       ,PACKAGE_NAME         
       ,PROCEDURE_NAME              
       ,SOURCE_SYSTEM_REF
       ,STAGING_TABLE_NAME            
       ,STAGING_COLUMN_NAME           
       ,STAGING_COLUMN_VALUE
       ,SOURCE_SYSTEM_CODE            
       ,ORACLE_ERROR_MSG)
    SELECT BATCH_ID
          ,EXCEPTION_ID  
          ,LOG_DATE       
          ,PACKAGE_NAME         
          ,PROCEDURE_NAME              
          ,SOURCE_SYSTEM_REF
          ,STAGING_TABLE_NAME            
          ,STAGING_COLUMN_NAME           
          ,STAGING_COLUMN_VALUE
          ,SOURCE_SYSTEM_CODE            
          ,ORACLE_ERROR_MSG
      FROM XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully inserted data into table' || 
      ' XX_COM_EXCEPTIONS_LOG_CONV...');
    

-- if no exceptions are found, a NO RECORDS FOUND row is inserted for reporting purposes
    If ln_exception_cnt = 0 then 
        fnd_file.put_line(fnd_file.LOG,' ');
        fnd_file.put_line(fnd_file.LOG,
          ' Started inserting data into the table' ||
          ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
        INSERT INTO XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS
          (BATCH_ID
          ,LOG_DATE       
          ,PACKAGE_NAME         
          ,PROCEDURE_NAME              
          ,SOURCE_SYSTEM_CODE            
          ,ORACLE_ERROR_MSG)
        SELECT ln_batch_id as batch_id
              ,TO_CHAR(SYSDATE,'DD-MON-YYYY') AS LOG_DATE       
              ,lc_package_name AS PACKAGE_NAME          
              ,lc_procedure_name AS PROCEDURE_NAME             
              ,lc_source_system AS SOURCE_SYSTEM_CODE            
              ,'NO ERRORS FOUND' as ORACLE_ERROR_MSG
          From DUAL;
        fnd_file.put_line(fnd_file.LOG,
          ' Successfully inserted data into the table' || 
          ' XXCRM.XX_SFA_WWW_VALIDATE_EXCEPTIONS...');
        fnd_file.put_line (fnd_file.log, 
          '"NO ERRORS FOUND" row inserted for reporting purposes');
    End if;

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started deleting exceptions from the table' ||
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
    DELETE FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS
    WHERE VALIDATE_STATUS <> 'OK';
    ln_delete_cnt := sql%rowcount;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully deleted exceptions from table' || 
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
    
    COMMIT;

    lc_program_name := 'XX_SFA_WWW_EXCEPTION_RPT';
    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' begin submit process for program ' || lc_program_name || ' ...');
    ln_conc_request_id := FND_REQUEST.submit_request 
       (application => 'XXCRM'
       ,program     => lc_program_name
       ,description => null 
       ,start_time  => NULL
       ,sub_request => FALSE
       );
    IF ln_conc_request_id = 0 THEN
        RAISE le_submit_request_failed;       
    ELSE
        fnd_file.put_line (fnd_file.log, ' ');
        fnd_file.put_line (fnd_file.log,
          'Submitted Child Request : '|| TO_CHAR(ln_conc_request_id ));
    END IF;

    FND_FILE.put_line(fnd_file.log,' ');
    FND_FILE.put_line(fnd_file.log,'Summary report:');
    FND_FILE.put_line(fnd_file.log,
      '  prospectimage rows========>' || ln_prospectimage_cnt);
    FND_FILE.put_line(fnd_file.log,
      '  new prospect rows loaded==>' || ln_newprospect_cnt);
    FND_FILE.put_line(fnd_file.log,
      '  rows archived=============>' || ln_archive_cnt);
    FND_FILE.put_line(fnd_file.log,
      '  exceptions================>' || ln_exception_cnt);
    FND_FILE.put_line(fnd_file.log,
      '  new prospect delete cnt===>' || ln_delete_cnt);
    Select count(*)
    Into ln_newprospect_net_cnt
    FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
    FND_FILE.put_line(fnd_file.log,
      '  actual new prospect rows==>' || ln_newprospect_net_cnt);

    fnd_file.put_line (fnd_file.log,' ');
    fnd_file.put_line (fnd_file.log,lc_package_name || ' ending');

EXCEPTION
    WHEN le_invalid_end_date THEN
      lc_error_msg := 'invalid format of end date';

      fnd_file.put_line (fnd_file.log,' ');  
      fnd_file.put_line(fnd_file.LOG,
        'An error occured. ' || lc_error_msg);
      fnd_file.put_line (fnd_file.log,' '); 

      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg);
      
      COMMIT;
  
      x_retcode := 2;

    WHEN le_submit_request_failed THEN
      x_errbuf  := fnd_message.get;
      lc_error_msg := 'Child Request for ' || lc_program_name || ' failed to submit, msg: ' || x_errbuf;

      fnd_file.put_line (fnd_file.log,' ');      
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
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_error_msg);
      
      COMMIT;
  
      x_retcode := 2;

    WHEN le_batch_id_error THEN
      fnd_file.put_line(fnd_file.LOG,' ');
      fnd_file.put_line(fnd_file.LOG,
        'Error while creating Batch ID. ' || lc_batch_error_msg);
      fnd_file.put_line(fnd_file.LOG,' ');
      
      INSERT INTO xx_com_exceptions_log_conv
        (exception_id
        ,log_date
        ,batch_id
        ,package_name
        ,procedure_name
        ,source_system_code
        ,exception_log)
      VALUES 
        (xxcomn.xx_exception_id_s1.nextval
        ,TO_CHAR(SYSDATE,'DD-MON-YYYY')
        ,ln_batch_id
        ,lc_package_name
        ,lc_procedure_name
        ,lc_source_system
        ,lc_batch_error_msg);
      
      COMMIT;
      
      x_retcode := 2;

    WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0030_WWW_VALIDATE_ERR');
      
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
END sfa_validate_main;

END XX_SFA_WWW_VALIDATE_PKG;
/
Show errors
