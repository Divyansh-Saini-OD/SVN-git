create or replace PACKAGE BODY      XX_C2T_CNV_CC_TOKEN_OM_PKG
	AS
	  -- +=====================================================================================================+
	  ---|                              Office Depot                                                           |
	  -- +=====================================================================================================+
	  -- |  Name:  XX_C2T_CNV_CC_TOKEN_OM_PKG                                                                  |
	  -- |                                                                                                     |
	  -- |  Description: Pre-Processing Credit Cards for OE Payments, Deposits and Returns                     |
	  -- |                                                                                                     |
	  -- |  Rice ID:     C0705                                                                                 |
	  -- +=====================================================================================================+
	  -- | Version     Date         Author               Remarks                                               |
	  -- | =========   ===========  =============        ======================================================|
	  ---|  1.0        17-SEP-2015  Havish Kasina        Initial Version for Payments and Deposits             |
    ---|  1.1        28-SEP-2015  Manikant Kasu        Initial Version for Returns                           |
    ---|  1.2        05-FEB-2016  Manikant Kasu        Made changes to the log messages and logging decrypted|
    ---|                                               credit card info                                      |  
	  -- +=====================================================================================================+
    gc_debug                   VARCHAR2(1)        := 'N';
    gc_req_data                VARCHAR2(240)      := NULL;
    gn_parent_request_id       NUMBER(15)         := FND_GLOBAL.CONC_REQUEST_ID;
    gn_parent_cp_id            NUMBER;
    gn_child_cp_id             NUMBER;
    gc_child_prog_name         fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
    gc_error_loc               VARCHAR2(4000)     := NULL;
	  gc_error_debug             VARCHAR2(4000);
    gn_user_id                 NUMBER             := FND_GLOBAL.USER_ID;
	  gn_login_id                NUMBER             := FND_GLOBAL.LOGIN_ID;
  -- +====================================================================+
  -- | Name       : PRINT_TIME_STAMP_TO_LOGFILE                           |
  -- |                                                                    |
  -- | Description: This procedure is used to print the time to the log   |
  -- |                                                                    |
  -- | Parameters : none                                                  |
  -- |                                                                    |
  -- | Returns    : none                                                  |
  -- +====================================================================+
  PROCEDURE print_time_stamp_to_logfile
  IS
  BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,chr(10)||'*** Current system time is '||
                            TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')||' ***'||chr(10));
  END print_time_stamp_to_logfile;
  
  -- +===================================================================+
  -- | PROCEDURE  : LOCATION_AND_LOG                                     |
  -- |                                                                   |
  -- | DESCRIPTION: Performs the following actions based on parameters   |
  -- |              1. Sets gc_error_location                            |
  -- |              2. Writes to log file if debug is on                 |
  -- |                                                                   |
  -- | PARAMETERS : p_debug_msg                                          |
  -- |                                                                   |
  -- | RETURNS    : None                                                 |
  -- +===================================================================+
  PROCEDURE location_and_log (p_debug           IN  VARCHAR2,
                              p_debug_msg       IN  VARCHAR2
                              )
  IS
  BEGIN
      gc_error_loc := p_debug_msg;   -- set error location

      IF p_debug = 'Y' THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG, gc_error_loc);
      END IF;

  END LOCATION_AND_LOG;
    	
	-- +===================================================================+
	-- | PROCEDURE  : XX_EXIT_PROGRAM_CHECK                                |
	-- |                                                                   |
	-- | DESCRIPTION: Performs the following actions based on parameters   |
	-- |              1. Sets p_program_name: Checks if the program needs  |
  -- |                 to be stoped. 	                                   |
	-- |                                                                   |
	-- | PARAMETERS : p_program_name                                       |
	-- |                                                                   |
	-- | RETURNS    : x_exit_prog_flag                                     |
	-- +===================================================================+
	PROCEDURE xx_exit_program_check(   p_program_name    IN  VARCHAR2
                                   , x_exit_prog_flag  OUT VARCHAR2
                                 )
	IS
	BEGIN
        SELECT    NVL(xftv.target_value1,'N')
          INTO    x_exit_prog_flag
          FROM    xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
         WHERE    xftd.translate_id = xftv.translate_id
           AND    xftd.translation_name = 'XX_PROGRAM_CONTROL'
           AND    xftv.source_value1 = p_program_name
           AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+ 1)
           AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,SYSDATE+ 1)
           AND    xftv.enabled_flag = 'Y'
           AND    xftd.enabled_flag = 'Y';
		   
  EXCEPTION
    WHEN OTHERS 
    THEN
       x_exit_prog_flag := 'N'; 
	     gc_error_loc := 'WHEN OTHERS EXCEPTION of XX_LOCATION_AND_LOG :: '||SQLERRM;	
  END xx_exit_program_check;
	
---OE Payments	
  
 -- +====================================================================+
 -- | Name       : prepare_pmts_master                                   |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads           IN                          |
 -- |              p_processing_type         IN                          |
 -- |              p_recreate_child_thrds    IN                          |
 -- |              p_batch_size              IN                          |  
 -- |              p_debug_flag              IN                          |
 -- | Returns    : x_errbuf                  OUT                         |
 -- |              x_retcode                 OUT                         |
 -- |                                                                    |
 -- +====================================================================+
 PROCEDURE prepare_pmts_master(       x_errbuf                   OUT NOCOPY   VARCHAR2
                                     ,x_retcode                  OUT NOCOPY   NUMBER
                                     ,p_child_threads            IN           NUMBER        
                                     ,p_processing_type          IN           VARCHAR2      
                                     ,p_recreate_child_thrds     IN           VARCHAR2      
                                     ,p_batch_size               IN           NUMBER  
                                     ,p_debug_flag               IN           VARCHAR2									 
		                          )
	IS    
    --Cursor Declaration
    --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_OE_PMT
	  CURSOR prep_threads_oe_pmt_cur	
	  IS
      SELECT  MIN(X.oe_payment_id)    min_oe_payment_id
            , MAX(X.oe_payment_id)    max_oe_payment_id
            , X.thread_num            thread_num
            , COUNT(1)                total_count
        FROM (SELECT /*+ full(OE_PMT) parallel(OE_PMT,8) */ 
                     OE_PMT.oe_payment_id
                   , NTILE(p_child_threads) OVER(ORDER BY OE_PMT.oe_payment_id) THREAD_NUM
                FROM xx_c2t_cc_token_stg_oe_pmt OE_PMT) X
      GROUP BY X.thread_num
      ORDER BY X.thread_num;
	  
	  --Cursor to get the data from XX_C2T_PREP_THREADS_OE_PMT
	  CURSOR get_threads_oe_pmt_cur	
	  IS
      SELECT /*+ parallel(a,8) */ a.*
		    FROM xx_c2t_prep_threads_oe_pmt a
       WHERE a.last_oe_payment_id < a.max_oe_payment_id;
       
    TYPE r_prep_threads_oe_pmt 
    IS
      RECORD ( min_oe_payment_id         NUMBER,
               max_oe_payment_id         NUMBER,
               thread_num                NUMBER,
               total_count               NUMBER);
               
    TYPE t_prep_threads_oe_pmt
    IS
      TABLE OF r_prep_threads_oe_pmt INDEX BY BINARY_INTEGER;
      
    TYPE t_get_prep_threads_oe_pmt
    IS
      TABLE OF xx_c2t_prep_threads_oe_pmt%ROWTYPE INDEX BY BINARY_INTEGER;
         
    --Local Variable Declaration
    l_get_prep_threads_oe_pmt     t_get_prep_threads_oe_pmt;
    l_prep_threads_oe_pmt         t_prep_threads_oe_pmt;
    ln_thread_cnt                 NUMBER := 0;
    EX_PROGRAM_INFO               EXCEPTION;
    EX_REQUEST_NOT_SUBMITTED      EXCEPTION;
    EX_NO_SUB_REQUESTS            EXCEPTION;
    ln_conc_req_id                NUMBER;
    ln_idx                        NUMBER := 1;
    ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
    ln_success_cnt                NUMBER := 0;
    ln_error_cnt                  NUMBER := 0;
    ln_retcode                    NUMBER := 0;  
    l_err_count                   NUMBER := 0;
    ln_error_idx                  NUMBER := 0;
    lc_error_msg                  VARCHAR2(4000);
    lc_conc_short_name            VARCHAR2(50) := 'XX_C2T_OM_PMT_PREP_CHILD';
    
	BEGIN
	   gc_debug := p_debug_flag;
         --========================================================================
      -- Initialize Processing
      --========================================================================
      gc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
      location_and_log(gc_debug, ' ########## gc_req_data :: '||gc_req_data);

    IF gc_req_data IS NULL 
    THEN
            location_and_log(gc_debug,'Processing Master Program'||chr(10));
         -------------------------------------------------
         -- Print Parameter Names and Values to Log File
         -------------------------------------------------

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Recreate Child Threads     : ' || p_recreate_child_thrds);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
		      	FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');

      print_time_stamp_to_logfile;
      
         --========================================================================
         -- Retrieve and Print Program Information to Log File
         --========================================================================
         location_and_log (gc_debug,'Retrieve Program IDs for Master and Child.' || CHR (10));

         BEGIN
            location_and_log (gc_debug,'Retrieve Program ID for Master');

            SELECT concurrent_program_id
              INTO gn_parent_cp_id
              FROM fnd_concurrent_requests fcr
             WHERE fcr.request_id = gn_parent_request_id;

            location_and_log (gc_debug,'     Retrieve Program Info for Child');

            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO gn_child_cp_id
                  ,gc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = lc_conc_short_name;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '***************************** PROGRAM INFORMATION ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Program ID      : ' || gn_parent_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program ID       : ' || gn_child_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program Name     : ' || gc_child_prog_name);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE EX_PROGRAM_INFO;
         END;  -- print program information

         print_time_stamp_to_logfile;
         
         IF UPPER (p_processing_type) = 'ERROR' 
         THEN 
            -------------------------------------
            -- Derive Child Thread Ranges - ERROR
            -------------------------------------          
            location_and_log (gc_debug,'Processing Type = "ERROR"' || CHR (10));
                 
                  location_and_log (gc_debug,'     FULL - Before the Loop');
                  LOOP
                    location_and_log(gc_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;
                     ---------------------------------------------------------
                     -- Submit Child Requests - ERROR
                     ---------------------------------------------------------
                     location_and_log (gc_debug,'     FULL - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => ln_thread_cnt
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => NULL 
                                                   ,argument5        => NULL 
                                                   ,argument6        => p_batch_size
												   ,argument7        => p_debug_flag
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug,'     Child Program is not submitted');
                        x_retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;  
                      ELSE
                        COMMIT;
                        location_and_log (gc_debug,'     Able to submit the Child Program');
                     END IF;
                     EXIT WHEN (ln_thread_cnt = p_child_threads); 
                  END LOOP;
                  
         ELSIF UPPER (p_processing_type) = 'ALL' 
          THEN
              IF p_recreate_child_thrds = 'Y' 
              THEN
	   
                    location_and_log( gc_debug,'TRUNCATE TABLE XX_C2T_PREP_THREADS_OE_PMT ');
                    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_OE_PMT';
		 
                    --***************************************************************************************
                    --INSERTING new values in table XX_C2T_PREP_THREADS_OE_PMT
                    --***************************************************************************************
		 
                    location_and_log( gc_debug,' Retriving records for inserting in XX_C2T_PREP_THREADS_OE_PMT table ');
                    OPEN prep_threads_oe_pmt_cur;
                    LOOP
                       FETCH prep_threads_oe_pmt_cur BULK COLLECT
                       INTO l_prep_threads_oe_pmt;
		 
                    location_and_log( gc_debug,'Inserting Data in table XX_C2T_PREP_THREADS_OE_PMT ');
                    BEGIN
                      FORALL i IN 1 .. l_prep_threads_oe_pmt.COUNT
		                  SAVE EXCEPTIONS
		  
                        INSERT INTO xx_c2t_prep_threads_oe_pmt
                        (
                                min_oe_payment_id
                              , max_oe_payment_id 
                              , thread_num
                              , total_count                              
                              , creation_date
                              , last_update_date
                              , last_oe_payment_id
                              )
                        VALUES
                        (
                                l_prep_threads_oe_pmt(i).min_oe_payment_id    --min_oe_payment_id
                              , l_prep_threads_oe_pmt(i).max_oe_payment_id    --max_oe_payment_id
                              , l_prep_threads_oe_pmt(i).thread_num           --thread_num
                              , l_prep_threads_oe_pmt(i).total_count          --total_count
                              , SYSDATE                                       --creation_date  
                              , SYSDATE                                       --last_update_date  
                              , l_prep_threads_oe_pmt(i).min_oe_payment_id    --last_oe_payment_id              
                        );
			
                       COMMIT;
                       EXIT WHEN prep_threads_oe_pmt_cur%NOTFOUND;
                    EXCEPTION
		                WHEN OTHERS 
                    THEN
		                   l_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		                   FOR i IN 1 .. l_err_count
		                   LOOP
			                    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			                    lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to insert value in XX_C2T_PREP_THREADS_OE_PMT' 
                                         || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
			                    location_and_log( gc_debug, ' BULK ERROR:: MAX Payment ID : '|| l_prep_threads_oe_pmt (ln_error_idx).max_oe_payment_id ||
                                                ':: MIN Payment ID : '|| l_prep_threads_oe_pmt (ln_error_idx).min_oe_payment_id ||
                                                ':: Error Message : '||lc_error_msg);
		                   END LOOP;   -- bulk_err_loop FOR INSERT

                    END;-- BEGIN Inserting Data in table XX_C2T_PREP_THREADS_OE_PMT
                    END LOOP;	-- 	 Main Loop in prep_threads_oe_pmt_cur Cursor
                CLOSE prep_threads_oe_pmt_cur;
              END IF; --p_recreate_child_thrds = 'Y'
              
        --***************************************************************************************
        --Retrieve incomplete batches, from XX_C2T_PREP_THREADS_OE_PMT table
        -- and then calling child program based on Child Thread
        --***************************************************************************************
		    BEGIN
             location_and_log( gc_debug, ' Retriving records from XX_C2T_PREP_THREADS_OE_PMT table ');
             OPEN get_threads_oe_pmt_cur;
               FETCH get_threads_oe_pmt_cur BULK COLLECT INTO l_get_prep_threads_oe_pmt;
		           
               FOR i IN 1..l_get_prep_threads_oe_pmt.COUNT
               LOOP
               location_and_log( gc_debug, ' STARTING FOR LOOP');
				 
               location_and_log( gc_debug,TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') 
                                     ||':: Submitting Child Program Request for THREAD :: '||l_get_prep_threads_oe_pmt(i).thread_num
                                    );
	                                                          
              ---------------------------------------------------------
              -- Submit Child Requests - ALL
              ---------------------------------------------------------
               location_and_log (gc_debug,'     FULL - Submitting Child Request');
               ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => NULL
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => l_get_prep_threads_oe_pmt(i).last_oe_payment_id 
                                                   ,argument5        => l_get_prep_threads_oe_pmt(i).max_oe_payment_id 
                                                   ,argument6        => p_batch_size   
                                                   ,argument7        => p_debug_flag												   
                                                   );

                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || l_get_prep_threads_oe_pmt(i).thread_num);
                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                 IF ln_conc_req_id = 0
                 THEN
                   location_and_log (gc_debug,'     Child Program is not submitted');
                   x_retcode := 2;
                   RAISE EX_REQUEST_NOT_SUBMITTED;  
                   ELSE
                     COMMIT;
                   location_and_log (gc_debug,'     Able to submit the Child Program');
                END IF;
           END LOOP; 
          CLOSE get_threads_oe_pmt_cur;
		    END;
                            
        END IF; --p_processing_type ='ALL'           
                  
         location_and_log ( gc_debug,'     FULL - After the Loop');
         location_and_log(gc_debug,'     Pausing MASTER Program......'||chr(10));
         FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                         request_data => 'CHILD_REQUESTS');
        
      ELSE
                  
         location_and_log(gc_debug,'     Restarting after CHILD_REQUESTS Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests 
         --========================================================================
         BEGIN
            location_and_log (gc_debug,'Post-processing for Child Requests' || CHR (10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_parent_request_id);

            location_and_log(gc_debug,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 
            THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  location_and_log(gc_debug,'     ltab_child_requests(i).request_id : '||ltab_child_requests(i).request_id);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_phase  : '||ltab_child_requests(i).dev_phase);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_status : '||ltab_child_requests(i).dev_status);

                  IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                     ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                  THEN
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_success_cnt := ln_success_cnt + 1;
                     x_retcode      := 0;
                  ELSE
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_error_cnt := ln_error_cnt + 1;
                     x_retcode    := 2;
                  END IF;

                  SELECT GREATEST (x_retcode, ln_retcode)
                    INTO ln_retcode
                    FROM DUAL;

               END LOOP; -- Checking Child Requests 
               
              ELSE
                 RAISE EX_NO_SUB_REQUESTS;
              END IF; -- retrieve child requests

            location_and_log (gc_debug,'     Captured Return Code for Master and Control Table Status');
            x_retcode := ln_retcode;

         END;  -- post processing for child requests

         print_time_stamp_to_logfile;
                                                  
    END IF;    
         
 EXCEPTION
     WHEN EX_PROGRAM_INFO 
     THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_PROGRAM_INFO at: ' || gc_error_loc);
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unable to get the Parent and Child Concurrent Names ');
          print_time_stamp_to_logfile;
          x_retcode := 2;
         
     WHEN EX_REQUEST_NOT_SUBMITTED 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_REQUEST_NOT_SUBMITTED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Unable to submit child request.');
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Rollback completed.');
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN EX_NO_SUB_REQUESTS 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_SUB_REQUESTS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN NO_DATA_FOUND 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;

     WHEN OTHERS 
     THEN
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;
 END prepare_pmts_master;
 
 -- +====================================================================+
 -- | Name       : prepare_pmts_child                                    |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads       IN                              |
 -- |              p_child_thread_num    IN                              |
 -- |              p_processing_type     IN                              |
 -- |              p_min_oe_payment_id   IN                              |
 -- |              p_max_oe_payment_id   IN                              |
 -- |              p_batch_size          IN                              |  
 -- |              p_debug_flag          IN                              |
 -- | Returns    : x_errbuf              OUT                             |
 -- |              x_retcode             OUT                             |
 -- |                                                                    |
 -- +====================================================================+
 
 PROCEDURE prepare_pmts_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                  ,x_retcode                  OUT NOCOPY   NUMBER
                                  ,p_child_threads            IN           NUMBER
                                  ,p_child_thread_num         IN           NUMBER
                                  ,p_processing_type          IN           VARCHAR2 
                                  ,p_min_oe_payment_id        IN           NUMBER
                                  ,p_max_oe_payment_id        IN           NUMBER
                                  ,p_batch_size               IN           NUMBER
                                  ,p_debug_flag               IN           VARCHAR2								  
                               )
 IS
 
 --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_OE_PMT
	  CURSOR get_cc_token_stg_oe_pmt_cur   
	  IS
      SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_OE_PMT_U1)*/ 
             a.oe_payment_id
            ,a.credit_card_number_orig
						,a.key_label_orig 
            ,a.re_encrypt_status
            ,a.error_action
            ,a.error_message
            ,a.credit_card_number_new
            ,a.key_label_new
            ,a.last_update_date
            ,a.last_updated_by
            ,a.last_update_login
		    FROM xx_c2t_cc_token_stg_oe_pmt a
       WHERE DECODE (UPPER (p_processing_type), 'ALL', 1, 2) = 1
         AND oe_payment_id >= p_min_oe_payment_id
         AND oe_payment_id <= p_max_oe_payment_id
         AND (re_encrypt_status IS NULL OR re_encrypt_status <> 'C')
       UNION         
      SELECT OE_PMT.oe_payment_id
            ,OE_PMT.credit_card_number_orig
						,OE_PMT.key_label_orig 
            ,OE_PMT.re_encrypt_status
            ,OE_PMT.error_action
            ,OE_PMT.error_message
            ,OE_PMT.credit_card_number_new
            ,OE_PMT.key_label_new
            ,OE_PMT.last_update_date
            ,OE_PMT.last_updated_by
            ,OE_PMT.last_update_login
        FROM (SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_OE_PMT_N1)*/ 
                      X.oe_payment_id
                     ,X.credit_card_number_orig
                     ,X.key_label_orig 
                     ,X.re_encrypt_status
                     ,X.error_action
                     ,X.error_message
                     ,X.credit_card_number_new
                     ,X.key_label_new
                     ,X.last_update_date
                     ,X.last_updated_by
                     ,X.last_update_login
                     ,NTILE(p_child_threads) OVER(ORDER BY X.oe_payment_id) THREAD_NUM
                FROM xx_c2t_cc_token_stg_oe_pmt X
              WHERE 1 =1 
                AND DECODE (UPPER (p_processing_type), 'ERROR', 1, 2) = 1
                AND X.re_encrypt_status IS NOT NULL 
                AND X.re_encrypt_status = 'E' ) OE_PMT
              WHERE OE_PMT.THREAD_NUM = p_child_thread_num
        ;
        
    TYPE r_cc_token_stg_oe_pmt 
    IS
      RECORD ( oe_payment_id                 xx_c2t_cc_token_stg_oe_pmt.oe_payment_id%TYPE,
               credit_card_number_orig       xx_c2t_cc_token_stg_oe_pmt.credit_card_number_orig%TYPE,
               key_label_orig                xx_c2t_cc_token_stg_oe_pmt.key_label_orig%TYPE,
               re_encrypt_status             xx_c2t_cc_token_stg_oe_pmt.re_encrypt_status%TYPE,
               error_action                  xx_c2t_cc_token_stg_oe_pmt.error_action%TYPE,
               error_message                 xx_c2t_cc_token_stg_oe_pmt.error_message%TYPE,
               credit_card_number_new        xx_c2t_cc_token_stg_oe_pmt.credit_card_number_new%TYPE,
               key_label_new                 xx_c2t_cc_token_stg_oe_pmt.key_label_new%TYPE,
               last_update_date              xx_c2t_cc_token_stg_oe_pmt.last_update_date%TYPE,
               last_updated_by               xx_c2t_cc_token_stg_oe_pmt.last_updated_by%TYPE,
               last_update_login             xx_c2t_cc_token_stg_oe_pmt.last_update_login%TYPE);
	   
	  TYPE t_cc_token_stg_oe_pmt	
	  IS
	  TABLE OF r_cc_token_stg_oe_pmt INDEX BY BINARY_INTEGER;
    
    -- Local Variables
    l_cc_token_stg_oe_pmt       t_cc_token_stg_oe_pmt;
    ln_last_oe_payment_id       xx_c2t_prep_threads_oe_pmt.last_oe_payment_id%TYPE;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	  ln_err_count                NUMBER          := 0;
	  ln_error_idx                NUMBER          := 0;
	  lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    lc_exit_prog_flag           VARCHAR2(1);
    xx_exit_program             EXCEPTION;
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;

BEGIN
    
    location_and_log(gc_debug,'Processing Child Program'||chr(10));
    -------------------------------------------------
    -- Print Parameter Names and Values to Log File
    -------------------------------------------------

    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Thread Number        : ' || p_child_thread_num);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OE Payment ID (From)       : ' || p_min_oe_payment_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'OE Payment ID (To)         : ' || p_max_oe_payment_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
	FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
	
	gc_debug  := p_debug_flag;

    print_time_stamp_to_logfile;
    --========================================================================
	  -- Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_OE_PMT
	  --========================================================================
    
    location_and_log(gc_debug,'Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_OE_PMT ');
    
    OPEN get_cc_token_stg_oe_pmt_cur;
    LOOP
       l_cc_token_stg_oe_pmt.DELETE; --- Deleting the data in the Table type
       
		  FETCH get_cc_token_stg_oe_pmt_cur BULK COLLECT
		   INTO l_cc_token_stg_oe_pmt
      LIMIT p_batch_size;
      
       --Check to continue/ stop the program
        xx_exit_program_check(  p_program_name    => 'XX_C2T_OM_PMT_PREP_CHILD'
                              , x_exit_prog_flag  => lc_exit_prog_flag 
                             );
								   
        IF lc_exit_prog_flag = 'Y' THEN
           RAISE xx_exit_program;
        END IF;
        
        ln_total_records_processed := ln_total_records_processed + l_cc_token_stg_oe_pmt.COUNT;
        
      FOR i IN 1 .. l_cc_token_stg_oe_pmt.COUNT
        LOOP
		     BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;
            --========================================================================
            -- DECRYPTING the Credit Card Number
            --========================================================================
            location_and_log(gc_debug, ' ');  -- add
            location_and_log(gc_debug, 'Decrypting CARD ID '||l_cc_token_stg_oe_pmt (i).credit_card_number_orig);
            DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
						                        , attribute => 'TYPE'
						                        , value     => 'EBS');

            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
                                          , p_key_label     => l_cc_token_stg_oe_pmt (i).key_label_orig
                                          , p_encrypted_val => l_cc_token_stg_oe_pmt (i).credit_card_number_orig
                                          , p_algorithm     => '3DES'
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number:'|| substr(lc_cc_decrypted,-1,4)); 
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg); 
				
                --Assigning values for update of OE Payments Staging table	 
                l_cc_token_stg_oe_pmt(i).re_encrypt_status := 'E';
                l_cc_token_stg_oe_pmt(i).error_action := 'DECRYPT';
                l_cc_token_stg_oe_pmt(i).error_message := lc_error_msg;
                l_cc_token_stg_oe_pmt(i).last_update_date := SYSDATE;
                l_cc_token_stg_oe_pmt(i).last_updated_by := gn_user_id;
                l_cc_token_stg_oe_pmt(i).last_update_login := gn_login_id;
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
                                        , attribute => 'TYPE'
                                        , value     => 'EBS');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'AJB'
                                                       , p_key_label     =>  NULL
                                                       , p_algorithm     => '3DES'
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --Unsuccessful

                   location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg); 
				   
                   --Assigning values for update of OE Payments Staging table	 													   
                   l_cc_token_stg_oe_pmt(i).re_encrypt_status := 'E';
                   l_cc_token_stg_oe_pmt(i).error_action := 'ENCRYPT';
                   l_cc_token_stg_oe_pmt(i).error_message := lc_error_msg;
                   l_cc_token_stg_oe_pmt(i).credit_card_number_new := NULL;
                   l_cc_token_stg_oe_pmt(i).key_label_new := NULL;
                   l_cc_token_stg_oe_pmt(i).last_update_date := SYSDATE;
                   l_cc_token_stg_oe_pmt(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_oe_pmt(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
				
                   --Assigning values for update of OE Payments Staging table
                   l_cc_token_stg_oe_pmt(i).re_encrypt_status := 'C';
                   l_cc_token_stg_oe_pmt(i).error_action := NULL;
                   l_cc_token_stg_oe_pmt(i).error_message := NULL;
                   l_cc_token_stg_oe_pmt(i).credit_card_number_new := lc_cc_encrypted_new;
                   l_cc_token_stg_oe_pmt(i).key_label_new := lc_cc_key_label_new;
                   l_cc_token_stg_oe_pmt(i).last_update_date := SYSDATE;
                   l_cc_token_stg_oe_pmt(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_oe_pmt(i).last_update_login := gn_login_id;
                   
                   ln_last_oe_payment_id := l_cc_token_stg_oe_pmt (i).oe_payment_id;
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_pmts_child Cursor LOOP: ' 
                                        || '. Credit Card Number Orig: ' || l_cc_token_stg_oe_pmt(i).credit_card_number_orig
                                        || '. Error Message: ' || SQLERRM);
										
                   --Assigning values for update of OE Payments Staging table
                   l_cc_token_stg_oe_pmt(i).re_encrypt_status := 'E';
                   l_cc_token_stg_oe_pmt(i).error_action := lc_error_action;
                   l_cc_token_stg_oe_pmt(i).error_message := SUBSTR(lc_error_msg|| SQLERRM,1,4000);
                   l_cc_token_stg_oe_pmt(i).credit_card_number_new := NULL;
                   l_cc_token_stg_oe_pmt(i).key_label_new := NULL;
                   l_cc_token_stg_oe_pmt(i).last_update_date := SYSDATE;
                   l_cc_token_stg_oe_pmt(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_oe_pmt(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;
        
        --========================================================================
        -- Updating the new Token Value in table XX_C2T_CC_TOKEN_STG_OE_PMT
        --========================================================================
        BEGIN
            FORALL i IN 1 .. l_cc_token_stg_oe_pmt.COUNT
            SAVE EXCEPTIONS
		
              UPDATE    xx_c2t_cc_token_stg_oe_pmt
                 SET    re_encrypt_status = l_cc_token_stg_oe_pmt(i).re_encrypt_status
		                  , error_action      = l_cc_token_stg_oe_pmt(i).error_action
		                  , error_message     = l_cc_token_stg_oe_pmt(i).error_message
		                  , credit_card_number_new = l_cc_token_stg_oe_pmt(i).credit_card_number_new
		                  , key_label_new  = l_cc_token_stg_oe_pmt(i).key_label_new
                      , last_update_date = l_cc_token_stg_oe_pmt(i).last_update_date
                      , last_updated_by = l_cc_token_stg_oe_pmt(i).last_updated_by
                      , last_update_login = l_cc_token_stg_oe_pmt(i).last_update_login 
               WHERE    1 = 1
                 AND    oe_payment_id = l_cc_token_stg_oe_pmt(i).oe_payment_id;
			
        COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
		        ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
            FOR i IN 1 .. ln_err_count
            LOOP
              ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
              lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
              location_and_log(gc_debug,'BULK ERROR:: OE Payment ID : '|| l_cc_token_stg_oe_pmt (ln_error_idx).oe_payment_id||' :: Error Message : '||lc_error_msg);
            END LOOP; -- bulk_err_loop FOR UPDATE
        END;
        
      EXIT WHEN get_cc_token_stg_oe_pmt_cur%NOTFOUND;
      END LOOP;
        
      CLOSE get_cc_token_stg_oe_pmt_cur;
      
      IF UPPER(p_processing_type)= 'ALL'
      THEN
        --=========================================================================
        -- Updating the new LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_oe_pmt
              SET last_oe_payment_id = NVL(ln_last_oe_payment_id,last_oe_payment_id)
                  ,last_update_date  = SYSDATE
            WHERE max_oe_payment_id = p_max_oe_payment_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT: LAST_OE_PAYMENT_ID'
                                 || ln_last_oe_payment_id ||' ::'|| SQLERRM);
        END;
      END IF;
      
    --========================================================================
		-- Updating the OUTPUT FILE
		--========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
    	  
	EXCEPTION
  WHEN xx_exit_program 
  THEN
        x_errbuf  := 'ENDING Conversion Program. EXIT FLAG has been updated to YES';   
        x_retcode := 1; --WARNING
        
        --=========================================================================
        -- Updating the new LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_oe_pmt
              SET last_oe_payment_id = NVL(ln_last_oe_payment_id,last_oe_payment_id)
                  ,last_update_date  = SYSDATE
            WHERE max_oe_payment_id = p_max_oe_payment_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT: LAST_OE_PAYMENT_ID'
                                 || ln_last_oe_payment_id ||' ::'|| SQLERRM);
        END;
	WHEN OTHERS 
  THEN
        --=========================================================================
        -- Updating the new LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_oe_pmt
              SET last_oe_payment_id = NVL(ln_last_oe_payment_id,last_oe_payment_id)
                  ,last_update_date  = SYSDATE
            WHERE max_oe_payment_id = p_max_oe_payment_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_OE_PAYMENT_ID in table XX_C2T_PREP_THREADS_OE_PMT: LAST_OE_PAYMENT_ID'
                                 || ln_last_oe_payment_id ||' ::'|| SQLERRM);
        END;
	  x_retcode    := 2; -- ERROR
	  gc_error_loc := 'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_pmts_child: ' || '. Error Message: ' || SQLERRM;
	  x_errbuf     := gc_error_loc;
	END prepare_pmts_child;
      
  
  ---Deposits	
  
 -- +====================================================================+
 -- | Name       : prepare_deps_master                                   |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads           IN                          |
 -- |              p_processing_type         IN                          |
 -- |              p_recreate_child_thrds    IN                          |
 -- |              p_batch_size              IN                          |  
 -- |              p_debug_flag              IN                          |
 -- | Returns    : x_errbuf                  OUT                         |
 -- |              x_retcode                 OUT                         |
 -- |                                                                    |
 -- +====================================================================+
 PROCEDURE prepare_deps_master(       x_errbuf                   OUT NOCOPY   VARCHAR2
                                     ,x_retcode                  OUT NOCOPY   NUMBER
                                     ,p_child_threads            IN           NUMBER        
                                     ,p_processing_type          IN           VARCHAR2      
                                     ,p_recreate_child_thrds     IN           VARCHAR2      
                                     ,p_batch_size               IN           NUMBER
                                     ,p_debug_flag               IN           VARCHAR2
		                          )
	IS    
    --Cursor Declaration
    --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_DEPOSITS
	  CURSOR prep_threads_dep_cur	
	  IS
      SELECT  MIN(X.deposit_id)       min_deposit_id
            , MAX(X.deposit_id)       max_deposit_id
            , X.thread_num            thread_num
            , COUNT(1)                total_count
        FROM (SELECT /*+ full(DEP) parallel(DEP,8) */ 
                     DEP.deposit_id
                   , NTILE(p_child_threads) OVER(ORDER BY DEP.deposit_id) THREAD_NUM
                FROM xx_c2t_cc_token_stg_deposits DEP) X
      GROUP BY X.thread_num
      ORDER BY X.thread_num;
	  
	  --Cursor to get the data from XX_C2T_PREP_THREADS_DEPOSITS
	  CURSOR get_threads_dep_cur	
	  IS
      SELECT /*+ parallel(a,8) */ a.*
		    FROM xx_c2t_prep_threads_deposits a
       WHERE a.last_deposit_id <= a.max_deposit_id
	   ;
       
    TYPE r_prep_threads_dep 
    IS
      RECORD ( min_deposit_id            NUMBER,
               max_deposit_id            NUMBER,
               thread_num                NUMBER,
               total_count               NUMBER);
               
    TYPE t_prep_threads_dep
    IS
      TABLE OF r_prep_threads_dep INDEX BY BINARY_INTEGER;
      
    TYPE t_get_prep_threads_dep
    IS
      TABLE OF xx_c2t_prep_threads_deposits%ROWTYPE INDEX BY BINARY_INTEGER;
         
    --Local Variable Declaration
    l_get_prep_threads_dep        t_get_prep_threads_dep;
    l_prep_threads_dep            t_prep_threads_dep;
    ln_thread_cnt                 NUMBER := 0;
    EX_PROGRAM_INFO               EXCEPTION;
    EX_REQUEST_NOT_SUBMITTED      EXCEPTION;
    EX_NO_SUB_REQUESTS            EXCEPTION;
    ln_conc_req_id                NUMBER;
    ln_idx                        NUMBER := 1;
    ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
    ln_success_cnt                NUMBER := 0;
    ln_error_cnt                  NUMBER := 0;
    ln_retcode                    NUMBER := 0;  
    l_err_count                   NUMBER := 0;
    ln_error_idx                  NUMBER := 0;
    lc_error_msg                  VARCHAR2(4000);
    lc_conc_short_name            VARCHAR2(50) := 'XX_C2T_OM_DEP_PREP_CHILD';
    
	BEGIN
      gc_debug := p_debug_flag;
      --========================================================================
      -- Initialize Processing
      --========================================================================
      gc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
      location_and_log(gc_debug, ' ########## gc_req_data :: '||gc_req_data);

    IF gc_req_data IS NULL 
    THEN
            location_and_log(gc_debug,'Processing Master Program'||chr(10));
         -------------------------------------------------
         -- Print Parameter Names and Values to Log File
         -------------------------------------------------

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Recreate Child Threads     : ' || p_recreate_child_thrds);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');

      print_time_stamp_to_logfile;
      
      --========================================================================
         -- Retrieve and Print Program Information to Log File
         --========================================================================
         location_and_log (gc_debug,'Retrieve Program IDs for Master and Child.' || CHR (10));

         BEGIN
            location_and_log (gc_debug,'Retrieve Program ID for Master');

            SELECT concurrent_program_id
              INTO gn_parent_cp_id
              FROM fnd_concurrent_requests fcr
             WHERE fcr.request_id = gn_parent_request_id;

            location_and_log (gc_debug,'     Retrieve Program Info for Child');

            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO gn_child_cp_id
                  ,gc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = lc_conc_short_name;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '***************************** PROGRAM INFORMATION ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Program ID      : ' || gn_parent_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program ID       : ' || gn_child_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program Name     : ' || gc_child_prog_name);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE EX_PROGRAM_INFO;
         END;  -- print program information

         print_time_stamp_to_logfile;
         
         IF UPPER (p_processing_type) = 'ERROR' 
         THEN 
            -------------------------------------
            -- Derive Child Thread Ranges - ERROR
            -------------------------------------          
            location_and_log (gc_debug,'Processing Type = "ERROR"' || CHR (10));
                 
                  location_and_log (gc_debug,'     FULL - Before the Loop');
                  LOOP
                    location_and_log(gc_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;
                     ---------------------------------------------------------
                     -- Submit Child Requests - ERROR
                     ---------------------------------------------------------
                     location_and_log (gc_debug,'     FULL - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => ln_thread_cnt
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => NULL 
                                                   ,argument5        => NULL 
                                                   ,argument6        => p_batch_size
                                                   ,argument7        => p_debug_flag
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug,'     Child Program is not submitted');
                        x_retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;  
                      ELSE
                        COMMIT;
                        location_and_log (gc_debug,'     Able to submit the Child Program');
                     END IF;
                     EXIT WHEN (ln_thread_cnt = p_child_threads); 
                  END LOOP;
                  
         ELSIF UPPER (p_processing_type) = 'ALL' 
          THEN
              IF p_recreate_child_thrds = 'Y' 
              THEN
	   
                    location_and_log( gc_debug,'TRUNCATE TABLE XX_C2T_PREP_THREADS_DEPOSITS ');
                    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_DEPOSITS';
		 
                    --***************************************************************************************
                    --INSERTING new values in table XX_C2T_PREP_THREADS_DEPOSITS
                    --***************************************************************************************
		 
                    location_and_log( gc_debug,' Retriving records for inserting in XX_C2T_PREP_THREADS_DEPOSITS table ');
                    OPEN prep_threads_dep_cur;
                    LOOP
                       FETCH prep_threads_dep_cur BULK COLLECT
                       INTO l_prep_threads_dep;
		 
                    location_and_log( gc_debug,'Inserting Data in table XX_C2T_PREP_THREADS_DEPOSITS ');
                    BEGIN
                      FORALL i IN 1 .. l_prep_threads_dep.COUNT
		                  SAVE EXCEPTIONS
		  
                        INSERT INTO xx_c2t_prep_threads_deposits
                        (
                                min_deposit_id
                              , max_deposit_id 
                              , thread_num
                              , total_count                              
                              , creation_date
                              , last_update_date
                              , last_deposit_id
                              )
                        VALUES
                        (
                                l_prep_threads_dep(i).min_deposit_id    --min_deposit_id
                              , l_prep_threads_dep(i).max_deposit_id    --max_deposit_id
                              , l_prep_threads_dep(i).thread_num        --thread_num
                              , l_prep_threads_dep(i).total_count       --total_count
                              , SYSDATE                                     --creation_date  
                              , SYSDATE                                     --last_update_date  
                              , l_prep_threads_dep(i).min_deposit_id    --last_deposit_id              
                        );
			
                       COMMIT;
                       EXIT WHEN prep_threads_dep_cur%NOTFOUND;
                    EXCEPTION
		                WHEN OTHERS 
                    THEN
		                   l_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		                   FOR i IN 1 .. l_err_count
		                   LOOP
			                    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			                    lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to insert value in XX_C2T_PREP_THREADS_DEPOSITS' 
                                         || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
			                    location_and_log( gc_debug, ' BULK ERROR:: MAX Deposit ID : '|| l_prep_threads_dep(ln_error_idx).max_deposit_id ||
                                                ':: MIN Deposit ID : '|| l_prep_threads_dep(ln_error_idx).min_deposit_id ||
                                                ':: Error Message : '||lc_error_msg);
		                   END LOOP;   -- bulk_err_loop FOR INSERT

                    END;-- BEGIN Inserting Data in table XX_C2T_PREP_THREADS_DEPOSITS
                    END LOOP;	-- 	 Main Loop in prep_threads_dep_cur Cursor
                CLOSE prep_threads_dep_cur;
              END IF; --p_recreate_child_thrds = 'Y'
              
        --***************************************************************************************
        --Retrieve incomplete batches, from XX_C2T_PREP_THREADS_DEPOSITS table
        -- and then calling child program based on Child Thread
        --***************************************************************************************
		    BEGIN
             location_and_log( gc_debug, ' Retriving records from XX_C2T_PREP_THREADS_DEPOSITS table ');
             OPEN get_threads_dep_cur;
               FETCH get_threads_dep_cur BULK COLLECT INTO l_get_prep_threads_dep;
		           
               FOR i IN 1..l_get_prep_threads_dep.COUNT
               LOOP
               location_and_log( gc_debug, ' STARTING FOR LOOP');
				 
               location_and_log( gc_debug,TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') 
                                     ||':: Submitting Child Program Request for THREAD :: '||l_get_prep_threads_dep(i).thread_num
                                    );
	                                                          
              ---------------------------------------------------------
              -- Submit Child Requests - ALL
              ---------------------------------------------------------
               location_and_log (gc_debug,'     FULL - Submitting Child Request');
               ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => NULL
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => l_get_prep_threads_dep(i).last_deposit_id 
                                                   ,argument5        => l_get_prep_threads_dep(i).max_deposit_id 
                                                   ,argument6        => p_batch_size
                                                   ,argument7        => p_debug_flag
                                                   );

                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || l_get_prep_threads_dep(i).thread_num);
                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                 IF ln_conc_req_id = 0
                 THEN
                   location_and_log (gc_debug,'     Child Program is not submitted');
                   x_retcode := 2;
                   RAISE EX_REQUEST_NOT_SUBMITTED;  
                   ELSE
                     COMMIT;
                   location_and_log (gc_debug,'     Able to submit the Child Program');
                END IF;
           END LOOP; 
          CLOSE get_threads_dep_cur;
		    END;
                            
        END IF; --p_processing_type ='ALL'           
                  
         location_and_log ( gc_debug,'     FULL - After the Loop');
         location_and_log(gc_debug,'     Pausing MASTER Program......'||chr(10));
         FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                         request_data => 'CHILD_REQUESTS');
        
      ELSE
                  
         location_and_log(gc_debug,'     Restarting after CHILD_REQUESTS Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests 
         --========================================================================
         BEGIN
            location_and_log (gc_debug,'Post-processing for Child Requests' || CHR (10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_parent_request_id);

            location_and_log(gc_debug,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 
            THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  location_and_log(gc_debug,'     ltab_child_requests(i).request_id : '||ltab_child_requests(i).request_id);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_phase  : '||ltab_child_requests(i).dev_phase);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_status : '||ltab_child_requests(i).dev_status);

                  IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                     ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                  THEN
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_success_cnt := ln_success_cnt + 1;
                     x_retcode      := 0;
                  ELSE
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_error_cnt := ln_error_cnt + 1;
                     x_retcode    := 2;
                  END IF;

                  SELECT GREATEST (x_retcode, ln_retcode)
                    INTO ln_retcode
                    FROM DUAL;

               END LOOP; -- Checking Child Requests 
               
              ELSE
                 RAISE EX_NO_SUB_REQUESTS;
              END IF; -- retrieve child requests

            location_and_log (gc_debug,'     Captured Return Code for Master and Control Table Status');
            x_retcode := ln_retcode;

         END;  -- post processing for child requests

         print_time_stamp_to_logfile;
                                                  
    END IF;    
         
 EXCEPTION
     WHEN EX_PROGRAM_INFO 
     THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_PROGRAM_INFO at: ' || gc_error_loc);
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unable to get the Parent and Child Concurrent Names ');
          print_time_stamp_to_logfile;
          x_retcode := 2;
         
     WHEN EX_REQUEST_NOT_SUBMITTED 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_REQUEST_NOT_SUBMITTED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Unable to submit child request.');
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Rollback completed.');
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN EX_NO_SUB_REQUESTS 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_SUB_REQUESTS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN NO_DATA_FOUND 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;

     WHEN OTHERS 
     THEN
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;
 END prepare_deps_master;
 
 -- +====================================================================+
 -- | Name       : prepare_deps_child                                    |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads       IN                              |
 -- |              p_child_thread_num    IN                              |
 -- |              p_processing_type     IN                              |
 -- |              p_min_deposit_id      IN                              |
 -- |              p_max_deposit_id      IN                              |
 -- |              p_batch_size          IN                              |  
 -- |              p_debug_flag          IN                              |
 -- | Returns    : x_errbuf              OUT                             |
 -- |              x_retcode             OUT                             |
 -- |                                                                    |
 -- +====================================================================+
 
 PROCEDURE prepare_deps_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                  ,x_retcode                  OUT NOCOPY   NUMBER
                                  ,p_child_threads            IN           NUMBER
                                  ,p_child_thread_num         IN           NUMBER
                                  ,p_processing_type          IN           VARCHAR2 
                                  ,p_min_deposit_id           IN           NUMBER
                                  ,p_max_deposit_id           IN           NUMBER
                                  ,p_batch_size               IN           NUMBER
                                  ,p_debug_flag               IN           VARCHAR2	
                               )
 IS
 
 --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_DEPOSITS
	  CURSOR get_cc_token_stg_dep_cur   
	  IS
      SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_DEPS_U1)*/ 
             a.deposit_id
            ,a.credit_card_number_orig
						,a.key_label_orig 
            ,a.re_encrypt_status
            ,a.error_action
            ,a.error_message
            ,a.credit_card_number_new
            ,a.key_label_new
            ,a.last_update_date
            ,a.last_updated_by
            ,a.last_update_login
		    FROM xx_c2t_cc_token_stg_deposits a
       WHERE DECODE (UPPER (p_processing_type), 'ALL', 1, 2) = 1
         AND deposit_id    >= p_min_deposit_id
         AND deposit_id    <= p_max_deposit_id
         AND (re_encrypt_status IS NULL OR re_encrypt_status <> 'C')
       UNION         
      SELECT DEP.deposit_id
            ,DEP.credit_card_number_orig
						,DEP.key_label_orig 
            ,DEP.re_encrypt_status
            ,DEP.error_action
            ,DEP.error_message
            ,DEP.credit_card_number_new
            ,DEP.key_label_new
            ,DEP.last_update_date
            ,DEP.last_updated_by
            ,DEP.last_update_login
        FROM (SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_OE_PMT_N1)*/ 
                      X.deposit_id
                     ,X.credit_card_number_orig
                     ,X.key_label_orig 
                     ,X.re_encrypt_status
                     ,X.error_action
                     ,X.error_message
                     ,X.credit_card_number_new
                     ,X.key_label_new
                     ,X.last_update_date
                     ,X.last_updated_by
                     ,X.last_update_login
                     ,NTILE(p_child_threads) OVER(ORDER BY X.deposit_id) THREAD_NUM
                FROM xx_c2t_cc_token_stg_deposits X
              WHERE 1 =1 
                AND DECODE (UPPER (p_processing_type), 'ERROR', 1, 2) = 1
                AND X.re_encrypt_status IS NOT NULL 
                AND X.re_encrypt_status = 'E' ) DEP
							 WHERE DEP.THREAD_NUM = p_child_thread_num
        ;
        
    TYPE r_cc_token_stg_dep 
    IS
      RECORD ( deposit_ID                    xx_c2t_cc_token_stg_deposits.deposit_id%TYPE,
               credit_card_number_orig       xx_c2t_cc_token_stg_deposits.credit_card_number_orig%TYPE,
               key_label_orig                xx_c2t_cc_token_stg_deposits.key_label_orig%TYPE,
               re_encrypt_status             xx_c2t_cc_token_stg_deposits.re_encrypt_status%TYPE,
               error_action                  xx_c2t_cc_token_stg_deposits.error_action%TYPE,
               error_message                 xx_c2t_cc_token_stg_deposits.error_message%TYPE,
               credit_card_number_new        xx_c2t_cc_token_stg_deposits.credit_card_number_new%TYPE,
               key_label_new                 xx_c2t_cc_token_stg_deposits.key_label_new%TYPE,
               last_update_date              xx_c2t_cc_token_stg_deposits.last_update_date%TYPE,
               last_updated_by               xx_c2t_cc_token_stg_deposits.last_updated_by%TYPE,
               last_update_login             xx_c2t_cc_token_stg_deposits.last_update_login%TYPE);
	   
	  TYPE t_cc_token_stg_dep	
	  IS
	  TABLE OF r_cc_token_stg_dep INDEX BY BINARY_INTEGER;
    
    -- Local Variables
    l_cc_token_stg_dep          t_cc_token_stg_dep;
    ln_last_deposit_id          xx_c2t_prep_threads_deposits.last_deposit_id%TYPE;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	  ln_err_count                NUMBER          := 0;
	  ln_error_idx                NUMBER          := 0;
	  lc_error_msg                VARCHAR2(4000);
    lc_error_action             VARCHAR2(2000);
    lc_exit_prog_flag           VARCHAR2(1);
    xx_exit_program             EXCEPTION;
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;

BEGIN
    
    location_and_log(gc_debug,'Processing Child Program'||chr(10));
    -------------------------------------------------
    -- Print Parameter Names and Values to Log File
    -------------------------------------------------

    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Thread Number        : ' || p_child_thread_num);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Deposit ID (From)          : ' || p_min_deposit_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Deposit ID (To)            : ' || p_max_deposit_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    
    gc_debug  := p_debug_flag;

    print_time_stamp_to_logfile;
    --========================================================================
	  -- Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_DEPOSITS
	  --========================================================================
    
    location_and_log(gc_debug,'Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_DEPOSITS ');
    
    OPEN get_cc_token_stg_dep_cur;
    LOOP
      l_cc_token_stg_dep.DELETE; --- Deleting the data in the Table type 
		  FETCH get_cc_token_stg_dep_cur BULK COLLECT
		   INTO l_cc_token_stg_dep
      LIMIT p_batch_size;
      
      --Check to continue/ stop the program
        xx_exit_program_check(  p_program_name    => 'XX_C2T_OM_DEP_PREP_CHILD'
                              , x_exit_prog_flag  => lc_exit_prog_flag 
                             );
								   
        IF lc_exit_prog_flag = 'Y' THEN
           RAISE xx_exit_program;
        END IF;
        
        ln_total_records_processed := ln_total_records_processed + l_cc_token_stg_dep.COUNT;
        
      FOR i IN 1 .. l_cc_token_stg_dep.COUNT
        LOOP
		     BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;
            --========================================================================
            -- DECRYPTING the Credit Card Number
            --========================================================================
            location_and_log(gc_debug, ' ');  
            location_and_log(gc_debug, 'Decrypting CARD ID '||l_cc_token_stg_dep (i).credit_card_number_orig);
            DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
						                        , attribute => 'TYPE'
						                        , value     => 'EBS');

            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
                                          , p_key_label     => l_cc_token_stg_dep (i).key_label_orig
                                          , p_encrypted_val => l_cc_token_stg_dep (i).credit_card_number_orig
                                          , p_algorithm     => '3DES'
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number:'|| substr(lc_cc_decrypted,-1,4));  
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg); 
				
                --Assigning values for update of Deposits Staging table	 
                l_cc_token_stg_dep(i).re_encrypt_status := 'E';
                l_cc_token_stg_dep(i).error_action := 'DECRYPT';
                l_cc_token_stg_dep(i).error_message := lc_error_msg;
                l_cc_token_stg_dep(i).last_update_date := SYSDATE;
                l_cc_token_stg_dep(i).last_updated_by := gn_user_id;
                l_cc_token_stg_dep(i).last_update_login := gn_login_id;
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
                                        , attribute => 'TYPE'
                                        , value     => 'EBS');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'AJB'
                                                       , p_key_label     =>  NULL
                                                       , p_algorithm     => '3DES'
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --Unsuccessful

                   location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg); 
				   
                   --Assigning values for update of Deposits Staging table	 													   
                   l_cc_token_stg_dep(i).re_encrypt_status := 'E';
                   l_cc_token_stg_dep(i).error_action := 'ENCRYPT';
                   l_cc_token_stg_dep(i).error_message := lc_error_msg;
                   l_cc_token_stg_dep(i).credit_card_number_new := NULL;
                   l_cc_token_stg_dep(i).key_label_new := NULL;
                   l_cc_token_stg_dep(i).last_update_date := SYSDATE;
                   l_cc_token_stg_dep(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_dep(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
				
                   --Assigning values for update of Deposits Staging table
                   l_cc_token_stg_dep(i).re_encrypt_status := 'C';
                   l_cc_token_stg_dep(i).error_action := NULL;
                   l_cc_token_stg_dep(i).error_message := NULL;
                   l_cc_token_stg_dep(i).credit_card_number_new := lc_cc_encrypted_new;
                   l_cc_token_stg_dep(i).key_label_new := lc_cc_key_label_new;
                   l_cc_token_stg_dep(i).last_update_date := SYSDATE;
                   l_cc_token_stg_dep(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_dep(i).last_update_login := gn_login_id;
                   
                   ln_last_deposit_id := l_cc_token_stg_dep (i).deposit_id;
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_deps_child Cursor LOOP: ' 
                                        || '. Credit Card Number Orig: ' || l_cc_token_stg_dep(i).credit_card_number_orig
                                        || '. Error Message: ' || SQLERRM);
										
                   --Assigning values for update of Deposits Staging table
                   l_cc_token_stg_dep(i).re_encrypt_status := 'E';
                   l_cc_token_stg_dep(i).error_action := lc_error_action;
                   l_cc_token_stg_dep(i).error_message := SUBSTR(lc_error_msg|| SQLERRM,1,4000);
                   l_cc_token_stg_dep(i).credit_card_number_new := NULL;
                   l_cc_token_stg_dep(i).key_label_new := NULL;
                   l_cc_token_stg_dep(i).last_update_date := SYSDATE;
                   l_cc_token_stg_dep(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_dep(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;
        
        --========================================================================
        -- Updating the new Token Value in table XX_C2T_CC_TOKEN_STG_DEPOSITS
        --========================================================================
        BEGIN
            FORALL i IN 1 .. l_cc_token_stg_dep.COUNT
            SAVE EXCEPTIONS
		
              UPDATE    xx_c2t_cc_token_stg_deposits
                 SET    re_encrypt_status = l_cc_token_stg_dep(i).re_encrypt_status
		                  , error_action      = l_cc_token_stg_dep(i).error_action
		                  , error_message     = l_cc_token_stg_dep(i).error_message
		                  , credit_card_number_new = l_cc_token_stg_dep(i).credit_card_number_new
		                  , key_label_new  = l_cc_token_stg_dep(i).key_label_new
                      , last_update_date = l_cc_token_stg_dep(i).last_update_date
                      , last_updated_by = l_cc_token_stg_dep(i).last_updated_by
                      , last_update_login = l_cc_token_stg_dep(i).last_update_login 
               WHERE    1 = 1
                 AND    deposit_id = l_cc_token_stg_dep(i).deposit_id;
			
        COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
		        ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
            FOR i IN 1 .. ln_err_count
            LOOP
              ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
              lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
              location_and_log(gc_debug,'BULK ERROR:: Deposit ID : '|| l_cc_token_stg_dep (ln_error_idx).deposit_id||' :: Error Message : '||lc_error_msg);
            END LOOP; -- bulk_err_loop FOR UPDATE
        END;
        
      EXIT WHEN get_cc_token_stg_dep_cur%NOTFOUND;
      END LOOP;
        
      CLOSE get_cc_token_stg_dep_cur;
      
      IF UPPER(p_processing_type)= 'ALL'
      THEN
        --===========================================================================
        -- Updating the new LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS
        --===========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_deposits
              SET last_deposit_id = NVL(ln_last_deposit_id,last_deposit_id)
                  ,last_update_date  = SYSDATE
            WHERE max_deposit_id = p_max_deposit_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS: LAST_DEPOSIT_ID'
                                 || ln_last_deposit_id ||' ::'|| SQLERRM);
        END;
      END IF;
      
      --========================================================================
      -- Updating the OUTPUT FILE
		  --========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
    	  
	EXCEPTION
  WHEN xx_exit_program 
  THEN
        x_errbuf  := 'ENDING Conversion Program. EXIT FLAG has been updated to YES';   
        x_retcode := 1; --WARNING
        
        --=========================================================================
        -- Updating the new LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_deposits
              SET last_deposit_id = NVL(ln_last_deposit_id,last_deposit_id)
                  ,last_update_date  = SYSDATE
            WHERE max_deposit_id = p_max_deposit_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS: LAST_DEPOSIT_ID'
                                 || ln_last_deposit_id ||' ::'|| SQLERRM);
        END;
	WHEN OTHERS 
  THEN
        --=========================================================================
        -- Updating the new LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_deposits
              SET last_deposit_id = NVL(ln_last_deposit_id,last_deposit_id)
                  ,last_update_date  = SYSDATE
            WHERE max_deposit_id = p_max_deposit_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_DEPOSIT_ID in table XX_C2T_PREP_THREADS_DEPOSITS: LAST_DEPOSIT_ID'
                                 || ln_last_deposit_id ||' ::'|| SQLERRM);
        END;
	  
	  gc_error_loc := 'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_deps_child: ' || '. Error Message: ' || SQLERRM;
	  x_errbuf     := gc_error_loc;
    x_retcode    := 2; -- ERROR
	END prepare_deps_child;
  
--- Returns
  
 -- +====================================================================+
 -- | Name       : prepare_rets_master                                   |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads           IN                          |
 -- |              p_processing_type         IN                          |
 -- |              p_recreate_child_thrds    IN                          |
 -- |              p_batch_size              IN                          |  
 -- |              p_debug_flag              IN                          |
 -- | Returns    : x_errbuf                  OUT                         |
 -- |              x_retcode                 OUT                         |
 -- |                                                                    | 
-- +====================================================================+
 PROCEDURE prepare_rets_master(       x_errbuf                   OUT NOCOPY   VARCHAR2
                                     ,x_retcode                  OUT NOCOPY   NUMBER
                                     ,p_child_threads            IN           NUMBER        
                                     ,p_processing_type          IN           VARCHAR2      
                                     ,p_recreate_child_thrds     IN           VARCHAR2      
                                     ,p_batch_size               IN           NUMBER
                                     ,p_debug_flag               IN           VARCHAR2
		                          )
	IS  
  --Cursor Declaration
  --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_RETURNS
  CURSOR prep_threads_rets_cur	
  IS
    SELECT  MIN(X.return_id)    min_return_id
          , MAX(X.return_id)    max_return_id
          , X.thread_num            thread_num
          , COUNT(1)                total_count
      FROM (SELECT /*+ full(RETS) parallel(RETS,8) */ 
                   RETS.return_id
                 , NTILE(p_child_threads) OVER(ORDER BY RETS.return_id) THREAD_NUM
              FROM xx_c2t_cc_token_stg_returns rets) X
    GROUP BY X.thread_num
    ORDER BY X.thread_num;
  
  --Cursor to get the data from XX_C2T_PREP_THREADS_RETURNS
  CURSOR get_threads_rets_cur	
  IS
    SELECT /*+ parallel(a,8) */ a.*
      FROM xx_c2t_prep_threads_returns a
     WHERE a.last_return_id < a.max_return_id;
     
  TYPE r_prep_threads_rets 
  IS
    RECORD ( min_return_id             NUMBER,
             max_return_id             NUMBER,
             thread_num                NUMBER,
             total_count               NUMBER);
             
  TYPE t_prep_threads_rets
  IS
    TABLE OF r_prep_threads_rets INDEX BY BINARY_INTEGER;
    
  TYPE t_get_prep_threads_rets
  IS
    TABLE OF xx_c2t_prep_threads_returns%ROWTYPE INDEX BY BINARY_INTEGER;
       
  --Local Variable Declaration
  l_get_prep_threads_rets       t_get_prep_threads_rets;
  l_prep_threads_rets           t_prep_threads_rets;
  ln_thread_cnt                 NUMBER := 0;
  EX_PROGRAM_INFO               EXCEPTION;
  EX_REQUEST_NOT_SUBMITTED      EXCEPTION;
  EX_NO_SUB_REQUESTS            EXCEPTION;
  ln_conc_req_id                NUMBER;
  ln_idx                        NUMBER := 1;
  ltab_child_requests           FND_CONCURRENT.REQUESTS_TAB_TYPE;
  ln_success_cnt                NUMBER := 0;
  ln_error_cnt                  NUMBER := 0;
  ln_retcode                    NUMBER := 0;  
  l_err_count                   NUMBER := 0;
  ln_error_idx                  NUMBER := 0;
  lc_error_msg                  VARCHAR2(2000);
  lc_conc_short_name            VARCHAR2(50) := 'XX_C2T_OM_RET_PREP_CHILD';
    
	BEGIN
    gc_debug := p_debug_flag;
    --========================================================================
    -- Initialize Processing
    --========================================================================
    gc_req_data := FND_CONC_GLOBAL.REQUEST_DATA;
    location_and_log(gc_debug, ' ########## gc_req_data :: '||gc_req_data);

    IF gc_req_data IS NULL 
    THEN
            location_and_log(gc_debug,'Processing Master Program'||chr(10));
         -------------------------------------------------
         -- Print Parameter Names and Values to Log File
         -------------------------------------------------

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Recreate Child Threads     : ' || p_recreate_child_thrds);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '');

      print_time_stamp_to_logfile;
      
         --========================================================================
         -- Retrieve and Print Program Information to Log File
         --========================================================================
         location_and_log (gc_debug,'Retrieve Program IDs for Master and Child.' || CHR (10));

         BEGIN
            location_and_log (gc_debug,'Retrieve Program ID for Master');

            SELECT concurrent_program_id
              INTO gn_parent_cp_id
              FROM fnd_concurrent_requests fcr
             WHERE fcr.request_id = gn_parent_request_id;

            location_and_log (gc_debug,'     Retrieve Program Info for Child');

            SELECT fcp.concurrent_program_id
                  ,fcp.user_concurrent_program_name
              INTO gn_child_cp_id
                  ,gc_child_prog_name
              FROM fnd_concurrent_programs_vl fcp
             WHERE fcp.concurrent_program_name = lc_conc_short_name;

            FND_FILE.PUT_LINE (FND_FILE.LOG, '');
            FND_FILE.PUT_LINE (FND_FILE.LOG, '***************************** PROGRAM INFORMATION ******************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Parent Program ID      : ' || gn_parent_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program ID       : ' || gn_child_cp_id);
            FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Program Name     : ' || gc_child_prog_name);
            FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
         EXCEPTION
            WHEN OTHERS
            THEN
               RAISE EX_PROGRAM_INFO;
         END;  -- print program information

         print_time_stamp_to_logfile;
         
         IF UPPER (p_processing_type) = 'ERROR' 
         THEN 
            -------------------------------------
            -- Derive Child Thread Ranges - ERROR
            -------------------------------------          
            location_and_log (gc_debug,'Processing Type = "ERROR"' || CHR (10));
                 
                  location_and_log (gc_debug,'     FULL - Before the Loop');
                  LOOP
                    location_and_log(gc_debug,'     Increment thread counter');
                    ln_thread_cnt := ln_thread_cnt + 1;
                     ---------------------------------------------------------
                     -- Submit Child Requests - ERROR
                     ---------------------------------------------------------
                     location_and_log (gc_debug,'     FULL - Submitting Child Request');
                     ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => ln_thread_cnt
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => NULL 
                                                   ,argument5        => NULL 
                                                   ,argument6        => p_batch_size
                                                   ,argument7        => p_debug_flag
                                                   );

                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || ln_thread_cnt);
                     FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                     IF ln_conc_req_id = 0
                     THEN
                        location_and_log (gc_debug,'     Child Program is not submitted');
                        x_retcode := 2;
                        RAISE EX_REQUEST_NOT_SUBMITTED;  
                      ELSE
                        COMMIT;
                        location_and_log (gc_debug,'     Able to submit the Child Program');
                     END IF;
                     EXIT WHEN (ln_thread_cnt = p_child_threads); 
                  END LOOP;
                  
         ELSIF UPPER (p_processing_type) = 'ALL' 
          THEN
              IF p_recreate_child_thrds = 'Y' 
              THEN
	   
                    location_and_log( gc_debug,'TRUNCATE TABLE XX_C2T_PREP_THREADS_RETURNS ');
                    EXECUTE IMMEDIATE 'TRUNCATE TABLE XXOM.XX_C2T_PREP_THREADS_RETURNS';
		 
                    --***************************************************************************************
                    --INSERTING new values in table XX_C2T_PREP_THREADS_RETURNS
                    --***************************************************************************************
		 
                    location_and_log( gc_debug,' Retriving records for inserting in XX_C2T_PREP_THREADS_RETURNS table ');
                    OPEN prep_threads_rets_cur;
                    LOOP
                       FETCH prep_threads_rets_cur BULK COLLECT
                       INTO l_prep_threads_rets;
		 
                    location_and_log( gc_debug,'Inserting Data in table XX_C2T_PREP_THREADS_RETS ');
                    BEGIN
                      FORALL i IN 1 .. l_prep_threads_rets.COUNT
		                  SAVE EXCEPTIONS
		  
                        INSERT INTO xx_c2t_prep_threads_returns
                        (
                                min_return_id
                              , max_return_id 
                              , thread_num
                              , total_count                              
                              , creation_date
                              , last_update_date
                              , last_return_id
                              )
                        VALUES
                        (
                                l_prep_threads_rets(i).min_return_id    --min_return_id
                              , l_prep_threads_rets(i).max_return_id    --max_return_id
                              , l_prep_threads_rets(i).thread_num       --thread_num
                              , l_prep_threads_rets(i).total_count      --total_count
                              , SYSDATE                                 --creation_date  
                              , SYSDATE                                 --last_update_date  
                              , l_prep_threads_rets(i).min_return_id    --last_return_id              
                        );
			
                       COMMIT;
                       EXIT WHEN prep_threads_rets_cur%NOTFOUND;
                    EXCEPTION
		                WHEN OTHERS 
                    THEN
		                   l_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		                   FOR i IN 1 .. l_err_count
		                   LOOP
			                    ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			                    lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to insert value in XX_C2T_PREP_THREADS_RETURNS' 
                                         || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
			                    location_and_log( gc_debug, ' BULK ERROR:: MAX Return ID : '|| l_prep_threads_rets (ln_error_idx).max_return_id ||
                                                ':: MIN Return ID : '|| l_prep_threads_rets (ln_error_idx).min_return_id ||
                                                ':: Error Message : '||lc_error_msg);
		                   END LOOP;   -- bulk_err_loop FOR INSERT

                    END;-- BEGIN Inserting Data in table XX_C2T_PREP_THREADS_RETURNS
                    END LOOP;	-- 	 Main Loop in prep_threads_rets_cur Cursor
                CLOSE prep_threads_rets_cur;
              END IF; --p_recreate_child_thrds = 'Y'
              
        --***************************************************************************************
        --Retrieve incomplete batches, from XX_C2T_PREP_THREADS_RETURNS table
        -- and then calling child program based on Child Thread
        --***************************************************************************************
		    BEGIN
             location_and_log( gc_debug, ' Retriving records from XX_C2T_PREP_THREADS_RETURNS table ');
             OPEN get_threads_rets_cur;
               FETCH get_threads_rets_cur BULK COLLECT INTO l_get_prep_threads_rets;
		           
               FOR i IN 1..l_get_prep_threads_rets.COUNT
               LOOP
               location_and_log( gc_debug, ' STARTING FOR LOOP');
				 
               location_and_log( gc_debug,TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') 
                                     ||':: Submitting Child Program Request for THREAD :: '||l_get_prep_threads_rets(i).thread_num
                                    );
	                                                          
              ---------------------------------------------------------
              -- Submit Child Requests - ALL
              ---------------------------------------------------------
               location_and_log (gc_debug,'     FULL - Submitting Child Request');
               ln_conc_req_id :=
                        fnd_request.submit_request (application      => 'XXOM'
                                                   ,program          => lc_conc_short_name
                                                   ,description      => ''
                                                   ,start_time       => ''
                                                   ,sub_request      => TRUE
                                                   ,argument1        => p_child_threads
                                                   ,argument2        => NULL
                                                   ,argument3        => p_processing_type
                                                   ,argument4        => l_get_prep_threads_rets(i).last_return_id 
                                                   ,argument5        => l_get_prep_threads_rets(i).max_return_id 
                                                   ,argument6        => p_batch_size 
                                                   ,argument7        => p_debug_flag
                                                   );

                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Thread Number    : ' || l_get_prep_threads_rets(i).thread_num);
                 FND_FILE.PUT_LINE (FND_FILE.LOG, '     Request ID       : ' || ln_conc_req_id);

                 IF ln_conc_req_id = 0
                 THEN
                   location_and_log (gc_debug,'     Child Program is not submitted');
                   x_retcode := 2;
                   RAISE EX_REQUEST_NOT_SUBMITTED;  
                   ELSE
                     COMMIT;
                   location_and_log (gc_debug,'     Able to submit the Child Program');
                END IF;
           END LOOP; 
          CLOSE get_threads_rets_cur;
		    END;
                            
        END IF; --p_processing_type ='ALL'           
                  
         location_and_log ( gc_debug,'     FULL - After the Loop');
         location_and_log(gc_debug,'     Pausing MASTER Program......'||chr(10));
         FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  => 'PAUSED',
                                         request_data => 'CHILD_REQUESTS');
        
      ELSE
                  
         location_and_log(gc_debug,'     Restarting after CHILD_REQUESTS Completed');
         location_and_log(gc_debug,'     Checking Child Requests');
         --========================================================================
         -- Post-Processing for Child Requests 
         --========================================================================
         BEGIN
            location_and_log (gc_debug,'Post-processing for Child Requests' || CHR (10));

            ltab_child_requests := FND_CONCURRENT.GET_SUB_REQUESTS(gn_parent_request_id);

            location_and_log(gc_debug,'     Checking Child Requests');
            IF ltab_child_requests.count > 0 
            THEN
               FOR i IN ltab_child_requests.FIRST .. ltab_child_requests.LAST
               LOOP

                  location_and_log(gc_debug,'     ltab_child_requests(i).request_id : '||ltab_child_requests(i).request_id);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_phase  : '||ltab_child_requests(i).dev_phase);
                  location_and_log(gc_debug,'     ltab_child_requests(i).dev_status : '||ltab_child_requests(i).dev_status);

                  IF ltab_child_requests(i).dev_phase  = 'COMPLETE' AND
                     ltab_child_requests(i).dev_status IN ('NORMAL','WARNING')
                  THEN
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_success_cnt := ln_success_cnt + 1;
                     x_retcode      := 0;
                  ELSE
                     location_and_log (gc_debug,'     Child Request status : '||ltab_child_requests(i).dev_status);
                     ln_error_cnt := ln_error_cnt + 1;
                     x_retcode    := 2;
                  END IF;

                  SELECT GREATEST (x_retcode, ln_retcode)
                    INTO ln_retcode
                    FROM DUAL;

               END LOOP; -- Checking Child Requests 
               
              ELSE
                 RAISE EX_NO_SUB_REQUESTS;
              END IF; -- retrieve child requests

            location_and_log (gc_debug,'     Captured Return Code for Master and Control Table Status');
            x_retcode := ln_retcode;

         END;  -- post processing for child requests

         print_time_stamp_to_logfile;
                                                  
    END IF;    
         
 EXCEPTION
     WHEN EX_PROGRAM_INFO 
     THEN
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_PROGRAM_INFO at: ' || gc_error_loc);
          FND_FILE.PUT_LINE (FND_FILE.LOG, 'Unable to get the Parent and Child Concurrent Names ');
          print_time_stamp_to_logfile;
          x_retcode := 2;
         
     WHEN EX_REQUEST_NOT_SUBMITTED 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_REQUEST_NOT_SUBMITTED at: ' || gc_error_loc);
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Unable to submit child request.');
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, '     Rollback completed.');
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN EX_NO_SUB_REQUESTS 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'EX_NO_SUB_REQUESTS at: ' || gc_error_loc);
         print_time_stamp_to_logfile;
         x_retcode := 2;
         
     WHEN NO_DATA_FOUND 
     THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'NO_DATA_FOUND at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;

     WHEN OTHERS 
     THEN
         ROLLBACK;
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'WHEN OTHERS at: ' || gc_error_loc || ' .' || SQLERRM);
         print_time_stamp_to_logfile;
         x_retcode := 2;
 END prepare_rets_master;
 
 -- +====================================================================+
 -- | Name       : prepare_rets_child                                    |
 -- |                                                                    |
 -- | Description:                                                       |
 -- |                                                                    |
 -- | Parameters : p_child_threads       IN                              |
 -- |              p_child_thread_num    IN                              |
 -- |              p_processing_type     IN                              |
 -- |              p_min_return_id       IN                              |
 -- |              p_max_return_id       IN                              |
 -- |              p_batch_size          IN                              |  
 -- |              p_debug_flag          IN                              |
 -- | Returns    : x_errbuf              OUT                             |
 -- |              x_retcode             OUT                             |
 -- |                                                                    |
 -- +====================================================================+
 
 PROCEDURE prepare_rets_child (    x_errbuf                   OUT NOCOPY   VARCHAR2
                                  ,x_retcode                  OUT NOCOPY   NUMBER
                                  ,p_child_threads            IN           NUMBER
                                  ,p_child_thread_num         IN           NUMBER
                                  ,p_processing_type          IN           VARCHAR2 
                                  ,p_min_return_id            IN           NUMBER
                                  ,p_max_return_id            IN           NUMBER
                                  ,p_batch_size               IN           NUMBER
                                  ,p_debug_flag               IN           VARCHAR2	
                               )
 IS
 
 --Cursor to get the data from table XX_C2T_CC_TOKEN_STG_RETURNS
	  CURSOR get_cc_token_stg_rets_cur   
	  IS
      SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_RETURNS_U1)*/ 
             a.return_id
            ,a.credit_card_number_orig
						,a.key_label_orig 
            ,a.re_encrypt_status
            ,a.error_action
            ,a.error_message
            ,a.credit_card_number_new
            ,a.key_label_new
            ,a.last_update_date
            ,a.last_updated_by
            ,a.last_update_login
		    FROM xx_c2t_cc_token_stg_returns a
       WHERE DECODE (UPPER (p_processing_type), 'ALL', 1, 2) = 1
         AND return_id >= p_min_return_id
         AND return_id <= p_max_return_id
         AND (re_encrypt_status IS NULL OR re_encrypt_status <> 'C')
       UNION         
      SELECT RETS.return_id
            ,RETS.credit_card_number_orig
						,RETS.key_label_orig 
            ,RETS.re_encrypt_status
            ,RETS.error_action
            ,RETS.error_message
            ,RETS.credit_card_number_new
            ,RETS.key_label_new
            ,RETS.last_update_date
            ,RETS.last_updated_by
            ,RETS.last_update_login
        FROM (SELECT /*+INDEX(XX_C2T_CC_TOKEN_STG_RETURNS_N1)*/ 
                      X.return_id
                     ,X.credit_card_number_orig
                     ,X.key_label_orig 
                     ,X.re_encrypt_status
                     ,X.error_action
                     ,X.error_message
                     ,X.credit_card_number_new
                     ,X.key_label_new
                     ,X.last_update_date
                     ,X.last_updated_by
                     ,X.last_update_login
                     ,NTILE(p_child_threads) OVER(ORDER BY X.return_id) THREAD_NUM
                FROM xx_c2t_cc_token_stg_returns X
              WHERE 1 =1 
                AND DECODE (UPPER (p_processing_type), 'ERROR', 1, 2) = 1
                AND X.re_encrypt_status IS NOT NULL 
                AND X.re_encrypt_status = 'E' ) RETS
							 WHERE RETS.THREAD_NUM = p_child_thread_num
        ;
        
    TYPE r_cc_token_stg_rets 
    IS
      RECORD ( return_id                     xx_c2t_cc_token_stg_returns.return_id%TYPE,
               credit_card_number_orig       xx_c2t_cc_token_stg_returns.credit_card_number_orig%TYPE,
               key_label_orig                xx_c2t_cc_token_stg_returns.key_label_orig%TYPE,
               re_encrypt_status             xx_c2t_cc_token_stg_returns.re_encrypt_status%TYPE,
               error_action                  xx_c2t_cc_token_stg_returns.error_action%TYPE,
               error_message                 xx_c2t_cc_token_stg_returns.error_message%TYPE,
               credit_card_number_new        xx_c2t_cc_token_stg_returns.credit_card_number_new%TYPE,
               key_label_new                 xx_c2t_cc_token_stg_returns.key_label_new%TYPE,
               last_update_date              xx_c2t_cc_token_stg_returns.last_update_date%TYPE,
               last_updated_by               xx_c2t_cc_token_stg_returns.last_updated_by%TYPE,
               last_update_login             xx_c2t_cc_token_stg_returns.last_update_login%TYPE);
	   
	  TYPE t_cc_token_stg_rets	
	  IS
	  TABLE OF r_cc_token_stg_rets INDEX BY BINARY_INTEGER;
    
    -- Local Variables
    l_cc_token_stg_rets         t_cc_token_stg_rets;
    ln_last_return_id           xx_c2t_prep_threads_returns.last_return_id%TYPE;
    lc_cc_decrypted             VARCHAR2(4000)  := NULL;
    lc_cc_decrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_encrypted_new         VARCHAR2(4000)  := NULL;
    lc_cc_encrypt_error         VARCHAR2(4000)  := NULL;
    lc_cc_key_label_new         VARCHAR2(4000)  := NULL;
	  ln_err_count                NUMBER          := 0;
	  ln_error_idx                NUMBER          := 0;
	  lc_error_msg                VARCHAR2(2000);
    lc_error_action             VARCHAR2(2000);
    lc_exit_prog_flag           VARCHAR2(1);
    xx_exit_program             EXCEPTION;
    ln_total_records_processed  NUMBER          := 0;
    ln_success_records          NUMBER          := 0;
    ln_failed_records           NUMBER          := 0;

BEGIN
    
    location_and_log(gc_debug,'Processing Child Program'||chr(10));
    -------------------------------------------------
    -- Print Parameter Names and Values to Log File
    -------------------------------------------------

    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '****************************** ENTERED PARAMETERS ******************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Threads              : ' || p_child_threads);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Child Thread Number        : ' || p_child_thread_num);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Processing Type            : ' || p_processing_type);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Return ID     (From)       : ' || p_min_return_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Return ID     (To)         : ' || p_max_return_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Bulk Processing Limit      : ' || p_batch_size);
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Debug Flag                 : ' || p_debug_flag);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    FND_FILE.PUT_LINE (FND_FILE.LOG, 'Request ID                 : ' || gn_parent_request_id);
    FND_FILE.PUT_LINE (FND_FILE.LOG, '********************************************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG, '');
    
    gc_debug  := p_debug_flag;

    print_time_stamp_to_logfile;
    --========================================================================
	  -- Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_RETURNS
	  --========================================================================
    
    location_and_log(gc_debug,'Retrieve Credit Card details from XX_C2T_CC_TOKEN_STG_RETURNS ');
    
    OPEN get_cc_token_stg_rets_cur;
    LOOP
      l_cc_token_stg_rets.DELETE; --- Deleting the data in the Table type
		  FETCH get_cc_token_stg_rets_cur BULK COLLECT
		   INTO l_cc_token_stg_rets
      LIMIT p_batch_size;
      
      --Check to continue/ stop the program
        xx_exit_program_check(  p_program_name    => 'XX_C2T_OM_RET_PREP_CHILD'
                              , x_exit_prog_flag  => lc_exit_prog_flag 
                             );
								   
        IF lc_exit_prog_flag = 'Y' THEN
           RAISE xx_exit_program;
        END IF;
        
        ln_total_records_processed := ln_total_records_processed + l_cc_token_stg_rets.COUNT;
        
      FOR i IN 1 .. l_cc_token_stg_rets.COUNT
        LOOP
		     BEGIN
            lc_cc_decrypted     := NULL;
            lc_cc_decrypt_error := NULL;
            lc_error_msg        := NULL;
            lc_cc_encrypted_new := NULL;
            lc_cc_encrypt_error := NULL;
            lc_cc_key_label_new := NULL;
            lc_error_action     := NULL;
            ln_err_count        := NULL;
            ln_error_idx        := NULL;
            --========================================================================
            -- DECRYPTING the Credit Card Number
            --========================================================================
            location_and_log(gc_debug, ' ');  -- add
            location_and_log(gc_debug, 'Decrypting CARD ID '||l_cc_token_stg_rets (i).credit_card_number_orig);
            DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
						                        , attribute => 'TYPE'
						                        , value     => 'EBS');

            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module        => 'AJB'
                                          , p_key_label     => l_cc_token_stg_rets (i).key_label_orig
                                          , p_encrypted_val => l_cc_token_stg_rets (i).credit_card_number_orig
                                          , p_algorithm     => '3DES'
                                          , x_decrypted_val => lc_cc_decrypted
                                          , x_error_message => lc_cc_decrypt_error);
										  
            lc_error_msg := SUBSTR(lc_cc_decrypt_error,1,4000);
            lc_error_action := 'DECRYPT';
			
            location_and_log(gc_debug, 'Decrypted Number:'|| substr(lc_cc_decrypted,-1,4));  
										  
            IF ( (lc_cc_decrypt_error IS NOT NULL) OR (lc_cc_decrypted IS NULL)) THEN --Unsuccessful

                location_and_log(gc_debug,'Decrypting Error Message :'||lc_error_msg);				
                --Assigning values for update of OE Payments Staging table	 
                l_cc_token_stg_rets(i).re_encrypt_status := 'E';
                l_cc_token_stg_rets(i).error_action := 'DECRYPT';
                l_cc_token_stg_rets(i).error_message := lc_error_msg;
                l_cc_token_stg_rets(i).last_update_date := SYSDATE;
                l_cc_token_stg_rets(i).last_updated_by := gn_user_id;
                l_cc_token_stg_rets(i).last_update_login := gn_login_id;
                
                ln_failed_records := ln_failed_records + 1;
				
            ELSE --If decryption is Successful
	            --========================================================================
	            -- ENCRYPTING/ Tokenizing the Credit Card Number again
	            --========================================================================
                DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_OM_CONTEXT'
                                        , attribute => 'TYPE'
                                        , value     => 'EBS');

                XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'AJB'
                                                       , p_key_label     =>  NULL
                                                       , p_algorithm     => '3DES'
                                                       , p_decrypted_val => lc_cc_decrypted
                                                       , x_encrypted_val => lc_cc_encrypted_new
                                                       , x_error_message => lc_cc_encrypt_error
                                                       , x_key_label     => lc_cc_key_label_new);
													   
                lc_error_msg := SUBSTR(lc_cc_encrypt_error,1,4000);
                lc_error_action := 'ENCRYPT';
													  
                IF ( (lc_cc_encrypt_error IS NOT NULL) OR (lc_cc_encrypted_new IS NULL)) THEN --Unsuccessful

                  location_and_log(gc_debug, 'Encrypting Error Message :'||lc_error_msg); 
				   
                   --Assigning values for update of Returns Staging table	 													   
                   l_cc_token_stg_rets(i).re_encrypt_status := 'E';
                   l_cc_token_stg_rets(i).error_action := 'ENCRYPT';
                   l_cc_token_stg_rets(i).error_message := lc_error_msg;
                   l_cc_token_stg_rets(i).credit_card_number_new := NULL;
                   l_cc_token_stg_rets(i).key_label_new := NULL;
                   l_cc_token_stg_rets(i).last_update_date := SYSDATE;
                   l_cc_token_stg_rets(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_rets(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
					
                ELSE  --If encryption is successful
				
                   --Assigning values for update of Returns Staging table
                   l_cc_token_stg_rets(i).re_encrypt_status := 'C';
                   l_cc_token_stg_rets(i).error_action := NULL;
                   l_cc_token_stg_rets(i).error_message := NULL;
                   l_cc_token_stg_rets(i).credit_card_number_new := lc_cc_encrypted_new;
                   l_cc_token_stg_rets(i).key_label_new := lc_cc_key_label_new;
                   l_cc_token_stg_rets(i).last_update_date := SYSDATE;
                   l_cc_token_stg_rets(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_rets(i).last_update_login := gn_login_id;
                   
                   ln_last_return_id := l_cc_token_stg_rets (i).return_id;
                   ln_success_records  := ln_success_records + 1;
                END IF;
            END IF;
          EXCEPTION
           WHEN OTHERS 
           THEN
                   location_and_log(gc_debug,'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_rets_child Cursor LOOP: ' 
                                        || '.Credit Card Number Orig: ' || l_cc_token_stg_rets(i).credit_card_number_orig
                                        || '. Error Message: ' || SQLERRM);
										
                   --Assigning values for update of Returns Staging table
                   l_cc_token_stg_rets(i).re_encrypt_status := 'E';
                   l_cc_token_stg_rets(i).error_action := lc_error_action;
                   l_cc_token_stg_rets(i).error_message := SUBSTR(lc_error_msg|| SQLERRM,1,4000);
                   l_cc_token_stg_rets(i).credit_card_number_new := NULL;
                   l_cc_token_stg_rets(i).key_label_new := NULL;
                   l_cc_token_stg_rets(i).last_update_date := SYSDATE;
                   l_cc_token_stg_rets(i).last_updated_by := gn_user_id;
                   l_cc_token_stg_rets(i).last_update_login := gn_login_id;
                   
                   ln_failed_records := ln_failed_records + 1;
          END;
        END LOOP;
        
        --========================================================================
        -- Updating the new Token Value in table XX_C2T_CC_TOKEN_STG_RETURNS
        --========================================================================
        BEGIN
            FORALL i IN 1 .. l_cc_token_stg_rets.COUNT
            SAVE EXCEPTIONS
		
              UPDATE    xx_c2t_cc_token_stg_returns
                 SET    re_encrypt_status = l_cc_token_stg_rets(i).re_encrypt_status
		                  , error_action      = l_cc_token_stg_rets(i).error_action
		                  , error_message     = l_cc_token_stg_rets(i).error_message
		                  , credit_card_number_new = l_cc_token_stg_rets(i).credit_card_number_new
		                  , key_label_new  = l_cc_token_stg_rets(i).key_label_new
                      , last_update_date = l_cc_token_stg_rets(i).last_update_date
                      , last_updated_by = l_cc_token_stg_rets(i).last_updated_by
                      , last_update_login = l_cc_token_stg_rets(i).last_update_login 
               WHERE    1 = 1
                 AND    return_id = l_cc_token_stg_rets(i).return_id;
			
        COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
		        ln_err_count := SQL%BULK_EXCEPTIONS.COUNT;
            FOR i IN 1 .. ln_err_count
            LOOP
              ln_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
              lc_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 4000);
              location_and_log(gc_debug,'BULK ERROR:: Return ID : '|| l_cc_token_stg_rets (ln_error_idx).return_id||' :: Error Message : '||lc_error_msg);
            END LOOP; -- bulk_err_loop FOR UPDATE
        END;
        
      EXIT WHEN get_cc_token_stg_rets_cur%NOTFOUND;
      END LOOP;
        
      CLOSE get_cc_token_stg_rets_cur;
      
      IF UPPER(p_processing_type)= 'ALL'
      THEN
        --=========================================================================
        -- Updating the new LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_returns
              SET last_return_id = NVL(ln_last_return_id,last_return_id)
                  ,last_update_date  = SYSDATE
            WHERE max_return_id = p_max_return_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS: LAST_RETURN_ID'
                                 || ln_last_return_id ||' ::'|| SQLERRM);
        END;
      END IF;
      
        --========================================================================
		    -- Updating the OUTPUT FILE
		    --========================================================================
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed :: '||ln_total_records_processed);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Processed Successfully :: '||ln_success_records);
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT, CHR(10));
        FND_FILE.PUT_LINE (FND_FILE.OUTPUT,'TOTAL Records Failed :: '||ln_failed_records);
    	  
	EXCEPTION
  WHEN xx_exit_program 
  THEN
        x_errbuf  := 'ENDING Conversion Program. EXIT FLAG has been updated to YES';   
        x_retcode := 1; --WARNING
        
        --=========================================================================
        -- Updating the new LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS
        --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_returns
              SET last_return_id = NVL(ln_last_return_id,last_return_id)
                  ,last_update_date  = SYSDATE
            WHERE max_return_id = p_max_return_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS: LAST_RETURN_ID'
                                 || ln_last_return_id ||' ::'|| SQLERRM);
        END;
	WHEN OTHERS 
  THEN
      --=========================================================================
      -- Updating the new LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS
      --=========================================================================
        BEGIN
           UPDATE xx_c2t_prep_threads_returns
              SET last_return_id = NVL(ln_last_return_id,last_return_id)
                  ,last_update_date  = SYSDATE
            WHERE max_return_id = p_max_return_id;
            
           COMMIT;
        EXCEPTION
        WHEN OTHERS 
        THEN
			    location_and_log(gc_debug, 'ERROR UPDATING LAST_RETURN_ID in table XX_C2T_PREP_THREADS_RETURNS: LAST_RETURN_ID'
                                 || ln_last_return_id ||' ::'|| SQLERRM);
        END;
	  x_retcode    := 2; -- ERROR
	  gc_error_loc := 'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_OM_PKG.prepare_rets_child: ' || '. Error Message: ' || SQLERRM;
	  x_errbuf     := gc_error_loc;

 END prepare_rets_child;
  
END XX_C2T_CNV_CC_TOKEN_OM_PKG;
/