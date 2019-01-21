CREATE OR REPLACE
PACKAGE BODY XXOD_HZ_TD_CUST_XREF_PKG  
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XXOD_HZ_TD_CUST_XREF_PKG                                                          |
-- |  Description:  Runs request set to load the customer cross reference XXOD_HZ_TD_CUST_XREF. |                                                                                           
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03/02/2014   Avinash Baddam   Initial version                                  |
-- | 2.0         11/12/2015   Havish Kasina    Removed the Schema References as per R12.2       |
-- |                                           Retrofit Changes                                 |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_PROC                                                                         |
-- |  Description: This procedure will insert tech depot - oracle customer cross reference      |
-- |               data from XXOD_HZ_TD_CUST_XREF_STG into XXOD_HZ_TD_CUST_XREF tables.         |
-- =============================================================================================|
PROCEDURE insert_proc (p_errbuf            OUT VARCHAR2
                      ,p_retcode           OUT VARCHAR2
                      ,p_batch_id          IN  NUMBER)
AS
   CURSOR xref_stg_cur IS
      SELECT batch_id,record_id,td_custno,aops_custno,end_date
        FROM  xxod_hz_td_cust_xref_stg
       WHERE batch_id = p_batch_id
         AND interface_status is null;
       
    TYPE xref_stg IS TABLE OF xref_stg_cur%ROWTYPE
        INDEX BY PLS_INTEGER;

   l_xref_stg xref_stg;       
       
   CURSOR get_custno_cur(p_orig_system_reference VARCHAR2) IS
      SELECT cust_account_id,account_number
        FROM hz_cust_accounts
       WHERE orig_system_reference = lpad(p_orig_system_reference,8,'0')||'-00001-A0';
       
   CURSOR check_cur(p_td_custno VARCHAR2) IS
      SELECT td_custno
        FROM  xxod_hz_td_cust_xref
       WHERE td_custno 	  = p_td_custno
         --AND aops_custno  = p_aops_custno
         AND end_date is null;       
         
   CURSOR check_aopscustno_cur(p_aops_custno VARCHAR2) IS
      SELECT aops_custno
        FROM  xxod_hz_td_cust_xref
       WHERE aops_custno = p_aops_custno
         AND end_date is null;              
       
   l_cross_ref_id  	NUMBER;
   l_cust_account_id  	NUMBER;
   l_account_number 	VARCHAR2(60);
   l_td_custno          VARCHAR2(60);
   l_aops_custno        VARCHAR2(60);
   l_limit          	NUMBER := 1000;
   indx                 NUMBER;
   l_rec_succ_cnt       NUMBER;
   l_rec_fail_cnt       NUMBER;
   l_rec_read      	NUMBER;
   l_error_msg          VARCHAR2(300);
   l_user_id  		NUMBER := nvl(fnd_global.user_id,0);
   l_login_id 		NUMBER := nvl(fnd_global.login_id,0);
BEGIN
   l_rec_succ_cnt       := 0;
   l_rec_fail_cnt       := 0;
   l_rec_read      	:= 0;

    OPEN xref_stg_cur;
    LOOP

        FETCH xref_stg_cur 
            BULK COLLECT INTO l_xref_stg LIMIT l_limit;

        FOR indx IN 1..l_xref_stg.COUNT 
        LOOP
           BEGIN
                   l_rec_read := l_rec_read + 1;
		   l_cust_account_id 	:= NULL;
		   l_account_number 	:= NULL;
		   OPEN get_custno_cur(l_xref_stg(indx).aops_custno);
		   FETCH get_custno_cur INTO l_cust_account_id,l_account_number;
		   CLOSE get_custno_cur;

		   IF l_cust_account_id is null THEN
		       UPDATE xxod_hz_td_cust_xref_stg
			  SET interface_status = 'E',error_desc = 'AOPS Customer not found in Oracle'
			WHERE record_id = l_xref_stg(indx).record_id;
			l_rec_fail_cnt := l_rec_fail_cnt + 1;
			
			IF l_rec_fail_cnt = 1 THEN
			   write_out('============= Customer Cross Reference failed records============='||CHR(10));
			   write_out(RPAD('TD_Custno',40)||RPAD('Error',100));
     			   write_out(RPAD('-',30,'-')||RPAD('-',50,'-'));
     			END IF;
     			   write_out(RPAD(l_xref_stg(indx).td_custno,40)||'AOPS customer not found in oracle');
		   ELSE
		       --If record already exists then end_date and insert.
			 l_td_custno := NULL;
			  OPEN check_cur(l_xref_stg(indx).td_custno);
			 FETCH check_cur INTO l_td_custno;
			 CLOSE check_cur;
			 
			 IF l_td_custno IS NOT NULL THEN
			    UPDATE xxod_hz_td_cust_xref
			       SET end_date  = sysdate,
			           last_update_date = sysdate,
			           last_updated_by  = l_user_id,
			           last_update_login = l_login_id
			     WHERE td_custno = l_xref_stg(indx).td_custno
			       --AND aops_custno  = l_xref_stg(indx).aops_custno
			       AND end_date is null;  
			 END IF;			 
			 
			 l_aops_custno := NULL;
			 OPEN check_aopscustno_cur(l_xref_stg(indx).aops_custno);
			 FETCH check_aopscustno_cur INTO l_aops_custno;
			 CLOSE check_aopscustno_cur;
			 
			 IF l_aops_custno IS NOT NULL THEN
			    UPDATE xxod_hz_td_cust_xref
			       SET end_date  = sysdate,
			           last_update_date = sysdate,
			           last_updated_by  = l_user_id,
			           last_update_login = l_login_id			       
			     WHERE aops_custno  = l_xref_stg(indx).aops_custno
			       AND end_date is null;
			 END IF;
			 
			 l_cross_ref_id := XXOD_CUST_XREF_ID_S.nextval;
			 INSERT into xxod_hz_td_cust_xref(cross_ref_id,td_custno,aops_custno,
				cust_account_id,account_number,end_date,created_by,creation_date,
				last_updated_by,last_update_date,last_update_login) 
			  VALUES(l_cross_ref_id,l_xref_stg(indx).td_custno,l_xref_stg(indx).aops_custno,
				l_cust_account_id,l_account_number,l_xref_stg(indx).end_date,l_user_id,sysdate,
				l_user_id,sysdate,l_login_id);
				
		         UPDATE xxod_hz_td_cust_xref_stg
		            SET interface_status = 'S' -- success
		          WHERE record_id = l_xref_stg(indx).record_id;
		         l_rec_succ_cnt := l_rec_succ_cnt +1;
		   END IF;
            COMMIT;
            
            EXCEPTION 
            WHEN others THEN
            l_error_msg := substr(sqlerrm,1,99);
            rollback;
                  UPDATE xxod_hz_td_cust_xref_stg
	    	     SET interface_status = 'E',error_desc = l_error_msg
		   WHERE record_id = l_xref_stg(indx).record_id;
		   write_out(RPAD(l_xref_stg(indx).td_custno,40)||l_error_msg);
		   l_rec_fail_cnt := l_rec_fail_cnt + 1;
            COMMIT;    
            END;
	   
         END LOOP;

         EXIT WHEN l_xref_stg.COUNT < l_limit;

     END LOOP;

     CLOSE xref_stg_cur;
     write_log('============= Customer Cross Reference ============='||CHR(10));
     write_log(CHR(10)||'-----------------------------------------------------------');
     write_log('Total no.of records read = '||to_char(l_rec_read));
     write_log('Total no.of records succeded = '||to_char(l_rec_succ_cnt));
     write_log('Total no.of records failed = '||to_char(l_rec_fail_cnt));
     write_log('-----------------------------------------------------------');     
     
     IF l_rec_fail_cnt > 0 THEN
        p_retcode   := '1'; -- warning
     ELSE 
        p_retcode   := '0'; -- normal
     END IF;
EXCEPTION     
WHEN others THEN
     p_errbuf    := 'Others Exception in INSERT_PROC procedure '||SQLERRM;
     p_retcode   := '2'; -- error
END INSERT_PROC; 

-- +===================================================================+
-- | Name  : update_batch                                              |
-- |                                                                   |
-- | Description:       This Procedure updates the batch id of the     |
-- |                    staging table XXOD_HZ_TD_CUST_XREF_STG for     |
-- |                    each file                                      |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_batch(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_batch_id        IN   number  
                    )
IS
  BEGIN
     UPDATE XXOD_HZ_TD_CUST_XREF_STG
        SET batch_id = p_batch_id
      WHERE batch_id = 99999999999999;

     COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      WRITE_LOG('Error in update_batch: ' || SQLERRM);
      ROLLBACK;
END update_batch;

-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

END write_out;

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

END write_log;

-- +===================================================================+
-- | Name  : upload                                                    |
-- |                                                                   |
-- | Description:       This Procedure will submit the programs to     |
-- |                    upload the data                                |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+ 
PROCEDURE UPLOAD(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_request_set_id  OUT NOCOPY  number   , 
                    p_file_name       IN  varchar2   
                  ) IS 
   
  lb_success            boolean; 
  req_id                number; 
  req_data              varchar2(10); 
  errbuf                varchar2(2000) := p_errbuf;
  retcode               varchar2(1) := p_retcode;
  l_file_name           varchar2(4000) := p_file_name;
  l_request_set_name    varchar2(30);
  srs_failed            exception; 
  submitprog_failed     exception; 
  submitset_failed      exception; 
  le_submit_failed      exception;
  request_desc          varchar2(240); /* Description for submit_request  */
  x_user_id             fnd_user.user_id%type; 
  x_resp_id             fnd_responsibility.responsibility_id%type; 
  x_resp_appl_id        fnd_responsibility.application_id%type;    
  b_complete            boolean := true;
  l_count               number;
  l_request_id          number;
  ln_batch_id           number;
  lv_return_status      varchar2(1);
  ln_msg_count          number;
  lv_msg_data           varchar2(2000);
  l_osr                 varchar2(240);
BEGIN 

   write_log('User_Id: ' || FND_GLOBAL.USER_ID);
   write_log('Resp_id: ' || FND_GLOBAL.RESP_ID);
   write_log('Resp_appl_id: ' || FND_GLOBAL.RESP_APPL_ID);
   write_log('p_file_name: ' || p_file_name);

   req_data := FND_CONC_GLOBAL.REQUEST_DATA; 

   write_log('req_data: ' || req_data);
   write_log('Calling set_request_set...');

   --delete the records that are stuck with temp batch_id
   DELETE 
     FROM XXOD_HZ_TD_CUST_XREF_STG
    WHERE batch_id = 99999999999999;

   COMMIT;
   
   SELECT request_set_name
     INTO l_request_set_name 
     FROM  fnd_request_sets_vl 
    WHERE user_request_set_name='OD: Customer Cross References';
   
   lb_success := FND_SUBMIT.SET_REQUEST_SET('XXCRM', l_request_set_name);  
   errbuf := SUBSTR(fnd_message.get,1, 240);

   IF ( NOT lb_success ) THEN  
     write_log('set_request_set: success!');
     raise srs_failed; 
   END IF; 
            
   write_log('Calling submit program first time...');  
   
   IF ( lb_success ) THEN
     
     ---------------------------------------------------------------------------
     -- Submit program 'OD Customer cross reference loader to staging' which is in 1st stage
     ---------------------------------------------------------------------------   
      
     
     lb_success := FND_SUBMIT.SUBMIT_PROGRAM
                         (  application => 'XXCRM',
                            program     => 'XXOD_CUST_XREF_STG',
                            stage       => 'XXOD_CUST_XREF_STG', 
                            argument1   => l_file_name                          
                         );
     errbuf := SUBSTR(FND_MESSAGE.GET,1, 240);
     
     write_log('submit_program XXOD_CUST_XREF_STG: success!');
     IF ( not lb_success ) THEN  
        raise submitprog_failed;     
     END IF;
     ----------------------------------------------------------    
     --End Submit program 'OD Customer cross reference loader to staging'
     ----------------------------------------------------------          
     --------------------
     ---Generate batch_id
     --------------------
     SELECT xxod_cust_xref_batch_id_s.nextval
       INTO ln_batch_id
       FROM dual;
       
     write_log('Batch ID - '||ln_batch_id||' Successfully generated!!');
     -------------------------
     ----end genarate batch_id
     -------------------------
     -----------------------------------------------------------------------------
     -- Submit program 'OD: Set correct batch for XREF staging' which is in 2nd stage
     -----------------------------------------------------------------------------
     
     lb_success := FND_SUBMIT.SUBMIT_PROGRAM
                      (  application => 'XXCRM',
                         program     => 'XXOD_XREFSTG_SET_BATCH',
                         stage       => 'XXOD_XREFSTG_SET_BATCH', 
                         argument1   => ln_batch_id                          
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ----------------------------------------------------------    
     --End Submit program 'OD: Set correct batch for XREF staging'
     ----------------------------------------------------------      

     -------------------------------------------------------------------------------------
     -- Submit program 'OD Customer Cross Reference Import' which is in 3rd stage 
     -------------------------------------------------------------------------------------
     
     lb_success := FND_SUBMIT.SUBMIT_PROGRAM
                      (  application => 'XXCRM',
                         program     => 'XXOD_CUST_XREF_IMPORT',
                         stage       => 'XXOD_CUST_XREF_IMPORT', 
                         argument1   => ln_batch_id
                      );   
     IF ( NOT lb_success ) THEN
        RAISE le_submit_failed;
     END IF;
     ------------------------------------------------------------------    
     --End Submit program 'OD Customer Cross Reference Import' 
     ------------------------------------------------------------------  
     write_log('Calling submit_set...'); 
      
     req_id := fnd_submit.submit_set(null,FALSE); 

   END IF; 
   --end of if lb_success of submit request set

   COMMIT;
   
   write_log('2 req_id:' || to_char(req_id));

   IF (req_id = 0 ) THEN 
      raise submitset_failed; 
   END IF; 
         
   write_log('Finished.'); 
         
    
   FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => '1') ; 
   FND_MESSAGE.SET_NAME('FND','CONC-Stage Submitted');
   FND_MESSAGE.SET_TOKEN('STAGE', request_desc);
   errbuf := SUBSTR(fnd_message.get,1, 240);
   retcode := 0;         
   write_log('errbuf: ' || errbuf); 
   p_errbuf := errbuf;

   retcode := 0; 
   p_retcode := retcode;

   p_request_set_id := req_id; 
 
EXCEPTION 
   WHEN srs_failed THEN 
      errbuf := 'Call to set_request_set failed: ' || fnd_message.get; 
      retcode := 2; 
      write_log(errbuf); 
   WHEN submitprog_failed THEN      
      errbuf := 'Call to submit_program failed: ' || fnd_message.get; 
      retcode := 2; 
      write_log(errbuf); 
   WHEN submitset_failed THEN      
      errbuf := 'Call to submit_set failed: ' || fnd_message.get; 
      retcode := 2; 
      write_log(errbuf); 
   WHEN others THEN 
      errbuf := 'Request set submission failed - unknown error: ' || sqlerrm; 
      retcode := 2; 
      write_log(errbuf); 
END upload;

END  XXOD_HZ_TD_CUST_XREF_PKG;
/
SHOW ERRORS;
