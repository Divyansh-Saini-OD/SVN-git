create or replace
PACKAGE body XX_AR_EXT_WC_MASTER_PKG
AS
PROCEDURE AR_EXT_MAIN(
    p_errbuf OUT VARCHAR2 ,
    p_retcode OUT NUMBER ,
    p_action_type   IN VARCHAR2 ,
    p_last_run_date IN VARCHAR2 ,
    p_to_run_date   IN VARCHAR2 ,
    P_no_of_threads IN NUMBER ,
    p_content_type  in number ,
    p_batch_limit   IN NUMBER,
    P_compute_stats IN VARCHAR2 ,
    P_debug         IN VARCHAR2 )
AS
  CURSOR lcu_cust_accts_txn(p_no_of_threads in number) 
  IS
    SELECT min(x.cust_account_id) 
          ,max(x.cust_account_id) 
          ,X.thread_num 
    FROM sys.dual, 
        (SELECT ce.cust_account_id, 
                   ntile(p_no_of_threads) over (ORDER BY ce.cust_account_id, ce.customer_trx_id ASC) AS thread_num 
         FROM  (SELECT xc.cust_account_id, rct.customer_trx_id from XX_CRM_WCELG_CUST xc 
                 ,ra_customer_trx_all rct 
         WHERE rct.last_update_date BETWEEN SYSDATE-180 and SYSDATE                                                             
         AND   rct.bill_to_customer_id = xc.cust_account_id ) ce ) x 
  GROUP BY x.thread_num
  ORDER BY x.thread_num;
  
   CURSOR lcu_cust_accts_cr(p_no_of_threads in number) 
  IS
    SELECT min(x.cust_account_id) 
          ,max(x.cust_account_id) 
          ,X.thread_num 
    FROM sys.dual, 
        (SELECT ce.cust_account_id, 
                   ntile(p_no_of_threads) over (ORDER BY ce.cust_account_id, ce.cash_receipt_id ASC) AS thread_num 
         FROM    (SELECT xc.cust_account_id, cr.cash_receipt_id from XX_CRM_WCELG_CUST xc 
                 ,ar_cash_receipts_all cr
         WHERE    cr.last_update_date BETWEEN SYSDATE-180 AND SYSDATE
        AND   xc.cust_account_id=cr.pay_from_customer ) ce ) x 
  GROUP BY x.thread_num
  ORDER BY x.thread_num;
  
   CURSOR lcu_cust_accts_adj(p_no_of_threads in number) 
  IS
    SELECT min(x.cust_account_id) 
          ,max(x.cust_account_id) 
          ,X.thread_num 
    FROM sys.dual, 
        (SELECT ce.cust_account_id, 
                   ntile(p_no_of_threads) over (order by ce.cust_account_id, ce.adjustment_id asc) as thread_num 
         FROM    (SELECT xc.cust_account_id, adj.adjustment_id from XX_CRM_WCELG_CUST xc 
                 ,ra_customer_trx_all rct 
                 ,ar_adjustments_all adj
         WHERE   adj.last_update_date BETWEEN SYSDATE-180 AND SYSDATE
          AND    rct.bill_to_customer_id = xc.cust_account_id               
          AND    adj.customer_trx_id = rct.customer_trx_id ) ce )  x 
  GROUP BY x.thread_num
  ORDER BY x.thread_num;
  
   CURSOR lcu_cust_accts_ps(p_no_of_threads in number) 
  IS
    SELECT min(x.cust_account_id) 
          ,max(x.cust_account_id) 
          ,X.thread_num 
    FROM sys.dual, 
        (SELECT ce.cust_account_id, 
                   ntile(p_no_of_threads) over (ORDER BY ce.cust_account_id, ce.payment_schedule_id ASC) AS thread_num 
         FROM  (SELECT xc.cust_account_id, ps.payment_schedule_id from XX_CRM_WCELG_CUST xc
              ,ar_payment_schedules_all ps 
         WHERE  ps.last_update_date BETWEEN SYSDATE-180 AND SYSDATE
         AND    xc.cust_account_id = ps.customer_id ) ce ) x 
  GROUP BY x.thread_num
  ORDER BY x.thread_num;
  
   CURSOR lcu_cust_accts_ra(p_no_of_threads in number) 
  IS
    SELECT min(x.cust_account_id) 
          ,max(x.cust_account_id) 
          ,X.thread_num 
    FROM sys.dual, 
        (SELECT ce.cust_account_id, 
                   ntile(p_no_of_threads) over (ORDER BY ce.cust_account_id, ce.receivable_application_id ASC) AS thread_num 
         FROM    (SELECT xc.cust_account_id, ra.receivable_application_id from XX_CRM_WCELG_CUST xc 
                 ,ra_customer_trx_all rct
                 ,ar_receivable_applications_all ra
         WHERE   ra.last_update_date BETWEEN SYSDATE-180 AND SYSDATE
         AND  xc.cust_account_id  =rct.bill_to_customer_id
         AND  rct.customer_trx_id =ra.applied_customer_trx_id) ce ) x 
  GROUP BY x.thread_num
  ORDER BY x.thread_num;


  ln_conc_id fnd_concurrent_requests.request_id%TYPE := -1;
  p_parent_program_id NUMBER(15);
  p_parent_request_id NUMBER(15);
  p_from_account_id   NUMBER(15);
  p_to_account_id     NUMBER(15);
  ln_from_cust_account_id hz_cust_accounts.cust_account_id%TYPE;
  ln_to_cust_account_id hz_cust_accounts.cust_account_id%TYPE;
  ln_thread_num        number(15);
  ln_batch_limit NUMBER;
  lc_program_name      varchar2(60);
  lb_GET_REQUEST_STATUS BOOLEAN;
  lc_DEV_STATUS         VARCHAR2(10);
  v_ext_wc_s          varchar2(10);
  lc_phase              varchar2(10);
  lc_status             varchar2(10);
  lc_flag              varchar2(1):='N';
  lc_DEV_PHASE          VARCHAR2(10);
  lc_message            varchar2(2000);
  ln_batch             number;
  lc_delimiter         varchar2(10);
  ln_threads           VARCHAR2(10);
  lc_compute_stats     varchar2(10);
  lc_debug             varchar2(10);
  ln_parent_request_id number := fnd_global.conc_request_id;
  ln_PARENT_CP_ID      NUMBER;
  ln_user_id           number := fnd_profile.value('user_id');
  ln_appl_id           number := fnd_profile.value('RESP_APPL_ID');
  ln_resp_id           NUMBER := FND_PROFILE.VALUE('RESP_ID');
  ln_conc_req_id1     NUMBER;
  ln_conc_req_id2     NUMBER;
  ln_conc_req_id3     NUMBER;
  ln_conc_req_id4     NUMBER;
  ln_conc_req_id5     NUMBER;
  ln_child_cp_id1     NUMBER;
  ln_child_cp_id2     NUMBER;
  ln_child_cp_id3     NUMBER;
  ln_child_cp_id4     NUMBER;
  ln_child_cp_id5    number;
  ld_last_run_date date;
  ld_last_run_date1 date;
  ld_last_run_date2 date;
  ld_last_run_date3 date;
  ld_last_run_date4 DATE;
  ld_last_run_date5 date;
  gc_error_debug varchar2(1000);
  gc_error_loc   number;
  ln_idx			number;
  ln_req_id1 req_id;
  ln_req_id req_id;
BEGIN
   FND_GLOBAL.APPS_INITIALIZE(ln_user_id,ln_resp_id, ln_appl_id);
  
 BEGIN
    SELECT  concurrent_program_id
    INTO   ln_parent_cp_id
    FROM  fnd_concurrent_requests fcr
    WHERE fcr.request_id =ln_parent_request_id;
  EXCEPTION
  WHEN OTHERS THEN
  
    fnd_file.put_line (fnd_file.log, 'Parent id '||ln_parent_cp_id );
    ln_parent_cp_id :=null;
    
  END;

--------------------------------------------------------------------------------------
--Submit the Program for the AR Transaction Daily Conversion
--------------------------------------------------------------------------------------  

  
  
  -- generate a sequence from xx_crm_common_delta_s.nextval from dual;
  SELECT XX_AR_EXT_WC_MASTER_S.nextval
  INTO   v_ext_wc_s
  FROM  dual;
  
 IF p_action_type ='F' THEN
 
 --------------------------------------------------------------------------------------
--Submit the Program for the Transactions  Daily Conversion
--------------------------------------------------------------------------------------

ln_idx           :=1; 
ln_threads :=4;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_TRANS_WC_STG';

 BEGIN
   SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_TRANS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'For Transalation Definition is not returning record for AR_TRANS');
 END;
  
    OPEN lcu_cust_accts_txn(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_txn
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_txn%NOTFOUND;
    

      ln_conc_req_id1 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARFTXNWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE 
                                       ,argument1   => ln_from_cust_account_id 
                                       ,argument2   => ln_to_cust_account_id 
                                       ,argument3   => ln_batch_limit
                                       ,argument4   => p_compute_stats 
                                       ,argument5   => p_debug );
                                      
      IF ln_conc_req_id1=0 THEN
               fnd_file.put_line(fnd_file.log,'Child Program is not submitted');
      ELSE

	  	ln_req_id(ln_idx):= ln_conc_req_id1;
		  ln_idx           := ln_idx+1;
	    END IF;
    /*  ELSE
          IF apps.fnd_concurrent.wait_for_request(ln_conc_id, 60, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	        THEN 
		         fnd_file.put_line(fnd_file.log, 'Full AR Transaction program completed');
 	        END IF;
*/
     
      BEGIN
              SELECT fcr.concurrent_program_id
              INTO   ln_child_cp_id1
              FROM  fnd_concurrent_requests fcr
              where fcr.request_id =ln_conc_req_id1;
      EXCEPTION 
        WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Parent id '||ln_parent_cp_id );
          ln_child_cp_id1 :=null;
       END;
      
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          ' ', ---child_program_name  ,
          ln_child_cp_id1 ,
          ln_conc_req_id1 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
           commit;
           
     END LOOP;
CLOSE lcu_cust_accts_txn;
   
   
--------------------------------------------------------------------------------------
--Submit the Program for the Cash Receipts  Daily Conversion
--------------------------------------------------------------------------------------
 ln_batch_limit :=0;
 ln_threads:=4;
 lc_compute_stats:='N';
   EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_CR_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_CASH_RECEIPTS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_CASH_RECEIPTS');
  END;
ln_threads:=1;
 OPEN lcu_cust_accts_cr(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_cr
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_cr%NOTFOUND;
    

      ln_conc_req_id2 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARFCRWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE 
                                       ,argument1   => ln_from_cust_account_id 
                                       ,argument2   => ln_to_cust_account_id 
                                       ,argument3   => p_batch_limit 
                                       ,argument4   => p_compute_stats 
                                       ,argument5   => p_debug );
                                       
                                      
      IF ln_conc_req_id2=0 THEN
               fnd_file.put_line(fnd_file.log,'Child Program is not submitted');
      ELSE

	  	ln_req_id(ln_idx):=  ln_conc_req_id2; 
		  ln_idx           := ln_idx+1;
	    END IF;
                                
 
    
        BEGIN
              SELECT fcr.concurrent_program_id
              INTO   ln_child_cp_id2
              FROM  fnd_concurrent_requests fcr
              WHERE fcr.request_id =ln_conc_req_id2;
         EXCEPTION 
        WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Child id '||ln_child_cp_id2 );
          ln_child_cp_id2 :=null;
       END;

      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          ' ', ---child_program_name  ,
          ln_child_cp_id2 ,
          ln_conc_req_id2 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
           COMMIT;
           
 END LOOP;
 
 CLOSE lcu_cust_accts_cr;
   
   /* FOR i IN ln_req_id2.FIRST..ln_req_id2.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id2(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		 	if upper(lc_status) = 'ERROR' then
                      lc_flag :='Y';
                   	  fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	   fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
		           fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		        END IF;
		end if;
  	END LOOP;*/
--------------------------------------------------------------------------------------
--Submit the Program for the Adjustments  Daily Conversion
--------------------------------------------------------------------------------------
 ln_batch_limit :=0;
 ln_threads:=4;
 lc_compute_stats:='N';
 
   EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_ADJ_WC_STG';
 
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_ADJUSTMENTS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_ADJUSTMENTS');
  END;
  
   OPEN lcu_cust_accts_adj(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_adj
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_adj%NOTFOUND;
    

      ln_conc_req_id3 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARFADJWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE 
                                       ,argument1   => ln_from_cust_account_id 
                                       ,argument2   => ln_to_cust_account_id 
                                       ,argument3   => p_batch_limit 
                                       ,argument4   => p_compute_stats 
                                       ,argument5   => p_debug );
                                       
                                      
      IF ln_conc_req_id3=0 THEN
               fnd_file.put_line(fnd_file.log,'Child Program is not submitted');
     ELSE

	  	ln_req_id(ln_idx):= ln_conc_req_id3;
		  ln_idx           := ln_idx+1;
	    END IF;
                                
 
      BEGIN
             SELECT fcr.concurrent_program_id
             INTO   ln_child_cp_id3
             FROM  fnd_concurrent_requests fcr
             WHERE fcr.request_id =ln_conc_req_id3;
      EXCEPTION 
      WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Child id '||ln_child_cp_id3 );
          ln_child_cp_id3 :=null;
       END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id3,
          ln_conc_req_id3 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
      
  COMMIT;
 END LOOP;
  
    CLOSE lcu_cust_accts_adj;
   
   FOR i IN ln_req_id.FIRST..ln_req_id.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		 	IF upper(lc_status) = 'ERROR' THEN
                      lc_flag :='Y';
                   	  fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	   fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
		           fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		        END IF;
		END IF;
  	END LOOP;
--------------------------------------------------------------------------------------
--Submit the Program for the Payment Schedules  Daily Conversion
--------------------------------------------------------------------------------------

IF lc_flag = 'N' THEN 
 ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
 
  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_WC_STG';
  
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_PAYMENT_SCHEDULE'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_PAYMENT_SCHEDULE');
  end;
  
     OPEN lcu_cust_accts_ps(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_ps
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_ps%NOTFOUND;
    

      ln_conc_req_id4 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARFPSWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE 
                                       ,argument1   => ln_from_cust_account_id 
                                       ,argument2   => ln_to_cust_account_id 
                                       ,argument3   => p_batch_limit 
                                       ,argument4   => p_compute_stats 
                                       ,argument5   => p_debug );
                                       
                                      
      IF ln_conc_req_id4=0 THEN
               fnd_file.put_line(fnd_file.log,'Child Program is not submitted');
      ELSE

	  	ln_req_id1(ln_idx):=  ln_conc_req_id4 ;
		  ln_idx           := ln_idx+1;
	    END IF;
                 
                                
 
      BEGIN
             SELECT fcr.concurrent_program_id
             INTO   ln_child_cp_id4
             FROM  fnd_concurrent_requests fcr
             WHERE fcr.request_id =ln_conc_req_id4;
      EXCEPTION 
      WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Child id '||ln_child_cp_id4 );
          ln_child_cp_id4 :=null;
       END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id4,
          ln_conc_req_id4 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
      
COMMIT;
 END LOOP;
   
  CLOSE lcu_cust_accts_ps;
   
    FOR i IN ln_req_id.FIRST..ln_req_id.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		 	IF UPPER(lc_status) = 'ERROR' THEN
                   	  fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	   fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
		           fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		        END IF;
		end if;
  	END LOOP;    
--------------------------------------------------------------------------------------
--Submit the Program for the Receivable Applications  Daily Conversion
--------------------------------------------------------------------------------------

 ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
 
 EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RECAPPL_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_RECEIVABLE_APP'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_RECEIVABLE_APP');
  END;
  
    OPEN lcu_cust_accts_ra(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_ra
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_ra%NOTFOUND;
    

      ln_conc_req_id5 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARFRAWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE 
                                       ,argument1   => ln_from_cust_account_id 
                                       ,argument2   => ln_to_cust_account_id 
                                       ,argument3   => ln_batch_limit 
                                       ,argument4   => lc_compute_stats
                                       ,argument5   => p_debug );
                                       
                                      
      IF ln_conc_req_id5=0 THEN
               fnd_file.put_line(fnd_file.log,'Child Program is not submitted');
      ELSE

	  	ln_req_id1(ln_idx):=  ln_conc_req_id5 ;
		ln_idx            :=  ln_idx+1;
	  END IF;
                                
 
      BEGIN
             SELECT fcr.concurrent_program_id
             INTO   ln_child_cp_id5
             FROM  fnd_concurrent_requests fcr
             WHERE fcr.request_id =ln_conc_req_id5;
      EXCEPTION 
      WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Child id '||ln_child_cp_id5 );
          ln_child_cp_id5 :=null;
       END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id5,
          ln_conc_req_id5 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
      
  COMMIT;
 END LOOP;
CLOSE lcu_cust_accts_ra;
   
    FOR i IN ln_req_id1.FIRST..ln_req_id1.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id1(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		 	IF UPPER(lc_status) = 'ERROR' THEN
                   	  fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	   fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
		           fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		        END IF;
		end if;
  	END LOOP;    
END IF;
------------------------------------------------------------------------------------------------ 
--For Incremental Program
------------------------------------------------------------------------------------------------ 
ELSIF P_ACTION_TYPE ='I' THEN
  
  BEGIN 
  
    SELECT MAX(program_run_date)
    INTO   ld_last_run_date1
    FROM   XX_CRMAR_INT_LOG
    WHERE program_name='OD: AR Transaction Extract to WebCollect Program'  AND status    ='SUCCESS';
    SELECT MAX(program_run_date)
    INTO   ld_last_run_date2
    FROM   XX_CRMAR_INT_LOG
    WHERE  program_name='OD: AR Payment Schedules Extract to WebCollect Program'  AND status    ='SUCCESS';
    SELECT max(program_run_date) 
    INTO   ld_last_run_date3
    FROM   XX_CRMAR_INT_LOG
    WHERE  program_name='OD: AR Cash Receipts Extract to WebCollect Program'  AND status    ='SUCCESS';
    select  max(program_run_date)
    INTO   ld_last_run_date4
    FROM    XX_CRMAR_INT_LOG
    WHERE   program_name='OD: AR Receivables Application Extract to WebCollect Program'  and status    ='SUCCESS';
    SELECT  MAX(program_run_date)
    INTO   ld_last_run_date5
    FROM    XX_CRMAR_INT_LOG
    WHERE   program_name='OD: AR Adjustments Extract to WebCollect Program'   AND status    ='SUCCESS';
  
  END;  
--------------------------------------------------------------------------------------
--Submit the Program for the Transactions for Daily Delta
--------------------------------------------------------------------------------------
ln_batch_limit :=0;
ln_threads:=0;
lc_compute_stats:='N';
 EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_TRANS_WC_STG';

 BEGIN
   SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_TRANS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'For Transalation Definition is not returning record for AR_TRANS');
 END;
 
  OPEN lcu_cust_accts_txn(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_txn
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_txn%NOTFOUND;
    
   
      ln_conc_req_id1 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARDTXNWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE
                                       ,argument1   => ld_last_run_date5
                                       ,argument2   => p_to_run_date 
                                       ,argument3  => ln_from_cust_account_id 
                                       ,argument4   => ln_to_cust_account_id 
                                       ,argument5   => p_batch_limit 
                                       ,argument6   => p_compute_stats 
                                       ,argument7   => p_debug );
                                       
                                       
           
      IF ln_conc_req_id1=0 THEN
         fnd_file.put_line(fnd_file.log,'Child Program is not submitted for AR Transactions Daily Delta');
      ELSE

	  	ln_req_id(ln_idx):= ln_conc_req_id1;
		  ln_idx           := ln_idx+1;
	  END IF;
        
  
      
      BEGIN
        SELECT  fcr.concurrent_program_id
        INTO    ln_child_cp_id1
        FROM    fnd_concurrent_requests fcr
        where   fcr.request_id =ln_conc_req_id1;
     EXCEPTION 
        WHEN OTHERS THEN
              fnd_file.put_line (fnd_file.log, 'Child id '||  ln_child_cp_id1);
          ln_child_cp_id1 :=null;
      END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id1 ,
          ln_conc_req_id1 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
        
        COMMIT;
		END LOOP;
CLOSE lcu_cust_accts_txn;
--------------------------------------------------------------------------------------
--Submit the Program for the Cash Receipt for Daily Delta
--------------------------------------------------------------------------------------
ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_CR_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_CASH_RECEIPTS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_CASH_RECEIPTS');
  END;
    
 OPEN lcu_cust_accts_cr(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_cr
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_cr%NOTFOUND;
    
    
    
      ln_conc_req_id2 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARDCRWC' 
                                           ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE
                                       ,argument1   => ld_last_run_date5
                                       ,argument2   => p_to_run_date 
                                       ,argument3  => ln_from_cust_account_id 
                                       ,argument4   => ln_to_cust_account_id 
                                       ,argument5   => p_batch_limit 
                                       ,argument6   => p_compute_stats 
                                       ,argument7   => p_debug );
                                       
                                       
           
     IF ln_conc_req_id2=0 THEN
           fnd_file.put_line(fnd_file.log,'Child Program is not submitted for Cash Receipt  Daily Delta');
     ELSE

	  	ln_req_id(ln_idx):= ln_conc_req_id2;
		  ln_idx           := ln_idx+1;
	 END IF;
        
      
      BEGIN
        SELECT  fcr.concurrent_program_id
        INTO    ln_child_cp_id2
        FROM    fnd_concurrent_requests fcr
        WHERE   fcr.request_id =ln_conc_req_id2;
     EXCEPTION 
        WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log, 'Child id '||  ln_child_cp_id2);
          ln_child_cp_id2 :=null;
      END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id2 ,
          ln_conc_req_id2 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
        
        COMMIT;
		END LOOP;
		
CLOSE lcu_cust_accts_cr;
--------------------------------------------------------------------------------------
--Submit the Program for the Adjustments for Daily Delta
--------------------------------------------------------------------------------------      
 ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_ADJ_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_ADJUSTMENTS'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_ADJUSTMENTS');
  END;
  
  OPEN lcu_cust_accts_cr(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_cr
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_cr%NOTFOUND;
    
    
    
      ln_conc_req_id3 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARDADJWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE
                                       ,argument1   => ld_last_run_date5
                                       ,argument2   => p_to_run_date 
                                       ,argument3  => ln_from_cust_account_id 
                                       ,argument4   => ln_to_cust_account_id 
                                       ,argument5   => p_batch_limit 
                                       ,argument6   => p_compute_stats 
                                       ,argument7   => p_debug );
                                       
                                       
           
      IF ln_conc_req_id3=0 THEN
           fnd_file.put_line(fnd_file.log,'Child Program is not submitted for Adjustments Daily Delta');
      ELSE

	      ln_req_id(ln_idx):= ln_conc_req_id3;
		  ln_idx           := ln_idx+1;
	  END IF;
        
    
      
      BEGIN
        SELECT  fcr.concurrent_program_id
        INTO    ln_child_cp_id3
        FROM    fnd_concurrent_requests fcr
        where   fcr.request_id =ln_conc_req_id3;
     EXCEPTION 
        WHEN OTHERS THEN
              fnd_file.put_line (fnd_file.log, 'Child id '||  ln_child_cp_id3);
          ln_child_cp_id3 :=null;
      END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id3 ,
          ln_conc_req_id3 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
        
        COMMIT;
       END LOOP;
	   
CLOSE lcu_cust_accts_adj;

   FOR i IN ln_req_id.FIRST..ln_req_id.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		        IF UPPER(LC_STATUS) = 'ERROR' THEN
                        	 lc_flag :='Y';
                   	     fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	     fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
					
		                 fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		        END IF;
		END IF;
  	END LOOP; 
	
 --------------------------------------------------------------------------------------
--Submit the Program for the Payment Schedules for Daily Delta
--------------------------------------------------------------------------------------

IF lc_flag='Y' THEN 
       
 ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
 EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_PS_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_PAYMENT_SCHEDULE'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_PAYMENT_SCHEDULE');
END;

    OPEN lcu_cust_accts_ps(ln_threads);
    LOOP
      FETCH
        lcu_cust_accts_ps
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      EXIT
    WHEN lcu_cust_accts_ps%NOTFOUND;
    
    
    
      ln_conc_req_id4 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARDPSWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE
                                       ,argument1   => ld_last_run_date5
                                       ,argument2   => p_to_run_date 
                                       ,argument3  => ln_from_cust_account_id 
                                       ,argument4   => ln_to_cust_account_id 
                                       ,argument5   => p_batch_limit 
                                       ,argument6   => p_compute_stats 
                                       ,argument7   => p_debug );
                                       
           
      IF ln_conc_req_id4=0 THEN
           fnd_file.put_line(fnd_file.log,'Child Program is not submitted for Payment Schedules Daily Delta');
      ELSE

	      ln_req_id1(ln_idx):= ln_conc_req_id4;
		  ln_idx           := ln_idx+1;
	  END IF;
        
        
     
      
      BEGIN
        SELECT  fcr.concurrent_program_id
        INTO    ln_child_cp_id4
        FROM    fnd_concurrent_requests fcr
        WHERE   fcr.request_id =ln_conc_req_id4;
     EXCEPTION 
        WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log, 'Child id '||  ln_child_cp_id4);
          ln_child_cp_id4 :=null;
      END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id4 ,
          ln_conc_req_id4 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
        
        COMMIT;
        
     END LOOP;   
	 
	 CLOSE lcu_cust_accts_ps;
 --------------------------------------------------------------------------------------
--Submit the Program for the Receivable Application for Daily Delta
--------------------------------------------------------------------------------------  
ln_batch_limit :=0;
 ln_threads:=0;
 lc_compute_stats:='N';
 EXECUTE IMMEDIATE 'TRUNCATE TABLE XXFIN.XX_AR_RA_WC_STG';
BEGIN
    SELECT xftv.target_value1
          ,xftv.target_value3
          ,xftv.target_value6
    INTO    ln_batch_limit,ln_threads,lc_compute_stats
        FROM xx_fin_translatevalues XFTV
            ,xx_fin_translatedefinition XFTD
       WHERE XFTV.translate_id    = XFTD.translate_id
         AND XFTD.translation_name = 'XXOD_WEBCOLLECT_INTERFACE'
         AND XFTV.source_value1 = 'AR_RECEIVABLE_APP'
         AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
         AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
         AND XFTV.enabled_flag = 'Y'
         AND XFTD.enabled_flag = 'Y';

  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   fnd_file.put_line (fnd_file.log,'No records in the Transalation Definition for AR_RECEIVABLE_APP');
  END;
  
    OPEN lcu_cust_accts_ra(ln_threads);
    LOOP
      fetch
        lcu_cust_accts_ra
      INTO
        ln_from_cust_account_id,
        ln_to_cust_account_id,
        ln_thread_num;
      exit
    WHEN lcu_cust_accts_ra%NOTFOUND;

      ln_conc_req_id5 := fnd_request.submit_request(
                                        application => 'XXFIN' 
                                       , program => 'XXARDRAWC' 
                                       ,description => '' 
                                       ,start_time  => SYSDATE
                                       ,sub_request => FALSE
                                       ,argument1   => ld_last_run_date5
                                       ,argument2   => p_to_run_date 
                                       ,argument3  => ln_from_cust_account_id 
                                       ,argument4   => ln_to_cust_account_id 
                                       ,argument5   => p_batch_limit 
                                       ,argument6   => p_compute_stats 
                                       ,argument7   => p_debug );
                                       
           
      IF ln_conc_req_id5=0 then
           fnd_file.put_line(fnd_file.log,'Child Program is not submitted for Receivable Application Daily Delta');
      ELSE

	      ln_req_id1(ln_idx):= ln_conc_req_id5;
		  ln_idx           := ln_idx+1;
	  END IF;
        
        
     
      
      BEGIN
        select  fcr.concurrent_program_id
        INTO    ln_child_cp_id5
        FROM    fnd_concurrent_requests fcr
        where   fcr.request_id =ln_conc_req_id5;
     EXCEPTION 
        WHEN OTHERS THEN
          fnd_file.put_line (fnd_file.log, 'Child id '||  ln_child_cp_id5 );
          ln_child_cp_id5 :=null;
      END;
      
      INSERT
      INTO
        XX_AR_EXT_WC_MASTER_DETAILS VALUES
        (
          v_ext_wc_s,ln_batch ,
          ln_parent_cp_id ,
          ln_parent_request_id ,
          P_no_of_threads,
          NULL , ---child_program_name  ,
          ln_child_cp_id5 ,
          ln_conc_req_id5 ,
          ln_from_cust_account_id ,
          ln_to_cust_account_id ,
          p_last_run_date ,
          p_to_run_date ,
          lc_dev_status ,
          ln_user_id ,
          sysdate,
          ln_user_id,
          sysdate
        ) ;
        
        COMMIT;
        
     END LOOP;   
	 
CLOSE lcu_cust_accts_ra;
	 
   FOR i IN ln_req_id1.FIRST..ln_req_id1.LAST
	 LOOP

		 IF apps.fnd_concurrent.wait_for_request( ln_req_id1(i), 30, 0, lc_phase,
                                    lc_status, lc_dev_phase, lc_dev_status, lc_message)
	         THEN
		 	IF upper(lc_status) = 'ERROR' then
                    
                   	    fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with error');
                        ELSIF UPPER(lc_status) = 'WARNING' THEN
                   	    fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed with warning');
                        ELSE
		                fnd_file.put_line(fnd_file.LOG,'Thread '||i||' completed normal');
 		    END IF;
		END IF;
  	END LOOP; 
	
END IF;
-------------------------------------------------------------------------------------
--End 
--------------------------------------------------------------------------------------  
  COMMIT;
    
  END IF; --action type end if 
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  gc_error_debug:=SQLERRM||
  'NO data found ';
  fnd_file.put_line
  (
    fnd_file.LOG, gc_error_loc||gc_error_debug
  )
  ;
WHEN OTHERS THEN
  gc_error_debug:=SQLERRM||
  'Others exception is raised in the Invoice Master Interface';
  fnd_file.put_line
  (
    fnd_file.LOG, gc_error_loc||gc_error_debug
  )
  ;
END;
END XX_AR_EXT_WC_MASTER_PKG;
/
SHOW ERRORS
