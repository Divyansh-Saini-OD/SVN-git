-- +===================================================================================+
-- |              Office Depot - Project Simplify                                      |
-- +===================================================================================+
-- | Name :    XX_GL_INT_EBS_COA_PKG                                                   |
-- |                                                                                   |
-- | RICE Id            : C0069 - OD GL Integral TO ORACLE ACCOUNT CONVERION API       |
-- |                                                                                   |
-- | Description : To convert the Integral accounts into Oracle account segments       |
-- |               using PSGL Account Conversion Common API                            |
-- |               DERIVE_STORED_VALUES,DERIVE_ALL_VALUES,DERIVE_COMPANY,              |
-- |               DERIVE_COSTCTR,DERIVE_LOCATION,DERIVE_ACCOUNT,DERIVE_INTERCO        |
-- |               DERIVE_LOCATION_TYPE,DERIVE_COSTCTR_TYPES,DERIVE_LOB,               |
-- |               SAVE_DERIVED_VALUES,DELETE_DERIVED_VALUES,DERIVE_CCID,              |
-- |               TRANSLATE_PS_VALUES                                                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version       Date              Author              Remarks                        |
-- |=======       ==========    =============        =======================           |
-- |1.0           11-JUN-2012   Paddy Sanjeevi       Initial Version (Defect 18792)    |
-- |1.1           22-JUN-2012   Paddy Sanjeevi       Modified for defect 19168         |
-- |1.2           28-JUN-2012   Paddy Sanjeevi       Modified for defect 19238         |
-- |1.3           06-JUL-2012   Paddy Sanjeevi       Modified for defect 19342         |
-- |1.4           09-JUL-2012   Paddy Sanjeevi       Removed insert into translate     |
-- |1.5           16-JUL-2012   Paddy Sanjeevi       Added distinct clause in error rpt|
-- |1.6           18-JUL-2013   Sheetal Sundaram     I0463 - Changes for R12           |
-- |                                                 Upgrade retrofit.                 |
-- |1.7           18-NOV-2015   Madhu Bolli          Remove schema for 12.2 retrofit   |
-- |1.8           10-DEC-2020   Venkateshwar Panduga Made changes for JIRA#NAIT-158610 |

-- +===================================================================================+

create or replace PACKAGE BODY XX_GL_INT_EBS_COA_PKG
AS


-- +===================================================================+
-- | Name             : XX_GL_INT_EBS_COA_REPORT                       |
-- | Description      : This Procedure reads GL_INT_EBS_COA_CALC       |
-- |                    from translation table and creates a pipe      |
-- |                    delimited file                                 |
-- |                                                                   |
-- | Parameters :  p_source_nm                                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns    :  errbuf,retcode                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE XX_GL_INT_EBS_COA_REPORT ( ERRBUFF     OUT VARCHAR2
                             	      ,retcode     OUT varchar2
						,p_source_nm  in VARCHAR2)
  IS

--- COA (Data)
	CURSOR COA_Cursor IS
    SELECT distinct b.source_name, b.source_value1,b.source_value2,b.source_value3,
        b.source_value4,b.source_value5,b.source_value6,
              b.target_value1,b.target_value2,b.target_value3,
              b.target_value4,b.target_value5,b.target_value6,
              b.target_value7,b.target_value8,b.target_value9,
              b.target_value10,b.target_value11,b.target_value12,
              b.target_value13,b.target_value14,b.target_value15,
              b.target_value16,b.target_value17,b.target_value18,
              b.target_value19
     FROM XX_FIN_ITGORA_STG b
     WHERE b.source_name=p_source_nm;
--- COA (Data)

   v_header VARCHAR2(2000);

  BEGIN


   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Source Name| Integral Company |Integral Department |Integral Account |Integral Account |Integral BU | Integral Batch |Oracle Company | Oracle Cost Center |Oracle Account |	Oracle Location |	Oracle LOB |Oracle SOB |Oracle Location Type | Oracle Cost Cnt Type |~COA Trans Status |*CC_ACCT_LOC |*ACCT_CC |*LOC_CC | *COST_CTR |#GLOBAL_LOCATION | #GLOBAL_COMPANY | #GLOBAL_COST_CENTER |*COSTCTR_LOC_TO_LOB |Oracle Code Combo ID | $COMBINATIONS');

    FOR rec IN COA_Cursor
    LOOP
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, rec.source_name ||'|'|| rec.source_value1 ||'|'|| rec.source_value2 || '|'||
       rec.source_value3 || '|' || rec.source_value4 || '|' || rec.source_value5 || '|' || rec.source_value6 || '|'||
       rec.target_value1|| '|' ||rec.target_value2|| '|' ||rec.target_value3|| '|' ||rec.target_value4|| '|'||
       rec.target_value5|| '|' ||rec.target_value6|| '|' ||rec.target_value7|| '|' ||rec.target_value8|| '|'||
       rec.target_value9|| '|' ||rec.target_value10|| '|' ||rec.target_value11|| '|' ||rec.target_value12|| '|'||
       rec.target_value13|| '|' ||rec.target_value14|| '|' ||rec.target_value15|| '|' ||rec.target_value16|| '|'||
       rec.target_value17||'|' ||rec.target_value18||'|' ||rec.target_value19);
    END LOOP;
EXCEPTION
  WHEN others THEN
    errbuff:=SQLERRM;
    RETCODE:='2';
END XX_GL_INT_EBS_COA_REPORT;

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

         IF gc_debug_message = 'Y' THEN
               LOOP

               EXIT WHEN ln_space_cnt = p_spaces;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                    ln_space_cnt := ln_space_cnt + 1;

               END LOOP;

               FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

         END IF;
   END;


-- +===================================================================+
-- | Name  :PROCESS_ERROR                                              |
-- | Description      : This Procedure is used to process any found    |
-- |                    derive  values, balanced errors                |
-- |                                                                   |
-- | Parameters :  p_rowid, p_fnd_message, p_type, p_value, p_details  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE PROCESS_ERROR (p_rowid         IN  ROWID
                        ,p_fnd_message   IN  VARCHAR2
                        ,p_source_nm     IN  VARCHAR2
                        ,p_type          IN  VARCHAR2
                        ,p_value         IN  VARCHAR2
                        ,p_details       IN  VARCHAR2
                        ,p_group_id      IN  NUMBER
                        ,p_sob_id        IN  NUMBER DEFAULT NULL
                        )
IS

UPDATE_ERR      EXCEPTION;

lc_detail_err   VARCHAR2(3000);
lc_debug_msg    VARCHAR2(500);
lc_debug_prog   VARCHAR2(15) := 'PROCESS_ERROR';
lc_debug_pkg_nm VARCHAR2(50) := 'XX_GL_INT_EBS_COA_PKG';

BEGIN

  FND_FILE.PUT_LINE(FND_FILE.LOG,'' );
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  lc_debug_pkg_nm
                                            ||  lc_debug_prog ||'!!!!!!!!!!!');

  -- intialize variables

  lc_debug_msg := 'Creating FND Message';
  lc_detail_err := p_details;

  BEGIN

    INSERT
      INTO XX_GL_INTERFACE_NA_ERROR
          (
           fnd_error_code
          ,source_name
          ,details
          ,type
          ,value
          ,group_id
          ,set_of_books_id
          ,creation_date
          )
   VALUES
          (
           p_fnd_message
          ,p_source_nm
          ,lc_detail_err
          ,p_type
          ,p_value
          ,p_group_id
          ,p_sob_id
          ,sysdate
          );
  EXCEPTION
    WHEN OTHERS THEN
      fnd_message.clear();
      fnd_message.set_name('FND','FS-UNKNOWN');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_message.set_token('ROUTINE',lc_debug_pkg_nm
                                                ||lc_debug_prog
                                                ||lc_debug_msg
                                               );
      fnd_file.put_line(fnd_file.log,fnd_message.get);

  END;

  ----------------------------------
  --update records to invalid status
  ----------------------------------

  IF p_fnd_message = 'XX_GL_TRANS_VALUE_ERROR' THEN

    lc_debug_msg := 'Updating XX_GL_INTERFACE_NA_STG' ||
                    ' with derived_val = INVALID, ROWID = ' ||
                                      p_rowid;

    BEGIN
      UPDATE XX_GL_INTERFACE_NA_STG
         SET derived_val = 'INVALID'
       WHERE rowid       =  p_rowid;

    EXCEPTION
      WHEN OTHERS THEN
        RAISE UPDATE_ERR;
    END;

  END IF;
  COMMIT;
EXCEPTION
  WHEN UPDATE_ERR THEN
    fnd_message.clear();
    fnd_message.set_name('FND','FS-UNKNOWN');
    fnd_message.set_token('ERROR',SQLERRM);
    fnd_message.set_token('ROUTINE',lc_debug_pkg_nm ||lc_debug_prog ||lc_debug_msg);
    fnd_file.put_line(fnd_file.log,fnd_message.get());
  WHEN OTHERS THEN
    fnd_message.clear();
    fnd_message.set_name('FND','FS-UNKNOWN');
    fnd_message.set_token('ERROR',SQLERRM);
    fnd_message.set_token('ROUTINE',lc_debug_pkg_nm ||lc_debug_prog ||lc_debug_msg);
    fnd_file.put_line(fnd_file.log,fnd_message.get());

END PROCESS_ERROR;

-- +===================================================================+
-- | Name  :DELETE_TRANSLATE                                           |
-- | Description      : This Procedure is used to delete the records   |
-- |                    in the translation table for the translation   |
-- |                    GL_INT_EBS_COA_CALC and xx_fin_itgora_stg      |
-- |                                                                   |
-- | Parameters :  p_source_nm                                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE DELETE_TRANSLATE(p_source_nm IN VARCHAR2)
IS

lc_error_message VARCHAR2(2000);

BEGIN

  DELETE
    FROM xx_fin_itgora_stg
   WHERE source_name=p_source_nm;
  COMMIT;

EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while Deleting from Translate GL_INT_EBS_COA_CALC :'||SQLERRM);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END DELETE_TRANSLATE;





-- +===================================================================================+
-- | Name        : DERIVE_CCID                                                         |
-- |                                                                                   |
-- | Description : To derive the CCID for various combinations of the segments         |
-- |                                                                                   |
-- |Parameters   :   p_ora_company                                                     |
-- |                 ,p_ora_cost_center                                                |
-- |                 ,p_ora_account                                                    |
-- |                 ,p_ora_location                                                   |
-- |                 ,p_ora_intercompany                                               |
-- |                 ,p_ora_lob                                                        |
-- |                 ,p_ora_future                                                     |
-- |                                                                                   |
-- |Returns      :       x_error_message => Error Message                              |
-- |                     ,x_ccid         => Oracle Code Combinaton id                  |
-- |                                                                                   |
-- +===================================================================================+

PROCEDURE DERIVE_CCID(
                      p_ora_company              IN          VARCHAR2
                     ,p_ora_cost_center         IN          VARCHAR2
                     ,p_ora_account             IN          VARCHAR2
                     ,p_ora_location            IN          VARCHAR2
                     ,p_ora_intercompany        IN          VARCHAR2
                     ,p_ora_lob                 IN          VARCHAR2
                     ,p_ora_future              IN          VARCHAR2
                     ,x_ccid                    OUT NOCOPY  VARCHAR2
                     ,x_error_message           OUT NOCOPY  VARCHAR2
                     )
IS
  lt_tbl_ora_segments      fnd_flex_ext.SegmentArray;
  lc_concat_segments       VARCHAR2(2000);
  lc_ccid_enabled_flag     VARCHAR2(1);
  lb_return                BOOLEAN;
  lc_ccid_exist_flag       VARCHAR2(1);
  lc_error_message         VARCHAR2(4000);
  lc_error_loc             VARCHAR2(2000);
  lc_error_debug           VARCHAR2(2000);
  lc_coa_id                gl_sets_of_books_v.chart_of_accounts_id%TYPE;
  ln_tot_segments          NUMBER(1):=7;
  lc_vrule_name            VARCHAR2(50);
  lc_ps_segments           VARCHAR2(150);
  lc_ora_segments	   VARCHAR2(150);


  ln_user_id        NUMBER;
  ln_resp_id        NUMBER;
  ln_resp_appl_id   NUMBER;

BEGIN

  lc_ps_segments :=gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob;
  lc_ora_segments:=gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future;

  IF     p_ora_company       IS NOT NULL
     AND p_ora_cost_center   IS NOT NULL
     AND p_ora_account       IS NOT NULL
     AND p_ora_location      IS NOT NULL
     AND p_ora_intercompany  IS NOT NULL
     AND p_ora_lob           IS NOT NULL
     AND p_ora_future        IS NOT NULL THEN

     lc_concat_segments := p_ora_company ||  '.' || p_ora_cost_center  || '.' ||
                           p_ora_account ||  '.' || p_ora_location || '.' ||
                           p_ora_intercompany ||  '.' || p_ora_lob || '.' ||
                           p_ora_future;

     BEGIN
       SELECT GSB.chart_of_accounts_id
         INTO lc_coa_id
         FROM  gl_sets_of_books_v GSB
        WHERE GSB.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');

       SELECT  GCC.code_combination_id
              ,GCC.enabled_flag
         INTO  gc_ccid
              ,lc_ccid_enabled_flag
         FROM  gl_code_combinations_v GCC
              ,gl_sets_of_books_v     GSB
        WHERE GCC.SEGMENT1 = p_ora_company
          AND GCC.SEGMENT2 = gc_cost_center
          AND GCC.SEGMENT3 = p_ora_account
          AND GCC.SEGMENT4 = p_ora_location
          AND GCC.SEGMENT5 = p_ora_intercompany
          AND GCC.SEGMENT6 = p_ora_lob
          AND GCC.SEGMENT7 = p_ora_future
          AND GCC.chart_of_accounts_id = GSB.chart_of_accounts_id
          AND GSB.set_of_books_id      = fnd_profile.value('GL_SET_OF_BKS_ID');

          lc_ccid_exist_flag := 'Y';



          IF lc_ccid_enabled_flag <> 'Y' THEN
               x_error_message := x_error_message || ' CCID=' || gc_ccid ||
                                  ' is not enabled for Oracle Segments=' || lc_concat_segments;
             IF gc_debug_message = 'Y' THEN
                   FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
             END IF;

	     gc_ccid_enabled    :='N';
	     lc_error_message   :='Record '||gc_record_no||
 	     '- TABLE - Oracle Code Combination ID is not enabled in the GL_CODE_COMBINATIONS table for Oracle COA: '||  	    	             lc_ora_segments||' Integral COA: '||lc_ps_segments;

             PROCESS_ERROR(p_rowid       =>g_row_id
		,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		,p_source_nm   =>gc_source_nm
		,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		,p_value  =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
			gc_sr_operating_unit||'.'||gc_sr_lob
		,p_details   =>lc_error_message
		,p_group_id    =>gn_grp_id
		   );

          ELSE
               IF gc_debug_message = 'Y' THEN
                      FND_FILE.PUT_LINE (FND_FILE.LOG,'CCID=' || gc_ccid ||
                     ' is defined in oracle EBS for Oracle Segments=' || lc_concat_segments);
               END IF;
          END IF;
     EXCEPTION
       WHEN OTHERS THEN
         IF gc_debug_message = 'Y' THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'CCID is not defined for Oracle Segments='
                     || lc_concat_segments);
         END IF;
         lc_ccid_exist_flag := 'N';
     END;

     IF  lc_ccid_exist_flag = 'N' THEN

         ln_user_id      := fnd_global.user_id;
         ln_resp_id      := fnd_global.resp_id;
         ln_resp_appl_id := fnd_global.resp_appl_id;

         FND_GLOBAL.APPS_INITIALIZE (ln_user_id, ln_resp_id, ln_resp_appl_id);


         -- This API will validate all the Oracle segments

         BEGIN
           lb_return := FND_FLEX_KEYVAL.VALIDATE_SEGS(
                                                      OPERATION         => 'CHECK_COMBINATION'
                                                      ,APPL_SHORT_NAME  => 'SQLGL'
                                                      ,KEY_FLEX_CODE    => 'GL#'
                                                      ,STRUCTURE_NUMBER => lc_coa_id
                                                      ,CONCAT_SEGMENTS  => lc_concat_segments
                                                      );
         EXCEPTION
           WHEN OTHERS THEN
             lc_error_loc     := 'Error: Exception raised while Validating all segments';
             lc_error_debug   := 'FND_FLEX_KEYVAL.VALIDATE_SEGS';
             lc_error_message := 'Exception raised. '|| SQLERRM;
             x_error_message  := x_error_message || lc_error_message || lc_error_loc
                                         || lc_error_debug;
         END;

         IF lb_return = FALSE  THEN

            -- The below API added for Defect : 1227
            -- This API returns the exact error message for CVR Rule violation

            BEGIN
              lc_error_message := FND_FLEX_KEYVAL.ERROR_MESSAGE;
            EXCEPTION
              WHEN OTHERS THEN
                lc_error_loc     := 'Error: Exception raised while getting the CVR Violation Message';
                lc_error_debug   := 'FND_FLEX_KEYVAL.ERROR_MESSAGE';
                lc_error_message := 'Exception raised. '|| SQLERRM;
                x_error_message := x_error_message || lc_error_message || lc_error_loc
                                        || lc_error_debug;
            END;

            x_error_message := x_error_message || 'CVR Message : ' ||lc_error_message
                                 || lc_concat_segments
                                 || '.Hence GL Cross Validation Rule does not allow to '
                                 || 'create CCID for this Oracle Segments.';

            IF gc_debug_message = 'Y' THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG, x_error_message);
            END IF;
         ELSE
           lt_tbl_ora_segments(1) := p_ora_company;
           lt_tbl_ora_segments(2) := gc_cost_center;
           lt_tbl_ora_segments(3) := p_ora_account;
           lt_tbl_ora_segments(4) := p_ora_location;
           lt_tbl_ora_segments(5) := p_ora_intercompany;
           lt_tbl_ora_segments(6) := p_ora_lob;
           lt_tbl_ora_segments(7) := p_ora_future;

           BEGIN
             lb_return := FND_FLEX_EXT.GET_COMBINATION_ID(
                                                              application_short_name => 'SQLGL'
                                                             ,key_flex_code         => 'GL#'
                                                             ,structure_number      => lc_coa_id
                                                             ,validation_date       => SYSDATE
                                                             ,n_segments            => ln_tot_segments
                                                             ,segments              => lt_tbl_ora_segments
                                                             ,combination_id        => gc_ccid
                                                             );
           EXCEPTION
             WHEN OTHERS THEN
               lc_error_loc     := 'Error: Exception raised while getting the CCID';
               lc_error_debug   := 'FND_FLEX_EXT.GET_COMBINATION_ID';
               lc_error_message := 'Exception raised. '|| SQLERRM;
               x_error_message  :=  x_error_message || lc_error_message || lc_error_loc
                                       || lc_error_debug;
           END;


           IF gc_debug_message = 'Y' THEN
              FND_FILE.PUT_LINE (FND_FILE.LOG,'CCID=' || gc_ccid || ' is created for Oracle Segments='
                                                           || lc_concat_segments);
           END IF;
         END IF;
     END IF;  -- IF  lc_ccid_exist_flag = 'N' THEN
       x_ccid := gc_ccid;
  ELSE
    x_error_message := 'To get CCID, all the Oracle segments are required';
  END IF;  --     p_ora_company       IS NOT NULL
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    lc_error_loc     := 'Error : Code combination is not defined '
                         || 'in Oracle for Oracle Account Segments=' || lc_concat_segments;
    lc_error_debug   := 'DERIVE_CCID';
    lc_error_message := 'Exception raised ' || SQLERRM;
    x_error_message := x_error_message || lc_error_message || lc_error_loc || lc_error_debug;
    IF gc_debug_message = 'Y' THEN
       FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
    END IF;

  WHEN OTHERS THEN
    lc_error_loc     := 'Error: Exception raised While Deriving CCID for Oracle Account Segments='
                        || lc_concat_segments;
    lc_error_debug   := 'DERIVE_CCID';
    lc_error_message := 'Exception raised. '|| SQLERRM;
    x_error_message  := x_error_message || lc_error_message || lc_error_loc
                        || lc_error_debug;
    --- +++++
    gc_debug_message := 'Y';
    --- +++++
    IF gc_debug_message = 'Y' THEN
       FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
    END IF;
END DERIVE_CCID;

-- +===================================================================================+
-- | Name        : DERIVE_FIN_TRANSLATE_VALUE                                          |
-- |                                                                                   |
-- | Description : To  derive the Translation values from XX_FIN_TRANSLATEVALUES table |
-- |                                                                                   |
-- |Parameters   :  p_source_value1 - 20 => Source value                               |
-- |                                                                                   |
-- |Returns      :  Target Values 1-20 => Translated Value                             |
-- |                x_error_message    => Error Message                                |
-- +===================================================================================+

PROCEDURE DERIVE_FIN_TRANSLATE_VALUE(
      p_translation_name   IN       VARCHAR2    DEFAULT NULL,
      p_trx_date           IN       DATE        DEFAULT SYSDATE,
      p_source_value1      IN       VARCHAR2    DEFAULT NULL,
      p_source_value2      IN       VARCHAR2    DEFAULT NULL,
      p_source_value3      IN       VARCHAR2    DEFAULT NULL,
      p_source_value4      IN       VARCHAR2    DEFAULT NULL,
      p_source_value5      IN       VARCHAR2    DEFAULT NULL,
      p_source_value6      IN       VARCHAR2    DEFAULT NULL,
      p_source_value7      IN       VARCHAR2    DEFAULT NULL,
      p_source_value8      IN       VARCHAR2    DEFAULT NULL,
      p_source_value9      IN       VARCHAR2    DEFAULT NULL,
      p_source_value10     IN       VARCHAR2    DEFAULT NULL,
      x_target_value1      OUT      VARCHAR2,
      x_target_value2      OUT      VARCHAR2,
      x_target_value3      OUT      VARCHAR2,
      x_target_value4      OUT      VARCHAR2,
      x_target_value5      OUT      VARCHAR2,
      x_target_value6      OUT      VARCHAR2,
      x_target_value7      OUT      VARCHAR2,
      x_target_value8      OUT      VARCHAR2,
      x_target_value9      OUT      VARCHAR2,
      x_target_value10     OUT      VARCHAR2,
      x_target_value11     OUT      VARCHAR2,
      x_target_value12     OUT      VARCHAR2,
      x_target_value13     OUT      VARCHAR2,
      x_target_value14     OUT      VARCHAR2,
      x_target_value15     OUT      VARCHAR2,
      x_target_value16     OUT      VARCHAR2,
      x_target_value17     OUT      VARCHAR2,
      x_target_value18     OUT      VARCHAR2,
      x_target_value19     OUT      VARCHAR2,
      x_target_value20     OUT      VARCHAR2,
      x_error_message      OUT      VARCHAR2
     )
IS
      lc_translate_id   xx_fin_translatedefinition.translate_id%TYPE;
      lc_error_message   VARCHAR2(2000);
      lc_error_loc       VARCHAR2(2000);
      lc_error_debug     VARCHAR2(2000);

BEGIN

  BEGIN
    SELECT translate_id
      INTO lc_translate_id
      FROM xx_fin_translatedefinition
     WHERE translation_name = p_translation_name
       AND enabled_flag = 'Y'
       AND (start_date_active <= p_trx_date
       AND (end_date_active >= p_trx_date OR end_date_active IS NULL));
  EXCEPTION
    WHEN OTHERS THEN
      lc_error_loc     := 'Error: Exception raised in DERIVE_FIN_TRANSLATE_VALUE '
                                   || 'while fetching Translation ID.';
      lc_error_debug   := p_translation_name;
      lc_error_message := 'Exception raised. ' || SQLERRM;
      x_error_message  := x_error_message || lc_error_message || lc_error_loc
                                   || lc_error_debug;
  END;


  --Translation is fine, retrieve the target values.

  BEGIN
    SELECT target_value1
          ,target_value2
          ,target_value3
          ,target_value4
          ,target_value5
          ,target_value6
          ,target_value7
          ,target_value8
          ,target_value9
          ,target_value10
          ,target_value11
          ,target_value12
          ,target_value13
          ,target_value14
          ,target_value15
          ,target_value16
          ,target_value17
          ,target_value18
          ,target_value19
          ,target_value20
     INTO  x_target_value1
          ,x_target_value2
          ,x_target_value3
          ,x_target_value4
          ,x_target_value5
          ,x_target_value6
          ,x_target_value7
          ,x_target_value8
          ,x_target_value9
          ,x_target_value10
          ,x_target_value11
          ,x_target_value12
          ,x_target_value13
          ,x_target_value14
          ,x_target_value15
          ,x_target_value16
          ,x_target_value17
          ,x_target_value18
          ,x_target_value19
          ,x_target_value20
     FROM xx_fin_translatevalues
    WHERE translate_id    = lc_translate_id
      AND NVL(source_value1,1)  = NVL(p_source_value1,1)
      AND NVL(source_value2,1)  = NVL(p_source_value2,1)
      AND NVL(source_value3,1)  = NVL(p_source_value3,1)
      AND NVL(source_value4,1)  = NVL(p_source_value4,1)
      AND NVL(source_value5,1)  = NVL(p_source_value5,1)
      AND NVL(source_value6,1)  = NVL(p_source_value6,1)
      AND NVL(source_value7,1)  = NVL(p_source_value7,1)
      AND NVL(source_value8,1)  = NVL(p_source_value8,1)
      AND NVL(source_value9,1)  = NVL(p_source_value9,1)
      AND NVL(source_value10,1) = NVL(p_source_value10,1)
      AND enabled_flag          = 'Y'
      AND (start_date_active   <= p_trx_date
      AND (end_date_active     >= p_trx_date OR end_date_active IS NULL));
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      x_error_message :=   x_error_message || 'No Translation defined in '
                           || p_translation_name || ' for ' || p_source_value1 || p_source_value2
                           || p_source_value3    || p_source_value4    || p_source_value5;
    WHEN OTHERS THEN
      lc_error_loc     := 'Error: Exception raised in DERIVE_FIN_TRANSLATE_VALUE procedure '
                           || ' while fetching Translation Value';
      lc_error_debug   := p_translation_name;
      lc_error_message := 'Exception raised. ' || SQLERRM;
      x_error_message  := x_error_message || lc_error_message || lc_error_loc
                          || lc_error_debug;
  END;
END DERIVE_FIN_TRANSLATE_VALUE;


-- +===================================================================+
-- | Name  : DERIVE_COST_CENTER                                        |
-- | Description      : This Procedure will derive the Oracle Cost     |
-- |                    center based on the translate                  |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Trans Date, Integral Department                |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Oracle Cost Center, error_message              |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE DERIVE_COST_CENTER(p_trans_date IN DATE,p_ps_department IN VARCHAR2)
IS

lc_error_message 	   VARCHAR2(2000);
lc_cc53a_error_message	   VARCHAR2(2000);
lc_target_value2           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value_comn       xx_fin_translatevalues.target_value2%TYPE ;
ld_trans_date		   DATE;
BEGIN

  ld_trans_date:=p_trans_date;

  gc_target_value13 :=NULL;

  -- Step 5.1 Derive oracle cost center by translate Integral Dept

  DERIVE_FIN_TRANSLATE_VALUE(
                             p_translation_name => 'GL_INT_EBS_COST_CTR'
                            ,p_source_value2    => SUBSTR(p_ps_department,2)
                            ,x_target_value1    => lc_target_value_comn
                            ,x_target_value2    => lc_target_value2
                            ,x_target_value3    => lc_target_value_comn
                            ,x_target_value4    => lc_target_value_comn
                            ,x_target_value5    => lc_target_value_comn
                            ,x_target_value6    => lc_target_value_comn
                            ,x_target_value7    => lc_target_value_comn
                            ,x_target_value8    => lc_target_value_comn
                            ,x_target_value9    => lc_target_value_comn
                            ,x_target_value10   => lc_target_value_comn
                            ,x_target_value11   => lc_target_value_comn
                            ,x_target_value12   => lc_target_value_comn
                            ,x_target_value13   => lc_target_value_comn
                            ,x_target_value14   => lc_target_value_comn
                            ,x_target_value15   => lc_target_value_comn
                            ,x_target_value16   => lc_target_value_comn
                            ,x_target_value17   => lc_target_value_comn
                            ,x_target_value18   => lc_target_value_comn
                            ,x_target_value19   => lc_target_value_comn
                            ,x_target_value20   => lc_target_value_comn
                            ,x_error_message    => lc_error_message
                            ,p_trx_date         => ld_trans_date
                            );

  IF (lc_error_message IS NOT NULL OR lc_target_value2 IS NULL) THEN

     gc_target_value13:='*INVALID';

     IF lc_target_value2 IS NULL THEN
        lc_cc53a_error_message:='Record '||gc_record_no||
	'- TRANSLATE/5.3.a - Oracle Cost Center is null in the translate GL_INT_EBS_COST_CTR '||
	'-  Department: '||p_ps_department;
     END IF;

     IF lc_error_message IS NOT NULL THEN
	lc_cc53a_error_message:='Record '||gc_record_no||
	'- TRANSLATE/5.3.a - Integral Department was not found in the translate GL_INT_EBS_COST_CTR'||
	'-  Department: '||p_ps_department;
     END IF;

     PROCESS_ERROR ( p_rowid       =>g_row_id
    	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
	     ,p_source_nm   =>gc_source_nm
	     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			      gc_intercompany||'.'||gc_lob||'.'||gc_future
             ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
	     ,p_details     =>lc_cc53a_error_message
	     ,p_group_id    =>gn_grp_id
		   );

     IF gc_debug_message = 'Y' THEN

        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
	FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while deriving Oracle CC for PS Dept :'||p_ps_department);
	FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
	FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

     END IF;

  END IF;

  IF lc_target_value2 IS NOT NULL THEN

     gc_target_value13 :='*VALID';
     gc_cost_center    :=lc_target_value2;

  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while when others DERIVE_COST_CENTER :'||SQLERRM);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END DERIVE_COST_CENTER;

-- +===================================================================+
-- | Name  :INSERT_ITGORA_STG                                          |
-- | Description      : This Procedure is used to insert records       |
-- |                    in the staging table xx_fin_itgora_stg         |
-- |                                                                   |
-- | Parameters :  p_request_id,p_ps_business_unit, p_ps_department,   |
-- |               p_ps_account,p_ps_operating_unit,p_ps_affilicate    |
-- |               p_reference24                                       |
-- |                                                                   |
-- | Returns :     x_error_message                                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE INSERT_ITGORA_STG (  p_source_nm		IN VARCHAR2
		           ,p_ps_business_unit 		IN VARCHAR2
                  	   ,p_ps_department    		IN VARCHAR2
	                   ,p_ps_account       		IN VARCHAR2
        	           ,p_ps_operating_unit		IN VARCHAR2
                	   ,p_ps_sales_channel 		IN VARCHAR2
	                   ,p_reference24 		IN VARCHAR2
			   ,x_error_message      	OUT  NOCOPY   VARCHAR2
  			 )
IS
BEGIN

  INSERT
    INTO XX_FIN_ITGORA_STG
  VALUES
	(  p_source_nm
	  ,p_ps_business_unit
	  ,p_ps_department
	  ,p_ps_account
	  ,p_ps_operating_unit
	  ,p_ps_sales_channel
	  ,p_reference24
	  ,gc_company
	  ,gc_cost_center
	  ,gc_account
	  ,gc_location
	  ,gc_lob
	  ,gc_sob
	  ,gc_location_type
	  ,gc_cost_center_type
	  ,gc_target_value9
	  ,gc_target_value10
	  ,gc_target_value11
	  ,gc_target_value12
	  ,gc_target_value13
	  ,gc_target_value14
	  ,gc_target_value15
	  ,gc_target_value16
	  ,gc_target_value17
	  ,gc_target_value18
	  ,gc_target_value19
	  ,sysdate
	  ,fnd_global.user_id
	  ,sysdate
	  ,fnd_global.user_id
	);
EXCEPTION
  WHEN others THEN
    x_error_message:='When others while inserting in the staging table xx_fin_psro_stg :'||sqlerrm;
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END INSERT_ITGORA_STG;


-- +===================================================================+
-- | Name  : DERIVE_COMPANY_LOC_TYPE                                   |
-- | Description      : This Procedure will derive the Oracle Company  |
-- |                    location type, cost center type, sob, lob      |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Trans Date                                     |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE DERIVE_COMPANY_LOC_TYPE(p_trans_date IN DATE)
IS

lc_error_message 		VARCHAR2(2000);
lc_lob_error_message		VARCHAR2(2000);
lc_sob_name			VARCHAR2(50);
ln_sob_id			NUMBER;
ld_trans_date  			DATE;
lc_target_value1           	xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value_comn       	xx_fin_translatevalues.target_value2%TYPE ;

BEGIN

  ld_trans_date  := p_trans_date;

  gc_target_value14	  := NULL;
  gc_target_value15	  := NULL;
  gc_target_value16	  := NULL;
  gc_target_value17	  := NULL;

  -- Step 6.1 Based on the oracle location, To get location type and company from OD_GL_GLOBAL_LOCATION

  IF gc_company IS NULL THEN

     BEGIN
       SELECT ffv.attribute1,
              ffv.attribute2
         INTO gc_company,
              gc_location_type
         FROM fnd_flex_values ffv,
              fnd_flex_value_sets vs
        WHERE vs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
          AND ffv.flex_value_set_id=vs.flex_value_set_id
          AND ffv.flex_value=gc_location
          AND ffv.enabled_flag='Y';
     EXCEPTION
       WHEN others THEN
        lc_error_message:='Record '||gc_record_no||
	' - VALUE SET/6.3a - Oracle Location (to derive Location Type and Company) was not  found in the '||
        'value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location: '|| gc_location;
        gc_target_value14:='#INVALID';

        PROCESS_ERROR ( p_rowid       =>g_row_id
	 	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
				gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_error_message
		     ,p_group_id    =>gn_grp_id
		   );

       IF gc_debug_message = 'Y' THEN

          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');
       END IF;

       RETURN;
     END;

     lc_error_message:=NULL;

     IF (gc_company IS NULL OR gc_location_type IS NULL) THEN

        IF gc_company IS NULL THEN

          lc_error_message:='Record '||gc_record_no||
			' - VALUE SET/6.3a - Oracle Location (to derive Location Type and Company), '||
			'NULL Company value in the value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location:'|| gc_location;

        END IF;

        IF gc_location_type IS NULL THEN
           lc_error_message:='Record '||gc_record_no||
			' - VALUE SET/6.3a - Oracle Location (to derive Location Type and Company), '||
		        'NULL Loc Type value in the value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location:'|| gc_location;
        END IF;

        IF (gc_location_type IS NULL AND gc_company IS NULL) THEN

           lc_error_message:='Record '||gc_record_no||
  	  ' - VALUE SET/6.3a - Oracle Location (to derive Location Type and Company), Company and Loc Type'||
	  'value NULL in the value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location:'|| gc_location;

        END IF;

        IF gc_debug_message = 'Y' THEN

           FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
           FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
           FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
           FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');
        END IF;

        PROCESS_ERROR ( p_rowid       =>g_row_id
	  	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value  =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
			gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_error_message
		     ,p_group_id    =>gn_grp_id
		   );
       gc_target_value14:='#INVALID';
       RETURN;

     END IF; --      IF (gc_company IS NULL OR gc_location_type IS NULL) THEN

  ELSE   --IF gc_company IS NULL THEN

     BEGIN
       SELECT ffv.attribute2
         INTO gc_location_type
         FROM fnd_flex_values ffv,
              fnd_flex_value_sets vs
        WHERE vs.flex_value_set_name='OD_GL_GLOBAL_LOCATION'
          AND ffv.flex_value_set_id=vs.flex_value_set_id
          AND ffv.flex_value=gc_location
          AND ffv.enabled_flag='Y';
     EXCEPTION
       WHEN others THEN
        lc_error_message:='Record '||gc_record_no||
	' - VALUE SET/6.3a - Oracle Location (to derive Location Type) was not  found in the '||
        'value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location: '|| gc_location;
        gc_target_value14:='#INVALID';

        PROCESS_ERROR ( p_rowid       =>g_row_id
	 	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
				gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_error_message
		     ,p_group_id    =>gn_grp_id
		   );

       IF gc_debug_message = 'Y' THEN

          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');
       END IF;

       RETURN;
     END;

     lc_error_message:=NULL;

     IF gc_location_type IS NULL THEN

        IF gc_location_type IS NULL THEN
           lc_error_message:='Record '||gc_record_no||
			' - VALUE SET/6.3a - Oracle Location (to derive Location Type), '||
		        'NULL Loc Type value in the value set  OD_GL_GLOBAL_LOCATION  -  Oracle Location:'|| gc_location;
        END IF;


        IF gc_debug_message = 'Y' THEN

           FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
           FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
           FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
           FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');
        END IF;

        PROCESS_ERROR ( p_rowid       =>g_row_id
	  	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value  =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
			gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_error_message
		     ,p_group_id    =>gn_grp_id
		   );
       gc_target_value14:='#INVALID';
       RETURN;

     END IF; --      IF gc_location_type IS NULL THEN

  END IF;  --  IF gc_company IS NULL THEN

  gc_target_value14:='#VALID';

  lc_error_message:=NULL;

  -- Step 7.1 Based on the Oracle company derived earlier, get the SOB from OD_GL_GLOBAL_COMPANY

  BEGIN
    SELECT ffv.attribute1
      INTO lc_sob_name
      FROM fnd_flex_values ffv,
           fnd_flex_value_sets vs
     WHERE vs.flex_value_set_name='OD_GL_GLOBAL_COMPANY'
       AND ffv.flex_value_set_id=vs.flex_value_set_id
       AND ffv.flex_value=gc_company
       AND ffv.enabled_flag='Y';

    IF lc_sob_name IS NULL THEN

       lc_error_message:='Record '||gc_record_no||
           '- VALUE SET/7.3a - Oracle Company (to derive SOB) , SOB value is NULL in the value set'||           'OD_GL_GLOBAL_COMPANY -  Oracle Company: '||gc_company;

       IF gc_debug_message = 'Y' THEN

          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
          FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
          FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

       END IF;
       gc_target_value15:='#INVALID';

       PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
		    ,p_group_id    =>gn_grp_id
		   );
      RETURN;
    END IF;


    BEGIN
	--Commented as part of R12 Retrofit Changes
      /*SELECT set_of_books_id
        INTO ln_sob_id
        FROM gl_sets_of_books
       WHERE short_name=lc_sob_name;	*/
	--Added as part of R12 Retrofit Changes
	   SELECT ledger_id
        INTO ln_sob_id
        FROM gl_ledgers
       WHERE short_name=lc_sob_name;
    EXCEPTION
      WHEN others THEN
        lc_error_message:='When others while sob id for the sob :'||lc_sob_name||sqlerrm;
    END;
  EXCEPTION
    WHEN others THEN
      lc_error_message:='Record '||gc_record_no||
	'- VALUE SET/7.3a - Oracle Company (to derive SOB) was not  found in the value set'||
        'OD_GL_GLOBAL_COMPANY -  Oracle Company: '||gc_company;
      PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
		    ,p_group_id    =>gn_grp_id
		   );
      IF gc_debug_message = 'Y' THEN

         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');
      END IF;
      gc_target_value15:='#INVALID';
      RETURN;
  END;

  gc_sob:=lc_sob_name;

  gc_target_value15:='#VALID';

  lc_error_message:=NULL;

  -- Step 8.1, Based on the Oracle Cost Center, get the Cost centry type from OD_GL_GLOBAL_COST_CENTER

  BEGIN
    SELECT ffv.attribute1
      INTO gc_cost_center_type
      FROM fnd_flex_values ffv,
           fnd_flex_value_sets vs
     WHERE vs.flex_value_set_name='OD_GL_GLOBAL_COST_CENTER'
       AND ffv.flex_value_set_id=vs.flex_value_set_id
       AND ffv.flex_value=gc_cost_center
       AND ffv.enabled_flag='Y';

    IF gc_cost_center_type IS NULL THEN

       gc_target_value16:='#INVALID';

       lc_error_message:='Record '||gc_record_no||
	  '- VALUE SET/8.3a - Oracle Cost Center (to derive Oracle Cost Center Type), cost center type '||
	  'is null in the value set OD_GL_GLOBAL_COST_CENTER  -  Oracle Cost Center:'||gc_cost_center;

      IF gc_debug_message = 'Y' THEN

        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

     END IF;
     PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
		    ,p_group_id    =>gn_grp_id
		   );
     RETURN;
    END IF;
  EXCEPTION
    WHEN others THEN

      gc_target_value16:='#INVALID';

      lc_error_message:='Record '||gc_record_no||
  	'- VALUE SET/8.3a - Oracle Cost Center (to derive Oracle Cost Center Type) was not '||
        'found in the value set OD_GL_GLOBAL_COST_CENTER  -  Oracle Cost Center:'||gc_cost_center;

      IF gc_debug_message = 'Y' THEN

        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

     END IF;
     PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
		    ,p_group_id    =>gn_grp_id
		   );
     RETURN;
  END;

  gc_target_value16:='#VALID';

  lc_error_message:=NULL;

  -- Step 9.1, Based on oracle cc type and location type, get the LOB from translation GL_COSTCTR_LOC_TO_LOB

  DERIVE_FIN_TRANSLATE_VALUE(
                                   p_translation_name => 'GL_COSTCTR_LOC_TO_LOB'
                                  ,p_source_value1    => gc_cost_center_type
                                  ,p_source_value2    => gc_location_type
                                  ,x_target_value1    => lc_target_value1
                                  ,x_target_value2    => lc_target_value_comn
                                  ,x_target_value3    => lc_target_value_comn
                                  ,x_target_value4    => lc_target_value_comn
                                  ,x_target_value5    => lc_target_value_comn
                                  ,x_target_value6    => lc_target_value_comn
                                  ,x_target_value7    => lc_target_value_comn
                                  ,x_target_value8    => lc_target_value_comn
                                  ,x_target_value9    => lc_target_value_comn
                                  ,x_target_value10   => lc_target_value_comn
                                  ,x_target_value11   => lc_target_value_comn
                                  ,x_target_value12   => lc_target_value_comn
                                  ,x_target_value13   => lc_target_value_comn
                                  ,x_target_value14   => lc_target_value_comn
                                  ,x_target_value15   => lc_target_value_comn
                                  ,x_target_value16   => lc_target_value_comn
                                  ,x_target_value17   => lc_target_value_comn
                                  ,x_target_value18   => lc_target_value_comn
                                  ,x_target_value19   => lc_target_value_comn
                                  ,x_target_value20   => lc_target_value_comn
                                  ,x_error_message    => lc_error_message
                                 ,p_trx_date         => ld_trans_date
                                 );

  IF (lc_error_message IS NOT NULL OR lc_target_value1 IS NULL) THEN

     gc_target_value17:='*INVALID';


     IF lc_target_value1 IS NULL THEN

       lc_lob_error_message:='Record '||gc_record_no||
	'- TRANSLATE/9.3a - Oracle Location Type and Cost Center Type (to derive LOB), LOB is null '||
	'in the translate GL_COSTCTR_LOC_TO_LOB  -  Oracle Loc Type: '||gc_location_type||
        ', Oracle Cost Center Type: '||gc_cost_center_type;
     END IF;

     IF lc_error_message IS NOT NULL THEN

       lc_lob_error_message:='Record '||gc_record_no||
	'- TRANSLATE/9.3a - Oracle Location Type and Cost Center Type (to derive LOB) was not found '||
	'in the translate GL_COSTCTR_LOC_TO_LOB  -  Oracle Loc Type: '|| gc_location_type||
	', Oracle Cost Center Type: '||gc_cost_center_type;
     END IF;


     IF gc_debug_message = 'Y' THEN

        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,lc_lob_error_message);
        FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
        FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

     END IF;

     PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_lob_error_message
		    ,p_group_id    =>gn_grp_id
		   );

     RETURN;
  END IF;

  IF lc_target_value1 IS NOT NULL THEN
     gc_lob:=lc_target_value1;
     gc_target_value17:='*VALID';

  END IF;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while when others DERIVE_BY_COMPANY_LOC_TYPE :'||SQLERRM);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END DERIVE_COMPANY_LOC_TYPE;


-- +===================================================================+
-- | Name  : DERIVE_LOCATION                                           |
-- | Description      : This Procedure will derive the Oracle Location |
-- |                    cost center type                               |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Integral Location, Department, Trans Date      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE DERIVE_LOCATION( p_ps_operating_unit IN VARCHAR2
	        ,p_ps_department     IN VARCHAR2
		,p_trans_date	     IN DATE)
IS

lc_error_message 	   VARCHAR2(2000);
lc_oraloc431_error_msg     VARCHAR2(2000);

lc_ora_loc431		   xx_fin_translatevalues.target_value2%TYPE ;
lc_target_value_comn       xx_fin_translatevalues.target_value2%TYPE ;
ld_trans_date   	   DATE;

BEGIN

  ld_trans_date :=p_trans_date;

  -- Step 4.3.1, Derive Oracle Location based on Integral Location by translate

  DERIVE_FIN_TRANSLATE_VALUE(
                                   p_translation_name => 'GL_INT_EBS_LOC_CC'
                                  ,p_source_value4    => p_ps_operating_unit
                                  ,x_target_value1    => lc_target_value_comn
                                  ,x_target_value2    => lc_target_value_comn
                                  ,x_target_value3    => lc_target_value_comn
                                  ,x_target_value4    => lc_ora_loc431
                                  ,x_target_value5    => lc_target_value_comn
                                  ,x_target_value6    => lc_target_value_comn
                                  ,x_target_value7    => lc_target_value_comn
                                  ,x_target_value8    => lc_target_value_comn
                                  ,x_target_value9    => lc_target_value_comn
                                  ,x_target_value10   => lc_target_value_comn
                                  ,x_target_value11   => lc_target_value_comn
                                  ,x_target_value12   => lc_target_value_comn
                                  ,x_target_value13   => lc_target_value_comn
                                  ,x_target_value14   => lc_target_value_comn
                                  ,x_target_value15   => lc_target_value_comn
                                  ,x_target_value16   => lc_target_value_comn
                                  ,x_target_value17   => lc_target_value_comn
                                  ,x_target_value18   => lc_target_value_comn
                                  ,x_target_value19   => lc_target_value_comn
                                  ,x_target_value20   => lc_target_value_comn
                                  ,x_error_message    => lc_error_message
                                  ,p_trx_date         => ld_trans_date
                                 );

  IF lc_ora_loc431 IS NOT NULL THEN

     gc_target_value12 :='*VALID';
     gc_location       :=lc_ora_loc431;

     IF gc_cost_center IS NULL THEN
        DERIVE_COST_CENTER(p_trans_date,p_ps_department);
     END IF;

     DERIVE_COMPANY_LOC_TYPE(p_trans_date);


  END IF;

  IF (lc_error_message IS NOT NULL OR lc_ora_loc431 IS NULL) THEN

      gc_target_value12:='*INVALID';

      IF lc_ora_loc431 IS NULL THEN
            lc_oraloc431_error_msg:='Record '||gc_record_no||
	    '- TRANSLATE/4.3.3.a - Oracle Location value IS NULL in the translate '||
	    'GL_INT_EBS_LOC_CC  - Location: '||p_ps_operating_unit;
      END IF;

      IF lc_error_message IS NOT NULL THEN
            lc_oraloc431_error_msg:='Record '||gc_record_no||
	    '- TRANSLATE/4.3.3.a - Integral Location was not found in the translate '||
            'GL_INT_EBS_LOC_CC  - Location: '||p_ps_operating_unit;
      END IF;

      PROCESS_ERROR ( p_rowid       =>g_row_id
	 	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_oraloc431_error_msg
		     ,p_group_id    =>gn_grp_id
		   );

      IF gc_debug_message = 'Y' THEN

         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_oraloc431_error_msg);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

      END IF;

      gc_target_value16:=NULL;
      lc_error_message :=NULL;

      IF gc_cost_center IS NULL THEN
         DERIVE_COST_CENTER(p_trans_date,p_ps_department);
      END IF;

      -- Translate Step 8.1 to get the cost center type  based on oracle cc

      IF gc_cost_center IS NOT NULL THEN

         BEGIN
           SELECT ffv.attribute1
             INTO gc_cost_center_type
             FROM fnd_flex_values ffv,
                  fnd_flex_value_sets vs
            WHERE vs.flex_value_set_name='OD_GL_GLOBAL_COST_CENTER'
              AND ffv.flex_value_set_id=vs.flex_value_set_id
              AND ffv.flex_value=gc_cost_center
	      AND ffv.enabled_flag='Y';

           IF gc_cost_center_type IS NULL THEN

    	      gc_target_value16:='#INVALID';
              lc_error_message:='Record '||gc_record_no||
		'- VALUE SET/8.3a - Oracle Cost Center (to derive Oracle Cost Center Type), cost center type '||
	        'is null in the value set OD_GL_GLOBAL_COST_CENTER  -  Oracle Cost Center:'||gc_cost_center;

              IF gc_debug_message = 'Y' THEN

                FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
                FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
                FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
                FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

              END IF;
              PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
   		    ,p_group_id    =>gn_grp_id
		   );

           ELSE
             gc_target_value16:='#VALID';
           END IF;
         EXCEPTION
           WHEN others THEN
             lc_error_message:='Record '||gc_record_no||
		'- VALUE SET/8.3a - Oracle Cost Center (to derive Oracle Cost Center Type) was not '||
		'found in the value set OD_GL_GLOBAL_COST_CENTER  -  Oracle Cost Center:'||gc_cost_center;

  	     gc_target_value16:='#INVALID';
             IF gc_debug_message = 'Y' THEN

               FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
               FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
               FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
               FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

             END IF;
             PROCESS_ERROR ( p_rowid       =>g_row_id
		    ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		    ,p_source_nm   =>gc_source_nm
		    ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		    ,p_value      =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		    ,p_details     =>lc_error_message
		    ,p_group_id    =>gn_grp_id
		   );
         END;
      END IF;  --IF gc_cost_center IS NOT NULL THEN

  END IF;   --IF (lc_error_message IS NOT NULL OR lc_ora_loc431 IS NULL) THEN
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while when others DERIVE_LOCATION :'||SQLERRM);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END DERIVE_LOCATION;


-- +===================================================================+
-- | Name  : DERIVE_BY_PSDEPTACCT                                      |
-- | Description      : This Procedure will derive the oracle segments |
-- |                    by Integral Department, Account, Location      |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :       Integral Department, Account, Location,        |
-- |                    Trans_date                                     |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


PROCEDURE DERIVE_BY_PSDEPTACCT(p_ps_department     IN VARCHAR2,
		               p_ps_account        IN VARCHAR2,
			       p_ps_operating_unit IN VARCHAR2,
			       p_trans_date	   IN DATE)
IS

lc_error_message 	   VARCHAR2(2000);
lc_acct_error_message	   VARCHAR2(2000);

lc_ora_dept31		   xx_fin_translatevalues.target_value2%TYPE ;
lc_ora_acct31		   xx_fin_translatevalues.target_value2%TYPE ;
lc_oracle_acct		   xx_fin_translatevalues.target_value2%TYPE ;
lc_oracle_cc		   xx_fin_translatevalues.target_value2%TYPE ;
lc_oracle_location	   xx_fin_translatevalues.target_value2%TYPE ;
lc_target_value_comn       xx_fin_translatevalues.target_value2%TYPE ;

ld_trans_date  DATE;


BEGIN

  ld_trans_date  := p_trans_date;
  gc_target_value11 :=NULL;

  -- Translate  Step 3.1, Derive Oracle CC and Acct based on Integral Dept,Acct

  DERIVE_FIN_TRANSLATE_VALUE(
                                   p_translation_name => 'GL_INT_EBS_ACCT_CC'
                                  ,p_source_value2    => SUBSTR(p_ps_department,2)
                                  ,p_source_value3    => SUBSTR(p_ps_account,1,7)
                                  ,x_target_value1    => lc_target_value_comn
                                  ,x_target_value2    => lc_ora_dept31
                                  ,x_target_value3    => lc_ora_acct31
                                  ,x_target_value4    => lc_target_value_comn
                                  ,x_target_value5    => lc_target_value_comn
                                  ,x_target_value6    => lc_target_value_comn
                                  ,x_target_value7    => lc_target_value_comn
                                  ,x_target_value8    => lc_target_value_comn
                                  ,x_target_value9    => lc_target_value_comn
                                  ,x_target_value10   => lc_target_value_comn
                                  ,x_target_value11   => lc_target_value_comn
                                  ,x_target_value12   => lc_target_value_comn
                                  ,x_target_value13   => lc_target_value_comn
                                  ,x_target_value14   => lc_target_value_comn
                                  ,x_target_value15   => lc_target_value_comn
                                  ,x_target_value16   => lc_target_value_comn
                                  ,x_target_value17   => lc_target_value_comn
                                  ,x_target_value18   => lc_target_value_comn
                                  ,x_target_value19   => lc_target_value_comn
                                  ,x_target_value20   => lc_target_value_comn
                                  ,x_error_message    => lc_error_message
                                  ,p_trx_date         => ld_trans_date
                                 );

  IF (lc_ora_dept31 IS NOT NULL AND lc_ora_acct31 IS NOT NULL) THEN

      gc_cost_center		:=lc_ora_dept31;
      gc_account    		:=lc_ora_acct31;
      gc_target_value11		:='*VALID';


      gc_target_value12 :=NULL;
      lc_error_message 	:=NULL;

      -- Translate Step 4.3.1 to get the location by translate GL_INT_EBS_LOC_CC

      DERIVE_LOCATION( p_ps_operating_unit,p_ps_department,p_trans_date);


  END IF;  -- (lc_ora_dept31 IS NOT NULL AND lc_ora_acct31 IS NOT NULL) THEN

  IF (lc_ora_dept31 IS NULL OR lc_ora_acct31 IS NULL) THEN

     gc_target_value11 :=NULL;

     -- Translate Account By  Step 3.3.1

     DERIVE_FIN_TRANSLATE_VALUE(
                                   p_translation_name => 'GL_INT_EBS_ACCT_CC'
                                  ,p_source_value3    => SUBSTR(p_ps_account,1,7)
                                  ,x_target_value1    => lc_target_value_comn
                                  ,x_target_value2    => lc_target_value_comn
                                  ,x_target_value3    => lc_oracle_acct
                                  ,x_target_value4    => lc_target_value_comn
                                  ,x_target_value5    => lc_target_value_comn
                                  ,x_target_value6    => lc_target_value_comn
                                  ,x_target_value7    => lc_target_value_comn
                                  ,x_target_value8    => lc_target_value_comn
                                  ,x_target_value9    => lc_target_value_comn
                                  ,x_target_value10   => lc_target_value_comn
                                  ,x_target_value11   => lc_target_value_comn
                                  ,x_target_value12   => lc_target_value_comn
                                  ,x_target_value13   => lc_target_value_comn
                                  ,x_target_value14   => lc_target_value_comn
                                  ,x_target_value15   => lc_target_value_comn
                                  ,x_target_value16   => lc_target_value_comn
                                  ,x_target_value17   => lc_target_value_comn
                                  ,x_target_value18   => lc_target_value_comn
                                  ,x_target_value19   => lc_target_value_comn
                                  ,x_target_value20   => lc_target_value_comn
                                  ,x_error_message    => lc_error_message
                                  ,p_trx_date         => ld_trans_date
                                 );

     IF (lc_error_message IS NOT NULL OR lc_oracle_acct IS NULL) THEN

         gc_target_value11:='*INVALID';

	 IF lc_oracle_acct IS NULL THEN
	    lc_acct_error_message:='Record '||gc_record_no||
			'- TRANSLATE - Integral Account is null in the translate GL_INT_EBS_ACCT_CC '||
		        '- Account :'||p_ps_account;
	 END IF;


	 IF lc_error_message IS NOT NULL THEN
	    lc_acct_error_message:='Record '||gc_record_no||
			'- TRANSLATE - Integral Account was not found in the translate GL_INT_EBS_ACCT_CC '||
		        '- Account :'||p_ps_account;

	 END IF;

         PROCESS_ERROR ( p_rowid       =>g_row_id
	 	     ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		     ,p_source_nm   =>gc_source_nm
		     ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		     ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob
		     ,p_details     =>lc_acct_error_message
		     ,p_group_id    =>gn_grp_id
		   );


         IF gc_debug_message = 'Y' THEN

            FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while deriving Oracle Acct for PS Acct :'||p_ps_account);
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_acct_error_message);
            FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
            FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

         END IF;

         -- continue step 4.1 for remaining mappings

     END IF;

     IF lc_oracle_acct IS NOT NULL THEN

        gc_target_value11 :='*VALID';
        gc_account        :=lc_oracle_acct;

        -- Proceed to Step 4.1 further to get gc_cost_center, gc_location
     END IF;


     gc_target_value12:=NULL;
     lc_error_message :=NULL;

     -- Translate by Dept and Loc (Step 4.1)  -- to be

     DERIVE_FIN_TRANSLATE_VALUE(
                                   p_translation_name => 'GL_INT_EBS_LOC_CC'
                                  ,p_source_value2    => SUBSTR(p_ps_department,2)
                                  ,p_source_value4    => p_ps_operating_unit
                                  ,x_target_value1    => lc_target_value_comn
                                  ,x_target_value2    => lc_oracle_cc
                                  ,x_target_value3    => lc_target_value_comn
                                  ,x_target_value4    => lc_oracle_location
                                  ,x_target_value5    => lc_target_value_comn
                                  ,x_target_value6    => lc_target_value_comn
                                  ,x_target_value7    => lc_target_value_comn
                                  ,x_target_value8    => lc_target_value_comn
                                  ,x_target_value9    => lc_target_value_comn
                                  ,x_target_value10   => lc_target_value_comn
                                  ,x_target_value11   => lc_target_value_comn
                                  ,x_target_value12   => lc_target_value_comn
                                  ,x_target_value13   => lc_target_value_comn
                                  ,x_target_value14   => lc_target_value_comn
                                  ,x_target_value15   => lc_target_value_comn
                                  ,x_target_value16   => lc_target_value_comn
                                  ,x_target_value17   => lc_target_value_comn
                                  ,x_target_value18   => lc_target_value_comn
                                  ,x_target_value19   => lc_target_value_comn
                                  ,x_target_value20   => lc_target_value_comn
                                  ,x_error_message    => lc_error_message
                                  ,p_trx_date         => ld_trans_date
                                 );

     IF     lc_oracle_cc       IS NOT NULL
        AND lc_oracle_location IS NOT NULL THEN

        gc_target_value12 :='*VALID';
        gc_cost_center    :=lc_oracle_cc;
        gc_location       :=lc_oracle_location;

         -- Translate by Step 6
        DERIVE_COMPANY_LOC_TYPE(p_trans_date);

     END IF;

     IF (lc_oracle_cc IS NULL OR lc_oracle_location IS NULL) THEN

        -- Translate by (Step 4.3.1)

        DERIVE_LOCATION( p_ps_operating_unit,p_ps_department,p_trans_date);

     END IF;	-- (lc_oracle_cc IS NULL OR lc_oracle_location IS NULL) THEN

  END IF;  -- lc_ora_dept31/acct31  is null
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Error while when others DERIVE_BY_PSDEPTACCT:'||SQLERRM);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
END DERIVE_BY_PSDEPTACCT;

-- +===================================================================================+
-- | Name        : TRANSLATE_PS_VALUES                                                 |
-- |                                                                                   |
-- | Description : To convert the Integral accounts into Oracle account segments       |
-- |                                                                                   |
-- | Parameters  : p_record_no                                                         |
-- |               ,p_ps_business_unit                                                 |
-- |               ,p_ps_department                                                    |
-- |               ,p_ps_account                                                       |
-- |               ,p_ps_operating_unit                                                |
-- |               ,p_ps_affiliate                                                     |
-- |               ,p_ps_sales_channel                                                 |
-- |               ,p_use_stored_combinations                                          |
-- |               ,p_convert_gl_history                                               |
-- |               ,p_reference24                                                      |
-- |               ,p_org_id                                                           |
-- |               ,p_trans_date  added per P.Marco(Defect 2598)                       |
-- |                                                                                   |
-- | Returns     :  x_seg1_company                                                     |
-- |               ,x_seg2_costctr                                                     |
-- |               ,x_seg3_account                                                     |
-- |               ,x_seg4_location                                                    |
-- |               ,x_seg5_interco                                                     |
-- |               ,x_seg6_lob                                                         |
-- |               ,x_seg7_future                                                      |
-- |               ,x_ccid                                                             |
-- |               ,x_error_message                                                    |
-- +===================================================================================+


PROCEDURE TRANSLATE_PS_VALUES(
			       p_record_no		  IN   VARCHAR2
	                      ,p_ps_business_unit         IN   VARCHAR2
                              ,p_ps_department            IN   VARCHAR2
                              ,p_ps_account               IN   VARCHAR2
                              ,p_ps_operating_unit        IN   VARCHAR2
                              ,p_ps_affiliate             IN   VARCHAR2
                              ,p_ps_sales_channel         IN   VARCHAR2
                              ,p_use_stored_combinations  IN   VARCHAR2 DEFAULT 'NO'
                              ,p_convert_gl_history       IN   VARCHAR2
    	      	              ,p_reference24		   IN   VARCHAR2
                              ,x_seg1_company             OUT  NOCOPY   VARCHAR2
                              ,x_seg2_costctr             OUT  NOCOPY   VARCHAR2
                              ,x_seg3_account             OUT  NOCOPY   VARCHAR2
                              ,x_seg4_location            OUT  NOCOPY   VARCHAR2
                              ,x_seg5_interco             OUT  NOCOPY   VARCHAR2
                              ,x_seg6_lob                 OUT  NOCOPY   VARCHAR2
                              ,x_seg7_future              OUT  NOCOPY   VARCHAR2
                              ,x_ccid                     OUT  NOCOPY   VARCHAR2
                              ,x_error_message            OUT  NOCOPY   VARCHAR2
                              ,p_org_id                   IN   NUMBER   DEFAULT  NULL
                              ,p_trans_date               IN   DATE     DEFAULT  SYSDATE
                             )
IS

lc_error_message           VARCHAR2(2000);
lc_error_loc               VARCHAR2(2000);
lc_error_debug             VARCHAR2(2000);
lc_derived_company         VARCHAR2(30);
lc_ps_segments		   VARCHAR2(150);
lc_ora_segments		   VARCHAR2(150);
lc_ccid_error_message	   VARCHAR2(2000);
lc_itgora_error_message	   VARCHAR2(2000);
lc_target_value1           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value2           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value3           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value4           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value5           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value6           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value7           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value8           xx_fin_translatevalues.target_value1%TYPE ;
lc_target_value9           xx_fin_translatevalues.target_value1%TYPE ;


lc_target_value_comn       xx_fin_translatevalues.target_value2%TYPE ;
ld_trans_date              DATE;
lc_sob_name		   VARCHAR2(50);
ln_sob_id		   NUMBER;
BEGIN

  ld_trans_date  := p_trans_date;

  gc_sr_business_unit	  :=NULL;
  gc_sr_department	  :=NULL;
  gc_sr_account		  :=NULL;
  gc_sr_operating_unit	  :=NULL;
  gc_sr_lob		  :=NULL;

  gc_company              := NULL;
  gc_cost_center          := NULL;
  gc_cost_center_type     := NULL;
  gc_cost_center_sub_type := NULL;
  gc_account              := NULL;
  gc_location             := NULL;
  gc_location_type        := NULL;
  gc_lob                  := NULL;
  gc_sob		  := NULL;
  gc_ccid                 := NULL;
  gc_ccid_enabled	  := NULL;
  gc_error_msg	  	  := NULL;
  gc_target_value9	  := NULL;
  gc_target_value11	  := NULL;
  gc_target_value12	  := NULL;
  gc_target_value13	  := NULL;
  gc_target_value14	  := NULL;
  gc_target_value15	  := NULL;
  gc_target_value16	  := NULL;
  gc_target_value17	  := NULL;
  gc_target_value18	  := NULL;
  gc_target_value19	  := NULL;
  gc_target_value10	:='*INVALID';




  IF gc_debug_message = 'Y' THEN

     FND_FILE.PUT_LINE (FND_FILE.LOG,'********************* Given Parameters *********************');
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Business_unit        : ' || p_ps_business_unit);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Department           : ' || p_ps_department);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Account              : ' || p_ps_account);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Operating_unit       : ' || p_ps_operating_unit);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Affiliate            : ' || p_ps_affiliate);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Integral Sales_channel        : ' || p_ps_sales_channel);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Use Translation Yes/No          : ' || p_use_stored_combinations);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Convert GL History Yes/No       : ' || p_convert_gl_history);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Org id                          : ' || p_org_id);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Transaction Date                : ' || p_trans_date );
     FND_FILE.PUT_LINE (FND_FILE.LOG,'************************************************************');
     FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                            ');
  END IF;

  gc_sr_business_unit	  :=p_ps_business_unit;
  gc_sr_department	  :=p_ps_department;
  gc_sr_account		  :=p_ps_account;
  gc_sr_operating_unit	  :=p_ps_operating_unit;
  gc_sr_lob		  :=p_ps_sales_channel;

  -- Step 1.2

  IF     p_ps_department        IS NULL
      OR p_ps_account           IS NULL
      OR p_ps_operating_unit    IS NULL THEN

	 lc_error_message:='Record '||gc_record_no||
			   ' - VALIDATION/1.2.a - One or more Integral required values are missing (null):   Department: '||
			    p_ps_department|| ', Account: '||p_ps_account|| ', Location: '||p_ps_operating_unit;



      IF gc_debug_message = 'Y' THEN

         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,lc_error_message);
         FND_FILE.PUT_LINE (FND_FILE.LOG,'********************************************************');
         FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                        ');

      END IF;

      PROCESS_ERROR(p_rowid       =>g_row_id
		   ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		   ,p_source_nm   =>gc_source_nm
		   ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		   ,p_value     =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
				gc_sr_operating_unit||'.'||gc_sr_lob
		   ,p_details   =>lc_error_message
		   ,p_group_id    =>gn_grp_id
		   );

      gc_target_value9	:='~INVALID';
      x_error_message   :='INVALID';
      RETURN;
  END IF;

  -- Step 2.2

  lc_error_message:=NULL;

  IF     p_ps_business_unit 	IS NOT NULL
     AND p_ps_department    	IS NOT NULL
     AND p_ps_account 		IS NOT NULL
     AND p_ps_operating_unit 	IS NOT NULL
     AND p_ps_sales_channel 	IS NOT NULL THEN

     DERIVE_FIN_TRANSLATE_VALUE(
                                p_translation_name => 'GL_INT_EBS_CC_ACCT_LOC'
                               ,p_source_value1    => p_ps_business_unit
                               ,p_source_value2    => SUBSTR(p_ps_department,2)
                               ,p_source_value3    => SUBSTR(p_ps_account,1,7)
                               ,p_source_value4    => p_ps_operating_unit
                               ,p_source_value5    => p_ps_sales_channel
                               ,x_target_value1    => lc_target_value1
                               ,x_target_value2    => lc_target_value2
                               ,x_target_value3    => lc_target_value3
                               ,x_target_value4    => lc_target_value4
                               ,x_target_value5    => lc_target_value5
                               ,x_target_value6    => lc_target_value6
                               ,x_target_value7    => lc_target_value7
                               ,x_target_value8    => lc_target_value8
                               ,x_target_value9    => lc_target_value9
                               ,x_target_value10   => lc_target_value_comn
                               ,x_target_value11   => lc_target_value_comn
                               ,x_target_value12   => lc_target_value_comn
                               ,x_target_value13   => lc_target_value_comn
                               ,x_target_value14   => lc_target_value_comn
                               ,x_target_value15   => lc_target_value_comn
                               ,x_target_value16   => lc_target_value_comn
                               ,x_target_value17   => lc_target_value_comn
                               ,x_target_value18   => lc_target_value_comn
                               ,x_target_value19   => lc_target_value_comn
                               ,x_target_value20   => lc_target_value_comn
                               ,x_error_message    => lc_error_message
                               ,p_trx_date         => ld_trans_date
                              );


     IF     lc_target_value1 IS NOT NULL
        AND lc_target_value2 IS NOT NULL
        AND lc_target_value3 IS NOT NULL
        AND lc_target_value4 IS NOT NULL
        AND lc_target_value5 IS NOT NULL  THEN

	gc_company	        :=lc_target_value1;
        gc_cost_center		:=lc_target_value2;
        gc_account    		:=lc_target_value3;
        gc_location   		:=lc_target_value4;
        gc_lob   		:=lc_target_value5;
	gc_target_value10	:='*VALID';

     ELSE

	gc_target_value10	:='*INVALID';

        lc_error_message:=NULL;

        -- Step 2.4

        DERIVE_FIN_TRANSLATE_VALUE(
                                p_translation_name => 'GL_INT_EBS_CC_ACCT_LOC'
                               ,p_source_value1    => p_ps_business_unit
                               ,p_source_value2    => SUBSTR(p_ps_department,2)
                               ,p_source_value3    => SUBSTR(p_ps_account,1,7)
                               ,p_source_value4    => p_ps_operating_unit
                               ,x_target_value1    => lc_target_value1
                               ,x_target_value2    => lc_target_value2
                               ,x_target_value3    => lc_target_value3
                               ,x_target_value4    => lc_target_value4
                               ,x_target_value5    => lc_target_value5
                               ,x_target_value6    => lc_target_value6
                               ,x_target_value7    => lc_target_value7
                               ,x_target_value8    => lc_target_value8
                               ,x_target_value9    => lc_target_value9
                               ,x_target_value10   => lc_target_value_comn
                               ,x_target_value11   => lc_target_value_comn
                               ,x_target_value12   => lc_target_value_comn
                               ,x_target_value13   => lc_target_value_comn
                               ,x_target_value14   => lc_target_value_comn
                               ,x_target_value15   => lc_target_value_comn
                               ,x_target_value16   => lc_target_value_comn
                               ,x_target_value17   => lc_target_value_comn
                               ,x_target_value18   => lc_target_value_comn
                               ,x_target_value19   => lc_target_value_comn
                               ,x_target_value20   => lc_target_value_comn
                               ,x_error_message    => lc_error_message
                               ,p_trx_date         => ld_trans_date
                              );

        IF     lc_target_value1 IS NOT NULL
           AND lc_target_value2 IS NOT NULL
           AND lc_target_value3 IS NOT NULL
           AND lc_target_value4 IS NOT NULL  THEN

       	   gc_company	        :=lc_target_value1;
           gc_cost_center	:=lc_target_value2;
           gc_account    	:=lc_target_value3;
           gc_location   	:=lc_target_value4;
	   gc_target_value10	:='*VALID';

           DERIVE_COMPANY_LOC_TYPE(p_trans_date);

	ELSE

   	   gc_target_value10	:='*INVALID';

	END IF;

     END IF;		--END IF of lc_target_value1/2/3/4/5 IS NOT NULL

  END IF ;  --IF     p_ps_business_unit 	IS NOT NULL


  IF  gc_target_value10 ='*INVALID' THEN

     IF      p_ps_department IS NOT NULL
         AND p_ps_account IS NOT NULL
         AND p_ps_operating_unit IS NOT NULL THEN

         -- Step 2.7

         DERIVE_FIN_TRANSLATE_VALUE(
                                p_translation_name => 'GL_INT_EBS_CC_ACCT_LOC'
                               ,p_source_value2    => SUBSTR(p_ps_department,2)
                               ,p_source_value3    => SUBSTR(p_ps_account,1,7)
                               ,p_source_value4    => p_ps_operating_unit
                               ,x_target_value1    => lc_target_value1
                               ,x_target_value2    => lc_target_value2
                               ,x_target_value3    => lc_target_value3
                               ,x_target_value4    => lc_target_value4
                               ,x_target_value5    => lc_target_value5
                               ,x_target_value6    => lc_target_value6
                               ,x_target_value7    => lc_target_value7
                               ,x_target_value8    => lc_target_value8
                               ,x_target_value9    => lc_target_value9
                               ,x_target_value10   => lc_target_value_comn
                               ,x_target_value11   => lc_target_value_comn
                               ,x_target_value12   => lc_target_value_comn
                               ,x_target_value13   => lc_target_value_comn
                               ,x_target_value14   => lc_target_value_comn
                               ,x_target_value15   => lc_target_value_comn
                               ,x_target_value16   => lc_target_value_comn
                               ,x_target_value17   => lc_target_value_comn
                               ,x_target_value18   => lc_target_value_comn
                               ,x_target_value19   => lc_target_value_comn
                               ,x_target_value20   => lc_target_value_comn
                               ,x_error_message    => lc_error_message
                               ,p_trx_date         => ld_trans_date
                              );


         lc_error_message:=NULL;

         IF     lc_target_value2 IS NOT NULL
            AND lc_target_value3 IS NOT NULL
            AND lc_target_value4 IS NOT NULL  THEN

            gc_cost_center		:=lc_target_value2;
            gc_account    		:=lc_target_value3;
            gc_location   		:=lc_target_value4;
      	    gc_target_value10	:='*VALID';


  	    -- Step 2.2.b to get the COmpany, LOB and SOB

            DERIVE_COMPANY_LOC_TYPE(p_trans_date);

         END IF;   --     lc_target_value2/value3/value4 IS NOT NULL

         lc_error_message:=NULL;

         -- Derive by PS Department and PS Account

         IF    lc_target_value2 IS NULL
            OR lc_target_value3 IS NULL
            OR lc_target_value4 IS NULL  THEN

   	    gc_target_value10	:='*INVALID';

            DERIVE_BY_PSDEPTACCT(p_ps_department,p_ps_account,p_ps_operating_unit,p_trans_date);


 	    --IF     gc_cost_center IS NOT NULL
  	    --   AND gc_location IS NOT NULL  THEN

            --   DERIVE_COMPANY_LOC_TYPE(p_trans_date);

  	    --END IF;

         END IF;

     END IF;     --     p_ps_department IS NOT NULL

  END IF ;  --END IF of gc_target_value10	:='*INVALID';

  DERIVE_CCID( gc_company
	      ,gc_cost_center
	      ,gc_account
	      ,gc_location
	      ,gc_intercompany
	      ,gc_lob
	      ,gc_future
	      ,gc_ccid
	      ,lc_error_message
	     );

  lc_ps_segments :=gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||gc_sr_operating_unit||'.'||gc_sr_lob;
  lc_ora_segments:=gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future;

  IF gc_ccid IS NULL THEN
     gc_target_value19	:='$INVALID';
     lc_ccid_error_message:='Record '||gc_record_no||
	   '- TABLE - Oracle Code Combination ID was not found in the GL_CODE_COMBINATIONS table for Oracle COA: '||  	    	           lc_ora_segments||' Integral COA: '||lc_ps_segments;
     PROCESS_ERROR(p_rowid       =>g_row_id
		   ,p_fnd_message =>'XX_GL_TRANS_VALUE_ERROR'
		   ,p_source_nm   =>gc_source_nm
		   ,p_type        =>gc_company||'.'||gc_cost_center||'.'||gc_account||'.'||gc_location||'.'||
			gc_intercompany||'.'||gc_lob||'.'||gc_future
 		   ,p_value  =>gc_sr_business_unit||'.'||gc_sr_department||'.'||gc_sr_account||'.'||
				gc_sr_operating_unit||'.'||gc_sr_lob
		   ,p_details   =>SUBSTR(lc_ccid_error_message||lc_error_message,1,2999)
		   ,p_group_id    =>gn_grp_id
		   );
  ELSE

    gc_target_value19	:='$VALID';
    gc_target_value18   :=gc_ccid;

    IF gc_ccid_enabled='N' THEN
       gc_target_value19 :='$INVALID';
    END IF;

  END IF;


  -- Assigning the Derived values to the out parameters

  x_seg1_company  := gc_company;
  x_seg2_costctr  := gc_cost_center;
  x_seg3_account  := gc_account;
  x_seg4_location := gc_location;
  x_seg5_interco  := gc_intercompany;
  x_seg6_lob      := gc_lob;
  x_seg7_future   := gc_future;
  x_ccid          := gc_ccid;


  IF (    gc_company IS NULL
       OR gc_cost_center IS NULL
       OR gc_account IS NULL
       OR gc_location IS NULL
       OR gc_lob IS NULL
       OR gc_ccid IS NULL
     ) THEN

     x_error_message := 'INVALID';
     gc_target_value9:='~INVALID';

  END IF;

  IF gc_ccid IS NOT NULL THEN
     gc_target_value9:='~VALID';

    IF gc_ccid_enabled='N' THEN
       gc_target_value9 :='~INVALID';
--- Below logic is added for V1.8     
       x_error_message := 'INVALID';
--- End for V1.8 
    END IF;

  END IF;

  IF gc_debug_message = 'Y' THEN

     FND_FILE.PUT_LINE (FND_FILE.LOG,'**********************************************************');
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Company      : ' || x_seg1_company);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Costcenter   : ' || x_seg2_costctr);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Account      : ' || x_seg3_account);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Location     : ' || x_seg4_location);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Intercompany : ' || x_seg5_interco);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle LOB          : ' || x_seg6_lob);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle Future       : ' || x_seg7_future);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Oracle CCID         : ' || x_ccid);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'Received Output Message      : ' || x_error_message);
     FND_FILE.PUT_LINE (FND_FILE.LOG,'**********************************************************');
     FND_FILE.PUT_LINE (FND_FILE.LOG,'                                                          ');
  END IF;

  Insert_itgora_stg( gc_source_nm
		  ,p_ps_business_unit
                  ,p_ps_department
                  ,p_ps_account
                  ,p_ps_operating_unit
                  ,p_ps_sales_channel
		  ,p_reference24
		  ,lc_itgora_error_message
  		 );
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    lc_error_loc     := 'Error : Exception raised in main procedure';
    lc_error_debug   := 'TRANSLATE_PS_VALUES';
    lc_error_message := 'Exception raised ' || SQLERRM;
    x_error_message  :=  x_error_message || lc_error_message || lc_error_loc
                             || lc_error_debug||'INVALID';
    IF gc_debug_message = 'Y' THEN
       FND_FILE.PUT_LINE (FND_FILE.LOG,x_error_message);
    END IF;
END TRANSLATE_PS_VALUES;

-- +===================================================================+
-- | Name  :GLSI_ITGORA_DERIVE_VALUES                                  |
-- | Description      : This Procedure is used the interface    to     |
-- |                    call the fuctions and procedures to derive     |
-- |                    needed values                                  |
-- | Parameters : p_group_id                                           |
-- |             ,p_source_nm                                          |
-- |             ,p_request_id                                         |
-- |             ,p_debug_flag                                         |
-- |                                                                   |
-- |                                                                   |
-- | Returns :    p_error_count                                        |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+


    PROCEDURE GLSI_ITGORA_DERIVE_VALUES ( p_group_id    IN VARCHAR2
				        ,p_source_nm   IN VARCHAR2
				        ,p_request_id  IN NUMBER
			                ,p_debug_flag  IN VARCHAR2
				        ,p_error_count OUT NUMBER
				      )
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
    lc_reference24       XX_GL_INTERFACE_NA_STG.reference24%TYPE;

    lc_debug_msg         VARCHAR2(1000);
    lc_error_flg         VARCHAR2(1);
    lc_debug_prog        VARCHAR2(100) := 'GLSI_ITGORA_DERIVE_VALUES';

    ln_row_id            rowid;
    ln_record_ctr	 NUMBER:=0;

    v_request_id number;
    lc_boolean        BOOLEAN;
    lc_boolean1        BOOLEAN;
    ln_error_count    NUMBER:=0;
    ---------------------------------------------------------------------
    -- Cursor to select individual new or invalid rows from staging table.
    -- This will be used to derive any needed values.
    ---------------------------------------------------------------------
    CURSOR get_je_lines_cursor IS
    SELECT  rowid
           ,legacy_segment1
           ,legacy_segment2
           ,legacy_segment3
           ,legacy_segment4
           ,legacy_segment6
           ,reference24
      FROM  XX_GL_INTERFACE_NA_STG
     WHERE  group_id                       = p_group_id
       AND(      NVL(derived_val,'INVALID')    = 'INVALID'
            OR   NVL(derived_sob,'INVALID')    = 'INVALID'
          );



    ----------------------------------------
    -- bug in translation definition program
    ----------------------------------------
    lc_source_value2     xx_fin_translatevalues.source_value2 %TYPE;

    BEGIN

      gn_grp_id 	:=p_group_id;
      gc_source_nm	:=p_source_nm;
      gn_req_id		:=p_request_id;
      gc_debug_message	:=p_debug_flag;

      DELETE_TRANSLATE(p_source_nm);

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

	ln_record_ctr:=ln_record_ctr+1;
	gc_record_no :=TO_CHAR(ln_record_ctr);

        FETCH get_je_lines_cursor
         INTO  ln_row_id
              ,lc_ps_company
              ,lc_ps_cost_center
              ,lc_ps_account
              ,lc_ps_location
              ,lc_ps_lob
	      ,lc_reference24;

        EXIT WHEN get_je_lines_cursor%NOTFOUND;

        lc_error_flg  := 'N';

	g_row_id:=ln_row_id;

        lc_debug_msg := '    Row processed by: '||lc_debug_prog|| ' p_row_id=> '   || ln_row_id;
        DEBUG_MESSAGE (lc_debug_msg,1);

        gc_error_message := NULL;


	XX_GL_INT_EBS_COA_PKG.TRANSLATE_PS_VALUES(
				  p_record_no		      => gc_record_no
                                 ,p_ps_business_unit          => lc_ps_company
                                 ,p_ps_department             => lc_ps_cost_center
                                 ,p_ps_account                => lc_ps_account
                                 ,p_ps_operating_unit         => lc_ps_location
                                 ,p_ps_affiliate              => NULL
                                 ,p_ps_sales_channel          => lc_ps_lob
                                 ,p_convert_gl_history        =>  'N'
				 ,p_reference24		      => lc_reference24
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

        IF (gc_error_message='INVALID' OR gc_error_message LIKE '%INVALID%') THEN

	   ln_error_count:=ln_error_count+1;

           lc_error_flg := 'Y';

        ELSE

          lc_error_flg := 'N';
          lc_debug_msg :=   gc_error_message;
          DEBUG_MESSAGE (lc_debug_msg);
          gc_error_message := NULL;

        END IF;

	IF gc_source_nm ='OD Inventory (SIV)' THEN

           IF lc_ora_cost_center IS NULL THEN
              lc_ora_cost_center := lc_ps_cost_center;
           END IF;

           IF lc_ora_account IS NULL THEN
              lc_ora_account := lc_ps_account;
           END IF;

           IF lc_ora_location IS NULL THEN
              lc_ora_location := lc_ps_location;
           END IF;

	END IF;

        IF gc_source_nm IN ('OD Inventory (SIV)','OD AP Integral') THEN

	   IF lc_ora_company IS NULL THEN
              lc_ora_company :='1001';
           END IF;

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
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '|| lc_debug_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_GL_INTERFACE_NA_STG = ROWID: '|| ln_row_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );
            END;

        ELSE   --         IF  lc_error_flg = 'N' THEN

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

           lc_debug_msg :='    Values errored Updating: '||'company=> '         ||lc_ora_company
                                     ||', cost_center=> '   ||lc_ora_cost_center
                                     ||', account=> '       ||lc_ora_account
                                     ||', location=> '      ||lc_ora_location
                                     ||', inter_company=> ' ||lc_ora_inter_company
                                     ||', lc_ora_lob=> '    ||lc_ora_lob
                                     ||', Future=> 000000 ' ||'INVALID';

           DEBUG_MESSAGE (lc_debug_msg);
          EXCEPTION
            WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '|| lc_debug_msg);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'XX_GL_INTERFACE_NA_STG = ROWID: '|| ln_row_id);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );
          END;

        END IF;   --         IF  lc_error_flg = 'N' THEN

      END LOOP;
      CLOSE get_je_lines_cursor;

      lc_boolean := fnd_submit.set_print_options(printer=>'XPTR',copies=>1);
      lc_boolean1:= fnd_request.add_printer (printer=>'XPTR',copies=> 1);
      v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXGLINTCOARPT',
					       'OD: PS GL INTERFACE CHART OF ACCOUNT REPORTS',
					        NULL,FALSE,p_source_nm
					      );
      IF v_request_id>0 THEN
         COMMIT;
      END IF;
      p_error_count:=ln_error_count;
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Total Errors occurred during mapping : '|| TO_CHAR(ln_error_count));
    EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Unknown issue: '|| lc_debug_msg );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Message: '|| SQLERRM );
        p_error_count:=ln_error_count;
    END GLSI_ITGORA_DERIVE_VALUES;

END XX_GL_INT_EBS_COA_PKG;
/
SHOW ERR;