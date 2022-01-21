CREATE OR REPLACE 
PACKAGE BODY XX_CE_ADHOC_RECONCILE_PKG AS

-- +=======================================================================================================+
-- |                            Office Depot - Project Simplify                                            |
-- |                                    Office Depot                                                       |
-- +=======================================================================================================+
-- | Name  : XX_CE_ADHOC_RECONCILE_PKG.pkb                                                            |
-- | Description  : This package will update the status FLOAT to CLEARED in xx_ce.statement_lines          |
-- | Parameters   : p_count                                                                                |
-- |                                                                                                       |
-- |===============                                                                                        |
-- |Version    Date          Author             Remarks                                                    |
-- |=======    ==========    =================  ===========================================================|
-- |1.0        19-FEB-2018   VIVEK KUMAR        Initial version                                            |
-- +=======================================================================================================+

PROCEDURE STATUS_UPDATE  (x_errbuff     OUT VARCHAR2
                         ,x_retcode     OUT NUMBER
                         ,p_count       IN NUMBER)

IS
  l_sub_request_id    NUMBER := NULL;
  l_resp_id           NUMBER := NULL;
  l_app_id            NUMBER := NULL;
  v_request_completed BOOLEAN;
  v_request_id        NUMBER;
  v_phase             VARCHAR2 (80) := NULL;
  lv_custm_exception  EXCEPTION;
  v_status            VARCHAR2 (80) := NULL;
  v_dev_phase         VARCHAR2 (30) := NULL;
  v_dev_status        VARCHAR2 (30) := NULL;
  v_message           VARCHAR2 (240);
  lv_rec_count        NUMBER :=0;
  lv_Request_count    NUMBER :=0;
  lv_msg              VARCHAR2(2000):=NULL;
  l_user_id           NUMBER;
  lv_user_name        NUMBER;
  lv_bank_branch_id   NUMBER;
  lv_bank_account_id  NUMBER;
  lv_statement_number VARCHAR2(50)  ;
  ln_request_id       NUMBER := fnd_global.conc_request_id;
  gn_org_id           NUMBER := fnd_profile.VALUE('ORG_ID');
  

  CURSOR cur_auto_recon_rec IS
  SELECT DISTINCT cba.bank_branch_id, cba.bank_Account_id, csh.statement_number from 
                  ce_Statement_headers csh, ce_bank_Accounts cba ,ce_statement_lines csl
                  WHERE cba.bank_Account_id=csh.bank_Account_id
                  AND EXISTS (SELECT 1 FROM xx_Ce_999_interface xcint WHERE xcint.status='FLOAT' 
	              AND xcint.record_type='AJB' 
				  AND xcint.x999_gl_complete='Y' 
				  AND xcint.x998_gl_complete='Y' 
				  AND  xcint.x996_gl_complete='Y'
	              AND xcint.currency_code='USD'
	              AND xcint.bank_Account_id= cba.bank_Account_id
                  AND xcint.statement_header_id= csh.statement_header_id)
				  AND csh.STATEMENT_HEADER_ID = csl.STATEMENT_HEADER_ID
				  AND csl.status = 'UNRECONCILED';
				  
  CURSOR cur_bank_rec(p_bank_branch_id number, p_bank_Account_id number, p_statement_number number ) IS
  SELECT DISTINCT xcint.trx_id, xcint.bank_rec_id, xcint.processor_id, xcint.statement_header_id, xcint.statement_LINe_Id from 
                  ce_Statement_headers csh, ce_bank_Accounts cba ,ce_statement_lines csl, xx_Ce_999_interface xcint
                  WHERE cba.bank_Account_id=csh.bank_Account_id
				  AND xcint.status='FLOAT' 
	              AND xcint.record_type='AJB' 
				  AND xcint.x999_gl_complete='Y' 
				  AND xcint.x998_gl_complete='Y' 
				  AND  xcint.x996_gl_complete='Y'
	              AND xcint.currency_code='USD'
	              AND xcint.bank_Account_id= cba.bank_Account_id
                  AND xcint.statement_header_id= csh.statement_header_id
				  AND csh.STATEMENT_HEADER_ID = csl.STATEMENT_HEADER_ID
				  AND xcint.STATEMENT_line_ID = csl.STATEMENT_line_ID
				  AND csl.status = 'UNRECONCILED'
				  AND cba.bank_branch_id = p_bank_branch_id 
				  AND cba.bank_Account_id = p_bank_Account_id
				  AND csh.statement_number = p_statement_number;
  
  
     BEGIN 
		mo_global.set_policy_context('S',gn_org_id); 
        FND_REQUEST.SET_ORG_ID(gn_org_id);  
		
       FOR rec IN cur_auto_recon_rec
        LOOP
		         
			FOR rec2 in cur_bank_rec(rec.bank_branch_id, rec.bank_account_id, rec.statement_number)
			loop
				FND_FILE.PUT_LINE (FND_FILE.LOG,'Trx_id-'||rec2.trx_id ||' bank_rec_id-'||rec2.bank_rec_id ||' , processor_id-'||rec2.processor_id||' , statement_header_id-'||rec2.statement_header_id||' , statement_line_id-'||rec2.statement_line_id);
			end loop;
			
		BEGIN
			
			ln_request_id  := fnd_global.conc_request_id;
	
               l_sub_request_id:= FND_REQUEST.SUBMIT_REQUEST (
               application  => 'CE'
              ,program      => 'ARPLABRC'
              ,description  =>  NULL
              ,start_time   =>  SYSDATE
              ,sub_request  =>  FALSE
              ,argument1    => 'RECONCILE'
              ,argument2    =>  rec.bank_branch_id
              ,argument3    =>  rec.bank_account_id
              ,argument4    =>  rec.statement_number
              ,argument5    =>  rec.statement_number
			  ,argument6    =>  NULL
              ,argument7    =>  NULL
              ,argument8    =>  TO_CHAR(SYSDATE, 'YYYY/MM/DD')
			  ,argument9    =>  NULL
              ,argument10   =>  NULL
              ,argument11   =>  NULL
			  ,argument12   =>  NULL
              ,argument13  =>  'NO_ACTION'
			  ,argument14   =>  'N'
			  ,argument15   =>  NULL
              ,argument16  =>   NULL);
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Reuqest Id-'||l_sub_request_id ||' Submitted for Bank Account ID-'||rec.bank_account_id ||' , Statement Number-'||rec.statement_number);
			   FND_FILE.PUT_LINE (FND_FILE.LOG,'---------------------------------------------------------------------------------------------------------------------');
COMMIT;
        
        BEGIN
		 
         LOOP
              SELECT COUNT(*)
              INTO lv_rec_count
              FROM fnd_concurrent_Requests fcr
              WHERE fcr.concurrent_program_id=36027              
              AND Phase_code                 !='C' ;
              IF lv_rec_count                < p_count THEN
              RAISE lv_custm_exception;
			  ELSE 
			  dbms_lock.sleep(30);
      END IF; 
      END LOOP;
               
           
        EXCEPTION
              WHEN lv_custm_exception THEN
              NULL;
              END;

        EXCEPTION
              WHEN OTHERS THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG,'Failed in submiting the Program: ' || SQLERRM );
              FND_FILE.PUT_LINE (FND_FILE.LOG, TO_CHAR(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    END;
    END LOOP;
              FND_FILE.PUT_LINE (FND_FILE.LOG,'COMPLETED');
			  
COMMIT;
  
    END STATUS_UPDATE;
  
  END XX_CE_ADHOC_RECONCILE_PKG ;
/
SHOW ERR;
