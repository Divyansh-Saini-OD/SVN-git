create or replace
PACKAGE body XX_MASTER_CARD_TRAN_VALID_PKG
AS
  -- +=============================================================================================+
  -- |                       Office Depot - iExpenses                                              |
  -- |                          Oracle Consulting                                                  |
  -- +=============================================================================================+
  -- | Name         : XX_MASTER_CARD_TRAN_VALID_PKG.pkb                                            |
  -- | Description  : This package is used for the execution of Java Concurrent Program            |
  -- |                for Master Card Transactions                                                 |
  -- |Type        Name                       Description                                           |
  -- |=========   ===========                ======================================================|
  -- |Procedure   CALL_MAIN                  This procedure will run 4 CP and delete decrypted file|
  -- |                                       1. File Copy Program                                  |                
  -- |                                       2. Decryption Program                                 |
  -- |                                       3. Java Import program                                |
  -- |                                       4. Email Program                                      |
  -- |                                       5. Delete the decrypted file in any case              |
  -- |                                                                                             |
  -- |Change Record:                                                                               |
  -- |===============                                                                              |
  -- |Version   Date         Author               Remarks                                          |
  -- |=======   ===========  ===============      =================================================|
  -- |DRAFT 1A  20-JAN-2012  Deepti S             Initial draft version                            |
  -- |1.1       21-FEB-2012  Deepti S             Added Decrypt file logic                         |
  -- |1.2       28-MAR-2012  Jay Gupta            Changes for UTL File Path                        |
  -- |1.3       13-Dec-2013  Jay GUpta            Defect# 27132, Replace Import program to custom  |
  -- |                                            import Program                                   |
  -- |1.4       06-JUL-2016  Madhan Sanjeevi      Modified for Defect# 36410(SOA call wait comment)|
  -- +=============================================================================================+
  PROCEDURE MAIN(errbuff     OUT      VARCHAR2,
                 retcode     OUT      VARCHAR2,
                 p_data_file IN VARCHAR2)
  IS  
  
      ln_CARD_PROGRAM_ID AP_CARD_PROGRAMS.CARD_PROGRAM_ID%type;      
      lc_valid_flag CHAR(1) := 'Y';
      lc_log_message VARCHAR2(2000);      
      
      ln_req_id     NUMBER := 0;
      lc_phase      VARCHAR2 (100) := NULL;
      lc_status     VARCHAR2 (100) := NULL;
      lc_dev_phase  VARCHAR2 (100) := NULL;
      lc_dev_status VARCHAR2 (100) := NULL;
      lc_message    VARCHAR2 (100) := NULL;
      lb_req_status BOOLEAN;
      lc_key        VARCHAR2(100);
      lc_email_body VARCHAR2(240);
      lc_email_subject VARCHAR2(240);
      -- V1.2
      lc_utl_dir_path VARCHAR2(200);
      lc_source_path_file VARCHAR2(200);
      lc_data_file_name VARCHAR2(100);
      lc_dest_path_file VARCHAR2(200); 
      lc_archive_path VARCHAR2(200); 
	  lc_file_name    VARCHAR2(200); --- v1.3

      ln_email_req_id NUMBER:=0;
      lc_email VARCHAR2(200);
      lc_sender_email VARCHAR2(50):= 'noreply@officedepot.com';

  BEGIN
     
     BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetch Email Address');     
        SELECT XFTV.target_value1 
          INTO lc_email
          FROM xx_fin_translatedefinition XFTD ,
               xx_fin_translatevalues XFTV
         WHERE XFTV.translate_id = XFTD.translate_id
           AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
           AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
           AND XFTV.source_value1    = 'INBOUND_EMAIL_IDS'
           AND XFTD.translation_name = 'OD_PGP_KEYS'
           AND XFTV.enabled_flag     = 'Y'
           AND XFTD.enabled_flag     = 'Y'
           AND XFTV.target_value2 = 'Y';
     EXCEPTION
        WHEN OTHERS THEN
           lc_log_message := 'Failed - While fetching Email Address';
           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);
           lc_valid_flag := 'N';
     END;     

     if lc_valid_flag = 'Y' then
     
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetch Master Card Program ID');
     
        BEGIN
           select CARD_PROGRAM_ID 
             into ln_CARD_PROGRAM_ID
             from AP_CARD_PROGRAMS
            WHERE CARD_EXP_TYPE_MAP_TYPE_CODE='MASTERCARD';
        EXCEPTION
           WHEN OTHERS THEN
              lc_log_message := 'Failed - While fetching Master Card Program ID';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);
              lc_valid_flag := 'N';
        END;    
     end if;

     if lc_valid_flag = 'Y' then
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetch Decryption Key');
        BEGIN
           SELECT XFTV.target_value1 
             INTO lc_key
             FROM xx_fin_translatedefinition XFTD ,
                  xx_fin_translatevalues XFTV
            WHERE XFTV.translate_id = XFTD.translate_id
              AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
              AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
              AND XFTV.source_value1    = 'I2168_IEXPENSES'
              AND XFTD.translation_name = 'OD_PGP_KEYS'
              AND XFTV.enabled_flag     = 'Y'
              AND XFTD.enabled_flag     = 'Y'
              AND XFTV.target_value2 = 'Y';
        EXCEPTION
           WHEN OTHERS THEN
              lc_log_message := 'Failed - While fetching Decryption Key';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);
              lc_valid_flag := 'N';
        END;
     end if;
     
     
     if lc_valid_flag = 'Y' then
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Fetch UTL Directory Path');
     
        BEGIN
           SELECT directory_path
             INTO lc_utl_dir_path
             FROM ALL_DIRECTORIES
            WHERE DIRECTORY_NAME = 'XXFIN_INBOUND_SECURE';
        EXCEPTION
           WHEN OTHERS THEN
              lc_log_message := 'Failed - While Fetching UTL Directory Path';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
              lc_valid_flag := 'N';        
        END;
     end if;

     if lc_valid_flag = 'Y' then 
        BEGIN
           lc_data_file_name := SUBSTR(p_data_file,INSTR(p_data_file,'/',-1)+1);
           lc_source_path_file := lc_utl_dir_path||'/'||lc_data_file_name;        
           lc_dest_path_file := lc_utl_dir_path||'/'||lc_data_file_name||'.dec';
           lc_archive_path := replace(LOWER(SUBSTR(lc_utl_dir_path,1,INSTR(lc_utl_dir_path,'/',-2)))
                             ,'inbound','archive/inbound');
		   
        
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Data File Path and Name = '||p_data_file);      
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Decryption Key = '||lc_key);     
           FND_FILE.PUT_LINE(FND_FILE.LOG,'UTL Path = '||lc_utl_dir_path);         
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Data File Name = '||lc_data_file_name);      
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Source Path and File for Decryption = '||lc_source_path_file);     
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Destination Path and File for Decryption = '||lc_dest_path_file);       
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Data File Archive Path = '||lc_archive_path);               
 
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit Common File Copy Program');        
           --submit Common File Copy and archive program
           ln_req_id := fnd_request.submit_request (application => 'XXFIN',
                                                 program => 'XXCOMFILCOPY',
                                                 argument1 => p_data_file, 
                                                 argument2 => lc_source_path_file,
                                                 argument3 => NULL,
                                                 argument4 => NULL,
                                                 argument5 => 'Y',
                                                 argument6 => lc_archive_path
                                          );        
           COMMIT;
      
           if ln_req_id = 0 then
              lc_log_message := 'Failed - While submitting Common File Copy Program';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
              lc_valid_flag := 'N';
           else
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Wait for File Copy Program to complete'); 
              lb_req_status := fnd_concurrent.wait_for_request (ln_req_id, 10, null, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
           
              if lc_status != 'Normal' then
                 lc_log_message := 'Failed - File Copy Program completed with error - '||lc_message;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
                 lc_valid_flag := 'N';
              else
                 lc_log_message := 'Success - File Copy Program completed successfully';
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);
              end if;
           end if;
        exception
           when others then 
              lc_log_message := 'File Copy Program - ' || SQLERRM;
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
              lc_valid_flag := 'N';
        END;
     end if;
     
          
     if lc_valid_flag = 'Y' then 
        BEGIN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit Decrypt program');        
           ln_req_id := fnd_request.submit_request (application => 'XXFIN', 
                                          program => 'XXCOMDEPTFILE',
                                          argument1 => lc_source_path_file,
                                          argument2 => lc_key,
                                          argument3 => 'Y'
                                          );
           COMMIT;

           if ln_req_id = 0 then
              lc_log_message := 'Failed - While submitting Decrypt Program';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
           else
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for Decrypt Program to complete'); 
              lb_req_status := fnd_concurrent.wait_for_request (ln_req_id, 10, null, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
           
              if lc_status != 'Normal' then
                 lc_log_message := 'Failed - Decrypt Program completed with error - '||lc_message;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
                 lc_valid_flag := 'N';
              else
                 lc_log_message := 'Success - Decrypt Program completed successfully';
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);               
              end if;
           end if;
        exception
           when others then
              lc_log_message := 'Decrypt Program - ' || SQLERRM;
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
              lc_valid_flag := 'N';                 
        end;
     end if;
     
     
     if lc_valid_flag = 'Y' then 
        begin
        
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit Import program');
           /* V1.3,   
           ln_req_id := fnd_request.submit_request (application => 'SQLAP',
                                                            program => 'APXMCCDF3',
                                                            argument1 => ln_card_program_id,
                                                            argument2 => lc_dest_path_file);
           */
		   lc_file_name := lc_data_file_name||'.dec';
           ln_req_id := fnd_request.submit_request (application => 'XXFIN',
                                                            program => 'XX_APMCENCMASTPRG',
                                                           argument1 => ln_card_program_id,
                                                            argument2 => lc_file_name,
															ARGUMENT3 => 'XXFIN_INBOUND_IEXPENSE',
															ARGUMENT4 => '/CDFTransmissionFile/IssuerEntity/CorporateEntity/AccountEntity',
															ARGUMENT5 => '@AccountNumber',
															ARGUMENT6 => 'N',
															ARGUMENT7 => 'Y',
														    ARGUMENT8 => 'N'														
															);		   
           COMMIT;
              
           if ln_req_id = 0 then
              lc_log_message := 'Failed - while submitting Import Program';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
              lc_valid_flag := 'N';               
           else              
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for Import Program to complete'); 
              lb_req_status := fnd_concurrent.wait_for_request (ln_req_id, 10, null, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
         
              IF lc_status != 'Normal' THEN
                 lc_log_message := 'Failed - Import Program completed with error - ' ||lc_message;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);                 
                 lc_valid_flag := 'N';                     
              ELSE
                 lc_log_message := 'Success - Import Program completed successfully';
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
              END IF;
           end if;   
        exception
           when others then
              lc_log_message := 'Import Program - '||SQLERRM;
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);                     
              lc_valid_flag := 'N';                  
        END;
     end if;

          
     BEGIN
        utl_file.fremove('XXFIN_INBOUND_SECURE',lc_dest_path_file);
     EXCEPTION
        WHEN NO_DATA_FOUND THEN
           lc_log_message := 'Warning - Decrypt file not exists - '|| SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
        WHEN OTHERS THEN           
           lc_log_message := 'Failed - Deleting the decrypt file or file not present - '|| SQLERRM;
           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
     END;
     
     
     
     if lc_valid_flag = 'N' then 
        begin
           lc_email_body := substr(lc_data_file_name ||' - '||lc_log_message,1,240);
           lc_email_subject := 'iExpense_Inbound_Errors';
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submit Email Program for sending notification');
           ln_email_req_id := fnd_request.submit_request (Application => 'XXFIN',
                                                       program => 'XXODEMAILER',
                                                       argument1 => lc_email, 
                                                       argument2 => lc_email_subject,
                                                       argument3 => lc_email_body
                                                      );
           COMMIT;
        
        
           if ln_email_req_id = 0 then
              lc_log_message := 'Failed - While submitting Email Program';
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message); 
           else              
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Waiting for Email Program to complete'); 
              lb_req_status := fnd_concurrent.wait_for_request (ln_email_req_id, 10, null, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
         
              IF lc_status != 'Normal' THEN
                 lc_log_message := 'Failed - Email Program completed with error - ' ||lc_message;
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);                 
              ELSE
                 lc_log_message := 'Success - Email Program successfully completed';
                 FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);      
              END IF;
           end if;           
        exception
           when others then
              lc_log_message := 'Email Program - '||SQLERRM;
              FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);                     
        END;
     end if;       
   
  EXCEPTION
     WHEN OTHERS THEN
        lc_log_message := 'Error in Mian Program - '||SQLERRM;
        FND_FILE.PUT_LINE(FND_FILE.LOG,lc_log_message);
  END main;
  
  procedure call_main(p_data_file IN VARCHAR2)
  is 
           ln_req_id     NUMBER := 0;
           lc_phase      VARCHAR2 (100) := NULL;
           lc_status     VARCHAR2 (100) := NULL;
           lc_dev_phase  VARCHAR2 (100) := NULL;
           lc_dev_status VARCHAR2 (100) := NULL;
           lc_message    VARCHAR2 (100) := NULL;
           lb_req_status BOOLEAN;
      ln_APPLICATION_ID FND_RESPONSIBILITY.APPLICATION_ID%TYPE;
      ln_RESPONSIBILITY_ID FND_RESPONSIBILITY.RESPONSIBILITY_ID%TYPE;
      ln_user_id FND_USER.USER_ID%TYPE;           
           
  begin

        SELECT user_id
          INTO ln_user_id
          FROM FND_USER
         WHERE USER_NAME = 'SVC_BPEL_FIN';
         
        select APPLICATION_ID, RESPONSIBILITY_ID 
          INTO ln_APPLICATION_ID, ln_RESPONSIBILITY_ID
          from FND_RESPONSIBILITY
         WHERE RESPONSIBILITY_KEY='OD_US_BATCH_JOBS';    
         
        fnd_global.apps_initialize (LN_USER_ID,ln_RESPONSIBILITY_Id, ln_APPLICATION_ID);         
         
 
     ln_req_id := fnd_request.submit_request (Application => 'XXFIN',
                                                  program => 'XXODAPIEXPIN',
                                                argument1 => p_data_file);
     
     commit;
     --lb_req_status := fnd_concurrent.wait_for_request (ln_req_id, 10, null, lc_phase, lc_status, lc_dev_phase, lc_dev_status, lc_message);
	 --The above line commented based on the defect# 36410 and added the below line
	 lb_req_status := TRUE;
  exception
     when others then
        FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);
		lb_req_status := FALSE; -- Added for defect# 36410
  end call_main;
  
END XX_Master_Card_Tran_Valid_PKG;
/
show err;
