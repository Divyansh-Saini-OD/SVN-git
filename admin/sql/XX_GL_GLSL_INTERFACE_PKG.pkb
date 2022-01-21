  CREATE OR REPLACE PACKAGE BODY XX_GL_GLSI_INTERFACE_PKG
   AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_GSS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface GLSI       |
-- |                      data with with the Oracle GL                 |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco				       |
-- |                                                                   |
-- +===================================================================+
  
    gc_translate_error VARCHAR2(5000);
    gc_error_message   VARCHAR2(5000);
    gc_source_name     XXFIN.XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gc_category_name   XXFIN.XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
    gn_group_id        XXFIN.XX_GL_INTERFACE_NA_STG.group_id%TYPE;
    gn_error_count     NUMBER := 0;  
    gc_debug_pkg_nm    VARCHAR2(30) := 'XX_GL_GLSI_INTERFACE_PKG.';
    gc_debug_flg       VARCHAR2(1)  := 'N';
    gn_request_id      NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();

    

-- +===================================================================+
-- | Name  :DEBUG_MESSAGE                                              |
-- | Description      :  This local procedure will write debug state-  |
-- |                     ments to the log file if debug_flag is Y      |
-- |                                                                   |
-- | Parameters :p_message (msg written), p_spaces (# of blank lines)  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE DEBUG_MESSAGE (p_message  IN  VARCHAR2
                            ,p_spaces   IN  NUMBER  DEFAULT 0 )

    IS  
    
    ln_space_cnt NUMBER := 0;
    
    BEGIN

         IF gc_debug_flg = 'Y' THEN
               LOOP

               EXIT WHEN ln_space_cnt = p_spaces; 

                    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                    ln_space_cnt := ln_space_cnt + 1;
                
               END LOOP;

               FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

         END IF;
   END;   


-- +===================================================================+
-- | Name  :GLSI_DERIVE_VALUES                                         |
-- | Description      : This Procedure is used the interface    to     |
-- |                    call the fuctions and procedures to derive     |
-- |                    needed values                                  |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE GLSI_DERIVE_VALUES (p_group_id   IN VARCHAR2 DEFAULT NULL)
    IS

    ---------------------------
    -- Local Variables declared
    ---------------------------

    lc_trans_name        XXFIN.XX_FIN_TRANSLATEDEFINITION.translation_name%TYPE;


    lc_ora_company       XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_cost_center   XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_account       XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_location      XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_inter_company XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_lob           XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_future        XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ccid              XXFIN.XX_GL_INTERFACE_NA_STG.code_combination_id%TYPE;


    lc_ps_company        XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ps_cost_center    XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment2%TYPE; 
    lc_ps_account        XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment3%TYPE;
    lc_ps_location       XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment4%TYPE;
    lc_ps_lob            XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment6%TYPE;

    lc_debug_msg         VARCHAR2(1000); 
    lc_error_flg         VARCHAR2(1);
    lc_debug_prog        VARCHAR2(100) := 'GLSI_DERIVE_VALUES'; 

    ln_row_id            rowid;


 

          ---------------------------------------------------------------------
          -- Cursor to select individual new or invalid rows from staging table.
          -- This will be used to derive any needed values.
          ---------------------------------------------------------------------
          CURSOR get_je_lines_cursor 
              IS
          SELECT  rowid
                 ,legacy_segment1
                 ,legacy_segment2 
                 ,legacy_segment3  
                 ,legacy_segment4                
                 ,legacy_segment6 
            FROM  XXFIN.XX_GL_INTERFACE_NA_STG
           WHERE group_id                       = gn_group_id
            AND   NVL(derived_val,'INVALID')    = 'INVALID'
             OR   NVL(derived_sob,'INVALID')    = 'INVALID';




    ----------------------------------------
    -- bug in translation definition program
    ----------------------------------------
    lc_source_value2     XXFIN.xx_fin_translatevalues.source_value2 %TYPE;

    BEGIN

       lc_debug_msg := '    Row processed by: '||lc_debug_prog
                                                 || ' p_row_id=> '   || ln_row_id; 

       DEBUG_MESSAGE (lc_debug_msg,1);

       gc_error_message := NULL;

       lc_error_flg  := 'N';

       -----------------------------------
       --  Select records to derive values 
       -----------------------------------

 	  ------------------------
          -- Derive Oracle Values
          ------------------------
          lc_debug_msg := 'Deriving Oracle Values  ';


           lc_debug_msg := '    Open Cursor get_je_lines_cursor '; 
           DEBUG_MESSAGE (lc_debug_msg);

            OPEN get_je_lines_cursor;
            LOOP

                FETCH get_je_lines_cursor
                INTO	  ln_row_id
                         ,lc_ps_company
                         ,lc_ps_cost_center          
                         ,lc_ps_account
                         ,lc_ps_location   
                         ,lc_ps_lob;           

                      
             EXIT WHEN get_je_lines_cursor%NOTFOUND;

  

               APPS.XX_CNV_GL_PSFIN_PKG.TRANSLATE_PS_VALUES(
                                  p_ps_business_unit          => lc_ps_company 
                                 ,p_ps_department             => lc_ps_cost_center 
                                 ,p_ps_account                => lc_ps_account
                                 ,p_ps_operating_unit         => lc_ps_location 
                                 ,p_ps_affiliate              => NULL   
                                 ,p_ps_sales_channel          => lc_ps_lob 
                                 ,p_convert_gl_history        =>  'N'
                                 ,x_seg1_company              => lc_ora_company
                                 ,x_seg2_costctr              => lc_ora_cost_center
                                 ,x_seg3_account              => lc_ora_account
                                 ,x_seg4_location             => lc_ora_location 
                                 ,x_seg5_interco              => lc_ora_inter_company
                                 ,x_seg6_lob                  => lc_ora_lob
                                 ,x_seg7_future               => lc_ora_future
                                 ,x_ccid                      => lc_ccid 
                                 ,x_error_message             => gc_error_message
                                 );

             
              IF gc_error_message IS NOT NULL THEN 

                     gn_error_count := gn_error_count + 1;

                     lc_error_flg := 'Y';


                     lc_debug_msg :=   gc_error_message;
                     DEBUG_MESSAGE (lc_debug_msg);                       
              

                    gc_error_message := NULL;

                     
	      END IF;


          ---------------------------
          --Update all derived values
          ---------------------------  

          IF  lc_error_flg = 'N' THEN

                lc_debug_msg := '    Updating segment values: ';

                BEGIN
                   	UPDATE XXFIN.XX_GL_INTERFACE_NA_STG 
         	        SET    segment1              =  lc_ora_company
                              ,Segment2              =  lc_ora_cost_center
     	                      ,segment3              =  lc_ora_account
                              ,segment4              =  lc_ora_location 
                              ,segment5              =  lc_ora_inter_company
                              ,segment6              =  lc_ora_lob
                              ,segment7              =  lc_ora_future   
                              ,code_combination_id   =  lc_ccid 
	                      ,derived_val           =  'VALID'
               	       WHERE   rowid     =  ln_row_id;

		       COMMIT;
                     
                           lc_debug_msg :='    Values Updated:'
                                         ||' company=> '        ||lc_ora_company 
                                         ||', cost_center=> '   ||lc_ora_cost_center
                                         ||', account=> '       ||lc_ora_account
                                         ||', location=> '      ||lc_ora_location
                                         ||', inter_company=> ' ||lc_ora_inter_company
                                         ||', lc_ora_lob=> '    ||lc_ora_lob
                                         ||', Future=> 000000 ' ||'VALID'; 
                       
                            DEBUG_MESSAGE (lc_debug_msg); 

             
                EXCEPTION 
                      WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '
                                           || lc_debug_msg 
                                          );

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_GL_INTERFACE_NA_STG = ROWID: '
                                           || ln_row_id 
                                          );

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM ); 

                         --------------------------------
                         -- TODO
                         -- log to standard error table
                         ------------------------------- 
                END;

            ELSE
       
                 lc_debug_msg :='    Values errored Updating: ' 
                                     ||'company=> '         ||lc_ora_company 
                                     ||', cost_center=> '   ||lc_ora_cost_center
                                     ||', account=> '       ||lc_ora_account
                                     ||', location=> '      ||lc_ora_location
                                     ||', inter_company=> ' ||lc_ora_inter_company
                                     ||', lc_ora_lob=> '    ||lc_ora_lob
                                     ||', Future=> 000000 ' ||'INVALID';

                 DEBUG_MESSAGE (lc_debug_msg); 

                

            END IF; 

       END LOOP;
       CLOSE get_je_lines_cursor;

    EXCEPTION
          
         WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '|| lc_debug_msg );
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );

              --------------------------------
              -- TODO
              -- log to standard error table
              -------------------------------  

    END GLSI_DERIVE_VALUES; 

-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for the GLSI    |    
-- |                    interface This will be called by the OD: GL    |                      
-- |                    Interface for GLSI concurrent program          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name, p_group_id                             |
-- |                                                                   |
-- |                                                                   |
-- | Returns : x_return_code, x_return_message	                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE PROCESS_JOURNALS (x_return_message   OUT VARCHAR2
			        ,x_return_code      OUT VARCHAR2
                                ,p_source_name       IN VARCHAR2
                                ,p_debug_flg         IN VARCHAR2 DEFAULT 'N'
                                 )
     IS 

          NO_GROUP_ID_FOUND EXCEPTION;
          DUPLICATE_FILE_FOUND EXCEPTION;
            
          ---------------------------
          -- local variables declared
          ---------------------------
          ln_error_cnt       NUMBER;
          lc_purge_err_log   VARCHAR2(1);
          ln_Conc_req_id     NUMBER;
          lc_log_status      XXFIN.XX_GL_INTERFACE_NA_LOG.status%TYPE;
          lc_submit_import   VARCHAR2(1);
          lc_debug_msg       VARCHAR2(2000);
          ln_temp_err_cnt    NUMBER;
          lc_firsT_record    VARCHAR2(1);
          lc_debug_prog      VARCHAR2(100) := 'PROCESS_JOURNALS';
          ln_conc_id         INTEGER;
          lc_mail_subject    VARCHAR2(250); 
          lc_details         XXFIN.XX_GL_INTERFACE_NA_LOG.details%TYPE;

          ------------------------------------------------ 
          --local variables for get_je_main_process_cursor
          ------------------------------------------------
          ln_group_id    XXFIN.XX_GL_INTERFACE_NA_STG.group_id%TYPE;       
          lc_source_name XXFIN.XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
          lc_batch_desc  XXFIN.XX_GL_INTERFACE_NA_STG.reference2%TYPE;


          ----------------------------------------- 
          --local variables for get_je_lines_cursor
          -----------------------------------------  
          ln_row_id          rowid;
          lc_jnrl_name       XXFIN.XX_GL_INTERFACE_NA_STG.reference22%TYPE;
          lc_derived_sob     XXFIN.XX_GL_INTERFACE_NA_STG.derived_sob%TYPE;
          lc_derived_value   XXFIN.XX_GL_INTERFACE_NA_STG.derived_val%TYPE; 
	  lc_balanced        XXFIN.XX_GL_INTERFACE_NA_STG.balanced%TYPE;
          lc_gl_gl_line_desc XXFIN.XX_GL_INTERFACE_NA_STG.reference10%TYPE;
          lc_gl_je_line_code XXFIN.XX_GL_INTERFACE_NA_STG.reference22%TYPE;
          lc_ora_company     XXFIN.XX_GL_INTERFACE_NA_STG.segment1%TYPE;
          ln_sobid           XXFIN.XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
          lc_legacy_segment4 XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment4%TYPE;
          lc_legacy_segment1 XXFIN.XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
          lc_reference24     XXFIN.XX_GL_INTERFACE_NA_STG.reference24%TYPE; 
       
 
         ------------------------------------------------
          -- Cursor to select all group ids from a source 
          ------------------------------------------------
          CURSOR get_je_main_process_cursor 
              IS
          SELECT DISTINCT
                  group_id
                 ,user_je_source_name
                 ,reference2 
                 ,reference24                
                  FROM  XXFIN.XX_GL_INTERFACE_NA_STG
           WHERE user_je_source_name            = p_source_name
            AND  (NVL(derived_val,'INVALID')    = 'INVALID'
             OR   NVL(derived_sob,'INVALID')    = 'INVALID'
             OR   NVL(balanced   ,'UNBALANCED') = 'UNBALANCED');

     

     BEGIN

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '
                                         ||gc_debug_pkg_nm  
                                         ||lc_debug_prog 
                                         ||' JE Source Name: '
                                         || p_source_name);
        -------------------
        -- initalize values
        -------------------
        lc_firsT_record  := 'Y'; 
        gn_error_count   :=  0;
        --ln_group_id      :=  0;

         

        lc_debug_msg     := '    Debug flag = '|| NVL(Upper(p_debug_flg),'N') ;
        DEBUG_MESSAGE (lc_debug_msg);

         
        IF NVL(Upper(p_debug_flg),'N') = 'Y' THEN

               gc_debug_flg := UPPER(p_debug_flg);

        END IF; 
 
        ---------------------------------
        -- Create output file header info 
        ---------------------------------
               
         XX_GL_INTERFACE_PKG.CREATE_OUTPUT_FILE(p_cntrl_flag   =>'HEADER'
                                               ,p_source_name  => p_source_name);

        ---------------------
        -- Main cursor opened
        ---------------------

        lc_debug_msg     := '    Opened get_je_main_process_cursor';
        DEBUG_MESSAGE (lc_debug_msg);

        OPEN get_je_main_process_cursor;
        LOOP

             FETCH get_je_main_process_cursor
              INTO      gn_group_id           
                       ,gc_source_name
                       ,lc_batch_desc
                       ,lc_reference24;   --file name
   
             IF lc_firsT_record = 'Y'AND (gc_source_name IS NULL 
                                           OR gn_group_id IS NULL) THEN
                   RAISE NO_GROUP_ID_FOUND;
                    
             END IF;
   
         EXIT WHEN get_je_main_process_cursor%NOTFOUND;

            lc_firsT_record  := 'N';


        lc_debug_msg     := '    before LOG_MESSAGE';
        DEBUG_MESSAGE (lc_debug_msg);

             ---------------------
             -- write to log table
             --------------------- 
             XX_GL_INTERFACE_PKG.LOG_MESSAGE 
                           (p_grp_id      =>   gn_group_id
                           ,p_source_nm   =>   gc_source_name
                           ,p_status      =>  'RECEIVED FILE'
                           ,p_details     =>  'File Name: '  || lc_reference24
                            );     

 
        lc_debug_msg     := '    after LOG_MESSAGE';
        DEBUG_MESSAGE (lc_debug_msg);          



  
    
           -----------------------------------------------------------------
            -- Determine if interface has been run previously for a group_id. 
            -- If records exist on error tbl then interface was run already.
            -- Set lc_purge_error_log to delete old error records.
            ----------------------------------------------------------------
            lc_debug_msg     := '    Checking Error table for'
                              ||' previous run of Group ID: '|| gn_group_id;

            DEBUG_MESSAGE  (lc_debug_msg,1);

            SELECT count(1)
            INTO   ln_error_cnt
            FROM   XXFIN.XX_GL_INTERFACE_NA_ERROR
            WHERE  group_id = gn_group_id 
            AND    rownum < 2;

            IF ln_error_cnt > 0 THEN
                
                   lc_purge_err_log := 'Y';
  
                   lc_debug_msg     := '    Previous errors found, ' 
                                       ||'Purge error flag = '|| lc_purge_err_log;
                   DEBUG_MESSAGE  (lc_debug_msg);


                  -----------------------
                  -- Write restart to log
                  -----------------------
                   XX_GL_INTERFACE_PKG.LOG_MESSAGE 
                           (p_grp_id      =>   gn_group_id
                           ,p_source_nm   =>   gc_source_name
                           ,p_status      =>  'RESTARTED'
                           ,p_details     =>  'File Name: '  || lc_reference24
                            );

                   ------------------------------------------- 
                   -- Delete previous records from error table
                   -------------------------------------------

                   BEGIN

                        lc_debug_msg  := '    Deleting previous error records';   
  
                        DELETE FROM XXFIN.XX_GL_INTERFACE_NA_ERROR
                        WHERE   group_id = gn_group_id;

                        COMMIT;
 
                   EXCEPTION  
                       WHEN OTHERS THEN
     
                       fnd_message.clear();              
	               fnd_message.set_name('FND','FS-UNKNOWN'); 
	               fnd_message.set_token('ERROR',SQLERRM);
                       fnd_message.set_token('ROUTINE',lc_debug_msg
                                                  ||gc_debug_pkg_nm 
                                                  ||lc_debug_prog);
                  
                   END;  
 
                   

                   BEGIN

                      ----------------------------------------------------- 
                      -- Delete any inter-company records from previous run
                      -----------------------------------------------------
                       lc_debug_msg     := '    Deleting previous inter-company records'; 
                      
                       DELETE FROM XXFIN.XX_GL_INTERFACE_NA_STG 
                       WHERE group_id = gn_group_id 
                       AND   derived_sob = 'INTER-COMP';

                       COMMIT;


                   EXCEPTION  
                       WHEN OTHERS THEN
     
                       fnd_message.clear();              
	               fnd_message.set_name('FND','FS-UNKNOWN'); 
	               fnd_message.set_token('ERROR',SQLERRM);
                       fnd_message.set_token('ROUTINE',lc_debug_msg
                                                  ||gc_debug_pkg_nm 
                                                  ||lc_debug_prog);
                  
                   END;


  

                   --------------------------------------------- 
                   -- Update previous records from staging table
                   ---------------------------------------------

                   BEGIN

  
                          UPDATE XXFIN.XX_GL_INTERFACE_NA_STG
                           SET DERIVED_VAL = 'INVALID'
                              ,DERIVED_SOB = 'INVALID'
                              ,BALANCED    = 'UNBALANCED'
                        WHERE  group_id = gn_group_id;

                        COMMIT;

                        lc_debug_msg  := '    updated previous error flags'
                                         ||' on staging table ';
                        DEBUG_MESSAGE  (lc_debug_msg);
 
                   EXCEPTION  
                       WHEN OTHERS THEN
     
                       fnd_message.clear();              
	               fnd_message.set_name('FND','FS-UNKNOWN'); 
	               fnd_message.set_token('ERROR',SQLERRM);
                       fnd_message.set_token('ROUTINE',lc_debug_msg
                                                  ||gc_debug_pkg_nm 
                                                  ||lc_debug_prog);
                       lc_debug_msg := fnd_message.get(); 

                       DEBUG_MESSAGE  (lc_debug_msg);
                       FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );
                  
                   END; 
        
            ELSE
                 
                  -------------------------------
                  -- Checking for duplicate files
                  -------------------------------
                  lc_debug_msg     := '   Duplicate records from'
                              ||' previous run of Group ID: '|| gn_group_id;

                  DEBUG_MESSAGE  (lc_debug_msg,1);

                  BEGIN

                       lc_details := NULL;
 
                       SELECT DISTINCT 
                                details
                         INTO  lc_details
                         FROM  XXFIN.XX_GL_INTERFACE_NA_LOG
                        WHERE
                              RTRIM(substr(details,12,250)) = lc_reference24;

                        RAISE DUPLICATE_FILE_FOUND;
                     

                  EXCEPTION

                     WHEN NO_DATA_FOUND  THEN

                     ---------------------
                     -- write to log table
                     --------------------- 
                      XX_GL_INTERFACE_PKG.LOG_MESSAGE 
                           (p_grp_id      =>   gn_group_id
                           ,p_source_nm   =>   gc_source_name
                           ,p_status      =>  'RECEIVED FILE'
                           ,p_details     =>  'File Name: '  || lc_reference24
                           ); 
                           
     

                  END;

    
                  --------------------------------------------- 
                   -- APPEND file name to batch description
                   ---------------------------------------------

                   BEGIN

                        UPDATE XXFIN.XX_GL_INTERFACE_NA_STG
                           SET reference2 = reference2 ||' '|| lc_reference24          
                        WHERE  group_id    = gn_group_id
                          AND  reference24 = lc_reference24;

                        COMMIT;

                        lc_debug_msg  := '    updated batch desc with file name'
                                         ||' on staging table ';
                        DEBUG_MESSAGE  (lc_debug_msg);
 
                   EXCEPTION  
                       WHEN OTHERS THEN
     
                       fnd_message.clear();              
	               fnd_message.set_name('FND','FS-UNKNOWN'); 
	               fnd_message.set_token('ERROR',SQLERRM);
                       fnd_message.set_token('ROUTINE',lc_debug_msg
                                                  ||gc_debug_pkg_nm 
                                                  ||lc_debug_prog);
                       lc_debug_msg := fnd_message.get(); 

                       DEBUG_MESSAGE  (lc_debug_msg);
                       FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );
                  
                   END; 
                   lc_purge_err_log := 'N';

                   lc_debug_msg     := '    No previous errors found, '
                                       ||'Purge error flag = '|| lc_purge_err_log;   
                  DEBUG_MESSAGE  (lc_debug_msg);

            END IF;

            ----------------------------
            --  Derive all needed values
            ----------------------------

            GLSI_DERIVE_VALUES;  


            lc_debug_msg := 'Total number of Derived errors: ' || gn_error_count; 
            DEBUG_MESSAGE (lc_debug_msg,1);   

 
 
            ----------------------------
            --  PROCESS JOURNAL LINES
            ----------------------------

            XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES(p_grp_id       => gn_group_id 
                                                  ,p_source_nm    => gc_source_name
                                                  ,p_file_name    => lc_reference24 
                                                  ,p_err_cnt      => gn_error_count
                                                  ,p_debug_flag   => gc_debug_flg 
                                                  ,p_chk_bal_flg  => 'Y'
                                                  ,p_chk_sob_flg  => 'Y'
                                                  ,p_bypass_flg   => 'Y'
                                                   );



       END LOOP;
       CLOSE get_je_main_process_cursor;

       lc_debug_msg := '!!!!!Total number of all errors: ' || gn_error_count; 
       DEBUG_MESSAGE (lc_debug_msg,1);  

       IF  gn_error_count <> 0 THEN

               lc_mail_subject := 'ERRORS: Found in '|| gc_source_name|| ' GL Import!';
       ELSE
               lc_mail_subject := gc_source_name ||' Import completed!';
       END IF;

       lc_debug_msg := 'Emailing output report: gn_request_id=> ' 
                       ||gn_request_id || ' gc_source_name=> ' ||gc_source_name
                       || ' lc_mail_subject=> ' || lc_mail_subject;

       DEBUG_MESSAGE (lc_debug_msg,1); 
        
 

       ln_conc_id := fnd_request.submit_request( application => 'XXFIN'       
						,program     => 'XXGLINTERFACEEMAIL' 
						,description => NULL
						,start_time  => SYSDATE
						,sub_request => FALSE
                     				,argument1   => gn_request_id
                                                ,argument2   => gc_source_name
                                                ,argument3   => lc_mail_subject  
                                                );
    
    EXCEPTION

         WHEN DUPLICATE_FILE_FOUND THEN

                lc_debug_msg := '    Duplicate file is being processed: '
                                        ||'Group ID =>'   || gn_group_id
                                        ||' File Name =>' || lc_reference24
                                           ||' on staging table ';

                fnd_message.clear();              
          	fnd_message.set_name('FND','FS-UNKNOWN'); 
	        fnd_message.set_token('ERROR',lc_debug_msg);
                fnd_message.set_token('ROUTINE',gc_debug_pkg_nm 
                                                ||lc_debug_prog
                                     );


                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Duplicate file is being processed'
                                             ||' on staging table');

                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Duplicate file is being processed'
                                             ||' on staging table');

	        x_return_code    := 2;
                x_return_message := fnd_message.get(); 

         WHEN NO_GROUP_ID_FOUND THEN   
	
                lc_debug_msg := '    No data exists for GROUP_ID: '
                                           || gn_group_id 
                                           ||' on staging table ';

                fnd_message.clear();              
          	fnd_message.set_name('FND','FS-UNKNOWN'); 
	        fnd_message.set_token('ERROR',lc_debug_msg);
                fnd_message.set_token('ROUTINE',gc_debug_pkg_nm 
                                                ||lc_debug_prog
                                     );


                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No records or invalid group/source ID'
                                             ||' on staging table');

                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No records or invalid group/source ID'
                                             ||' on staging table');

	        x_return_code    := 2;
                x_return_message := fnd_message.get(); 

        WHEN OTHERS THEN
	       
               fnd_message.clear();              
	       fnd_message.set_name('FND','FS-UNKNOWN'); 
	       fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',lc_debug_msg
                                               ||gc_debug_pkg_nm 
                                               ||lc_debug_prog 
                                                
                                     );

               x_return_code    := 1;
	       x_return_message := fnd_message.get(); 

               -----------------------------------
	       --TODO insert into stardard err tbl	
               --XX_GL_INTERFACE_PKG.INSERT_ERROR_MESSAGE( 'x_return_message'); 

			
     END PROCESS_JOURNALS;


END XX_GL_GLSI_INTERFACE_PKG;

/







