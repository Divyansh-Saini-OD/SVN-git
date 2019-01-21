create or replace PACKAGE BODY XX_GL_TMS_INTERFACE_PKG AS

 -- +==================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |               		Office Depot Organization   	       |
-- +===================================================================+
-- | Name  : XX_GL_TMS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface a Treasury |
-- |                     Management data file to the Oracle GL         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      03-MAR-2010  D.Nardo	   Initial version             |
-- |2.0      18-Nov-2015  Avinash Baddam   R12.2 Compliance Changes    |
-- +===================================================================+

    gc_translate_error VARCHAR2(5000);
    gc_source_name     XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gc_category_name   XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
    gn_group_id        XX_GL_INTERFACE_NA_STG.group_id%TYPE;
    gn_error_count     NUMBER := 0;
    gc_debug_pkg_nm    VARCHAR2(30) := 'XX_GL_TMS_INTERFACE_PKG.';
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
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for the CE      |
-- |                    interface. This will be called by the OD: GL   |
-- |                    Interface for TMS concurrent program.          |
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
          ln_dup_cnt         NUMBER;
          lc_purge_err_log   VARCHAR2(1);
          ln_Conc_req_id     NUMBER;
          lc_log_status      XX_GL_INTERFACE_NA_LOG.status%TYPE;
          lc_submit_import   VARCHAR2(1);
          lc_debug_msg       VARCHAR2(2000);
          ln_temp_err_cnt    NUMBER;
          lc_first_record    VARCHAR2(1);
          lc_debug_prog      VARCHAR2(100) := 'PROCESS_JOURNALS';
          ln_conc_id         INTEGER;
          lc_mail_subject    VARCHAR2(250);


          ------------------------------------------------
          --local variables for get_je_main_process_cursor
          ------------------------------------------------
          ln_group_id    XX_GL_INTERFACE_NA_STG.group_id%TYPE;
          lc_source_name XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
          lc_batch_desc  XX_GL_INTERFACE_NA_STG.reference2%TYPE;


          -----------------------------------------
          --local variables for get_je_lines_cursor
          -----------------------------------------
          ln_row_id          rowid;
          lc_jnrl_name       XX_GL_INTERFACE_NA_STG.reference22%TYPE;
          lc_derived_sob     XX_GL_INTERFACE_NA_STG.derived_sob%TYPE;
          lc_derived_value   XX_GL_INTERFACE_NA_STG.derived_val%TYPE;
	  lc_balanced        XX_GL_INTERFACE_NA_STG.balanced%TYPE;
          lc_gl_gl_line_desc XX_GL_INTERFACE_NA_STG.reference10%TYPE;
          lc_gl_je_line_code XX_GL_INTERFACE_NA_STG.reference22%TYPE;
          lc_ora_company     XX_GL_INTERFACE_NA_STG.segment1%TYPE;
          ln_sobid           XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;        
          lc_reference24     XX_GL_INTERFACE_NA_STG.reference24%TYPE;

          lc_details         XX_GL_INTERFACE_NA_LOG.details%TYPE;
          p_set_of_books_id  XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;

         ------------------------------------------------
          -- Cursor to select all group ids from a source
          ------------------------------------------------
          
          
          CURSOR get_je_main_process_cursor 
              IS
          SELECT DISTINCT
                  group_id
                 ,user_je_source_name
                 ,reference24
                  FROM  XX_GL_INTERFACE_NA_STG
           WHERE user_je_source_name  = p_source_name
             AND NVL(balanced   ,'UNBALANCED') = 'UNBALANCED';
            -- AND set_of_books_id    = p_set_of_books_id
             



     BEGIN
      -- Get set of books based on responsibility running this program
      --  p_set_of_books_id := fnd_profile.value('GL_SET_OF_BKS_ID');
   

          FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '
                                         ||gc_debug_pkg_nm
                                         ||lc_debug_prog
                                         ||' JE Source Name: '
                                         || p_source_name);
        -------------------
        -- initalize values
        -------------------
        lc_first_record  := 'Y';
        gn_error_count   :=  0;
        ln_group_id      := NULL;

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
        
        -- lc_debug_msg     := '    Profile set of books '|| p_set_of_books_id; 
        --DEBUG_MESSAGE (lc_debug_msg);

        lc_debug_msg     := '    Opening get_je_main_process_cursor';
        DEBUG_MESSAGE (lc_debug_msg);

        --OPEN get_je_main_process_cursor(p_set_of_books_id);
        OPEN get_je_main_process_cursor;
        LOOP

             FETCH get_je_main_process_cursor
              INTO      gn_group_id
                       ,gc_source_name
                       ,lc_reference24;   --file name

             IF lc_first_record = 'Y'AND (gc_source_name IS NULL
                                           OR gn_group_id IS NULL) THEN
                   RAISE NO_GROUP_ID_FOUND;

             END IF;

         EXIT WHEN get_je_main_process_cursor%NOTFOUND;

            lc_first_record  := 'N';



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
            FROM   XX_GL_INTERFACE_NA_ERROR
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

                        DELETE FROM XX_GL_INTERFACE_NA_ERROR
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

                   ---------------------------------------------
                   -- Update previous records from staging table
                   ---------------------------------------------

                   BEGIN



                        UPDATE XX_GL_INTERFACE_NA_STG
                           SET DERIVED_VAL = 'INVALID'
                              ,DERIVED_SOB = 'INVALID'
                              ,BALANCED    = 'UNBALANCED'
                        WHERE  group_id = gn_group_id;

                        COMMIT;

                        lc_debug_msg  := '    updated previous derived and balanced flags'
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
                  lc_debug_msg     := '    Checking duplicate records from'
                              ||' previous run of Group ID: '|| gn_group_id;

                  DEBUG_MESSAGE  (lc_debug_msg,1);
                  ln_dup_cnt := 0;
                  
                  SELECT count(1)
                    INTO  ln_dup_cnt
                    FROM  XX_GL_INTERFACE_NA_LOG
                   WHERE
                          RTRIM(substr(details,12,250)) = lc_reference24;
                          
                  lc_debug_msg     := '    Duplicate count: ' || ln_dup_cnt;
                  DEBUG_MESSAGE  (lc_debug_msg,1);
                         

                  IF  ln_dup_cnt  <> 0 THEN

                        RAISE DUPLICATE_FILE_FOUND;

                  ELSE

                     ---------------------
                     -- write to log table
                     ---------------------
                      XX_GL_INTERFACE_PKG.LOG_MESSAGE
                           (p_grp_id      =>   gn_group_id
                           ,p_source_nm   =>   gc_source_name
                           ,p_status      =>  'RECEIVED FILE'
                           ,p_details     =>  'File Name: '  || lc_reference24
                           );


                   END IF;

                   ---------------------------------------------
                   -- APPEND file name to batch description
                   ---------------------------------------------

                   BEGIN

                        UPDATE XX_GL_INTERFACE_NA_STG
                           SET reference2 = reference2 ||' '|| lc_reference24
                         WHERE group_id    = gn_group_id
                           AND reference24 = lc_reference24;

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



                   ---------------------------------------------
                   -- Update previous records from staging table
                   -- to valid status to by-pass deriving values.
                   -- Make sure DERIVED_SOB remains 'INVALID' because
                   -- it does need to be derived by the GL Interface.
                   ---------------------------------------------

                   BEGIN                                                 

                        UPDATE XX_GL_INTERFACE_NA_STG
                           SET DERIVED_VAL = 'VALID'                            
                              ,BALANCED    = 'UNBALANCED'
                        WHERE  group_id = gn_group_id;

                        COMMIT;

                        lc_debug_msg  := '    updated derived and balanced flags'
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


                  lc_debug_msg     := '    No previous errors found, '
                                      ||'Purge error flag = '|| lc_purge_err_log;
                  DEBUG_MESSAGE  (lc_debug_msg);

            END IF;

            ----------------------------
            --  PROCESS JOURNAL LINES
            ----------------------------

       
		-- Have interface determine the Set of Books id - do not want it hardcoded by vendor
        

            XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES(p_grp_id         => gn_group_id
                                                  ,p_source_nm      => gc_source_name
                                                  ,p_file_name      => lc_reference24
                                                  ,p_err_cnt        => gn_error_count
                                                  ,p_debug_flag     => gc_debug_flg
                                                  ,p_chk_bal_flg    => 'Y'
                                                  ,p_chk_sob_flg    => 'Y'               
                                                   );



       END LOOP;
       CLOSE get_je_main_process_cursor;

       lc_debug_msg := '!!!!!Total number of all errors: ' || gn_error_count;
       DEBUG_MESSAGE (lc_debug_msg,1);

       IF  gn_error_count <> 0 THEN

               lc_mail_subject := 'ERRORS: Found in '||gc_source_name ||' GL Import!';
       ELSE
               lc_mail_subject :=  gc_source_name||' GL Import completed!';

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
                                        ||'Group ID '   || gn_group_id
                                        ||' File Name ' || lc_reference24
                                        ||' on staging table ';
                                           
                lc_mail_subject :=  gc_source_name ||' Duplicate File is processed in the staging table!' ;
                                           
                ln_conc_id := fnd_request.submit_request( application => 'XXFIN'
                      		,program     => 'XXGLINTERFACEEMAIL'
                          ,description => NULL
                          ,start_time  => SYSDATE
                          ,sub_request => FALSE
                          ,argument1   => gn_request_id
                          ,argument2   => gc_source_name
                          ,argument3   => lc_mail_subject
                           );  
                COMMIT;
                
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
                                           
                lc_mail_subject :=  gc_source_name ||'No data exists for GROUP_ID: '|| gn_group_id ||' on staging table ' ;
                                           
                ln_conc_id := fnd_request.submit_request( application => 'XXFIN'
                        			,program     => 'XXGLINTERFACEEMAIL'
                              ,description => NULL
                              ,start_time  => SYSDATE
                              ,sub_request => FALSE
                              ,argument1   => gn_request_id
                              ,argument2   => gc_source_name
                              ,argument3   => lc_mail_subject
                              );  
                COMMIT;

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

                x_return_code    := 0;  
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
	      

     END PROCESS_JOURNALS;

END XX_GL_TMS_INTERFACE_PKG;

/