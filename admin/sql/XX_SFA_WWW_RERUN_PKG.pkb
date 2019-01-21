-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_SFA_WWW_RERUN_PKG.pkb                            |
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

create or replace package body XX_SFA_WWW_RERUN_PKG
AS 
PROCEDURE sfa_rerun_main 
   (x_errbuf              OUT NOCOPY VARCHAR2
   ,x_retcode             OUT NOCOPY NUMBER
   ,p_batch_id            IN         VARCHAR2
  )
IS
    ln_batch_id             NUMBER;
    ln_batch_cnt            NUMBER;
    lc_package_name         varchar2(32) := 'XX_SFA_WWW_RERUN_PKG';
    lc_procedure_name       varchar2(32) := 'WWW RERUN';
    lc_sqlerr_code          varchar2(100);
    lc_sqlerr_msg           varchar2(2000);
    lc_source_system        varchar2(10) := 'WWW';
    lc_error_msg            varchar2(2000);
 
    ln_newprospect_cnt      number:=0;
    le_empty_batch          EXCEPTION;
    
BEGIN    
    fnd_file.put_line(fnd_file.LOG,' ');
    
    fnd_file.put_line(fnd_file.LOG,rpad('Office Depot',40,' ')
                                 ||lpad('DATE: ',60,' ')
                                 ||to_date(SYSDATE,'DD-MON-YYYY HH:MI'));
    
    fnd_file.put_line(fnd_file.LOG,
      lpad('OD: SFA WWW rerun batch',69,' '));
    
    fnd_file.put_line(fnd_file.LOG,' ');
    ln_batch_id := p_batch_id;
    FND_FILE.put_line(fnd_file.log,'batch_id=' || ln_batch_id);   

    select count(*) 
    into ln_batch_cnt
    from XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE
    WHERE validation_batch_id = ln_batch_id
      And VALIDATE_STATUS = 'OK';
    fnd_file.put_line (fnd_file.log, 
      to_char(ln_batch_cnt,'999999') || 
      ' rows found for batch id ' || ln_batch_id);
    If ln_batch_cnt = 0 then 
        RAISE le_empty_batch;
    end if;

    fnd_file.put_line(fnd_file.LOG,' ');
    fnd_file.put_line(fnd_file.LOG,
      ' Started deleting existing records from the table' ||  
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');
    DELETE FROM XXCRM.XX_SFA_WWW_NEW_PROSPECTS;
    fnd_file.put_line(fnd_file.LOG,
      ' Successfully deleted all the records from the table' || 
      ' XXCRM.XX_SFA_WWW_NEW_PROSPECTS...');

    fnd_file.put_line (fnd_file.log, 
      'end step 1 – delete data from new prospects table');

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
       ,POSTAL_CODE
       ,COUNTRY
       ,PHONE
       ,REV_BAND
       ,NUM_WC_EMP_OD	
       ,VALIDATE_STATUS
       ,VALIDATION_BATCH_ID)
    SELECT INTERNID	
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
    FROM XXCRM.XX_SFA_WWW_PROSPECT_ARCHIVE
    WHERE validation_batch_id = ln_batch_id
      And VALIDATE_STATUS = 'OK';

    ln_newprospect_cnt := sql%rowcount;
    fnd_file.put_line (fnd_file.log, 
      'end step 2 – retrieve new prospects from atrchive');

    COMMIT;
    FND_FILE.put_line(fnd_file.log,' ');
    FND_FILE.put_line(fnd_file.log,'Summary report:');
    FND_FILE.put_line(fnd_file.log,
      '  new prospect rows loaded==>' || ln_newprospect_cnt);
    fnd_file.put_line (fnd_file.log,' ');
    fnd_file.put_line (fnd_file.log,lc_package_name || ' ending');

EXCEPTION
    WHEN le_empty_batch THEN
      lc_error_msg := 'invalid format of end date';

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

    WHEN OTHERS THEN
      fnd_message.set_name('XXCRM','XX_CDH_0034_WWW_RERUN_ERR');
      
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

END sfa_rerun_main;

END XX_SFA_WWW_RERUN_PKG;
/
Show errors
/


