SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET TERM         ON

PROMPT Creating Package Specification XX_AR_CREATE_ACCT_MASTER_PKG 
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_GL_GLSI_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_GSS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface GLSI       |
-- |                      data with the Oracle GL                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco				       |
-- |1.1      24-FEB-2008 Raji              Fixed Defect 4889           |
-- |1.2      10-MAR-2008 Raji              Fixed defect 5308           |
-- |1.3      11-MAR-2008 Raji              Fixed defect 5330           |  
-- |1.4      12-MAR-2008 Raji              Fixed defect 5328           |
-- |1.5       08-29/2008  Chandarakala D   Changes for defect  5327    |
-- |1.6      07-JUL-2009 Ganesan JV        Fixed defect 538            |
-- |1.7      10-Jun-2013 Paddy Sanjeevi    Modified for defect 18792   |
-- |1.8      18-Jul-2013 Sheetal           I0463 - Changes for R12     |
-- |                                       Upgrade retrofit.           |
-- +===================================================================+

    gc_translate_error VARCHAR2(5000);
    gc_error_message   VARCHAR2(5000);
    gc_source_name     XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gc_category_name   XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
    gn_group_id        XX_GL_INTERFACE_NA_STG.group_id%TYPE;
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

    lc_trans_name        XX_FIN_TRANSLATEDEFINITION.translation_name%TYPE;


    lc_ora_company       XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_cost_center   XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_account       XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_location      XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_inter_company XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_lob           XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ora_future        XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ccid              XX_GL_INTERFACE_NA_STG.code_combination_id%TYPE;


    lc_ps_company        XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
    lc_ps_cost_center    XX_GL_INTERFACE_NA_STG.legacy_segment2%TYPE;
    lc_ps_account        XX_GL_INTERFACE_NA_STG.legacy_segment3%TYPE;
    lc_ps_location       XX_GL_INTERFACE_NA_STG.legacy_segment4%TYPE;
    lc_ps_lob            XX_GL_INTERFACE_NA_STG.legacy_segment6%TYPE;
    ln_sob               XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;


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
            FROM  XX_GL_INTERFACE_NA_STG
           WHERE group_id                       = gn_group_id
            AND(  NVL(derived_val,'INVALID')    = 'INVALID'
             OR   NVL(derived_sob,'INVALID')    = 'INVALID');




    ----------------------------------------
    -- bug in translation definition program
    ----------------------------------------
    lc_source_value2     xx_fin_translatevalues.source_value2 %TYPE;

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

               lc_error_flg  := 'N';
               
               XX_CNV_GL_PSFIN_PKG.TRANSLATE_PS_VALUES(
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
                    
----Defect 5330 and 5328                                
                     IF lc_ora_company IS NULL THEN 
                     lc_ora_company := lc_ps_company;
                     END IF;
                     IF lc_ora_cost_center IS NULL THEN
                     lc_ora_cost_center := lc_ps_cost_center;
                     END IF;
                     IF lc_ora_account IS NULL THEN
                     lc_ora_account := lc_ps_account;
                     END IF;
                     IF lc_ora_location IS NULL THEN
                     lc_ora_location := lc_ps_location;
                     END IF;
                     
                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  ln_row_id
                                   ,p_fnd_message  =>  'XX_GL_TRANS_VALUE_ERROR'
                                   ,p_source_nm      =>  gc_source_name
                                   ,p_type         =>  lc_ora_company||'.'||lc_ora_cost_center||'.'||lc_ora_account||'.'||lc_ora_location||'.'||lc_ora_inter_company||'.'||lc_ora_lob||'.'||lc_ora_future
       	                           ,p_value        =>  lc_ps_company||'.'||lc_ps_cost_center||'.'||lc_ps_account||'.'||lc_ps_location
                                   ,p_details      =>  SUBSTR('Derived Value Error: '||gc_error_message,1,100)
                                   ,p_group_id     =>  gn_group_id
                                   );
                                   
                     lc_error_flg := 'Y';
                     
                     ELSE
                     
                     lc_error_flg := 'N';
                     
               
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
                   	UPDATE XX_GL_INTERFACE_NA_STG
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
            
             BEGIN
                   	UPDATE XX_GL_INTERFACE_NA_STG
         	        SET    segment1              =  lc_ora_company
                              ,Segment2              =  lc_ora_cost_center
     	                      ,segment3              =  lc_ora_account
                              ,segment4              =  lc_ora_location
                              ,segment5              =  lc_ora_inter_company
                              ,segment6              =  lc_ora_lob
                              ,segment7              =  lc_ora_future
                              ,code_combination_id   =  lc_ccid
	                      ,derived_val           =  'INVALID'
               	       WHERE   rowid     =  ln_row_id;

		       COMMIT;

                           lc_debug_msg :='    Values errored Updating: '
                                     ||'company=> '         ||lc_ora_company
                                     ||', cost_center=> '   ||lc_ora_cost_center
                                     ||', account=> '       ||lc_ora_account
                                     ||', location=> '      ||lc_ora_location
                                     ||', inter_company=> ' ||lc_ora_inter_company
                                     ||', lc_ora_lob=> '    ||lc_ora_lob
                                     ||', Future=> 000000 ' ||'INVALID';

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
          ln_itg_error_cnt   NUMBER;
          ln_dup_cnt         NUMBER;
          lc_purge_err_log   VARCHAR2(1);
          ln_Conc_req_id     NUMBER;
          lc_log_status      XX_GL_INTERFACE_NA_LOG.status%TYPE;
          lc_submit_import   VARCHAR2(1);
          lc_debug_msg       VARCHAR2(2000);
          ln_temp_err_cnt    NUMBER;
          lc_firsT_record    VARCHAR2(1);
          lc_debug_prog      VARCHAR2(100) := 'PROCESS_JOURNALS';
          ln_conc_id         INTEGER;
          lc_mail_subject    VARCHAR2(250);
          lc_details         XX_GL_INTERFACE_NA_LOG.details%TYPE;

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
          lc_legacy_segment4 XX_GL_INTERFACE_NA_STG.legacy_segment4%TYPE;
          lc_legacy_segment1 XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
          lc_reference24     XX_GL_INTERFACE_NA_STG.reference24%TYPE;


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
        lc_firsT_record   := 'Y';
        gn_error_count    :=  0;
        --ln_group_id     :=  0;




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
                       ,lc_reference24;   --file name

             IF lc_firsT_record = 'Y'AND (gc_source_name IS NULL
                                           OR gn_group_id IS NULL) THEN
                   RAISE NO_GROUP_ID_FOUND;

             END IF;

         EXIT WHEN get_je_main_process_cursor%NOTFOUND;

            lc_firsT_record  := 'N';




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



                   BEGIN

                      -----------------------------------------------------
                      -- Delete any inter-company records from previous run
                      -----------------------------------------------------
                       lc_debug_msg     := '    Deleting previous inter-company records';

                       DELETE FROM XX_GL_INTERFACE_NA_STG
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


                          UPDATE XX_GL_INTERFACE_NA_STG
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

                  SELECT count(1)
                    INTO  ln_dup_cnt
                    FROM  XX_GL_INTERFACE_NA_LOG
                   WHERE
                          RTRIM(substr(details,12,250)) = lc_reference24;

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

	    -- Modified by Paddy for the defect # 18792

	    IF p_source_name IN ('OD Inventory (SIV)','OD AP Integral') THEN

	       XX_GL_INT_EBS_COA_PKG.GLSI_ITGORA_DERIVE_VALUES(gn_group_id,gc_source_name,
						     gn_request_id,NVL(Upper(p_debug_flg),'N'),
						     ln_itg_error_cnt);

	       gn_error_count:=ln_itg_error_cnt;

	    ELSE	
              GLSI_DERIVE_VALUES;
	    END IF;


            lc_debug_msg := 'Total number of Derived errors: ' || gn_error_count;
            DEBUG_MESSAGE (lc_debug_msg,1);



            ----------------------------
            --  PROCESS JOURNAL LINES
            ----------------------------


            XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES
				(p_grp_id       => gn_group_id
                                ,p_source_nm    => gc_source_name
                                ,p_file_name    => lc_reference24
                                ,p_err_cnt      => gn_error_count
                                ,p_debug_flag   => gc_debug_flg
                                ,p_chk_bal_flg  => 'Y' --'Y' commented by Raji 04/mar --Set to 'Y' for defect 5327
                                ,p_chk_sob_flg  => 'Y'
                                ,p_summary_flag   => 'Y' -- added by Raji 10/Mar/08 defect 5308
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
----Defect 4889---
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

	        x_return_code    := 0; --changed from 2 to 0 for the defect 538 by Ganesan
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

--+===================================================================+
-- | Name  :CREATE_SUSPENSE_LINES                                      
-- | Description : This procedure will be used to find
-- |               the difference in balance of the credit 
-- |               and debit amount of the journal entry  
-- |               and create a new suspense line with it
-- |                  
-- |               
-- | Parameters : p_grp_id, 
-- | 
-- |                                                                   
-- +===================================================================+
 
PROCEDURE CREATE_SUSPENSE_LINES(p_grp_id NUMBER
				,p_sob_id NUMBER
                                )
AS
lc_source_name VARCHAR2(30) :=  'OD Inventory (SIV)';
lc_src_name   XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
lc_debug_prog        VARCHAR2(100) := 'CREATE_SUSPENSE_LINES';
ln_suspense_line_counter NUMBER(10) := 0;
ln_created_by  NUMBER := fnd_profile.value('USER_ID');
lc_debug_msg VARCHAR2(250);

CURSOR lcu_unbalanced_lines IS
SELECT 
                          status
                         ,XGINS.set_of_books_id
                         --,GSOB.currency_code sob_curr Commented as part of R12 Retrofit
                         ,GL.currency_code sob_curr --Added as part of R12 Retrofit                        
                         ,date_created
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,user_je_category_name
                         ,user_je_source_name
                         ,accounting_date
                         ,XGINS.currency_code
                         ,decode(sign(sum(nvl(entered_dr,0))-sum(nvl(entered_cr,0))),-1,-(sum(nvl(entered_dr,0))-sum(nvl(entered_cr,0))),null) debit
                         ,decode(sign(sum(nvl(entered_dr,0))-sum(nvl(entered_cr,0))),1,sum(nvl(entered_dr,0))-sum(nvl(entered_cr,0)),null) credit
                         ,reference24
	               ,target_Value1
	               ,target_Value2
	               ,target_Value3
	               ,target_Value4
	               ,target_Value5
	               ,target_Value6
	               ,target_Value7
FROM xx_gl_interface_na_stg XGINS
      --, gl_sets_of_books GSOB Commented as part of R12 Retrofit
	  , gl_ledgers GL --Added as part of R12 Retrofit
      ,  xx_fin_translatedefinition XFTD
      ,  xx_fin_translatevalues  XFTV
    WHERE user_je_source_name = lc_source_name 
    --AND XGINS.set_of_books_id =  GSOB.set_of_books_id(+) Commented as part of R12 Retrofit
	AND XGINS.set_of_books_id =  GL.ledger_id(+) --Added as part of R12 Retrofit
    AND XFTD.translation_name = 'OD_GL_GLSI_DEFAULTS'
    AND XFTD.translate_id  = XFTV.translate_id
    --AND XFTV.source_value1 = GSOB.currency_code Commented as part of R12 Retrofit
	AND XFTV.source_value1 = GL.currency_code --Added as part of R12 Retrofit
    AND group_id = p_grp_id
    AND XGINS.set_of_books_id = p_sob_id
    AND  (NVL(derived_val,'INVALID')    = 'INVALID'
    OR   NVL(derived_sob,'INVALID')    = 'INVALID'
    OR   NVL(balanced   ,'UNBALANCED') = 'UNBALANCED')
    GROUP BY 
	                  status
                         ,XGINS.set_of_books_id
                         --,GSOB.currency_code  Commented as part of R12 Retrofit
						 ,GL.currency_code  --Added as part of R12 Retrofit
                         ,date_created
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,user_je_category_name
                         ,user_je_source_name
                         ,accounting_date
                         ,XGINS.currency_code
                         ,reference24
	                ,target_Value1
	               ,target_Value2
	               ,target_Value3
	               ,target_Value4
	               ,target_Value5
	               ,target_Value6
	               ,target_Value7
                       having sum(nvl(entered_dr,0))-sum(nvl(entered_cr,0)) <> 0;
BEGIN
     BEGIN
       SELECT distinct user_je_source_name
       INTO lc_src_name
       FROM XX_GL_INTERFACE_NA_STG
       WHERE group_id = p_grp_id;
    EXCEPTION
    WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );
    END;


IF  lc_src_name = lc_source_name THEN
     
       FOR lcu_unbalanced_rec in lcu_unbalanced_lines
            LOOP  
		BEGIN           
                       INSERT INTO  XX_GL_INTERFACE_NA_STG
                         (status
                         ,set_of_books_id
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,user_je_category_name
                         ,user_je_source_name
                         ,accounting_date
                         ,currency_code
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference24
	      		 ,segment1
	       		 ,segment2
	       		 ,segment3
	      		 ,segment4 
	      		 ,segment5
	      		 ,segment6
	      		 ,segment7
                         )
         	       VALUES(lcu_unbalanced_rec.status
                 	 ,lcu_unbalanced_rec.set_of_books_id
                 	 ,lcu_unbalanced_rec.date_Created
                 	 ,ln_created_by
                 	 ,lcu_unbalanced_rec.actual_flag
                	 ,lcu_unbalanced_rec.group_id
                 	 ,lcu_unbalanced_rec.reference1
                	 ,lcu_unbalanced_rec.reference2
                	 ,lcu_unbalanced_rec.reference4
                	 ,lcu_unbalanced_rec.reference5
                 	 ,lcu_unbalanced_rec.reference6
                 	 ,lcu_unbalanced_rec.user_je_category_name
                 	 ,lcu_unbalanced_rec.user_je_source_name
                 	 ,lcu_unbalanced_rec.accounting_date
                 	 ,lcu_unbalanced_rec.currency_code--.currency_code
                 	 ,lcu_unbalanced_rec.debit--.debit
                 	 ,lcu_unbalanced_rec.credit--.credit
                	 ,'Suspense Account added to Balance Legacy Intercompany'
                  	 ,lcu_unbalanced_rec.reference24
			 ,lcu_unbalanced_rec.target_value1
			 ,lcu_unbalanced_rec.target_value2
		         ,lcu_unbalanced_rec.target_value3
			 ,lcu_unbalanced_rec.target_value4
			 ,lcu_unbalanced_rec.target_value5
			 ,lcu_unbalanced_rec.target_value6
			 ,lcu_unbalanced_rec.target_value7);

          	     COMMIT;
            	     ln_suspense_line_counter:=ln_suspense_line_counter+1;
                     --lc_reference1:=lcu_unbalanced_rec.reference1;
                     --ln_group_id:=lcu_unbalanced_rec.group_id;
	  EXCEPTION
		WHEN others THEN
		lc_debug_msg := 'Error in inserting the suspense line for'|| lcu_unbalanced_rec.reference1||SQLERRM ;
		DEBUG_MESSAGE (lc_debug_msg,1);
	  END;
          -- EXIT WHEN lcu_unbalanced_lines%NOTFOUND;

     END LOOP; 
FND_FILE.PUT_LINE(FND_FILE.LOG,'No of suspense line created for group_id:  ' || p_grp_id||' is ' || ln_suspense_line_counter);


 ELSE
     lc_debug_msg := 'Source :OD Inventory (SIV) not found';
     DEBUG_MESSAGE (lc_debug_msg,1);
 NULL;
 END IF;

EXCEPTION
       WHEN OTHERS THEN
               fnd_message.clear();
	       fnd_message.set_name('FND','FS-UNKNOWN');
	       fnd_message.set_token('ERROR',SQLERRM);
                         fnd_message.set_token('ROUTINE',lc_debug_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);
                                   
              --  x_return_code    := 1;
             --   x_return_message := fnd_message.get();
 END CREATE_SUSPENSE_LINES; 



END XX_GL_GLSI_INTERFACE_PKG;
/
SHO ERR;