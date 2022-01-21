CREATE OR REPLACE
PACKAGE BODY XX_GL_GSS_INTERFACE_PKG
   AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      		Office Depot Organization   		       |
-- +===================================================================+
-- | Name  : XX_GL_GSS_INTERFACE_PKG                                   |
-- | Description      :  This PKG will be used to interface PeopleSoft |
-- |                      data with the Oracle GL                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco				       |
-- |1.1      24-FEB-2008  Raji              Fixed Defect 4889          |
-- |1.2      25-Mar-2009  P.Marco          Defect 14556                |
-- |1.3      30-Apr-2009  Ranjith T        Defect 14566                |
-- |1.4      18-NOV-2015  Madhu Bolli      Remove schema for 12.2 retrofit |
-- +===================================================================+

    gc_translate_error VARCHAR2(5000);
    gc_source_name     XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gc_category_name   XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
    gn_group_id        XX_GL_INTERFACE_NA_STG.group_id%TYPE;
    gn_error_count     NUMBER := 0;
    gc_debug_pkg_nm    VARCHAR2(24) := 'XX_GL_GSS_INTERFACE_PKG.';
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
-- | Name  :CREATE_INTERCOMP_JRNL                                      |
-- | Description      :  Creation of Inter-company journal             |
-- |                      entries for Other Fee journals               |
-- |                                                                   |
-- | Parameters :    p_group_id                                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE CREATE_INTERCOMP_JRNL (p_group_id   IN VARCHAR2 DEFAULT NULL
                                    )
    IS
          PRAGMA AUTONOMOUS_TRANSACTION;

          lc_debug_msg       VARCHAR2(1000);
          lc_debug_prog      VARCHAR2(25) := ' CREATE_INTERCOMP_JRNLS';

          ------------------
          --Local Variables
          ------------------
          lc_reference24       XX_GL_INTERFACE_NA_STG.reference24%TYPE;
          lc_reference21       XX_GL_INTERFACE_NA_STG.reference21%TYPE;
          lc_legacy_segment1   XX_GL_INTERFACE_NA_STG.legacy_segment1%TYPE;
          ln_entered_dr        XX_GL_INTERFACE_NA_STG.entered_dr%TYPE;
          ln_entered_cr        XX_GL_INTERFACE_NA_STG.entered_cr%TYPE;
          ld_date              DATE := trunc(sysdate);
          x_message_msg1       VARCHAR2(5000);
          x_message_msg2       VARCHAR2(5000);
          ln_rowid             ROWID;


          lc_trans_name        XX_FIN_TRANSLATEDEFINITION.translation_name%TYPE;
          lc_ora_location      XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
          lc_ora_company       XX_FIN_TRANSLATEVALUES.target_value4%TYPE;
          lc_ora_int_company   XX_FIN_TRANSLATEVALUES.target_value5%TYPE;
          lc_ora_int_cst_cntr  XX_FIN_TRANSLATEVALUES.target_value6%TYPE;
          lc_ora_int_accnt     XX_FIN_TRANSLATEVALUES.target_value7%TYPE;
          lc_ora_int_loc       XX_FIN_TRANSLATEVALUES.target_value8%TYPE;
          lc_ora_int_lob       XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
          lc_ora_future        FND_FLEX_VALUES_VL.attribute7%TYPE;
          lc_error_flg         VARCHAR2(1);
          lc_ps_company        XX_FIN_TRANSLATEVALUES.source_value2%TYPE;
          lc_currency_code     XX_GL_INTERFACE_NA_STG.currency_code%TYPE;
          lc_date_created      XX_GL_INTERFACE_NA_STG.date_created%TYPE;
          lc_reference1        XX_GL_INTERFACE_NA_STG.reference1%TYPE;
          lc_reference2        XX_GL_INTERFACE_NA_STG.reference2%TYPE;
          lc_accounting_date   XX_GL_INTERFACE_NA_STG.accounting_date%TYPE;
          lc_set_of_books_id   XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
          lc_je_category_name  XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;

           lc_translate_error VARCHAR2(5000);
          ---------------------------------------------------------------------
          -- Nothing is loaded to the following  x_target_value... variables.
          -- They are only needed to make XX_FIN_TRANSLATEVALUE_PROC exec correctly
          ---------------------------------------------------------------------

          x_target_value1_out  xx_fin_translatevalues.target_value1%TYPE;
          x_target_value2_out  xx_fin_translatevalues.target_value2%TYPE;
          x_target_value3_out  xx_fin_translatevalues.target_value3%TYPE;
          x_target_value4_out  xx_fin_translatevalues.target_value4%TYPE;
          x_target_value5_out  xx_fin_translatevalues.target_value5%TYPE;
          x_target_value6_out  xx_fin_translatevalues.target_value6%TYPE;
          x_target_value7_out  xx_fin_translatevalues.target_value7%TYPE;
          x_target_value8_out  xx_fin_translatevalues.target_value8%TYPE;
          x_target_value9_out  xx_fin_translatevalues.target_value9%TYPE;
          x_target_value10_out xx_fin_translatevalues.target_value10%TYPE;
          x_target_value11_out xx_fin_translatevalues.target_value11%TYPE;
          x_target_value12_out xx_fin_translatevalues.target_value12%TYPE;
          x_target_value13_out xx_fin_translatevalues.target_value13%TYPE;
          x_target_value14_out xx_fin_translatevalues.target_value14%TYPE;
          x_target_value15_out xx_fin_translatevalues.target_value15%TYPE;
          x_target_value16_out xx_fin_translatevalues.target_value16%TYPE;
          x_target_value17_out xx_fin_translatevalues.target_value17%TYPE;
          x_target_value18_out xx_fin_translatevalues.target_value18%TYPE;
          x_target_value19_out xx_fin_translatevalues.target_value19%TYPE;
          x_target_value20_out xx_fin_translatevalues.target_value20%TYPE;



          -----------------------------
          --Intercompany journal cursor
          -----------------------------

          CURSOR intercomp_jrnl_cursor IS
               SELECT rowid
                     ,reference21
                     ,set_of_books_id
                     ,legacy_segment1
                     ,reference1
                     ,user_je_category_name
                     ,entered_dr
                     ,entered_cr
                     ,currency_code
                     ,date_created
                     ,reference1
                     ,reference2
                     ,reference24
                     ,accounting_date
              FROM  XX_GL_INTERFACE_NA_STG
               WHERE reference21        = 'GSS-RET-VARIANCES'
               AND  legacy_segment1     = '0003'
               AND  user_je_source_name = gc_source_name
               AND  group_id            = gn_group_id;

    BEGIN

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                 ||  lc_debug_prog );

        lc_error_flg  := 'N';
        lc_trans_name := 'GL_GSS_ACCT_VALUES';


         OPEN intercomp_jrnl_cursor;
          LOOP

             FETCH intercomp_jrnl_cursor
              INTO      ln_rowid
                       ,lc_reference21
                       ,lc_set_of_books_id
                       ,lc_legacy_segment1
                       ,lc_reference1
                       ,lc_je_category_name
                       ,ln_entered_dr
                       ,ln_entered_cr
                       ,lc_currency_code
                       ,lc_date_created
                       ,lc_reference1
                       ,lc_reference2
                       ,lc_reference24
                       ,lc_accounting_date;


         EXIT WHEN intercomp_jrnl_cursor%NOTFOUND;


         ----------------------------------------------
         -- Derive values for intercompany journals
         ----------------------------------------------
         lc_debug_msg := 'Derive values for intercompany journals ';


         XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                  (p_translation_name => lc_trans_name
                                  ,p_source_value1    => lc_reference21
                                  ,p_source_value2    => lc_legacy_segment1
                                  ,x_target_value1    => x_target_value1_out
                                  ,x_target_value2    => x_target_value2_out
                                  ,x_target_value3    => x_target_value3_out
                                  ,x_target_value4    => lc_ora_company
                                  ,x_target_value5    => lc_ora_int_company
                                  ,x_target_value6    => lc_ora_int_cst_cntr
                                  ,x_target_value7    => lc_ora_int_accnt
                                  ,x_target_value8    => lc_ora_int_loc
                                  ,x_target_value9    => x_target_value9_out
                                  ,x_target_value10   => x_target_value10_out
                                  ,x_target_value11   => x_target_value11_out
                                  ,x_target_value12   => x_target_value12_out
                                  ,x_target_value13   => x_target_value13_out
                                  ,x_target_value14   => x_target_value14_out
                                  ,x_target_value15   => x_target_value15_out
                                  ,x_target_value16   => x_target_value16_out
                                  ,x_target_value17   => x_target_value17_out
                                  ,x_target_value18   => x_target_value18_out
                                  ,x_target_value19   => x_target_value19_out
                                  ,x_target_value20   => x_target_value20_out
		                  ,x_error_message    => lc_translate_error
                                   );


              IF lc_translate_error IS NOT NULL THEN

                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  ln_rowid
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_INTRCOMP_ERR'
                                   ,p_source_nm    =>  gc_source_name
                                   ,p_type         =>  'Inter-Company Journal'
       	                           ,p_value        =>  'derived'
                                   ,p_details      =>  gc_translate_error
                                   ,p_group_id     =>  gn_group_id
                                   );



                   gn_error_count := gn_error_count + 1;
                   lc_error_flg := 'Y';

                   lc_debug_msg := '    Ora inter-company values error: '||gc_translate_error;
                   DEBUG_MESSAGE (lc_debug_msg);

                   gc_translate_error := NULL;



               END IF;

           -----------------------------------------------------------
           -- Derive Oracle Line of Business for intercompany journals
           -----------------------------------------------------------
           lc_debug_msg := 'Deriving Oracle Line of Business for intercompany journals: ';
           DEBUG_MESSAGE (lc_debug_msg);

           XX_GL_TRANSLATE_UTL_PKG.DERIVE_LOB_FROM_COSTCTR_LOC
                                        (p_location      => lc_ora_int_loc
                                        ,p_cost_center   => lc_ora_int_cst_cntr
                                        ,x_lob           => lc_ora_int_lob
                                        ,x_error_message => gc_translate_error
                                         );

          IF gc_translate_error IS NOT NULL THEN

                  XX_GL_INTERFACE_PKG.PROCESS_ERROR
                              (p_rowid        =>  ln_rowid
                              ,p_fnd_message  =>  'XX_GL_INTERFACE_INTRCOMP_ERR'
                              ,p_source_nm    =>  gc_source_name
                              ,p_type         =>  'Inter-Company Journal'
                              ,p_value        =>  'derived'
                              ,p_details      =>  gc_translate_error
                              ,p_group_id     =>  gn_group_id
                               );

                   gn_error_count := gn_error_count + 1;
                   lc_error_flg := 'Y';

                   lc_debug_msg := '    Ora inter-company LOB error: '
                                   ||gc_translate_error;
                   DEBUG_MESSAGE (lc_debug_msg);

                   gc_translate_error := NULL;

          END IF ;


          -----------------------------------
          --Create intercompany journal line
          -----------------------------------
          lc_debug_msg := 'Creating intercomapny journal: ';
          DEBUG_MESSAGE (lc_debug_msg);

          IF NVL(ln_entered_cr,0) > 0 THEN

                 lc_debug_msg := '    Created Ora inter-company ln_entered_Cr: '||ln_entered_dr ;
                 DEBUG_MESSAGE (lc_debug_msg);

                 x_message_msg1 := 'NULL';
                 x_message_msg2 := 'NULL';

                 XX_GL_INTERFACE_PKG.CREATE_STG_JRNL_LINE
                         (p_status            =>  'NEW'
			, p_date_created      =>  lc_date_created
			, p_created_by        =>  3
			, p_actual_flag       =>  'A'
			, p_group_id          =>  gn_group_id
			, p_batch_name        =>  lc_reference1     --TO_CHAR(lc_date_created,'YYYY/MM/DD')
			, p_batch_desc        =>  lc_reference2
			, p_user_source_name  =>  gc_source_name
			, p_user_catgory_name =>  lc_je_category_name
			, p_set_of_books_id   =>  lc_set_of_books_id
			, p_accounting_date   =>  lc_accounting_date
			, p_currency_code     =>  lc_currency_code
			, p_company           =>  lc_ora_int_company    --segment1
			, p_cost_center       =>  lc_ora_int_cst_cntr   --segment2
			, p_account           =>  lc_ora_int_accnt      --segment3
			, p_location          =>  lc_ora_int_loc        --segment4
			, p_intercompany      =>  lc_ora_company        --segment5
			, p_channel           =>  lc_ora_int_lob        --segment6
			, p_future            =>  '000000'              --segment7
                        , p_ccid              =>  NULL
			, p_entered_dr        =>  NULL
			, p_entered_cr        =>  ln_entered_cr
                        , p_derived_val       =>  'VALID'
                        , p_derived_sob       =>  'INTER-COMP'
                        , p_balanced          =>  'UNBALANCED'
                        , p_reference24       =>  lc_reference24
			, x_output_msg        =>  x_message_msg2
			);


                 XX_GL_INTERFACE_PKG.CREATE_STG_JRNL_LINE
                         (p_status            =>  'NEW'
			, p_date_created      =>  lc_date_created
			, p_created_by        =>  3
			, p_actual_flag       =>  'A'
			, p_group_id          =>  gn_group_id
			, p_batch_name        =>  lc_reference1     --TO_CHAR(lc_date_created,'YYYY/MM/DD')
        		, p_batch_desc        =>  lc_reference2
			, p_user_source_name  =>  gc_source_name
			, p_user_catgory_name =>  lc_je_category_name
			, p_set_of_books_id   =>  lc_set_of_books_id
			, p_accounting_date   =>  lc_accounting_date
			, p_currency_code     =>  lc_currency_code
			, p_company           =>  lc_ora_company        --segment1
			, p_cost_center       =>  lc_ora_int_cst_cntr   --segment2
			, p_account           =>  lc_ora_int_accnt      --segment3
			, p_location          =>  lc_ora_int_loc        --segment4
			, p_intercompany      =>  lc_ora_int_company    --segment5
			, p_channel           =>  lc_ora_int_lob        --segment6
			, p_future            =>  '000000'              --segment7
                        , p_ccid              =>  NULL
			, p_entered_dr        =>  ln_entered_cr
			, p_entered_cr        =>  NULL
                        , p_derived_val       =>  'VALID'
                        , p_derived_sob       =>  'INTER-COMP'
                        , p_balanced          =>  'UNBALANCED'
                        , p_reference24       =>  lc_reference24
			, x_output_msg        =>  x_message_msg1
			);

                    COMMIT;



                    IF x_message_msg1  IS NOT NULL AND x_message_msg2  IS NOT NULL THEN


                         XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  ln_rowid
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_INTRCOMP_ERR'
                                   ,p_source_nm    =>  gc_source_name
                                   ,p_type         =>  'Inter-Company Journal'
       	                           ,p_value        =>  'created'
                                   ,p_details      =>  x_message_msg1 || x_message_msg2
                                   ,p_group_id     =>  gn_group_id
                                   );

                         gn_error_count := gn_error_count + 1;

                         lc_debug_msg := '    Ora inter-company create debit line: '||x_message_msg1 ;
                          DEBUG_MESSAGE (lc_debug_msg);

                         lc_debug_msg := '    Ora inter-company create debit line: '||x_message_msg2 ;
                          DEBUG_MESSAGE (lc_debug_msg);

                     END IF;



          ELSIF NVL(ln_entered_dr,0) > 0 THEN

                 lc_debug_msg := '    created Ora inter-company ln_entered_dr: '||ln_entered_dr ;
                 DEBUG_MESSAGE (lc_debug_msg);

                 x_message_msg1 := 'NULL';
                 x_message_msg2 := 'NULL';

                 XX_GL_INTERFACE_PKG.CREATE_STG_JRNL_LINE
                         (p_status            => 'NEW'
			, p_date_created      =>  lc_date_created
			, p_created_by        =>  3
			, p_actual_flag       =>  'A'
			, p_group_id          =>  gn_group_id
			, p_batch_name        =>  lc_reference1  --TO_CHAR(lc_date_created,'YYYY/MM/DD')
        		, p_batch_desc        =>  lc_reference2
			, p_user_source_name  =>  gc_source_name
			, p_user_catgory_name =>  lc_je_category_name
			, p_set_of_books_id   =>  lc_set_of_books_id
			, p_accounting_date   =>  lc_accounting_date
			, p_currency_code     =>  lc_currency_code
			, p_company           =>  lc_ora_company        --segment1
			, p_cost_center       =>  lc_ora_int_cst_cntr   --segment2
			, p_account           =>  lc_ora_int_accnt      --segment3
			, p_location          =>  lc_ora_int_loc        --segment4
			, p_intercompany      =>  lc_ora_int_company    --segment5
			, p_channel           =>  lc_ora_int_lob        --segment6
			, p_future            =>  '000000'              --segment7
                        , p_ccid              =>  NULL
			, p_entered_dr        =>  NULL
			, p_entered_cr        =>  ln_entered_dr
                        , p_derived_val       =>  'VALID'
                        , p_derived_sob       =>  'INTER-COMP'
                        , p_balanced          =>  'UNBALANCED'
                        , p_reference24       =>  lc_reference24
  			, x_output_msg        =>  x_message_msg1
			);

                 XX_GL_INTERFACE_PKG.CREATE_STG_JRNL_LINE
                         (p_status            =>  'NEW'
			, p_date_created      =>  lc_date_created
			, p_created_by        =>  3
			, p_actual_flag       =>  'A'
			, p_group_id          =>  gn_group_id
			, p_batch_name        =>  lc_reference1        --TO_CHAR(lc_date_created,'YYYY/MM/DD')
			, p_batch_desc        =>  lc_reference2
			, p_user_source_name  =>  gc_source_name
			, p_user_catgory_name =>  lc_je_category_name
			, p_set_of_books_id   =>  lc_set_of_books_id
			, p_accounting_date   =>  lc_accounting_date
			, p_currency_code     =>  lc_currency_code
			, p_company           =>  lc_ora_int_company    --segment1
			, p_cost_center       =>  lc_ora_int_cst_cntr   --segment2
			, p_account           =>  lc_ora_int_accnt      --segment3
			, p_location          =>  lc_ora_int_loc        --segment4
			, p_intercompany      =>  lc_ora_company        --segment5
			, p_channel           =>  lc_ora_int_lob        --segment6
			, p_future            =>  '000000'              --segment7
                        , p_ccid              =>  NULL
			, p_entered_dr        =>  ln_entered_dr
			, p_entered_cr        =>  NULL
                        , p_derived_val       =>  'VALID'
                        , p_derived_sob       =>  'INTER-COMP'
                        , p_balanced          =>  'UNBALANCED'
                        , p_reference24       =>  lc_reference24
			, x_output_msg        =>  x_message_msg2
			);

                    COMMIT;




                    IF x_message_msg1  IS NOT NULL AND x_message_msg2  IS NOT NULL THEN

                         XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  ln_rowid
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_INTRCOMP_ERR'
                                   ,p_source_nm    =>  gc_source_name
                                   ,p_type         =>  'Inter-Company Journal'
       	                           ,p_value        =>  'created'
                                   ,p_details      =>  x_message_msg1 || x_message_msg2
                                   ,p_group_id     =>  gn_group_id
                                   );

                         gn_error_count := gn_error_count + 1;

                         lc_debug_msg := '    Ora inter-company create debit line: '||x_message_msg1 ;
                         DEBUG_MESSAGE (lc_debug_msg);

                         lc_debug_msg := '    Ora inter-company create debit line: '||x_message_msg2 ;
                         DEBUG_MESSAGE (lc_debug_msg);


                    END IF;


          ELSE
                   gn_error_count := gn_error_count + 1;

                   XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  ln_rowid
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_INTRCOMP_ERR'
                               ,p_source_nm    =>  gc_source_name
                               ,p_type         =>  'Inter-Company Journal'
       	                       ,p_value        =>  ' Entered amts (zero or neg.)'
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id);

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'   Error: enterd amounts (zero or neg.)'
                                               ||  ' row_id=>'
                                               ||    ln_rowid);

          END IF;

        END LOOP;
        CLOSE intercomp_jrnl_cursor;




    EXCEPTION
          WHEN OTHERS THEN

               fnd_message.clear();
	       fnd_message.set_name('FND','FS-UNKNOWN');
	       fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',lc_debug_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog

                                     );
       FND_FILE.PUT_LINE(FND_FILE.LOG,'Error: '||  gc_debug_pkg_nm
                                               ||  lc_debug_prog
                                               ||  fnd_message.get );


    END CREATE_INTERCOMP_JRNL;


-- +===================================================================+
-- | Name  :GSS_DERIVE_VALUES                                          |
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
    PROCEDURE GSS_DERIVE_VALUES (p_row_id          IN  ROWID
                                ,p_jrnl_name       IN  VARCHAR2
       	                        ,p_je_line_code    IN  VARCHAR2
                                ,p_legacy_segment4 IN  VARCHAR2
                                ,p_legacy_segment1 IN  VARCHAR2
                                 )
    IS

    ---------------------------
    -- Local Variables declared
    ---------------------------

    lc_trans_name        XX_FIN_TRANSLATEDEFINITION.translation_name%TYPE;
    lc_ora_location      XX_FIN_TRANSLATEVALUES.target_value3%TYPE;
    lc_ora_company       FND_FLEX_VALUES_VL.attribute1%TYPE;
    lc_ora_cost_center   XX_FIN_TRANSLATEVALUES.target_value2%TYPE;
    lc_ora_account       XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
    lc_ora_inter_company XX_FIN_TRANSLATEVALUES.target_value4%TYPE;
    lc_ora_lob           XX_FIN_TRANSLATEVALUES.target_value1%TYPE;
    lc_ora_future        FND_FLEX_VALUES_VL.attribute7%TYPE;
    lc_debug_msg         VARCHAR2(1000);
    lc_error_flg         VARCHAR2(1);
    lc_debug_prog        VARCHAR2(100) := 'GSS_DERIVE_VALUES';
    lc_ps_company        XX_FIN_TRANSLATEVALUES.source_value2%TYPE;


    ---------------------------------------------------------------------
    -- Nothing is loaded to the following  x_target_value... variables.
    -- They are only needed to make XX_FIN_TRANSLATEVALUE_PROC exec correctly
    ---------------------------------------------------------------------

    x_target_value1_out  xx_fin_translatevalues.target_value1%TYPE;
    x_target_value2_out  xx_fin_translatevalues.target_value2%TYPE;
    x_target_value3_out  xx_fin_translatevalues.target_value3%TYPE;
    x_target_value4_out  xx_fin_translatevalues.target_value4%TYPE;
    x_target_value5_out  xx_fin_translatevalues.target_value5%TYPE;
    x_target_value6_out  xx_fin_translatevalues.target_value6%TYPE;
    x_target_value7_out  xx_fin_translatevalues.target_value7%TYPE;
    x_target_value8_out  xx_fin_translatevalues.target_value8%TYPE;
    x_target_value9_out  xx_fin_translatevalues.target_value9%TYPE;
    x_target_value10_out xx_fin_translatevalues.target_value10%TYPE;
    x_target_value11_out xx_fin_translatevalues.target_value11%TYPE;
    x_target_value12_out xx_fin_translatevalues.target_value12%TYPE;
    x_target_value13_out xx_fin_translatevalues.target_value13%TYPE;
    x_target_value14_out xx_fin_translatevalues.target_value14%TYPE;
    x_target_value15_out xx_fin_translatevalues.target_value15%TYPE;
    x_target_value16_out xx_fin_translatevalues.target_value16%TYPE;
    x_target_value17_out xx_fin_translatevalues.target_value17%TYPE;
    x_target_value18_out xx_fin_translatevalues.target_value18%TYPE;
    x_target_value19_out xx_fin_translatevalues.target_value19%TYPE;
    x_target_value20_out xx_fin_translatevalues.target_value20%TYPE;

    ----------------------------------------
    -- bug in translation definition program
    ----------------------------------------
    lc_source_value2     xx_fin_translatevalues.source_value2 %TYPE;

    BEGIN


       lc_debug_msg := '    Row processed by: '||lc_debug_prog
                                                 || ' p_row_id=> '   || p_row_id
                                                 || ',p_jrnl_name=> '|| p_jrnl_name
                                                 || ',p_je_line_code'|| p_je_line_code;
       DEBUG_MESSAGE (lc_debug_msg,1);

       gc_translate_error := NULL;

       lc_error_flg  := 'N';
       lc_trans_name := 'GL_GSS_ACCT_VALUES';

       -----------------------------------------------------------
       --Derive values for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
       -----------------------------------------------------------
       IF p_jrnl_name = 'RECADVLOAD' THEN

	      ---------------------------------------------------------------------
              -- Derive Oracle location for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
              ---------------------------------------------------------------------
              lc_debug_msg := 'Deriving Oracle Location for '
                              ||'GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES.';


              XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                  (p_translation_name => lc_trans_name
                                  ,p_source_value1    => p_je_line_code
                                  ,x_target_value1    => x_target_value1_out
                                  ,x_target_value2    => x_target_value2_out
                                  ,x_target_value3    => lc_ora_location
                                  ,x_target_value4    => x_target_value4_out
                                  ,x_target_value5    => x_target_value5_out
                                  ,x_target_value6    => x_target_value6_out
                                  ,x_target_value7    => x_target_value7_out
                                  ,x_target_value8    => x_target_value8_out
                                  ,x_target_value9    => x_target_value9_out
                                  ,x_target_value10   => x_target_value10_out
                                  ,x_target_value11   => x_target_value11_out
                                  ,x_target_value12   => x_target_value12_out
                                  ,x_target_value13   => x_target_value13_out
                                  ,x_target_value14   => x_target_value14_out
                                  ,x_target_value15   => x_target_value15_out
                                  ,x_target_value16   => x_target_value16_out
                                  ,x_target_value17   => x_target_value17_out
                                  ,x_target_value18   => x_target_value18_out
                                  ,x_target_value19   => x_target_value19_out
                                  ,x_target_value20   => x_target_value20_out
		                  ,x_error_message    => gc_translate_error
                                   );


              IF gc_translate_error IS NOT NULL THEN


                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  p_row_id
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                   ,p_source_nm      =>  gc_source_name
                                   ,p_type         =>  'Location'
       	                           ,p_value        =>  NVL(p_je_line_code,'Not Found')
                                                       || ' '|| lc_ora_location
                                   ,p_details      =>  gc_translate_error
                                   ,p_group_id     =>  gn_group_id
                                   );

                     gn_error_count := gn_error_count + 1;

                     lc_error_flg := 'Y';

                     lc_debug_msg := '    Ora Location error1: '||gc_translate_error;
                     DEBUG_MESSAGE (lc_debug_msg);

                     gc_translate_error := NULL;


	      END IF;

              --------------------------------------------------------------------
              -- Derive Oracle Company for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
              --------------------------------------------------------------------
              lc_debug_msg := '    Deriving Oracle Company for '
                               || 'GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES';


              lc_ora_company :=  XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION
                                                   (p_location => lc_ora_location
                                                   );

              IF lc_ora_company IS NULL THEN

                     gc_translate_error := 'Could not derive Ora Company from Ora Location';

                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>   p_row_id
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                   ,p_source_nm      =>   gc_source_name                      --p_jrnl_name
                                   ,p_type         =>  'Company'
       	                           ,p_value        =>  NVL(lc_ora_location,'Not Found')
                                   ,p_details      =>  gc_translate_error
                                   ,p_group_id     =>  gn_group_id
                                   );

                     gn_error_count := gn_error_count + 1;

                     lc_error_flg := 'Y';

                     lc_debug_msg := '    Ora company error1: '||gc_translate_error;
                     DEBUG_MESSAGE (lc_debug_msg);

                     gc_translate_error := NULL;

              END IF;


              ------------------------------------------------------------------------
              -- Derive Oracle Cost Center for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
              ------------------------------------------------------------------------

              lc_debug_msg := '    Deriving Oracle Cost Center '
                            ||'for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES'
                            ||' p_je_line_code => '||   p_je_line_code
                            ||' lc_trans_name => ' ||   lc_trans_name;

               DEBUG_MESSAGE (lc_debug_msg);

               gc_translate_error := NULL;

               XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                          (p_translation_name  => lc_trans_name
                                          ,p_source_value1     => p_je_line_code
                                   ---      ,p_source_value2     => lc_source_value2         --BUG source_value2???
                                          ,x_target_value1    => x_target_value1_out
                                          ,x_target_value2     => lc_ora_cost_center
                                          ,x_target_value3    => x_target_value3_out
                                          ,x_target_value4    => x_target_value4_out
                                          ,x_target_value5    => x_target_value5_out
                                          ,x_target_value6    => x_target_value6_out
                                          ,x_target_value7    => x_target_value7_out
                                          ,x_target_value8    => x_target_value8_out
                                          ,x_target_value9    => x_target_value9_out
                                          ,x_target_value10   => x_target_value10_out
                                          ,x_target_value11   => x_target_value11_out
                                          ,x_target_value12   => x_target_value12_out
                                          ,x_target_value13   => x_target_value13_out
                                          ,x_target_value14   => x_target_value14_out
                                          ,x_target_value15   => x_target_value15_out
                                          ,x_target_value16   => x_target_value16_out
                                          ,x_target_value17   => x_target_value17_out
                                          ,x_target_value18   => x_target_value18_out
                                          ,x_target_value19   => x_target_value19_out
                                          ,x_target_value20   => x_target_value20_out
                                          ,x_error_message     => gc_translate_error
                                          );


               IF gc_translate_error IS NOT NULL THEN

                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                              (p_rowid        =>  p_row_id
                              ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                              ,p_source_nm      =>  gc_source_name
                              ,p_type         =>  'Cost Center'
                              ,p_value        =>  NVL(p_je_line_code,'Not Found')
                              ,p_details      =>  gc_translate_error
                              ,p_group_id     =>  gn_group_id
                              );

                      gn_error_count := gn_error_count + 1;

                      lc_error_flg := 'Y';
                      lc_debug_msg := '    Ora cost center error2: '||gc_translate_error;

                      DEBUG_MESSAGE (lc_debug_msg);

                      gc_translate_error := NULL;

              END IF;

              --------------------------------------------------------------------
              -- Derive Oracle Account for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
              --------------------------------------------------------------------

              lc_debug_msg := '    Deriving Oracle Account '
                         || 'for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES'
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
              DEBUG_MESSAGE (lc_debug_msg);


              XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                        (p_translation_name  => lc_trans_name
                                        ,p_source_value1     => p_je_line_code
                                        ,x_target_value1     => lc_ora_account
                                        ,x_target_value2    => x_target_value2_out
                                        ,x_target_value3    => x_target_value3_out
                                        ,x_target_value4    => x_target_value4_out
                                        ,x_target_value5    => x_target_value5_out
                                        ,x_target_value6    => x_target_value6_out
                                        ,x_target_value7    => x_target_value7_out
                                        ,x_target_value8    => x_target_value8_out
                                        ,x_target_value9    => x_target_value9_out
                                        ,x_target_value10   => x_target_value10_out
                                        ,x_target_value11   => x_target_value11_out
                                        ,x_target_value12   => x_target_value12_out
                                        ,x_target_value13   => x_target_value13_out
                                        ,x_target_value14   => x_target_value14_out
                                        ,x_target_value15   => x_target_value15_out
                                        ,x_target_value16   => x_target_value16_out
                                        ,x_target_value17   => x_target_value17_out
                                        ,x_target_value18   => x_target_value18_out
                                        ,x_target_value19   => x_target_value19_out
                                        ,x_target_value20   => x_target_value20_out
                                        ,x_error_message     => gc_translate_error
                                        );

               IF gc_translate_error IS NOT NULL THEN

                      XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>  gc_source_name
                               ,p_type         =>  'Account'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                               );


                      gn_error_count := gn_error_count + 1;
                      lc_error_flg := 'Y';

                      lc_debug_msg := '    Ora account error:  '||gc_translate_error;
                      DEBUG_MESSAGE (lc_debug_msg);
                      gc_translate_error := NULL;

               END IF;

               --------------------------------------------------------------------------
               -- Derive Oracle Inter-Company for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES
               --------------------------------------------------------------------------

               lc_debug_msg := '    Deriving Oracle Inter-Company: '
                         ||'for GSS-ADD-LOAD-FEES AND GSS-RECORDED-FEES'
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
               DEBUG_MESSAGE (lc_debug_msg);


                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                 (p_translation_name => lc_trans_name
                                 ,p_source_value1    => p_je_line_code
                                 ,x_target_value1    => x_target_value1_out
                                 ,x_target_value2    => x_target_value2_out
                                 ,x_target_value3    => x_target_value3_out
                                 ,x_target_value4    => lc_ora_inter_company
                                 ,x_target_value5    => x_target_value5_out
                                 ,x_target_value6    => x_target_value6_out
                                 ,x_target_value7    => x_target_value7_out
                                 ,x_target_value8    => x_target_value8_out
                                 ,x_target_value9    => x_target_value9_out
                                 ,x_target_value10   => x_target_value10_out
                                 ,x_target_value11   => x_target_value11_out
                                 ,x_target_value12   => x_target_value12_out
                                 ,x_target_value13   => x_target_value13_out
                                 ,x_target_value14   => x_target_value14_out
                                 ,x_target_value15   => x_target_value15_out
                                 ,x_target_value16   => x_target_value16_out
                                 ,x_target_value17   => x_target_value17_out
                                 ,x_target_value18   => x_target_value18_out
                                 ,x_target_value19   => x_target_value19_out
                                 ,x_target_value20   => x_target_value20_out
                                 ,x_error_message    => gc_translate_error
                                  );

                 IF gc_translate_error IS NOT NULL THEN

                        XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>   gc_source_name
                               ,p_type         =>  'Inter-Company'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                                );

                        gn_error_count := gn_error_count + 1;

                        lc_error_flg := 'Y';

                        lc_debug_msg := '    Ora inter-company error:  '||gc_translate_error;
                        DEBUG_MESSAGE (lc_debug_msg);
                        gc_translate_error := NULL;

                END IF;


       END IF;


       ------------------------------------------------------------
       -- Derive  values for CROSS DOCK LABOR, OUTBOUND AND INBOUND
       ------------------------------------------------------------
       IF p_jrnl_name = 'RECXDOCKCR' THEN

             -------------------------------------------------
             -- Derive  location and company for GSS-FROMXDOCK
             -------------------------------------------------
             IF p_je_line_code = 'GSS-FROMXDOCK' THEN

	             -----------------------------------------
                     -- Derive Oracle location from (Leg_seg4)
                     -----------------------------------------
                     lc_debug_msg := 'Deriving Oracle Location from PS leg_seg4 '
                                     || 'GSS-FROMXDOCK';

                     XX_GL_PSHR_INTERFACE_PKG.DERIVE_LOCATION
                               (p_ps_location    => p_legacy_segment4
			       ,x_ora_location   => lc_ora_location
			       ,x_error_message  => gc_translate_error
                               );

                     IF gc_translate_error IS NOT NULL THEN


                           XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  p_row_id
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                   ,p_source_nm    =>  gc_source_name
                                   ,p_type         =>  'Location'
       	                           ,p_value        =>  NVL(p_legacy_segment4,'Not Found')
                                   ,p_details      =>  gc_translate_error
                                   ,p_group_id     =>  gn_group_id
                                   );

                           gn_error_count := gn_error_count + 1;
                           lc_error_flg := 'Y';

                           lc_debug_msg := '    Ora Location error2: '||gc_translate_error;
                           DEBUG_MESSAGE (lc_debug_msg);

                           gc_translate_error := NULL;

                     END IF;

                     ------------------------------------------
                     -- Derive Oracle Company for GSS-FROMXDOCK
                     ------------------------------------------
                     lc_debug_msg := '    Deriving Oracle Company2 '
                                     ||'GSS-FROMXDOCK';
                     DEBUG_MESSAGE (lc_debug_msg);


                     lc_ora_company :=  XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION
                                                        (p_location => lc_ora_location
                                                        );

                     IF lc_ora_company IS NULL THEN

                             gc_translate_error := 'Could not derive Ora '||
                                                   'Company from Ora Location';

                             XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                       (p_rowid        =>   p_row_id
                                       ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                       ,p_source_nm      =>   gc_source_name
                                       ,p_type         =>  'Company'
       	                               ,p_value        =>  NVL(lc_ora_location,'Not Found')
                                       ,p_details      =>  gc_translate_error
                                       ,p_group_id     =>  gn_group_id
                                       );

                             gn_error_count := gn_error_count + 1;

                             lc_error_flg := 'Y';

                             lc_debug_msg := '    Ora company error2: '||gc_translate_error;
                             DEBUG_MESSAGE (lc_debug_msg);

                             gc_translate_error := NULL;

                     END IF;

              ELSE

	             -------------------------------------------
                     -- Derive Oracle location GSS-RECORDED-FEES
                     -------------------------------------------

                     lc_error_flg  := 'N';
                     lc_trans_name := 'GL_GSS_ACCT_VALUES';

                     lc_debug_msg := 'Deriving Oracle Location2 '
                                     ||'GSS-RECORDED-FEES';


                     XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                  (p_translation_name => lc_trans_name
                                  ,p_source_value1    => p_je_line_code
                                  ,x_target_value1    => x_target_value1_out
                                  ,x_target_value2    => x_target_value2_out
                                  ,x_target_value3    => lc_ora_location
                                  ,x_target_value4    => x_target_value4_out
                                  ,x_target_value5    => x_target_value5_out
                                  ,x_target_value6    => x_target_value6_out
                                  ,x_target_value7    => x_target_value7_out
                                  ,x_target_value8    => x_target_value8_out
                                  ,x_target_value9    => x_target_value9_out
                                  ,x_target_value10   => x_target_value10_out
                                  ,x_target_value11   => x_target_value11_out
                                  ,x_target_value12   => x_target_value12_out
                                  ,x_target_value13   => x_target_value13_out
                                  ,x_target_value14   => x_target_value14_out
                                  ,x_target_value15   => x_target_value15_out
                                  ,x_target_value16   => x_target_value16_out
                                  ,x_target_value17   => x_target_value17_out
                                  ,x_target_value18   => x_target_value18_out
                                  ,x_target_value19   => x_target_value19_out
                                  ,x_target_value20   => x_target_value20_out
		                  ,x_error_message    => gc_translate_error
                                   );


                     IF gc_translate_error IS NOT NULL THEN


                          XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                   (p_rowid        =>  p_row_id
                                   ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                   ,p_source_nm      =>  gc_source_name
                                   ,p_type         =>  'Location'
       	                           ,p_value        =>  NVL(p_je_line_code,'Not Found')
                                   ,p_details      =>  gc_translate_error
                                   ,p_group_id     =>  gn_group_id
                                   );

                          gn_error_count := gn_error_count + 1;

                          lc_error_flg := 'Y';

                          lc_debug_msg := '    Ora Location error3: '||gc_translate_error;
                          DEBUG_MESSAGE (lc_debug_msg);

                          gc_translate_error := NULL;


	             END IF;

                     --------------------------------------
                     -- Derive PS Company GSS-RECORDED-FEES
                     --------------------------------------
                     lc_debug_msg := '    Deriving Oracle Company3 '
                                     ||'GSS-RECORDED-FEES';


                     XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                  (p_translation_name => lc_trans_name
                                  ,p_source_value1    => p_je_line_code
                                  ,x_target_value1    => x_target_value1_out
                                  ,x_target_value2    => x_target_value2_out
                                  ,x_target_value3    => x_target_value3_out
                                  ,x_target_value4    => lc_ora_company
                                  ,x_target_value5    => x_target_value5_out
                                  ,x_target_value6    => x_target_value6_out
                                  ,x_target_value7    => x_target_value7_out
                                  ,x_target_value8    => x_target_value8_out
                                  ,x_target_value9    => x_target_value9_out
                                  ,x_target_value10   => x_target_value10_out
                                  ,x_target_value11   => x_target_value11_out
                                  ,x_target_value12   => x_target_value12_out
                                  ,x_target_value13   => x_target_value13_out
                                  ,x_target_value14   => x_target_value14_out
                                  ,x_target_value15   => x_target_value15_out
                                  ,x_target_value16   => x_target_value16_out
                                  ,x_target_value17   => x_target_value17_out
                                  ,x_target_value18   => x_target_value18_out
                                  ,x_target_value19   => x_target_value19_out
                                  ,x_target_value20   => x_target_value20_out
		                  ,x_error_message    => gc_translate_error
                                   );


                      IF gc_translate_error IS NOT NULL THEN

                              XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                    (p_rowid        =>  p_row_id
                                    ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                    ,p_source_nm      =>  gc_source_name
                                    ,p_type         =>  'Location'
       	                            ,p_value        =>  NVL(p_je_line_code,'Not Found')
                                    ,p_details      =>  gc_translate_error
                                    ,p_group_id     =>  gn_group_id
                                    );

                              gn_error_count := gn_error_count + 1;

                              lc_error_flg := 'Y';

                              lc_debug_msg := '    Ora Company error3: '||gc_translate_error;
                              DEBUG_MESSAGE (lc_debug_msg);

                              gc_translate_error := NULL;

                      END IF;


              END IF;


              --------------------------------------------------------------------
              -- Derive Oracle Cost Center for GSS-FROMXDOCK AND GSS-RECORDED-FEES
              --------------------------------------------------------------------

              lc_debug_msg := '    Deriving Oracle Cost Center '
                            ||'for GSS-FROMXDOCK AND GSS-RECORDED-FEES'
                            ||' p_je_line_code => '||   p_je_line_code
                            ||' lc_trans_name => ' ||   lc_trans_name;

               DEBUG_MESSAGE (lc_debug_msg);

               gc_translate_error := NULL;

               XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                          (p_translation_name  => lc_trans_name
                                          ,p_source_value1     => p_je_line_code
                                          ,x_target_value1    => x_target_value1_out
                                          ,x_target_value2     => lc_ora_cost_center
                                          ,x_target_value3    => x_target_value3_out
                                          ,x_target_value4    => x_target_value4_out
                                          ,x_target_value5    => x_target_value5_out
                                          ,x_target_value6    => x_target_value6_out
                                          ,x_target_value7    => x_target_value7_out
                                          ,x_target_value8    => x_target_value8_out
                                          ,x_target_value9    => x_target_value9_out
                                          ,x_target_value10   => x_target_value10_out
                                          ,x_target_value11   => x_target_value11_out
                                          ,x_target_value12   => x_target_value12_out
                                          ,x_target_value13   => x_target_value13_out
                                          ,x_target_value14   => x_target_value14_out
                                          ,x_target_value15   => x_target_value15_out
                                          ,x_target_value16   => x_target_value16_out
                                          ,x_target_value17   => x_target_value17_out
                                          ,x_target_value18   => x_target_value18_out
                                          ,x_target_value19   => x_target_value19_out
                                          ,x_target_value20   => x_target_value20_out
                                          ,x_error_message     => gc_translate_error
                                          );


               IF gc_translate_error IS NOT NULL THEN

                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                              (p_rowid        =>  p_row_id
                              ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                              ,p_source_nm      =>  gc_source_name
                              ,p_type         =>  'Cost Center'
                              ,p_value        =>  NVL(p_je_line_code,'Not Found')
                              ,p_details      =>  gc_translate_error
                              ,p_group_id     =>  gn_group_id
                              );

                      gn_error_count := gn_error_count + 1;

                      lc_error_flg := 'Y';
                      lc_debug_msg := '    Ora cost center error2: '||gc_translate_error;

                      DEBUG_MESSAGE (lc_debug_msg);

                      gc_translate_error := NULL;

              END IF;

              ----------------------------------------------------------------
              -- Derive Oracle Account for GSS-FROMXDOCK AND GSS-RECORDED-FEES
              ----------------------------------------------------------------

              lc_debug_msg := '    Deriving Oracle Account '
                         || 'for GSS-FROMXDOCK AND GSS-RECORDED-FEES'
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
              DEBUG_MESSAGE (lc_debug_msg);


              XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                        (p_translation_name  => lc_trans_name
                                        ,p_source_value1     => p_je_line_code
                                        ,x_target_value1     => lc_ora_account
                                        ,x_target_value2    => x_target_value2_out
                                        ,x_target_value3    => x_target_value3_out
                                        ,x_target_value4    => x_target_value4_out
                                        ,x_target_value5    => x_target_value5_out
                                        ,x_target_value6    => x_target_value6_out
                                        ,x_target_value7    => x_target_value7_out
                                        ,x_target_value8    => x_target_value8_out
                                        ,x_target_value9    => x_target_value9_out
                                        ,x_target_value10   => x_target_value10_out
                                        ,x_target_value11   => x_target_value11_out
                                        ,x_target_value12   => x_target_value12_out
                                        ,x_target_value13   => x_target_value13_out
                                        ,x_target_value14   => x_target_value14_out
                                        ,x_target_value15   => x_target_value15_out
                                        ,x_target_value16   => x_target_value16_out
                                        ,x_target_value17   => x_target_value17_out
                                        ,x_target_value18   => x_target_value18_out
                                        ,x_target_value19   => x_target_value19_out
                                        ,x_target_value20   => x_target_value20_out
                                        ,x_error_message     => gc_translate_error
                                        );

               IF gc_translate_error IS NOT NULL THEN

                      XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>  gc_source_name
                               ,p_type         =>  'Account'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                               );


                      gn_error_count := gn_error_count + 1;
                      lc_error_flg := 'Y';

                      lc_debug_msg := '    Ora account error:  '||gc_translate_error;
                      DEBUG_MESSAGE (lc_debug_msg);
                      gc_translate_error := NULL;

               END IF;

               ----------------------------------------------------------------------
               -- Derive Oracle Inter-Company for GSS-FROMXDOCK AND GSS-RECORDED-FEES
               ----------------------------------------------------------------------

               lc_debug_msg := '    Deriving Oracle Inter-Company: '
                         ||'for GSS-FROMXDOCK AND GSS-RECORDED-FEES'
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
               DEBUG_MESSAGE (lc_debug_msg);


                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                 (p_translation_name => lc_trans_name
                                 ,p_source_value1    => p_je_line_code
                                 ,x_target_value1    => x_target_value1_out
                                 ,x_target_value2    => x_target_value2_out
                                 ,x_target_value3    => x_target_value3_out
                                 ,x_target_value4    => lc_ora_inter_company
                                 ,x_target_value5    => x_target_value5_out
                                 ,x_target_value6    => x_target_value6_out
                                 ,x_target_value7    => x_target_value7_out
                                 ,x_target_value8    => x_target_value8_out
                                 ,x_target_value9    => x_target_value9_out
                                 ,x_target_value10   => x_target_value10_out
                                 ,x_target_value11   => x_target_value11_out
                                 ,x_target_value12   => x_target_value12_out
                                 ,x_target_value13   => x_target_value13_out
                                 ,x_target_value14   => x_target_value14_out
                                 ,x_target_value15   => x_target_value15_out
                                 ,x_target_value16   => x_target_value16_out
                                 ,x_target_value17   => x_target_value17_out
                                 ,x_target_value18   => x_target_value18_out
                                 ,x_target_value19   => x_target_value19_out
                                 ,x_target_value20   => x_target_value20_out
                                 ,x_error_message    => gc_translate_error
                                  );

                 IF gc_translate_error IS NOT NULL THEN

                        XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>   gc_source_name
                               ,p_type         =>  'Inter-Company'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                                );

                        gn_error_count := gn_error_count + 1;

                        lc_error_flg := 'Y';

                        lc_debug_msg := '    Ora inter-company error:  '||gc_translate_error;
                        DEBUG_MESSAGE (lc_debug_msg);
                        gc_translate_error := NULL;

                END IF;



       END IF;


       ------------------------------
       -- Derive values for ALCELCVAR
       ------------------------------

       IF p_jrnl_name = 'ALCELCVAR' THEN

           -------------------------------------------------------------------------------
           -- Derive Oracle location for GSS-BSG-VARIANCES,GSS-RECORDED-FEES for ALCELCVAR
           -------------------------------------------------------------------------------

           IF p_je_line_code = 'GSS-BSG-VARIANCES' OR
                p_je_line_code = 'GSS-RECORDED-FEES'THEN

                lc_debug_msg := 'Deriving Oracle Location4: ';
                lc_trans_name := 'GL_GSS_ACCT_VALUES';

                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                             (p_translation_name => lc_trans_name
                             ,p_source_value1    => p_je_line_code
                             ,x_target_value1    => x_target_value1_out
                             ,x_target_value2    => x_target_value2_out
                             ,x_target_value3    => lc_ora_location
                             ,x_target_value4    => x_target_value4_out
                             ,x_target_value5    => x_target_value5_out
                             ,x_target_value6    => x_target_value6_out
                             ,x_target_value7    => x_target_value7_out
                             ,x_target_value8    => x_target_value8_out
                             ,x_target_value9    => x_target_value9_out
                             ,x_target_value10   => x_target_value10_out
                             ,x_target_value11   => x_target_value11_out
                             ,x_target_value12   => x_target_value12_out
                             ,x_target_value13   => x_target_value13_out
                             ,x_target_value14   => x_target_value14_out
                             ,x_target_value15   => x_target_value15_out
                             ,x_target_value16   => x_target_value16_out
                             ,x_target_value17   => x_target_value17_out
                             ,x_target_value18   => x_target_value18_out
                             ,x_target_value19   => x_target_value19_out
                             ,x_target_value20   => x_target_value20_out
                             ,x_error_message    => gc_translate_error
                             );


                  IF gc_translate_error IS NOT NULL THEN

                        XX_GL_INTERFACE_PKG.PROCESS_ERROR
                             (p_rowid        =>  p_row_id
                             ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                             ,p_source_nm      =>  gc_source_name
                             ,p_type         =>  'Location'
                             ,p_value        =>  NVL(p_je_line_code,'Not Found')
                             ,p_details      =>  gc_translate_error
                             ,p_group_id     =>  gn_group_id
                             );

                        gn_error_count := gn_error_count + 1;

                        lc_error_flg := 'Y';
                        lc_debug_msg := '    Ora Location error4: '||gc_translate_error;
                        DEBUG_MESSAGE (lc_debug_msg);

                        gc_translate_error := NULL;

                   END IF;

           ELSE

           -------------------------------------------------------------
           -- Derive Oracle location for GSS-RET-VARIANCES for ALCELCVAR
           -------------------------------------------------------------

                 lc_debug_msg := 'Deriving Oracle Location5: ';
                 lc_trans_name := 'GL_GSS_ACCT_VALUES';

                 XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                             (p_translation_name => lc_trans_name
                             ,p_source_value1    => p_je_line_code
                             ,p_source_value2    => p_legacy_segment1
                             ,x_target_value1    => x_target_value1_out
                             ,x_target_value2    => x_target_value2_out
                             ,x_target_value3    => lc_ora_location
                             ,x_target_value4    => x_target_value4_out
                             ,x_target_value5    => x_target_value5_out
                             ,x_target_value6    => x_target_value6_out
                             ,x_target_value7    => x_target_value7_out
                             ,x_target_value8    => x_target_value8_out
                             ,x_target_value9    => x_target_value9_out
                             ,x_target_value10   => x_target_value10_out
                             ,x_target_value11   => x_target_value11_out
                             ,x_target_value12   => x_target_value12_out
                             ,x_target_value13   => x_target_value13_out
                             ,x_target_value14   => x_target_value14_out
                             ,x_target_value15   => x_target_value15_out
                             ,x_target_value16   => x_target_value16_out
                             ,x_target_value17   => x_target_value17_out
                             ,x_target_value18   => x_target_value18_out
                             ,x_target_value19   => x_target_value19_out
                             ,x_target_value20   => x_target_value20_out
                             ,x_error_message    => gc_translate_error
                             );


                  IF gc_translate_error IS NOT NULL THEN

                       XX_GL_INTERFACE_PKG.PROCESS_ERROR
                             (p_rowid        =>  p_row_id
                             ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                             ,p_source_nm      =>  gc_source_name
                             ,p_type         =>  'Location'
                             ,p_value        =>  NVL(p_je_line_code,'Not Found')
                             ,p_details      =>  gc_translate_error
                             ,p_group_id     =>  gn_group_id
                             );

                       gn_error_count := gn_error_count + 1;

                       lc_error_flg := 'Y';
                       lc_debug_msg := '    Ora Location error5: '||gc_translate_error;
                       DEBUG_MESSAGE (lc_debug_msg);

                       gc_translate_error := NULL;

                   END IF;


           END IF;

           ----------------------------------------------------------------------
           -- Derive Company GSS-RECORDED-FEES for ALCELCVAR OR GSS-BSG-VARIANCES
           ----------------------------------------------------------------------
           IF p_je_line_code = 'GSS-RECORDED-FEES'
             OR p_je_line_code = 'GSS-BSG-VARIANCES' THEN

                gc_translate_error := NULL;
                lc_debug_msg := '    Deriving  PS Company5: p_je_line_code=> '
                                ||p_je_line_code ;

                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                             (p_translation_name => lc_trans_name
                             ,p_source_value1    => p_je_line_code
                             ,x_target_value1    => x_target_value1_out
                             ,x_target_value2    => x_target_value2_out
                             ,x_target_value3    => x_target_value3_out
                             ,x_target_value4    => lc_ora_company
                             ,x_target_value5    => x_target_value5_out
                             ,x_target_value6    => x_target_value6_out
                             ,x_target_value7    => x_target_value7_out
                             ,x_target_value8    => x_target_value8_out
                             ,x_target_value9    => x_target_value9_out
                             ,x_target_value10   => x_target_value10_out
                             ,x_target_value11   => x_target_value11_out
                             ,x_target_value12   => x_target_value12_out
                             ,x_target_value13   => x_target_value13_out
                             ,x_target_value14   => x_target_value14_out
                             ,x_target_value15   => x_target_value15_out
                             ,x_target_value16   => x_target_value16_out
                             ,x_target_value17   => x_target_value17_out
                             ,x_target_value18   => x_target_value18_out
                             ,x_target_value19   => x_target_value19_out
                             ,x_target_value20   => x_target_value20_out
                             ,x_error_message    => gc_translate_error
                             );


                 IF gc_translate_error IS NOT NULL THEN

                         XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                (p_rowid        =>  p_row_id
                                ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                ,p_source_nm      =>  gc_source_name
                                ,p_type         =>  'Company'
                                ,p_value        =>  NVL(p_je_line_code,'Not Found')
                                ,p_details      =>  gc_translate_error
                                ,p_group_id     =>  gn_group_id
                                );
                         gn_error_count := gn_error_count + 1;

                         lc_error_flg := 'Y';

                         lc_debug_msg := '    Ora Company error5: '||gc_translate_error;
                         DEBUG_MESSAGE (lc_debug_msg);

                         gc_translate_error := NULL;

                END IF;


           ELSE
              ------------------------------------------------------------
              -- Derive Oracle Company from leg_seg1 for GSS-RET-VARIANCES
              ------------------------------------------------------------
                gc_translate_error := NULL;
                lc_debug_msg := '    Deriving  PS Company6: p_je_line_code=> '
                                ||p_je_line_code ;

                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                             (p_translation_name => lc_trans_name
                             ,p_source_value1    => p_je_line_code
                             ,p_source_value2    => p_legacy_segment1
                             ,x_target_value1    => x_target_value1_out
                             ,x_target_value2    => x_target_value2_out
                             ,x_target_value3    => x_target_value3_out
                             ,x_target_value4    => lc_ora_company
                             ,x_target_value5    => x_target_value5_out
                             ,x_target_value6    => x_target_value6_out
                             ,x_target_value7    => x_target_value7_out
                             ,x_target_value8    => x_target_value8_out
                             ,x_target_value9    => x_target_value9_out
                             ,x_target_value10   => x_target_value10_out
                             ,x_target_value11   => x_target_value11_out
                             ,x_target_value12   => x_target_value12_out
                             ,x_target_value13   => x_target_value13_out
                             ,x_target_value14   => x_target_value14_out
                             ,x_target_value15   => x_target_value15_out
                             ,x_target_value16   => x_target_value16_out
                             ,x_target_value17   => x_target_value17_out
                             ,x_target_value18   => x_target_value18_out
                             ,x_target_value19   => x_target_value19_out
                             ,x_target_value20   => x_target_value20_out
                             ,x_error_message    => gc_translate_error
                             );


                 IF gc_translate_error IS NOT NULL THEN

                         XX_GL_INTERFACE_PKG.PROCESS_ERROR
                                (p_rowid        =>  p_row_id
                                ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                                ,p_source_nm      =>  gc_source_name
                                ,p_type         =>  'Company'
                                ,p_value        =>  NVL(p_je_line_code,'Not Found')
                                ,p_details      =>  gc_translate_error
                                ,p_group_id     =>  gn_group_id
                                );
                         gn_error_count := gn_error_count + 1;

                         lc_error_flg := 'Y';

                         lc_debug_msg := '    Ora Company error6: '||gc_translate_error;
                         DEBUG_MESSAGE (lc_debug_msg);

                         gc_translate_error := NULL;

                END IF;


           END IF;

           ---------------------------------------------------------------
           -- Derive Cost Center, Account and Inter-compnany for ALCELCVAR
           ---------------------------------------------------------------

           ------------------------------------------------------------------------
           -- Derive Oracle Cost Center for GSS-BSG-VARIANCES and GSS-RECORDED-FEES
           ------------------------------------------------------------------------

           IF p_je_line_code = 'GSS-BSG-VARIANCES' OR
                p_je_line_code = 'GSS-RECORDED-FEES'THEN

                lc_debug_msg := '    Deriving Oracle Cost Center for '
                                || ' GSS-BSG-VARIANCES and GSS-RECORDED-FEES'
                                ||' p_je_line_code => '||   p_je_line_code
                                ||' lc_trans_name => ' ||   lc_trans_name;

                DEBUG_MESSAGE (lc_debug_msg);

                gc_translate_error := NULL;


                XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                     (p_translation_name  => lc_trans_name
                                     ,p_source_value1     => p_je_line_code
                                     ,x_target_value1    => x_target_value1_out
                                     ,x_target_value2     => lc_ora_cost_center
                                     ,x_target_value3    => x_target_value3_out
                                     ,x_target_value4    => x_target_value4_out
                                     ,x_target_value5    => x_target_value5_out
                                     ,x_target_value6    => x_target_value6_out
                                     ,x_target_value7    => x_target_value7_out
                                     ,x_target_value8    => x_target_value8_out
                                     ,x_target_value9    => x_target_value9_out
                                     ,x_target_value10   => x_target_value10_out
                                     ,x_target_value11   => x_target_value11_out
                                     ,x_target_value12   => x_target_value12_out
                                     ,x_target_value13   => x_target_value13_out
                                     ,x_target_value14   => x_target_value14_out
                                     ,x_target_value15   => x_target_value15_out
                                     ,x_target_value16   => x_target_value16_out
                                     ,x_target_value17   => x_target_value17_out
                                     ,x_target_value18   => x_target_value18_out
                                     ,x_target_value19   => x_target_value19_out
                                     ,x_target_value20   => x_target_value20_out
                                     ,x_error_message     => gc_translate_error
                                      );



               IF gc_translate_error IS NOT NULL THEN

                     XX_GL_INTERFACE_PKG.PROCESS_ERROR
                              (p_rowid        =>  p_row_id
                              ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                              ,p_source_nm      =>  gc_source_name
                              ,p_type         =>  'Cost Center'
                              ,p_value        =>  NVL(p_je_line_code,'Not Found')
                              ,p_details      =>  gc_translate_error
                              ,p_group_id     =>  gn_group_id
                              );

                     gn_error_count := gn_error_count + 1;

                     lc_error_flg := 'Y';
                     lc_debug_msg := '    Ora cost center error2: '||gc_translate_error;
                     DEBUG_MESSAGE (lc_debug_msg);

                     gc_translate_error := NULL;

              END IF;

              ------------------------------------------------------------------------------
              -- Derive Oracle Account for GSS-BSG-VARIANCES and GSS-RECORDED-FEES ALCELCVAR
              ------------------------------------------------------------------------------

              lc_debug_msg := '    Deriving Oracle Account '
                              ||'for GSS-BSG-VARIANCES and GSS-RECORDED-FEES '
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
              DEBUG_MESSAGE (lc_debug_msg);


              XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                        (p_translation_name  => lc_trans_name
                                        ,p_source_value1     => p_je_line_code
                                        ,x_target_value1     => lc_ora_account
                                        ,x_target_value2    => x_target_value2_out
                                        ,x_target_value3    => x_target_value3_out
                                        ,x_target_value4    => x_target_value4_out
                                        ,x_target_value5    => x_target_value5_out
                                        ,x_target_value6    => x_target_value6_out
                                        ,x_target_value7    => x_target_value7_out
                                        ,x_target_value8    => x_target_value8_out
                                        ,x_target_value9    => x_target_value9_out
                                        ,x_target_value10   => x_target_value10_out
                                        ,x_target_value11   => x_target_value11_out
                                        ,x_target_value12   => x_target_value12_out
                                        ,x_target_value13   => x_target_value13_out
                                        ,x_target_value14   => x_target_value14_out
                                        ,x_target_value15   => x_target_value15_out
                                        ,x_target_value16   => x_target_value16_out
                                        ,x_target_value17   => x_target_value17_out
                                        ,x_target_value18   => x_target_value18_out
                                        ,x_target_value19   => x_target_value19_out
                                        ,x_target_value20   => x_target_value20_out
                                        ,x_error_message     => gc_translate_error
                                        );

               IF gc_translate_error IS NOT NULL THEN

                      XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>  gc_source_name
                               ,p_type         =>  'Account'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                               );


                      gn_error_count := gn_error_count + 1;
                      lc_error_flg := 'Y';

                      lc_debug_msg := '    Ora account error:  '||gc_translate_error;
                      DEBUG_MESSAGE (lc_debug_msg);
                      gc_translate_error := NULL;

               END IF;

               ------------------------------------------------------------------------------------
               -- Derive Oracle Inter-Company for GSS-BSG-VARIANCES and GSS-RECORDED-FEES ALCELCVAR
               ------------------------------------------------------------------------------------

               lc_debug_msg := '    Deriving Oracle Inter-Company: '
                               || 'for GSS-BSG-VARIANCES and GSS-RECORDED-FEES '
                         ||' p_je_line_code => '||   p_je_line_code
                         ||' lc_trans_name => ' ||   lc_trans_name;
               DEBUG_MESSAGE (lc_debug_msg);


               XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                 (p_translation_name => lc_trans_name
                                 ,p_source_value1    => p_je_line_code
                                 ,x_target_value1    => x_target_value1_out
                                 ,x_target_value2    => x_target_value2_out
                                 ,x_target_value3    => x_target_value3_out
                                 ,x_target_value4    => lc_ora_inter_company
                                 ,x_target_value5    => x_target_value5_out
                                 ,x_target_value6    => x_target_value6_out
                                 ,x_target_value7    => x_target_value7_out
                                 ,x_target_value8    => x_target_value8_out
                                 ,x_target_value9    => x_target_value9_out
                                 ,x_target_value10   => x_target_value10_out
                                 ,x_target_value11   => x_target_value11_out
                                 ,x_target_value12   => x_target_value12_out
                                 ,x_target_value13   => x_target_value13_out
                                 ,x_target_value14   => x_target_value14_out
                                 ,x_target_value15   => x_target_value15_out
                                 ,x_target_value16   => x_target_value16_out
                                 ,x_target_value17   => x_target_value17_out
                                 ,x_target_value18   => x_target_value18_out
                                 ,x_target_value19   => x_target_value19_out
                                 ,x_target_value20   => x_target_value20_out
                                 ,x_error_message    => gc_translate_error
                                  );

               IF gc_translate_error IS NOT NULL THEN

                        XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>   gc_source_name
                               ,p_type         =>  'Inter-Company'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                                );

                        gn_error_count := gn_error_count + 1;

                        lc_error_flg := 'Y';

                        lc_debug_msg := '    Ora inter-company error:  '||gc_translate_error;
                        DEBUG_MESSAGE (lc_debug_msg);
                        gc_translate_error := NULL;

               END IF;


           ELSE

           ------------------------------------------------------------
           -- Derive Oracle Cost Center for GSS-RET-VARIANCES ALCELCVAR
           ------------------------------------------------------------
                   gc_translate_error := NULL;

                   lc_debug_msg := '    Deriving Oracle Cost Center1: ';

                    XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                          (p_translation_name  => lc_trans_name
                                          ,p_source_value1     => p_je_line_code
                                          ,p_source_value2     => p_legacy_segment1
                                          ,x_target_value1     => x_target_value1_out
                                          ,x_target_value2     => lc_ora_cost_center
                                          ,x_target_value3     => x_target_value3_out
                                          ,x_target_value4     => x_target_value4_out
                                          ,x_target_value5     => x_target_value5_out
                                          ,x_target_value6     => x_target_value6_out
                                          ,x_target_value7     => x_target_value7_out
                                          ,x_target_value8     => x_target_value8_out
                                          ,x_target_value9     => x_target_value9_out
                                          ,x_target_value10    => x_target_value10_out
                                          ,x_target_value11    => x_target_value11_out
                                          ,x_target_value12    => x_target_value12_out
                                          ,x_target_value13    => x_target_value13_out
                                          ,x_target_value14    => x_target_value14_out
                                          ,x_target_value15    => x_target_value15_out
                                          ,x_target_value16    => x_target_value16_out
                                          ,x_target_value17    => x_target_value17_out
                                          ,x_target_value18    => x_target_value18_out
                                          ,x_target_value19    => x_target_value19_out
                                          ,x_target_value20    => x_target_value20_out
                                          ,x_error_message     => gc_translate_error
                                          );

                    IF gc_translate_error IS NOT NULL THEN

                          XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>  gc_source_name
                               ,p_type         =>  'Cost Center'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                               );

                          gn_error_count := gn_error_count + 1;

                          lc_error_flg := 'Y';
                          lc_debug_msg := '    Ora cost center error: '||gc_translate_error;
                           DEBUG_MESSAGE (lc_debug_msg);

                           gc_translate_error := NULL;
                    END IF;

                    --------------------------------------------------------
                    -- Derive Oracle Account for GSS-RET-VARIANCES ALCELCVAR
                    --------------------------------------------------------
                    lc_debug_msg := '    Deriving Oracle Account: ';

                     XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                        (p_translation_name  => lc_trans_name
                                        ,p_source_value1     => p_je_line_code
                                        ,p_source_value2     => p_legacy_segment1
                                        ,x_target_value1     => lc_ora_account
                                        ,x_target_value2     => x_target_value2_out
                                        ,x_target_value3     => x_target_value3_out
                                        ,x_target_value4     => x_target_value4_out
                                        ,x_target_value5     => x_target_value5_out
                                        ,x_target_value6     => x_target_value6_out
                                        ,x_target_value7     => x_target_value7_out
                                        ,x_target_value8     => x_target_value8_out
                                        ,x_target_value9     => x_target_value9_out
                                        ,x_target_value10    => x_target_value10_out
                                        ,x_target_value11    => x_target_value11_out
                                        ,x_target_value12    => x_target_value12_out
                                        ,x_target_value13    => x_target_value13_out
                                        ,x_target_value14    => x_target_value14_out
                                        ,x_target_value15    => x_target_value15_out
                                        ,x_target_value16    => x_target_value16_out
                                        ,x_target_value17    => x_target_value17_out
                                        ,x_target_value18    => x_target_value18_out
                                        ,x_target_value19    => x_target_value19_out
                                        ,x_target_value20    => x_target_value20_out
                                        ,x_error_message     => gc_translate_error
                                        );

                     IF gc_translate_error IS NOT NULL THEN


                         XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>  gc_source_name
                               ,p_type         =>  'Account'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                               );


                          gn_error_count := gn_error_count + 1;
                          lc_error_flg := 'Y';

                          lc_debug_msg := '    Ora account error:  '||gc_translate_error;
                          DEBUG_MESSAGE (lc_debug_msg);
                          gc_translate_error := NULL;

                    END IF;

                    --------------------------------------------------------------
                    -- Derive Oracle Inter-Company for GSS-RET-VARIANCES ALCELCVAR
                    --------------------------------------------------------------

                    lc_debug_msg := '    Deriving Oracle Inter-Company: ';


                    XX_FIN_TRANSLATE_PKG.XX_FIN_TRANSLATEVALUE_PROC
                                 (p_translation_name => lc_trans_name
                                 ,p_source_value1    => p_je_line_code
                                 ,p_source_value2    => p_legacy_segment1
                                 ,x_target_value1    => x_target_value1_out
                                 ,x_target_value2    => x_target_value2_out
                                 ,x_target_value3    => x_target_value3_out
                                 ,x_target_value4    => lc_ora_inter_company
                                 ,x_target_value5    => x_target_value5_out
                                 ,x_target_value6    => x_target_value6_out
                                 ,x_target_value7    => x_target_value7_out
                                 ,x_target_value8    => x_target_value8_out
                                 ,x_target_value9    => x_target_value9_out
                                 ,x_target_value10   => x_target_value10_out
                                 ,x_target_value11   => x_target_value11_out
                                 ,x_target_value12   => x_target_value12_out
                                 ,x_target_value13   => x_target_value13_out
                                 ,x_target_value14   => x_target_value14_out
                                 ,x_target_value15   => x_target_value15_out
                                 ,x_target_value16   => x_target_value16_out
                                 ,x_target_value17   => x_target_value17_out
                                 ,x_target_value18   => x_target_value18_out
                                 ,x_target_value19   => x_target_value19_out
                                 ,x_target_value20   => x_target_value20_out
                                 ,x_error_message    => gc_translate_error
                                  );

                   IF gc_translate_error IS NOT NULL THEN

                        XX_GL_INTERFACE_PKG.PROCESS_ERROR
                               (p_rowid        =>  p_row_id
                               ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                               ,p_source_nm      =>   gc_source_name
                               ,p_type         =>  'Inter-Company'
                               ,p_value        =>  NVL(p_je_line_code,'Not Found')
                               ,p_details      =>  gc_translate_error
                               ,p_group_id     =>  gn_group_id
                                );

                        gn_error_count := gn_error_count + 1;

                        lc_error_flg := 'Y';

                        lc_debug_msg := '    Ora inter-company error:  '
                                         ||gc_translate_error;
                        DEBUG_MESSAGE (lc_debug_msg);

                        gc_translate_error := NULL;

                  END IF;

            END IF;

       END IF;

       -----------------------------------------
       -- Derive Oracle Line of Business for all
       -----------------------------------------
       lc_debug_msg := '    Deriving Oracle Line of Business: '
                       ||' p_je_line_code => '||   p_je_line_code
                       ||' lc_trans_name => ' ||   lc_trans_name;
       DEBUG_MESSAGE (lc_debug_msg);


       XX_GL_TRANSLATE_UTL_PKG.DERIVE_LOB_FROM_COSTCTR_LOC
                                        (p_location      => lc_ora_location
                                        ,p_cost_center   => lc_ora_cost_center
                                        ,x_lob           => lc_ora_lob
                                        ,x_error_message => gc_translate_error
                                         );

        IF gc_translate_error IS NOT NULL THEN

                  XX_GL_INTERFACE_PKG.PROCESS_ERROR
                              (p_rowid        =>  p_row_id
                              ,p_fnd_message  =>  'XX_GL_INTERFACE_VALUE_ERROR'
                              ,p_source_nm      =>  gc_source_name
                              ,p_type         =>  'Ora LOB'
                              ,p_value        =>  'Ora Loc=> '
                                                   || lc_ora_location
                                                   ||'Cost Center => '
                                                   || lc_ora_cost_center
                              ,p_details      =>  gc_translate_error
                              ,p_group_id     =>  gn_group_id
                               );

                  gn_error_count := gn_error_count + 1;

                  lc_error_flg := 'Y';


                  lc_debug_msg := '    Ora line of business error:  '
                                       ||gc_translate_error;
                  DEBUG_MESSAGE (lc_debug_msg);

                  gc_translate_error := NULL;

        END IF ;

       ---------------------------
       --Update all derived values
       ---------------------------

       IF  lc_error_flg = 'N' THEN

                lc_debug_msg := '    Updating segment values: ';

                BEGIN
                   	UPDATE XX_GL_INTERFACE_NA_STG
         	        SET    segment1    =  lc_ora_company
                              ,Segment2    =  lc_ora_cost_center
     	                      ,segment3    =  lc_ora_account
                              ,segment4    =  lc_ora_location
                              ,segment5    =  NVL(lc_ora_inter_company,'0000')
                              ,segment6    =  lc_ora_lob
                              ,segment7    =  '000000'  --Oracle Future Value
	                      ,derived_val =  'VALID'
               	       WHERE   rowid       =  p_row_id;

		       COMMIT;

                           lc_debug_msg :='    Values Updated: '
                                         ||'company=> '         ||lc_ora_company
                                         ||', cost_center=> '   ||lc_ora_cost_center
                                         ||', account=> '       ||lc_ora_account
                                         ||', location=> '      ||lc_ora_location
                                         ||', inter_company=> ' ||NVL(lc_ora_inter_company,
                                                                        '0000'
                                                                       )
                                         ||', lc_ora_lob=> '    ||lc_ora_lob
                                         ||', Future=> 000000 ' ||'VALID';

                            DEBUG_MESSAGE (lc_debug_msg);


                EXCEPTION
                      WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '
                                           || lc_debug_msg
                                          );

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_GL_INTERFACE_NA_STG = ROWID: '
                                           || p_row_id
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
         	        SET    segment1    =  lc_ora_company
                              ,Segment2    =  lc_ora_cost_center
     	                      ,segment3    =  lc_ora_account
                              ,segment4    =  lc_ora_location
                              ,segment5    =  NVL(lc_ora_inter_company,'0000')
                              ,segment6    =  lc_ora_lob
                              ,segment7    =  '000000'  --Oracle Future Value
	                      ,derived_val =  'INVALID'
               	       WHERE   rowid       =  p_row_id;

		       COMMIT;

                 lc_debug_msg :='    Values errored Updating: '
                                     ||'company=> '         ||lc_ora_company
                                     ||', cost_center=> '   ||lc_ora_cost_center
                                     ||', account=> '       ||lc_ora_account
                                     ||', location=> '      ||lc_ora_location
                                     ||', inter_company=> ' ||NVL(lc_ora_inter_company,
                                                                  '0000'
                                                                  )
                                     ||', lc_ora_lob=> '    ||lc_ora_lob
                                     ||', Future=> 000000 ' ||'INVALID';

                 DEBUG_MESSAGE (lc_debug_msg);
                 
              EXCEPTION
                      WHEN OTHERS THEN
                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '
                                           || lc_debug_msg
                                          );

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_GL_INTERFACE_NA_STG = ROWID: '
                                           || p_row_id
                                          );

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );

                         --------------------------------
                         -- TODO
                         -- log to standard error table
                         -------------------------------
                END;


        END IF;

    EXCEPTION

         WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '|| lc_debug_msg );
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );

              --------------------------------
              -- TODO
              -- log to standard error table
              -------------------------------

    END GSS_DERIVE_VALUES;

-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for the GSS     |
-- |                    interface This will be called by the OD: GL    |
-- |                    Interface for GSS concurrent program           |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name, p_debug_flg                            |
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
          lc_firsT_record    VARCHAR2(1);
          lc_debug_prog      VARCHAR2(100) := 'PROCESS_JOURNALS';
          ln_conc_id         INTEGER;
          lc_mail_subject    VARCHAR2(250);
          lc_details         XX_GL_INTERFACE_NA_LOG.details%TYPE;
          ln_set_of_books_id  XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;  --added Defect 14556
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
          CURSOR get_je_main_process_cursor -- (p_set_of_books_id IN NUMBER) commented for defect 14556
              IS
          SELECT DISTINCT
                  group_id
                 ,user_je_source_name
                 ,reference24
                  FROM  XX_GL_INTERFACE_NA_STG
           WHERE user_je_source_name            = p_source_name
      --      AND  set_of_books_id                = p_set_of_books_id            --added Defect 14556  commented for defect 14556
            AND  (NVL(derived_val,'INVALID')    = 'INVALID'
             OR   NVL(derived_sob,'INVALID')    = 'INVALID'
             OR   NVL(balanced   ,'UNBALANCED') = 'UNBALANCED');


          ---------------------------------------------------------------------
          -- Cursor to select individual new or invalid rows from staging table.
          -- This will be used to derive any needed values or check balance.
          ---------------------------------------------------------------------
          CURSOR get_je_lines_cursor-- (p_set_of_books_id IN NUMBER)   commented for defect 14556
              IS
          SELECT  rowid
                 ,reference22
                 ,group_id
                 ,user_je_source_name
                 ,user_je_category_name
                 ,derived_sob
                 ,derived_val
                 ,balanced
                 ,reference21
                 ,legacy_segment4
                 ,legacy_segment1
            FROM  XX_GL_INTERFACE_NA_STG
           WHERE group_id                       = gn_group_id
         --   AND  set_of_books_id                = p_set_of_books_id            --added Defect 14556 commented for defect 14556
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


        ln_set_of_books_id := fnd_profile.value('GL_SET_OF_BKS_ID');                 --added Defect 14556

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

        OPEN get_je_main_process_cursor; -- (ln_set_of_books_id);           --added parameter for Defect 14556
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
                        WHERE  group_id = gn_group_id ;

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


           -----------------------------------
           --  Select records to derive values
           -----------------------------------

           lc_debug_msg := '    Open Cursor get_je_lines_cursor ';
           DEBUG_MESSAGE (lc_debug_msg);

            OPEN get_je_lines_cursor;-- (ln_set_of_books_id);                 --added parameter for Defect 14556
            LOOP  

                FETCH get_je_lines_cursor
                INTO	  ln_row_id
                         ,lc_jnrl_name
                         ,gn_group_id
                         ,gc_source_name
                         ,gc_category_name
                         ,lc_derived_sob
                         ,lc_derived_value
                         ,lc_balanced
                         ,lc_gl_je_line_code
                         ,lc_legacy_segment4
                         ,lc_legacy_segment1;

             EXIT WHEN get_je_lines_cursor%NOTFOUND;



                ----------------------------
                --  Derive all needed values
                ----------------------------
      	        IF NVL(lc_derived_value, 'INVALID') = 'INVALID' THEN

                    GSS_DERIVE_VALUES (p_row_id          => ln_row_id
                                      ,p_jrnl_name       => lc_jnrl_name
      	                              ,p_je_line_code    => lc_gl_je_line_code
                                      ,p_legacy_segment4 => lc_legacy_segment4
                                      ,p_legacy_segment1 => lc_legacy_segment1
                                       );
	        END IF;

            END LOOP;
            CLOSE get_je_lines_cursor;

            lc_debug_msg := 'Total number of Derived errors: ' || gn_error_count;
            DEBUG_MESSAGE (lc_debug_msg,1);


      --   END LOOP;
      --   CLOSE get_je_main_process_cursor;


            ---------------------------------
            -- Create inter-company Journal
            ---------------------------------

            CREATE_INTERCOMP_JRNL;

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


END XX_GL_GSS_INTERFACE_PKG;
/