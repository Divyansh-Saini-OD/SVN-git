	CREATE OR REPLACE PACKAGE BODY xx_c2t_cnv_cc_token_ordt_pkg
	AS
	  -- +=====================================================================================================+
	  ---|                              Office Depot                                                           |
	  -- +=====================================================================================================+
	  -- |  Name:  XX_C2T_CNV_CC_TOKEN_ORDT_PKG                                                                |
	  -- |                                                                                                     |
	  -- |  Description:  Package for Pre-Processing of Credit Card in ORDT Table                              | 
	  -- |                                                                                                     |
	  -- |  Change Record:                                                                                     |
	  -- +=====================================================================================================+
	  -- | Version     Date         Author               Remarks                                               |
	  -- | =========   ===========  =============        ======================================================|
	  ---|  1.0        30-JUL-2015  Harvinder Rakhra     Initial Version                                       |
	  ---|  1.1        21-OCT-2015  Harvinder Rakhra     Added Debug Flag to call for Child Program            |
	  ---|  1.2        29-OCT-2015  Harvinder Rakhra     Modified  xx_exit_program_check                       |
	  ---|  1.3        04-NOV-2015  Harvinder Rakhra     Modified  xx_exit_program_check                       |
	  ---|  1.4        09-FEB-2016  Harvinder Rakhra     Added logic to discard Citi, Amex and card with Junk Char|
	  ---|  1.5        11-MAR-2016  Avinash Baddam       Added check for disc records and special characters   |
	  -- |  1.6        06-NOV-2016  Avinash Baddam       Defect#40315 Amex Conv Changes 			   |	
	  -- |  1.7        16-MAR-2017  Avinash Baddam       Outstanding Cleanup Records (Post-Amex)               |	  
	  -- +=====================================================================================================+
	  
	  gc_debug              xx_fin_translatevalues.target_value1%TYPE := 'Y';
	  gc_debug_file         xx_fin_translatevalues.target_value1%TYPE;
	  gc_location           VARCHAR2(1000);
	  gn_max_workers        PLS_INTEGER;
	  gn_request_id         fnd_concurrent_requests.request_id%TYPE     := NVL ( fnd_global.conc_request_id, -1);
	  gn_parent_request_id  fnd_concurrent_requests.request_id%TYPE;
	  gn_user_id            fnd_concurrent_requests.requested_by%TYPE   := NVL ( fnd_global.user_id, -1);
	  gn_login_id           fnd_concurrent_requests.conc_login_id%TYPE  := NVL ( fnd_global.login_id , -1);
	  
	  -- Program Information
	  gc_program_name       xx_com_error_log.program_name%TYPE := 'C2T ORDT Stage CC';
	  gc_program_type       xx_com_error_log.program_type%TYPE := 'Data Import';
	  gc_object_id          xx_com_error_log.object_id%TYPE;
	  gc_object_type        xx_com_error_log.object_type%TYPE;
	  gc_error_loc          VARCHAR2(4000);
	  gc_error_debug        VARCHAR2(4000);
	  
	  TYPE request_id_tab
	  IS
	  TABLE OF fnd_concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;
	  
 
	-- +===================================================================+
	-- | PROCEDURE  : XX_LOCATION_AND_LOG                                  |
	-- |                                                                   |
	-- | DESCRIPTION: Performs the following actions based on parameters   |
	-- |              1. Sets gc_error_location                            |
	-- |              2. Writes to log file if debug is on                 |
	-- |                                                                   |
	-- | PARAMETERS : p_debug_msg                                          |
	-- |                                                                   |
	-- | RETURNS    : None                                                 |
	-- +===================================================================+
	PROCEDURE xx_location_and_log(
		p_debug_msg IN VARCHAR2)
	IS
	BEGIN

	  -- Write Debug information for execution from concurrent request
	  IF (gc_debug                 = 'Y') THEN
		IF NVL (gn_request_id, -1) = -1 THEN
		  -- Write Debug information for execution from ad-hoc SQL
		  DBMS_OUTPUT.ENABLE;
		  DBMS_OUTPUT.put_line(' ');
		  DBMS_OUTPUT.put_line(p_debug_msg);
		  DBMS_OUTPUT.put_line(' ');
		ELSE
		  -- Write Debug information for execution from concurrent request
		  FND_FILE.put_line(FND_FILE.LOG, '     ' || p_debug_msg);
		END IF;
	  END IF;
	EXCEPTION
	WHEN OTHERS THEN
	  gc_error_loc := 'Entering WHEN OTHERS exception of XX_LOCATION_AND_LOG. ';
	  xx_com_error_log_pub.log_error(p_program_type => gc_program_type
								   , p_program_name => gc_program_name
								   , p_program_id => NULL
								   , p_module_name => 'IBY'
								   , p_error_location => SUBSTR(gc_error_loc, 1, 60)
								   , p_error_message_count => 1, p_error_message_code => 'E'
								   , p_error_message => SQLERRM, p_error_message_severity => 'Major'
								   , p_notify_flag => 'N'
								   , p_object_type => gc_object_type
								   , p_object_id => gc_object_id);
	END xx_location_and_log;
	
	-- +===================================================================+
	-- | PROCEDURE  : XX_EXIT_PROGRAM_CHECK                                |
	-- |                                                                   |
	-- | DESCRIPTION: Performs the following actions based on parameters   |
	-- |              1. Sets p_program_name: Checks if the program needs  |
    -- |                 to be stoped. 	                                   |
	-- |                                                                   |
	-- |                                                                   |
	-- | PARAMETERS : p_debug_msg                                          |
	-- |                                                                   |
	-- | RETURNS    : None                                                 |
	-- +===================================================================+
	PROCEDURE xx_exit_program_check(
		                             p_program_name    IN  VARCHAR2
                                   , x_exit_prog_flag  OUT VARCHAR2
                                   )
	IS
      l_exit_prog_flag    xx_fin_translatevalues.target_value1%TYPE;
	BEGIN
        SELECT    NVL(xftv.target_value1,
		          'N')
          INTO    l_exit_prog_flag
          FROM    xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
         WHERE    xftd.translate_id = xftv.translate_id
           AND    xftd.translation_name = 'XX_PROGRAM_CONTROL'
           AND    xftv.source_value1 = p_program_name
           AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,
														          SYSDATE
													              + 1)
           AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
														          SYSDATE
													              + 1)
           AND    xftv.enabled_flag = 'Y'
           AND    xftd.enabled_flag = 'Y';
		   
		   x_exit_prog_flag := l_exit_prog_flag;		   
    EXCEPTION
    WHEN OTHERS THEN
	  gc_error_loc := 'WHEN OTHERS EXCEPTION of XX_LOCATION_AND_LOG :: '||SQLERRM;	
    END xx_exit_program_check;
	

	--  +====================================================================+
	-- | Name       : prepare_master                                          |
	-- |                                                                      |
	-- | Description: This Procedure Import data from XX_AR_ORDER_RECEIPT_DTL |
	-- |               table into xx_c2t_cc_token_stg_ordt table              |
	-- |                                                                      |
	-- | Parameters : p_run_type       IN                                     |
	-- |              p_gather_stats   IN                                     |
	-- |                                                                      |
	-- |              x_errbuf          OUT                                   |
	-- |              x_retcode         OUT                                   |
	-- |                                                                      |
	-- | Returns    : none                                                    |
	-- +====================================================================+	  
	PROCEDURE prepare_master (x_errbuf               OUT NOCOPY        VARCHAR2
							, x_retcode              OUT NOCOPY        NUMBER
							, p_child_threads        IN  PLS_INTEGER   DEFAULT 10
							, p_processing_type      IN  VARCHAR2      DEFAULT 'ALL'
							, p_recreate_child_thrds IN  VARCHAR2      DEFAULT 'N'
							, p_batch_size           IN  PLS_INTEGER   DEFAULT 10000
							, p_debug_flag           IN  VARCHAR2      DEFAULT 'N'
							)
	IS

	  --Cursor to get the data for ORDT threads table XX_C2T_PREP_THREADS_ORDT
	  CURSOR prep_threads_ordt_cur	
	  IS
	  SELECT  MIN(X.order_payment_id)    min_order_payment_id
			, MAX(X.order_payment_id)    max_order_payment_id
			, X.thread_num               thread_num
			, COUNT(1)                   total_cnt
		FROM (SELECT /*+ full(ORDT) parallel(ORDT,8) */ 
					 ORDT.order_payment_id
				   , NTILE(p_child_threads) OVER(ORDER BY ORDT.order_payment_id) THREAD_NUM
				FROM xx_c2t_cc_token_stg_ordt ORDT
			   WHERE NVL (ORDT.re_encrypt_status, 'N') <> 'C') X
	  GROUP BY X.thread_num
	  ORDER BY X.thread_num;
	  
	  --Cursor to get the data from xx_c2t_prep_threads_ordt
	  CURSOR get_threads_ordt_cur	
	  IS
	  SELECT /*+ parallel(a,8) */ a.*
		FROM xx_c2t_prep_threads_ordt a
	   WHERE a.last_order_payment_id < a.max_order_payment_id;
	  
	  TYPE t_order_payment_id
	  IS
	  TABLE OF xx_c2t_prep_threads_ordt.min_order_payment_id%TYPE INDEX BY BINARY_INTEGER;
	  
	  l_min_order_pmnt_id       t_order_payment_id;
	  l_max_order_pmnt_id       t_order_payment_id;
	  
	  TYPE t_thread_num
	  IS
	  TABLE OF xx_c2t_prep_threads_ordt.thread_num%TYPE INDEX BY BINARY_INTEGER;
	  
	  l_thread_num              t_order_payment_id;
	  
	  TYPE t_total_cnt
	  IS
	  TABLE OF xx_c2t_prep_threads_ordt.total_count%TYPE INDEX BY BINARY_INTEGER;
	  
	  l_total_cnt                t_total_cnt;
	  
	  TYPE t_threads_ordt_tbl
	  IS
	  TABLE OF xx_c2t_prep_threads_ordt%ROWTYPE INDEX BY BINARY_INTEGER;
	  
	--  l_threads_ordt_tbl        t_threads_ordt_tbl;

	  x_request_id_tab          request_id_tab;
	  l_cc_decrypted            VARCHAR2(4000)  := NULL;
	  l_cc_decrypt_error        VARCHAR2(4000)  := NULL;
	  l_cc_encrypted_new        VARCHAR2(4000)  := NULL;
	  l_cc_encrypt_error        VARCHAR2(4000)  := NULL;
	  l_cc_key_label_new        VARCHAR2(4000)  := NULL;
	  l_err_count               PLS_INTEGER     := 0;
	  l_error_idx               PLS_INTEGER     := 0;
	  l_error_msg               VARCHAR2(2000);
	  l_error_action            VARCHAR2(2000);
	  l_thread_cnt              NUMBER          := 0;
	  l_request_id              NUMBER;
	  l_req_data                VARCHAR2(240) := NULL;
	  
      ex_request_not_submitted  EXCEPTION;
	BEGIN
	--========================================================================
	-- Initialize Processing
	--========================================================================
    gc_debug := p_debug_flag;
	l_req_data := fnd_conc_global.request_data;

	IF l_req_data IS NULL THEN

		IF UPPER (p_processing_type) = 'ERROR' THEN
								
			xx_location_and_log( TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') 
								||':: Submitting Child Program Request for ERROR lines'
							   );
            -------------------------------------
            -- Derive Child Thread Ranges - ERROR
            -------------------------------------          
                  LOOP
                    l_thread_cnt := l_thread_cnt + 1;
                     ---------------------------------------------------------
                     -- Submit Child Requests - ERROR
                     ---------------------------------------------------------
							
			        l_request_id := FND_REQUEST.submit_request(
														'XXFIN'
													  , 'XX_C2T_ORDT_PREP_CHILD'
													  , NULL
													  , TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
													  , TRUE                            --sub_request
													  , p_child_threads                 --p_child_threads
													  , l_thread_cnt                    --p_child_thread_num 
													  , p_processing_type               --p_processing_type
													  , NULL                            --p_min_order_payment_id
													  , NULL                            --p_max_order_payment_id
													  , p_batch_size                    --p_batch_size
                                                      , p_debug_flag                    --p_debug_flag
													  );
													  
                     IF l_request_id = 0
                     THEN
                        xx_location_and_log(  'Child Program is not submitted');
                        x_retcode := 2;
                        RAISE ex_request_not_submitted;  
                      END IF;
					  
                     EXIT WHEN (l_thread_cnt >= p_child_threads); 
                  END LOOP;
													  
			--Pausing the MAIN Program till all child programs are complete
			xx_location_and_log('     Pausing MASTER Program......'||chr(10));
			FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status => 'PAUSED', request_data => 'CHILD_REQUESTS');
			
		ELSIF UPPER (p_processing_type) = 'ALL' THEN
		
		   IF p_recreate_child_thrds = 'Y' THEN
		   
			 xx_location_and_log( 'TRUNCATE  TABLE XX_C2T_PREP_THREADS_ORDT ');
			 EXECUTE IMMEDIATE 'TRUNCATE  TABLE XXFIN.XX_C2T_PREP_THREADS_ORDT';
			 
			--***************************************************************************************
			--INSERTING new values in table XX_C2T_PREP_THREADS_ORDT
			--***************************************************************************************
			 
			 xx_location_and_log( ' Retriving records for inserting in XX_C2T_PREP_THREADS_ORDT table ');
			 OPEN prep_threads_ordt_cur;
			 LOOP
			 FETCH prep_threads_ordt_cur BULK COLLECT
			 INTO l_min_order_pmnt_id
				 ,l_max_order_pmnt_id
				 ,l_thread_num
				 ,l_total_cnt;
			 
			 xx_location_and_log( 'Inserting Data in table XX_C2T_PREP_THREADS_ORDT ');
			 BEGIN
			  FORALL i IN l_thread_num.FIRST .. l_thread_num.LAST
			  SAVE EXCEPTIONS
			  
			  INSERT INTO xx_c2t_prep_threads_ordt
				(
				  min_order_payment_id
				, max_order_payment_id
				, last_order_payment_id
				, total_count
				, thread_num
				, creation_date
				, last_update_date
				)
				VALUES
				(
				  l_min_order_pmnt_id(i)    --min_order_payment_id
				, l_max_order_pmnt_id(i)    --max_order_payment_id
				, l_min_order_pmnt_id(i)    --last_order_payment_id
				, l_total_cnt(i)            --total_cnt
				, l_thread_num (i)          --thread_num
				, SYSDATE                   --creation_date
				, SYSDATE                   --last_update_date
				);
				
			COMMIT;
			EXIT WHEN prep_threads_ordt_cur%NOTFOUND;
			EXCEPTION
			WHEN OTHERS THEN
			  l_err_count := SQL%BULK_EXCEPTIONS.COUNT;
			  FOR i IN 1 .. l_err_count
			  LOOP
				l_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
				l_error_msg := SUBSTR ( 'Bulk Exception - Failed to insert value in XX_C2T_PREP_THREADS_ORDT' 
									   || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
				xx_location_and_log( ' BULK ERROR:: MAX Payment ID : '|| l_min_order_pmnt_id (l_error_idx) ||
									 ':: MIN Payment ID : '|| l_min_order_pmnt_id (l_error_idx) ||
									 ':: Error Message : '||l_error_msg);
			  END LOOP;   -- bulk_err_loop FOR INSERT

			 END;-- BEGIN Inserting Data in table XX_C2T_PREP_THREADS_ORDT
			END LOOP;		 
		   END IF; --p_recreate_child_thrds = 'Y'
		   
			--***************************************************************************************
			--Retrieve incomplete batches, from XX_C2T_PREP_THREADS_ORDT table
			-- and then calling child program based on Child Thread
			--***************************************************************************************
			BEGIN
			 xx_location_and_log( ' Retriving records from XX_C2T_PREP_THREADS_ORDT table ');

			FOR l_threads_ordt_tbl IN get_threads_ordt_cur
			LOOP		 
                --Check if we need to stop the Child request submission
                xx_location_and_log( TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') 
                                    ||':: Submitting Child Program Request for THREAD :: '||l_threads_ordt_tbl.thread_num
                                    );
							
                l_request_id := FND_REQUEST.submit_request(
                                                            'XXFIN'
                                                          , 'XX_C2T_ORDT_PREP_CHILD'
                                                          , NULL
                                                          , TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS')
                                                          , TRUE                            --sub_request
                                                          , NULL                            --p_child_threads
                                                          , NULL                            --p_child_thread_num 
                                                          , p_processing_type               --p_processing_type
                                                          , l_threads_ordt_tbl.last_order_payment_id  --p_min_order_payment_id
                                                          , l_threads_ordt_tbl.max_order_payment_id   --p_max_order_payment_id
                                                          , p_batch_size                     --p_batch_size
                                                          , p_debug_flag                     --p_debug_flag
                                                          );
															  
			END LOOP;
			
			--Pausing the MAIN Program till all child programs are complete
			xx_location_and_log('     Pausing MASTER Program......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') );
			fnd_conc_global.set_req_globals(conc_status => 'PAUSED',request_data =>'1');
			xx_location_and_log('     Complete Pausing......:: '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') );
	
			EXCEPTION
			WHEN OTHERS THEN
				xx_location_and_log( 'ENCOUNTERED Error : '||SQLERRM );
			END;
		END IF;  --p_processing_type = 'ALL'
	END IF; --l_req_data IS NULL THEN
	 
	EXCEPTION
     WHEN ex_request_not_submitted 
     THEN          
          x_retcode := 2;
	WHEN OTHERS THEN
	   xx_location_and_log( 'ENCOUNTERED ERROR in procedure PREPARE_MASTER :: '||SQLERRM);
       x_retcode := 2;
	END prepare_master;

	--  +====================================================================+
	-- | Name       : PREPARE_CHILD                                           |
	-- |                                                                      |
	-- | Description: This Procedure Import data from XX_AR_ORDER_RECEIPT_DTL |
	-- |               table into xx_c2t_cc_token_stg_ordt table              |
	-- |                                                                      |
	-- | Parameters : p_run_type       IN                                     |
	-- |              p_gather_stats   IN                                     |
	-- |                                                                      |
	-- |              x_errbuf          OUT                                   |
	-- |              x_retcode         OUT                                   |
	-- |                                                                      |
	-- | Returns    : none                                                    |
	-- +====================================================================+
	PROCEDURE prepare_child (x_errbuf                   OUT NOCOPY      VARCHAR2
						   , x_retcode                  OUT NOCOPY      NUMBER
						   , p_child_threads            IN              NUMBER
						   , p_child_thread_num         IN              NUMBER
						   , p_processing_type          IN              VARCHAR2 DEFAULT 'ALL'
						   , p_min_order_payment_id     IN              NUMBER
						   , p_max_order_payment_id     IN              NUMBER
						   , p_batch_size               IN              NUMBER
						   , p_debug_flag               IN              VARCHAR2 DEFAULT 'N'
						   )
	IS
 
      TYPE cur_cc_token_stg_ordt IS REF CURSOR;	 
      get_cc_token_stg_ordt_cur  cur_cc_token_stg_ordt;
	   
	  TYPE t_cc_token_stg_ordt	
	  IS
	  TABLE OF xx_c2t_cc_token_stg_ordt%ROWTYPE INDEX BY BINARY_INTEGER;

	  l_cc_token_stg_ordt        t_cc_token_stg_ordt;
	  l_last_success_odr_pmnt_id xx_c2t_cc_token_stg_ordt.order_payment_id%TYPE;
	  l_cc_decrypted             VARCHAR2(4000)  := NULL;
	  l_cc_decrypt_error         VARCHAR2(4000)  := NULL;
	  l_cc_encrypted_new         VARCHAR2(4000)  := NULL;
	  l_cc_encrypt_error         VARCHAR2(4000)  := NULL;
	  l_cc_key_label_new         VARCHAR2(4000)  := NULL;
      l_cursor_query             VARCHAR2(4000)  := NULL;
	  l_err_count                PLS_INTEGER     := 0;
	  l_error_idx                PLS_INTEGER     := 0;
      num_of_records_processed   NUMBER          := 0;
      num_of_successful_rec      NUMBER          := 0;
      num_of_failed_rec          NUMBER          := 0;
	  l_error_msg                VARCHAR2(2000);
      l_exit_prog_flag           VARCHAR2(1);
	  l_error_action             VARCHAR2(2000);
      xx_exit_program            EXCEPTION;
	BEGIN
      gc_debug := p_debug_flag;
	  
	  xx_location_and_log( 'Retrieve Credit Card details from xx_c2t_cc_token_stg_ordt ');
      IF UPPER (p_processing_type) = 'ERROR' THEN
        l_cursor_query :=  '     SELECT MAIN.order_payment_id'
                           ||' , MAIN.payment_type_code'
                           ||' , MAIN.od_payment_type'
                           ||' , MAIN.credit_card_code'
                           ||' , MAIN.token_flag'
                           ||' , MAIN.credit_card_number_orig'
                           ||' , MAIN.cc_key_label_orig'
                           ||' , MAIN.credit_card_number_new'
                           ||' , MAIN.cc_key_label_new'
                           ||' , MAIN.cc_mask_number'
                           ||' , MAIN.re_encrypt_status'
                           ||' , MAIN.error_action'
                           ||' , MAIN.error_message'
                           ||' , MAIN.convert_status'
                           ||' , MAIN.created_by'
                           ||' , MAIN.creation_date'
                           ||' , MAIN.last_updated_by'
                           ||' , MAIN.last_update_date'
                           ||' , MAIN.last_update_login'                  
                           ||' FROM'                
                           ||' (SELECT /*+INDEX(a XX_C2T_CC_TOKEN_STG_ORDT_U1)*/ a.*'
                           ||' , NTILE('||p_child_threads||') OVER(ORDER BY a.order_payment_id) THREAD_NUM'
                           ||' FROM xx_c2t_cc_token_stg_ordt a'
                           ||' WHERE NVL (a.re_encrypt_status, ''N'') = ''E'') MAIN'
                           ||' WHERE MAIN.thread_num = '||p_child_thread_num;
      ELSE
        l_cursor_query :=  'SELECT /*+INDEX(a XX_C2T_CC_TOKEN_STG_ORDT_U1)*/'
                           ||'   a.order_payment_id'
                           ||' , a.payment_type_code'
                           ||' , a.od_payment_type'
                           ||' , a.credit_card_code'
                           ||' , a.token_flag'
                           ||' , a.credit_card_number_orig'
                           ||' , a.cc_key_label_orig'
                           ||' , a.credit_card_number_new'
                           ||' , a.cc_key_label_new'
                           ||' , a.cc_mask_number'
                           ||' , a.re_encrypt_status'
                           ||' , a.error_action'
                           ||' , a.error_message'
                           ||' , a.convert_status'
                           ||' , a.created_by'
                           ||' , a.creation_date'
                           ||' , a.last_updated_by'
                           ||' , a.last_update_date'
                           ||' , a.last_update_login' 		
                           ||' FROM xx_c2t_cc_token_stg_ordt a'
                           ||' WHERE a.order_payment_id >= '||p_min_order_payment_id
                           ||' AND a.order_payment_id <= '||p_max_order_payment_id
                           ||' AND NVL (a.re_encrypt_status, ''N'') <> ''C''';
      END IF;
	  
	  xx_location_and_log( 'l_cursor_query :: '||l_cursor_query);
	  
      OPEN get_cc_token_stg_ordt_cur FOR l_cursor_query;
      LOOP
		FETCH get_cc_token_stg_ordt_cur BULK COLLECT
		INTO l_cc_token_stg_ordt
		LIMIT p_batch_size;
		
        --Check to continue/ stop the program
        xx_exit_program_check(  p_program_name    => 'XX_C2T_ORDT_PREP_CHILD'
                              , x_exit_prog_flag  => l_exit_prog_flag 
                             );
								   
        IF l_exit_prog_flag = 'Y' THEN
           RAISE xx_exit_program;
        END IF;
		
        num_of_records_processed := num_of_records_processed + l_cc_token_stg_ordt.COUNT;
		  
		FOR i IN 1 .. l_cc_token_stg_ordt.COUNT
		LOOP
		  BEGIN
			--========================================================================
			-- DECRYPTING the Credit Card
			--========================================================================
			xx_location_and_log( 'Decripting CARD ID '||l_cc_token_stg_ordt (i).order_payment_id 
                              || ' #Start Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS') );
			DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_ORDT_CONTEXT'
									, attribute => 'TYPE'
									, value     => 'EBS');
									  
	        XX_OD_SECURITY_KEY_PKG.DECRYPT ( p_module        => 'AJB'
							               , p_key_label     => l_cc_token_stg_ordt (i).cc_key_label_orig
							               , p_encrypted_val => l_cc_token_stg_ordt (i).credit_card_number_orig
							               , p_algorithm     => '3DES'
							               , x_decrypted_val => l_cc_decrypted
							               , x_error_message => l_cc_decrypt_error)	;

			l_error_msg := l_cc_decrypt_error;
			l_error_action := 'DECRYPT';
			
			xx_location_and_log( 'l_cc_decrypted '||l_cc_token_stg_ordt (i).order_payment_id|| ': '
                              || ' #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'));
			xx_location_and_log( 'l_cc_decrypt_error '||l_cc_token_stg_ordt (i).order_payment_id|| ': '||l_cc_decrypt_error);
										  
			IF ( (l_cc_decrypt_error IS NOT NULL) OR (l_cc_decrypted IS NULL)) THEN --Unsuccessful

				xx_location_and_log( 'Decrypting Error Message for '||l_cc_token_stg_ordt (i).order_payment_id|| ': '||l_cc_decrypt_error);
				
				--Assigning values for update of Crypto Vault Staging table	 
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).error_action := 'DECRYPT';
				l_cc_token_stg_ordt(i).error_message := l_error_msg;
				num_of_failed_rec := num_of_failed_rec + 1;
				
            --Version 1.4 Added logic to remove AMEX, CITI records/*need to check this condition for amex conversion.*/
            --Version 1.5 Added check for discover records
           /*ELSIF ((SUBSTR (l_cc_decrypted, 1, 1) = '3' and LENGTH(l_cc_decrypted) <> 14)) THEN 
				--Assigning values for update of ordt Staging table	 
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).convert_status := 'E';
				l_cc_token_stg_ordt(i).error_action := 'AMEX';
				l_cc_token_stg_ordt(i).error_message := 'AMEX Card';
                num_of_failed_rec := num_of_failed_rec + 1;*/

           ELSIF (SUBSTR (l_cc_decrypted, 1, 6) IN ('601116','601156','603543'))
	          OR (SUBSTR (l_cc_decrypted, 1, 7) IN ('6011656'))
	          OR (SUBSTR (l_cc_decrypted, 1, 8) IN ('60352810','60352880'))
	          OR (SUBSTR (l_cc_decrypted, 1, 9) IN ('600525154')) 
	         THEN 
				--Assigning values for update of ordt Staging table	 
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).convert_status := 'E';
				l_cc_token_stg_ordt(i).error_action := 'CITI';
				l_cc_token_stg_ordt(i).error_message := 'CITI Card';
                num_of_failed_rec := num_of_failed_rec + 1;                
		
            --Added check to eliminate non amex cards	
           /* ELSIF SUBSTR (l_cc_decrypted, 1, 1) != '3' THEN 
				
				--Assigning values for update of ordt Staging table
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).convert_status := 'E';
				l_cc_token_stg_ordt(i).error_action := 'NOT AMEX';
				l_cc_token_stg_ordt(i).error_message := 'NOT AMEX';
                num_of_failed_rec := num_of_failed_rec + 1;*/
                
             --Version 1.4 Added logic to remove Invalid cards with Junk Characters
             --Version 1.5 Added check for special characters
            ELSIF ((SUBSTR (l_cc_decrypted, 1, 1) NOT IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) OR (LENGTH(TRIM(TRANSLATE(l_cc_decrypted,'0123456789',' '))) > 0)) THEN              

				--Assigning values for update of iby Staging table	 
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).convert_status := 'E';
				l_cc_token_stg_ordt(i).error_action := 'INVALID_CARD';
				l_cc_token_stg_ordt(i).error_message := 'Invalid Card With Junk Characters';
                num_of_failed_rec := num_of_failed_rec + 1;
				
			ELSE --If decryption is Successful
				--========================================================================
				-- ENCRYPTING/ Tokenizing the Credit Card again
				--========================================================================
				DBMS_SESSION.SET_CONTEXT( namespace => 'XX_C2T_CNV_ORDT_CONTEXT'
										, attribute => 'TYPE'
										, value     => 'EBS');

				XX_OD_SECURITY_KEY_PKG.ENCRYPT_OUTLABEL( p_module        => 'AJB'
													   , p_key_label     => NULL
													   , p_algorithm     => '3DES'
													   , p_decrypted_val => l_cc_decrypted
													   , x_encrypted_val => l_cc_encrypted_new
													   , x_error_message => l_cc_encrypt_error
													   , x_key_label     => l_cc_key_label_new);
													   
				l_error_msg := l_cc_encrypt_error;
				l_error_action := 'ENCRYPT_CC';
													  
				IF ( (l_cc_encrypt_error IS NOT NULL) OR (l_cc_encrypted_new IS NULL)) THEN --Unsuccessful

				   xx_location_and_log( 'Encrypting Error Message for Order Payment ID :'
										||l_cc_token_stg_ordt (i).order_payment_id|| ': '||l_cc_encrypt_error);
				   
				   --Assigning values for update of Crypto Vault Staging table                                                            
				   l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				   l_cc_token_stg_ordt(i).error_action := 'ENCRYPT';
				   l_cc_token_stg_ordt(i).error_message := l_error_msg;
				   l_cc_token_stg_ordt(i).credit_card_number_new := NULL;
				   l_cc_token_stg_ordt(i).cc_key_label_new := NULL;
				   num_of_failed_rec := num_of_failed_rec + 1;
					
				ELSE  --If encryption is successful
				
				   --Assigning values for update of Crypto Vault Staging table
				   l_cc_token_stg_ordt(i).re_encrypt_status := 'C';
				   l_cc_token_stg_ordt(i).error_action := NULL;
				   l_cc_token_stg_ordt(i).error_message := NULL;
				   l_cc_token_stg_ordt(i).credit_card_number_new := l_cc_encrypted_new;
				   l_cc_token_stg_ordt(i).cc_key_label_new := l_cc_key_label_new;
				   
				   l_last_success_odr_pmnt_id := l_cc_token_stg_ordt (i).order_payment_id;
                   num_of_successful_rec  := num_of_successful_rec + 1;
				END IF;
			END IF;
		  EXCEPTION 
		   WHEN OTHERS THEN
				xx_location_and_log( 'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_ORDT_PKG.prepare_child Cursor LOOP: ' 
									 || '. ORDER_PAYMENT_ID: ' || l_cc_token_stg_ordt(i).order_payment_id
									 || '. Error Message: ' || SQLERRM);
										
				   --Assigning values for update of ORDT Staging table
				l_cc_token_stg_ordt(i).re_encrypt_status := 'E';
				l_cc_token_stg_ordt(i).error_action := l_error_action;
				l_cc_token_stg_ordt(i).error_message := l_error_msg|| SQLERRM;
				l_cc_token_stg_ordt(i).credit_card_number_new := NULL;
				l_cc_token_stg_ordt(i).cc_key_label_new := NULL;
				num_of_failed_rec := num_of_failed_rec + 1;
		  END;
		END LOOP;
		--========================================================================
		-- Updating the new Token Value in table xx_c2t_cc_token_stg_ordt
		--========================================================================
		BEGIN
		   xx_location_and_log( 'STARTING BULK UPDATE xx_c2t_cc_token_stg_ordt #START Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'));
			FORALL i IN l_cc_token_stg_ordt.FIRST .. l_cc_token_stg_ordt.LAST
			SAVE EXCEPTIONS
		
			  UPDATE xx_c2t_cc_token_stg_ordt
				 SET    re_encrypt_status = l_cc_token_stg_ordt(i).re_encrypt_status
					  , convert_status    = l_cc_token_stg_ordt(i).convert_status  --Version 1.4
					  , error_action      = l_cc_token_stg_ordt(i).error_action
					  , error_message     = l_cc_token_stg_ordt(i).error_message
					  , credit_card_number_new = l_cc_token_stg_ordt(i).credit_card_number_new
					  , cc_key_label_new  = l_cc_token_stg_ordt(i).cc_key_label_new
			   WHERE order_payment_id = l_cc_token_stg_ordt (i).order_payment_id;
			
		COMMIT;
		EXCEPTION
		WHEN OTHERS THEN
		  l_err_count := SQL%BULK_EXCEPTIONS.COUNT;
		  FOR i IN 1 .. l_err_count
		  LOOP
			l_error_idx := SQL%BULK_EXCEPTIONS(i).ERROR_INDEX;
			l_error_msg := SUBSTR ( 'Bulk Exception - Failed to UPDATE value' || ' - ' || SQLERRM (SQL%BULK_EXCEPTIONS (i).ERROR_CODE * -1), 1, 500);
			xx_location_and_log( 'BULK ERROR:: Card ID : '|| l_cc_token_stg_ordt (l_error_idx).order_payment_id||' :: Error Message : '||l_error_msg);
		  END LOOP; -- bulk_err_loop FOR UPDATE
		END;
      EXIT WHEN get_cc_token_stg_ordt_cur%NOTFOUND;
      END LOOP;
      xx_location_and_log( 'ENDING BULK UPDATE xx_c2t_cc_token_stg_ordt #END Time : '||TO_CHAR(SYSDATE,'MM-DD-YYYY HH:Mi:SS'));
	  
	  CLOSE get_cc_token_stg_ordt_cur;
		
      --========================================================================
		-- Updating the new LAST_ORDER_PAYMENT_ID in table XX_C2T_ORDT_PREPARE_THREADS
      --========================================================================
      BEGIN
	   UPDATE xx_c2t_prep_threads_ordt
			  SET last_order_payment_id = NVL (l_last_success_odr_pmnt_id, last_order_payment_id)
				 ,last_update_date = SYSDATE
			WHERE max_order_payment_id = p_max_order_payment_id;
      EXCEPTION
		WHEN OTHERS THEN
			xx_location_and_log( 'ERROR UPDATING  LAST_ORDER_PAYMENT_ID in table XX_C2T_ORDT_PREPARE_THREADS: LAST_ORDER_PAYMENT_ID'
								 || l_last_success_odr_pmnt_id ||' ::'|| SQLERRM);
      END;

	 EXCEPTION
     WHEN xx_exit_program THEN
        x_retcode  := 1;   --WARNING
        x_errbuf := 'ENDING Conversion Program. EXIT FLAG has been updated to YES';
		
       --========================================================================
		-- Updating the new LAST_ORDER_PAYMENT_ID in table XX_C2T_ORDT_PREPARE_THREADS
       --========================================================================
       BEGIN
	       UPDATE xx_c2t_prep_threads_ordt
			  SET last_order_payment_id = NVL (l_last_success_odr_pmnt_id, last_order_payment_id)
				 ,last_update_date = SYSDATE
			WHERE max_order_payment_id = p_max_order_payment_id;
		EXCEPTION
		WHEN OTHERS THEN
			xx_location_and_log( 'ERROR UPDATING  LAST_ORDER_PAYMENT_ID in table XX_C2T_ORDT_PREPARE_THREADS: LAST_ORDER_PAYMENT_ID'
								 || l_last_success_odr_pmnt_id ||' ::'|| SQLERRM);
       END;
	 WHEN OTHERS THEN
	  x_retcode    := 2; -- ERROR
	  gc_error_loc := 'WHEN OTHERS ERROR encountered in XX_C2T_CNV_CC_TOKEN_ORDT_PKG.prepare_child: ' || '. Error Message: ' || SQLERRM;
	  x_errbuf     := gc_error_loc;
	  xx_com_error_log_pub.log_error(p_program_type => gc_program_type
								   , p_program_name => gc_program_name
								   , p_program_id => NULL
								   , p_module_name => 'IBY'
								   , p_error_location => SUBSTR(gc_error_loc, 1, 60)
								   , p_error_message_count => 1
								   , p_error_message_code => 'E'
								   , p_error_message => SQLERRM
								   , p_error_message_severity => 'Major'
								   , p_notify_flag => 'N'
								   , p_object_type => gc_object_type
								   , p_object_id => gc_object_id);    

	END prepare_child;
					   
	END xx_c2t_cnv_cc_token_ordt_pkg; 
/