create or replace
PACKAGE BODY XX_HR_USER_ACCTCOUR_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_USER_ACCTCOUR_PKG                                                            |
-- |  Description:  OD: HR User Extract for Account Courier                                     |
-- |                I2124_EBS_User_Feed_for_Account_Courier                                     |
-- |                Defect 9215                                                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         12/14/2010   Joe Klein        Initial version                                  |
-- | 1.1         11/19/2015   Avinash Baddam   R12.2 Compliance Changes                         |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: XX_CREATE_EXTR_FILE_PROC                                                            |
-- |  Description: This pkg.procedure will extract users from fnd_user table to feed to Account |
-- |  Courier.                                                                                  |
-- =============================================================================================|

   ---------------------
   -- Global Variables
   --------------------
   gn_request_id         NUMBER   := FND_GLOBAL.CONC_REQUEST_ID();

PROCEDURE XX_CREATE_EXTR_FILE_PROC    (errbuff     OUT VARCHAR2
                                       ,retcode     OUT VARCHAR2)
    AS
         g_FileHandle              UTL_FILE.FILE_TYPE;
         lc_output_file            VARCHAR2 (100);
         lc_fileheader             VARCHAR2(5000);
         lc_filerec                VARCHAR2(5000);
         ln_record_cnt             NUMBER;
         ln_req_id_c               NUMBER;
         ln_req_id_p               NUMBER;
         lc_status_code            VARCHAR2(25);
         lc_warning_flg            VARCHAR2(1) := 'N';
         lc_error_flg              VARCHAR2(1) := 'N';         
 
         ----------------------------------------------
         --Cursor to select records for extract file
         ----------------------------------------------
         CURSOR SELECT_EXTRACT_REC IS 
                   SELECT user_name
                   FROM   fnd_user
                   WHERE  user_name BETWEEN '000001' AND '999999'
                     AND  LENGTH(user_name) = 6
                     AND  (end_date > SYSDATE OR end_date IS NULL)
                   ORDER  BY user_name;         

    BEGIN
        ln_req_id_p := fnd_global.conc_request_id;
        
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Program XX_CREATE_EXTR_FILE_PROC started...');
               
        IF FND_CONC_GLOBAL.request_data IS NULL THEN  -- not a restart of parent
           
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent request started...');
          
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Setting Filename...');
           lc_output_file := 'EBIZ_USERS.txt';
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Filename = '||lc_output_file); 
	        
           g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND',lc_output_file,'w');        
        
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Writing Extract Records...');
           ln_record_cnt := 0;
           FOR R_EX IN SELECT_EXTRACT_REC LOOP
              ln_record_cnt := ln_record_cnt + 1;
              lc_filerec := R_EX.USER_NAME;
              UTL_FILE.PUT_LINE(g_FileHandle, lc_filerec); 
	         END LOOP;    

           UTL_FILE.FFLUSH(g_FileHandle);
           UTL_FILE.FCLOSE(g_FileHandle);
        
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Finished Writing File...');
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Record count  = '|| ln_record_cnt);  

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting child process XXCOMFTP');
           ln_req_id_c := fnd_request.submit_request('XXFIN','XXCOMFTP',
                          '','01-OCT-04 00:00:00',TRUE, 'OD_HR_USER_ACCTCOUR',
                          lc_output_file , lc_output_file,'N' );    
 
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Child XXCOMFTP request id = '||ln_req_id_c);
           COMMIT;
           
           IF ln_req_id_c  > 0  THEN
              FND_CONC_GLOBAL.set_req_globals(conc_status => 'PAUSED',request_data => to_char(gn_request_id));
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error in process file'); 
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'FTP program never was submitted!');
              retcode :=2;
              errbuff := fnd_message.get;
              return;
           END IF;

        ELSE  -- restart detected
           SELECT status_code
             INTO lc_status_code
             FROM fnd_concurrent_requests
            WHERE parent_request_id = gn_request_id; 

           IF (lc_status_code = 'G' OR lc_status_code = 'X' OR lc_status_code ='D' OR lc_status_code ='T') THEN
              lc_warning_flg := 'Y'; 
           ELSIF ( lc_status_code = 'E' ) THEN
              lc_error_flg := 'Y';  
           END IF;
 
           IF lc_error_flg = 'Y' THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Setting completion status to ERROR.  Please check child program');
              retcode := 2;
           ELSIF lc_warning_flg = 'Y' THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Setting completion status to WARNING.  Please check child program');      
              retcode := 1;
           ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Setting completion status to NORMAL.');
           END IF;
           COMMIT;
        END IF;
        
 
    END XX_CREATE_EXTR_FILE_PROC;

END XX_HR_USER_ACCTCOUR_PKG;

/
