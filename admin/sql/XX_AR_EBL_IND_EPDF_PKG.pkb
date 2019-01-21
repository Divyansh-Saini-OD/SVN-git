create or replace 
PACKAGE BODY      XX_AR_EBL_IND_EPDF_PKG
 AS

    gc_error_location       VARCHAR2(2000);
    gc_debug                VARCHAR2(1000);
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_IND_EPDF_PKG                                              |
-- | Description : This Package contains the common functions for Individual eBilling. |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 07-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 19-OCT-2015  Vasu Raparla            Removed Schema References for 12.2  |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD_IND                                                    |
-- | Description : This Procedure is used to multi thread the transactions to be       |
-- |               printed through Individual eBilling.                                |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 07-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 09-Apr-2012  Rajeshkumar M R         Defect#18432                        |
-- +===================================================================================+
    PROCEDURE MULTI_THREAD_IND ( x_error_buff                 OUT VARCHAR2
                                ,x_ret_code                   OUT NUMBER
                                ,p_batch_size                 IN  NUMBER
                                ,p_thread_count               IN  NUMBER
                                ,p_debug_flag                 IN  VARCHAR2
                                ,p_del_mthd                   IN  VARCHAR2
                                ,p_doc_type                   IN  VARCHAR2
                                ,p_cycle_date                 IN  VARCHAR2
                                )
    AS

       CURSOR  lcu_batch_id (p_status  IN VARCHAR2)
       IS
       SELECT  DISTINCT XAEIHM.batch_id
       FROM    xx_ar_ebl_ind_hdr_main XAEIHM
       WHERE   XAEIHM.billdocs_delivery_method = p_del_mthd
       AND     XAEIHM.org_id                   = FND_PROFILE.VALUE('ORG_ID')
       AND     XAEIHM.status                   = 'MARKED_FOR_RENDER';
     /*Added as per Defect# 18432 to resolve Render error issue */
      CURSOR lcu_file_status
      IS
      SELECT invoice_type,cust_doc_id,file_id,transmission_id,status 
	  from xx_ar_ebl_file where status='RENDER_ERROR' and invoice_type='IND';--- Removed apps schema References

       lc_status                 VARCHAR2(10)              := 'RENDER';
       lc_appl_short_name        CONSTANT VARCHAR2(50)     := 'XXFIN';
       ln_request_id             NUMBER;
       ln_req_id                 NUMBER;
       lc_conc_pgm_name          VARCHAR2(30)              := 'XX_AR_EBL_IND_EPDF_PKG_MAIN';

       lb_debug                  BOOLEAN;

       lc_request_data           VARCHAR2(15);
       ln_thread_count           NUMBER                    := 0;

       ln_err_req_cnt            NUMBER                    := 0;
	   /*Added as per Defect# 18432 to resolve Render error issue */
       lc_errbuf    VARCHAR2(2000);
       lc_retcode   VARCHAR2(2000);
	   ln_error_rec_count Number:=0;

    BEGIN

       ln_req_id              := FND_GLOBAL.CONC_REQUEST_ID;
       lc_request_data        := FND_CONC_GLOBAL.REQUEST_DATA;

       IF p_debug_flag = 'Y' THEN
          lb_debug := TRUE;
       ELSE
          lb_debug := FALSE;
       END IF;

       IF lc_request_data IS NULL THEN

          gc_error_location    := 'Calling Common Function Multithread to batch the transactions according to the parent cust doc id';
          XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                 ,FALSE
                                                 ,gc_error_location
                                                 );

          XX_AR_EBL_COMMON_UTIL_PKG.MULTI_THREAD( p_batch_size
                                                 ,p_thread_count
                                                 ,p_debug_flag
                                                 ,p_del_mthd
                                                 ,ln_req_id
                                                 ,p_doc_type
                                                 ,lc_status
                                                 ,p_cycle_date
                                                 );

          BEGIN

             FOR doc_batch_id IN lcu_batch_id (lc_status)
             LOOP
                ln_thread_count      := ln_thread_count + 1;

                gc_error_location    := 'Submitting Child program for the batch ID : '||doc_batch_id.batch_id;
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,FALSE
                                                       ,gc_error_location
                                                       );

                ln_request_id := FND_REQUEST.SUBMIT_REQUEST ( application         => lc_appl_short_name
                                                             ,program             => lc_conc_pgm_name
                                                             ,description         => NULL
                                                             ,start_time          => NULL
                                                             ,sub_request         => TRUE
                                                             ,argument1           => doc_batch_id.batch_id
                                                             ,argument2           => p_debug_flag
                                                             ,argument3           => p_del_mthd
                                                             ,argument4           => p_doc_type
                                                             ,argument5           => p_cycle_date
                                                             );
             END LOOP;

          EXCEPTION
             WHEN OTHERS THEN
                XX_AR_EBL_COMMON_UTIL_PKG.PUT_LOG_LINE( lb_debug
                                                       ,TRUE
                                                       ,'Error in Submitting ePDF Document Level Program'
                                                       );
          END;

          IF (ln_thread_count > 0) THEN
             fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => 'COMPLETE');
          END IF;

       ELSE

          SELECT COUNT(1)
          INTO   ln_err_req_cnt
          FROM   fnd_concurrent_requests
          WHERE  parent_request_id   = ln_req_id
          AND    phase_code          = 'C'
          AND    status_code         = 'E';

          /* Action taken to the main program in any of the child program completed in error. */
          IF ln_err_req_cnt <> 0 THEN
             gc_debug   := ln_err_req_cnt ||' Child Requests are Errored Out.Please, Check the Child Requests LOG for Details';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_debug
                                                    );
             x_ret_code := 2;
          ELSE
             gc_debug   := 'All the Child Programs Completed Normal...';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_debug
                                                    );
          END IF;

       END IF;	
	   /*Added for defect 18432 */
		FOR ren_err IN lcu_file_status
		LOOP
			ln_error_rec_count :=ln_error_rec_count+1;
			XX_AR_EBL_COMMON_UTIL_PKG.update_file_table (lc_errbuf
                                                   ,lc_retcode
                                                   ,ren_err.invoice_type 
                                                    ,''
                                                    ,''
                                                    ,ren_err.FILE_ID
                                                    ,''
                                                    ,'' );
													

		END LOOP;
		COMMIT;
		fnd_file.put_line(fnd_file.log,'ln_error_rec_count'||ln_error_rec_count);
		IF (ln_error_rec_count > 0) THEN 
		x_ret_code := 2;
		END IF;
	   /*End of code Added for defect 18432 */

    EXCEPTION
       WHEN OTHERS THEN
          gc_debug  := ' Exception raised in Multi Thread procedure '|| SQLERRM;
          XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                 ,TRUE
                                                 ,gc_debug
                                                 );
          x_ret_code := 2;

    END MULTI_THREAD_IND;

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : SUBMIT_EPDF_MAIN                                                    |
-- | Description : This Procedure is used to submit the exact IND ePDF pgm and the     |
-- |               bursting program.                                                   |
-- | Parameters   :                                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 14-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- |      1.1 01-OCT-2018  Sravan      			   Added for  NAIT-58403               |
-- +===================================================================================+
    PROCEDURE SUBMIT_EPDF_MAIN ( x_error_buff                 OUT VARCHAR2
                                ,x_retcode                    OUT NUMBER
                                ,p_batch_id                   IN  NUMBER
                                ,p_debug_flag                 IN  VARCHAR2
                                ,p_del_meth                   IN  VARCHAR2
                                ,p_doc_type                   IN  VARCHAR2
                                ,p_cycle_date                 IN  VARCHAR2
                                )
    AS

       CURSOR lcu_file_name
       IS
       SELECT DISTINCT SUBSTR( file_name
                              ,1,INSTR(file_name,'.PDF',1)-1
                              )||'_'||file_id||'.PDF'           bill_file_name
             ,file_id                                           bill_file_id
             ,transmission_id                                   bill_trans_id
			 ,mbs_doc_id
       FROM   xx_ar_ebl_ind_hdr_main
       WHERE  batch_id                     = p_batch_id;	   
      

       lb_debug               BOOLEAN;
       lc_burst_path          xx_fin_translatevalues.target_value1%TYPE;
       lc_font_path           xx_fin_translatevalues.target_value1%TYPE;
       lc_ind_opath           xx_fin_translatevalues.target_value1%TYPE;

       lc_appl_name           VARCHAR2(5)     := 'XXFIN';
       lc_file_type           VARCHAR2(5)     := 'PDF';
       lc_rdf_name            VARCHAR2(15)    := NULL; -- Commented value for NAIT-58403 'XXAREBLINDEPDF';
       lc_burst_java_name     VARCHAR2(15)    := 'XXARXMLCOMBURST';
       lc_burst_file          VARCHAR2(25)    := NULL; -- Commented value for NAIT-58403 'XXAREBLINDEPDFBURST.xml';
       lc_rtf_name            VARCHAR2(20)    := NULL; -- Commented value for NAIT-58403 'XXAREBLINDEPDF.rtf';
       lc_rtf_type            VARCHAR2(5)     := 'rtf';
       lc_ofile_name          VARCHAR2(10)    := 'FILE_NAME';

       lc_request_data        VARCHAR2(25);
       lc_update_flag         VARCHAR2(1)     := 'N';
	   lc_sku_set_flag		  VARCHAR2(1)     := 'N';	

       ln_epdf_req_id         NUMBER;
	   ln_ePDF_req_id_sku     NUMBER;
	   ln_ePDF_req_id_nrml    NUMBER;
       ln_error               NUMBER          := 0;

       lb_wait                BOOLEAN;
       lc_phase               VARCHAR2 (50);
       lc_status              VARCHAR2 (50);
       lc_dev_phase           VARCHAR2 (15);
       lc_dev_status          VARCHAR2 (15);
       lc_message             VARCHAR2 (2000);

       ln_burst_req_id        NUMBER;
	   ln_burst_req_id_sku    NUMBER;
	   ln_det_sku_cnt         NUMBER       := 0; -- Added for NAIT-58403
       ln_det_non_sku_cnt     NUMBER       := 0; -- Added for NAIT-58403 
       lc_nrml_set_flag       VARCHAR2(2) := 'N';-- Added for NAIT-58403
       ln_blob_err_cnt        NUMBER       := 0;
       ln_blob_err            NUMBER       := 0;
       ln_err_req_cnt         NUMBER       := 0;
       lc_output_path         dba_directories.directory_path%TYPE;

    BEGIN

       lc_request_data        := fnd_conc_global.request_data;
      
       IF p_debug_flag = 'Y' THEN
          lb_debug  := TRUE;
       ELSE
          lb_debug  := FALSE;
       END IF;

       gc_error_location := 'Submitting the ePDF Program for batch ID : '||p_batch_id;
       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,FALSE
                                              ,gc_error_location
                                              );

				IF lc_request_data IS NULL THEN
				--Added for NAIT-58403
				-- Start Aniket
				BEGIN
				  SELECT COUNT(1)
				  INTO ln_det_sku_cnt
				  FROM xx_ar_ebl_ind_hdr_main ind
				  WHERE batch_id = p_batch_id
				  AND EXISTS
					(SELECT 1
					 FROM XX_CDH_MBS_DOCUMENT_MASTER xcmdm
					 WHERE xcmdm.doc_detail_level = 'DETAILSKU'
					 AND UPPER(xcmdm.doc_type)    = 'INVOICE'
					 AND ind.mbs_doc_id           = xcmdm.document_id
					 );
				EXCEPTION
				WHEN OTHERS THEN
				  ln_det_sku_cnt    := 0;
				  gc_error_location := ' EXCEPTION IN GET MBS DOC ID Count for batch_id  ' ;
				  XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug ,FALSE ,gc_error_location );
				END;


				BEGIN
				  SELECT COUNT(1)
				  INTO ln_det_non_sku_cnt
				  FROM xx_ar_ebl_ind_hdr_main ind
				  WHERE batch_id = p_batch_id
				  AND NOT EXISTS
					(SELECT 1
					 FROM XX_CDH_MBS_DOCUMENT_MASTER xcmdm
					 WHERE xcmdm.doc_detail_level = 'DETAILSKU'--10240
					 AND upper(xcmdm.doc_type)    = 'INVOICE'
					 AND ind.mbs_doc_id           = xcmdm.document_id
					 );
				EXCEPTION
				WHEN OTHERS THEN
				  ln_det_non_sku_cnt    := 0;
				  gc_error_location := ' EXCEPTION IN GET MBS DOC ID Count for batch_id  ' ;
				  XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug ,FALSE ,gc_error_location );
				END;

			-- Assign program names as per count
			IF ln_det_sku_cnt >= 1 THEN
			  
				  lc_rdf_name     := 'XXAREBLINDEPDFS';  
			  
				 ln_epdf_req_id_sku  := fnd_request.submit_request ( application => lc_appl_name ,
																program => lc_rdf_name ,
																description => NULL ,
																start_time => NULL ,
																sub_request => TRUE ,
																argument1 => p_batch_id );
																
				  fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => TO_CHAR(ln_epdf_req_id_sku)||'-ePDF');
			  
			   
				  gc_error_location   := '  Found Line Level Cust Doc ' || ' Request Submitted for SKU ' ||  ln_epdf_req_id_sku;
				  XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
																	,FALSE
																	,gc_error_location
																	);
				-- Added for NAIT-58403
				  xx_insert_req_td(ln_epdf_req_id_sku, 'SKU', 'Y','CREATE');
							  
		   END IF;

		  IF ln_det_non_sku_cnt >= 1 THEN 
		  
				lc_rdf_name    := 'XXAREBLINDEPDF';

				ln_ePDF_req_id_nrml := FND_REQUEST.SUBMIT_REQUEST ( application => lc_appl_name ,
																	program => lc_rdf_name ,
																	description => NULL ,
																	start_time => NULL ,
																	sub_request => TRUE ,
																	argument1 => p_batch_id );
																	
				fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => TO_CHAR(ln_epdf_req_id_nrml)||'-ePDF');

				gc_error_location   := '  Found Line Level Cust Doc ' || ' Request Submitted for SKU ' ||  ln_ePDF_req_id_nrml;
		        XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
														,FALSE
														,gc_error_location
														);
						 
				xx_insert_req_td(ln_epdf_req_id_sku, 'NRML', 'Y','CREATE');												
																	
		  END IF;
				--END    

ELSIF (SUBSTR(lc_request_data,INSTR(lc_request_data,'-')+1) = 'ePDF') THEN

-- Start  added to get previous cust doc from temp table 

				BEGIN 
					SELECT request_id  , sku_flag 
					INTO ln_epdf_req_id_sku ,lc_sku_set_flag  
					FROM  xx_epdf_req_id WHERE prg_name = 'SKU';
				EXCEPTION WHEN OTHERS THEN 
				ln_epdf_req_id_sku:= 0;
				lc_sku_set_flag := 'N';
				END;

				BEGIN 
					SELECT sku_flag 
					INTO  lc_nrml_set_flag  
					FROM  xx_epdf_req_id WHERE prg_name = 'NRML';
				EXCEPTION WHEN OTHERS THEN 
				lc_nrml_set_flag := 'N';
				END;

				ln_ePDF_req_id_nrml := SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1);

          SELECT COUNT(1)
          INTO   ln_error
          FROM   fnd_concurrent_requests
          WHERE  request_id          IN (ln_ePDF_req_id_nrml ,ln_epdf_req_id_sku )
          AND    phase_code          = 'C'
          AND    status_code         = 'E';


          IF ln_error = 0 THEN

		  SELECT XFTV.TARGET_value1
             INTO   lc_burst_path
             FROM   xx_fin_translatedefinition XFTD   -- Removed xxfin schema References
                   ,xx_fin_translatevalues     XFTV   -- Removed xxfin schema References
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'BPATH'
             and    sysdate                 between xftv.start_date_active and nvl(xftv.end_date_active,sysdate+1)
             AND    SYSDATE                  BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';

             gc_error_location   := 'Getting the font Path for Bursting Prgoram';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             SELECT XFTV.TARGET_value1
             INTO   lc_font_path
             FROM   xx_fin_translatedefinition XFTD    -- Removed xxfin schema References
                   ,xx_fin_translatevalues     XFTV    -- Removed xxfin schema References
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'FPATH'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             and    xftd.enabled_flag       = 'Y';

             -- below select added for defect 7397
             gc_error_location   := 'Getting the output file path';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );
             SELECT directory_path
             INTO   lc_output_path
             FROM   dba_directories
             WHERE  directory_name = 'XXFIN_EBL_'||p_doc_type;

              
           IF lc_sku_set_flag = 'Y' THEN
				lc_burst_file   := 'XXAREBLINDEPDFSBURST.xml';
				lc_rtf_name     := 'XXAREBLINDEPDFS.rtf';   
             
			 ln_burst_req_id_sku  := FND_REQUEST.SUBMIT_REQUEST ( lc_appl_name
                                                             ,lc_burst_java_name
                                                             ,NULL
                                                             ,NULL
                                                             ,TRUE
                                                             ,ln_epdf_req_id_sku
                                                             ,lc_burst_path||'/'||lc_burst_file
                                                             ,lc_font_path
                                                             --,lc_burst_path||'/'||p_doc_type commented for defect 7397
                                                             ,lc_output_path  -- added for defect 7397
                                                             ,lc_burst_path||'/'||lc_rtf_name
                                                             ,LOWER(lc_file_type)
                                                             ,lc_rtf_type
                                                             ,lc_ofile_name
                                                             );

            fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1));
			 
			xx_insert_req_td(ln_epdf_req_id_sku, 'SKU', 'Y','DELETE');
          
           END IF;
	   
			IF lc_nrml_set_flag ='Y' THEN	 
			   lc_burst_file  := 'XXAREBLINDEPDFBURST.xml';
			   lc_rtf_name    := 'XXAREBLINDEPDF.rtf';
			   
			   ln_burst_req_id  := FND_REQUEST.SUBMIT_REQUEST ( lc_appl_name
																	 ,lc_burst_java_name
																	 ,NULL
																	 ,NULL
																	 ,TRUE
																	 ,SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1)
																	 ,lc_burst_path||'/'||lc_burst_file
																	 ,lc_font_path
																	 --,lc_burst_path||'/'||p_doc_type commented for defect 7397
																	 ,lc_output_path  -- added for defect 7397
																	 ,lc_burst_path||'/'||lc_rtf_name
																	 ,LOWER(lc_file_type)
																	 ,lc_rtf_type
																	 ,lc_ofile_name
																	 );

				 fnd_conc_global.set_req_globals(conc_status => 'PAUSED', request_data => SUBSTR(lc_request_data,1,INSTR(lc_request_data,'-')-1));
				 
				xx_insert_req_td(ln_epdf_req_id_sku, 'NRML', 'Y','DELETE');	   
			 END IF;			 
		ELSE
             gc_error_location   := 'Error in RDF Program';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,gc_error_location
                                                    );

             lc_update_flag    := 'Y';
             x_retcode         := 2;

          END IF;
       ELSE

          SELECT COUNT(1)
          INTO   ln_error
          FROM   fnd_concurrent_requests
          WHERE  parent_request_id   = fnd_global.conc_request_id
          AND    phase_code          = 'C'
          AND    status_code         = 'E';

          IF ln_error = 0 THEN

             gc_error_location   := 'Getting the Individual Output Path for Bursting Prgoram';
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             SELECT XFTV.TARGET_value1
             INTO   lc_ind_opath
             FROM   xx_fin_translatedefinition XFTD   -- Removed xxfin schema References
                   ,xx_fin_translatevalues     XFTV   -- Removed xxfin schema References
             WHERE  XFTD.translate_id       = XFTV.translate_id
             AND    XFTD.translation_name   = 'XX_EBL_COMMON_TRANS'
             AND    XFTV.source_value1      = 'IND_OPATH'
             AND    SYSDATE                 BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
             AND    SYSDATE                 BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
             AND    XFTV.enabled_flag       = 'Y'
             AND    XFTD.enabled_flag       = 'Y';

             gc_error_location := 'Updating xx_ar_ebl_file table for batch ID : '||p_batch_id||' and request ID : '||ln_ePDF_req_id;
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             FOR file_name IN lcu_file_name
             LOOP

                gc_error_location   := 'Inserting Blob into ss_ar_ebl_file table for the file id.';
                XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                       ,FALSE
                                                       ,gc_error_location
                                                       );

                XX_AR_EBL_COMMON_UTIL_PKG.insert_blob_file ( lc_ind_opath
                                                            ,file_name.bill_file_name
                                                            ,lc_file_type
                                                            ,file_name.bill_trans_id
                                                            ,file_name.bill_file_id
                                                            ,p_debug_flag
                                                            ,ln_blob_err
                                                            );

                ln_blob_err_cnt := ln_blob_err_cnt + ln_blob_err;

                IF ln_blob_err > 0 THEN
                   XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                          ,TRUE
                                                          ,'File '||file_name.bill_file_name||' is not updated in the xx_ar_ebl_file table'
                                                          );

                   UPDATE xx_ar_ebl_ind_hdr_main   XAEIHM
                   SET    status             = 'File '||file_name.bill_file_name||' is not updated in the xx_ar_ebl_file table'
                         ,request_id         = fnd_global.conc_request_id
                         ,last_updated_by    = fnd_global.user_id
                         ,last_updated_date  = SYSDATE
                         ,last_updated_login = fnd_global.user_id
                   WHERE  file_id            = file_name.bill_file_id
                   AND    transmission_id    = file_name.bill_trans_id
                   AND    batch_id           = p_batch_id;

                END IF;
             END LOOP;
             gc_error_location := 'Calling common function for updting standard table and deleting custom table for batch ID : '||p_batch_id;
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,FALSE
                                                    ,gc_error_location
                                                    );

             XX_AR_EBL_COMMON_UTIL_PKG.update_bill_status( p_batch_id
                                                          ,p_doc_type
                                                          ,p_del_meth
                                                          ,lc_request_data
                                                          ,p_debug_flag
                                                          );

          ELSE
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Error While : ' || gc_error_location
                                                    );
             lc_update_flag    := 'Y';
             x_retcode         := 2;

          END IF;

          IF ln_blob_err_cnt > 0 THEN
             XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                                    ,TRUE
                                                    ,'Some of the files are not updated into the xx_ar_ebl_file table'
                                                    );

             IF x_retcode IS NULL THEN
                x_retcode := 1;
             END IF;

          END IF;

       END IF;

       IF lc_update_flag = 'Y' THEN

          UPDATE xx_ar_ebl_file   XAEF
          SET    status_detail      = 'Error Location : '||gc_error_location
                ,status             = 'RENDER_ERROR'
                ,last_updated_by    = fnd_global.user_id
                ,last_update_date   = SYSDATE
                ,last_update_login  = fnd_global.user_id
          WHERE  EXISTS            (SELECT file_id
                                    FROM   xx_ar_ebl_ind_hdr_main
                                    WHERE  batch_id           = p_batch_id
                                    AND    file_id            = XAEF.file_id
                                    );

          UPDATE xx_ar_ebl_ind_hdr_main   XAEIHM
          SET    status             = 'Error Location : '||gc_error_location
                ,request_id         = fnd_global.conc_request_id
                ,last_updated_by    = fnd_global.user_id
                ,last_updated_date  = SYSDATE
                ,last_updated_login = fnd_global.user_id
          WHERE  batch_id           = p_batch_id;

          COMMIT;

       END IF;

    EXCEPTION
    WHEN OTHERS THEN

       ROLLBACK;

       gc_error_location := gc_error_location||CHR(13)||' SQLERRM : '||SQLERRM;

       XX_AR_EBL_COMMON_UTIL_PKG.put_log_line( lb_debug
                                              ,TRUE
                                              ,gc_error_location
                                              );

       UPDATE xx_ar_ebl_file   XAEF
       SET    status_detail      = 'Error Location : '||gc_error_location
             ,status             = 'RENDER_ERROR'
             ,last_updated_by    = fnd_global.user_id
             ,last_update_date   = sysdate
             ,last_update_login  = fnd_global.user_id
       WHERE  EXISTS            (SELECT file_id
                                 FROM   xx_ar_ebl_ind_hdr_main
                                 WHERE  batch_id           = p_batch_id
                                 AND    file_id            = XAEF.file_id
                                 );

       UPDATE xx_ar_ebl_ind_hdr_main   XAEIHM
       SET    status             = 'Error Location : '||gc_error_location
             ,request_id         = fnd_global.conc_request_id
             ,last_updated_by    = fnd_global.user_id
             ,last_updated_date  = sysdate
             ,last_updated_login = fnd_global.user_id
       WHERE  batch_id           = p_batch_id;

       COMMIT;

       x_retcode := 2;

    END submit_epdf_main;
-- Added for SKU line level     
	PROCEDURE xx_insert_req_td(
    p_in_req_id    NUMBER ,
    p_in_prg_name  VARCHAR2,
    p_in_file_name VARCHAR2 ,
    p_in_dml_op    VARCHAR2 )
IS
  PRAGMA AUTONOMOUS_TRANSACTION ;
BEGIN
  IF p_in_dml_op = 'CREATE' THEN
    INSERT
    INTO xx_epdf_req_id
      (
        request_id,
        prg_name,
        sku_flag
      )
      VALUES
      (
        p_in_req_id ,
        p_in_prg_name ,
        p_in_file_name
      );
  ELSIF p_in_dml_op = 'DELETE' THEN
    DELETE FROM xx_epdf_req_id WHERE prg_name = p_in_prg_name  ;
  END IF;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
END xx_insert_req_td;

END xx_ar_ebl_ind_epdf_pkg;
/
SHOW ERROR;