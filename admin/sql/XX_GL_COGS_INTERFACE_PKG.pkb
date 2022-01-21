create or replace
PACKAGE BODY XX_GL_COGS_INTERFACE_PKG
   AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_COGS_INTERFACE_PKG                                  |
-- | Description      :  This PKG will be used to interface COGS       |
-- |                      data with the Oracle GL                      |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1.0      25-JUN-2007  P.Marco                                      |
-- |1.1      23-OCT-2007  P.Marco          Added decode statement to   |
-- |                                       handle credit transactions  |
-- |                                       IF quantity_invoice is null |
-- |                                       use quantity_credited in    |
-- |                                       amount formula              |
-- |                                                                   |
-- |1.2      24-OCT-2007  Arul Justin Raj  Fixed Defect for 2436       |
-- |                                       When build the Journal Line |
-- |                                       to get Consignment Account  |
-- |                                       from Attrbiute10 for        |
-- |                                       Consigment line             |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |1.3       19-DEc-2007                  Defect 3117  Default Account|
-- |                                       segment to 00000 on journal |
-- |                                       creation.                   |
-- |1.4       28-FEB-2008   Srividya S     Funtion Added as part of    |
-- |                                       Defect #3456 to fetch the   |
-- |                                       LOB values based on the     |
-- |                                       Location_Type and Fixed the |
-- |                                       defect #4903                |
-- |1.5       25-MAR-2008    Raji          Fixed defect # 5716         |
-- |          29-MAR-2008    Raji          Fixed defect # 5888         |
-- |1.6       10-MAY-2008    Prakash S	   - Performance Fixes         |
-- |                                       - p_chk_bal_flag = 'N'      |
-- |1.7       14-MAY-2008    Raji          Performanc Fixes            |
-- |          16-MAY-2008    Raji          Fixed defect 7145           |
-- |1.8       06-JUNE-2008   Srividya      Fixed defect #7700          |
-- |          06-JUNE-2008   Srividya      Fixed defect #7684          |
 --|          06-JUNE-2008   Srinidhi      Fixed defect #7793          |
 --|                                       Populated few refrence      |
 --|                                       columns in staging table    |
 --|1.9       19-JUNE-2008  Raji           Fixed defect 8261           |
 --|2.0       20-JUNE-2008  Raji           Perf fixes for defect 8242  |
 --|          24-JUNE-2008  Raji           Fixed defect 8283           |
 --|          26-JUNE-2008  Raji           Fixed defect 8506           |
 --|2.1       07-JUNE-2008  Manovinayak    Added code for the defect   |
 --|                                            #8706 and #8705        |
 --|2.2       25-July-2008  Manovinayak    Fixed the defect for 9123   |
 --|2.3       04-AUG-2008   Manovinayak    Added parameter for the     |
 --|                                       defect#9419                 |
 --|2.4       24-MAR-2009   Lincy K        Modified code for           |
 --|                                            defect #13428          |
-- |2.5       18-NOV-2015   Madhu Bolli    Remove schema for 12.2 retrofit |
-- +===================================================================+

    gc_translate_error VARCHAR2(5000);
    gc_source_name     XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
    gc_category_name   XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
    gn_group_id        XX_GL_INTERFACE_NA_STG.group_id%TYPE;
    gn_error_count     NUMBER := 0;
    gc_debug_pkg_nm    VARCHAR2(30) := 'XX_GL_COGS_INTERFACE_PKG.';
    gc_debug_flg       VARCHAR2(1)  := 'N';
    gn_request_id      NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();


-- +===================================================================+ -------Funtion Added as part of Defect #3456
-- | Name  :XX_DERIVE_LOB                                              |
-- | Description      :  This Funtion will fetch the LOB values        |
-- |                     corresponding to the location from the        |
-- |                     translation 'XX_RA_COGS_LOB_VALUES'           |
-- |                                                                   |
-- | Parameters :p_location (Location)                                 |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     FUNCTION XX_DERIVE_LOB(p_location IN VARCHAR2)
     RETURN NUMBER

     IS

     ln_lob_type  xx_fin_translatevalues.target_value1%TYPE;
     lc_loc_type  fnd_flex_values_vl.attribute2%TYPE;

     BEGIN

---------------- To Fetch  location Lype ---------------
          BEGIN
               SELECT FFV.attribute2
               INTO   lc_loc_type
               FROM   FND_FLEX_VALUES FFV ,
                      fnd_flex_value_sets FFVS
               WHERE FFV.flex_value_set_id = FFVS.flex_value_set_id
               AND  FFVS.flex_value_set_name = 'OD_GL_GLOBAL_LOCATION'
               AND FFV.flex_value = p_location;

         EXCEPTION
         WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the location Lype  :'
                                      || SQLERRM );
         END;


---------------- To Fetch  LOB for the Specified location Lype ---------------
         BEGIN
               SELECT  XFT.target_value1
               INTO    ln_lob_type
               FROM    xx_fin_translatedefinition XFTD
                      ,xx_fin_translatevalues XFT
               WHERE   XFTD.translate_id = XFT.translate_id
               AND     XFTD.translation_name = 'XX_RA_COGS_LOB_VALUES'
               AND     XFT.enabled_flag = 'Y'
               AND     XFT.source_value1=lc_loc_type;

         EXCEPTION
         WHEN OTHERS   THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the location LOB from Translation  :'
                                      || SQLERRM );
         END;

     RETURN ln_lob_type;

     END XX_DERIVE_LOB;

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
   END DEBUG_MESSAGE;

-- +===================================================================+-------Funtion Added as part of Defect #4140
-- | Name  :XX_EXCEPTION_REPORT_PROC                                   |
-- | Description      :  This Procedure will Submit request for the    |
-- |                     Report which will fetch  the  Invalid records |
-- |                     from the staging table                        |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE XX_EXCEPTION_REPORT_PROC
    IS
    lc_phase                    VARCHAR2(50);
    lc_status                   VARCHAR2(50);
lc_temp_email                    VARCHAR2(250);
    lc_devphase                 VARCHAR2(50);
    lc_devstatus                VARCHAR2(50);
    lc_message                  VARCHAR2(250);
    lb_req_status               BOOLEAN;
    ln_request_id               fnd_concurrent_requests.request_id%TYPE;
    lb_set_layout_option        BOOLEAN;
    lc_debug_prog               VARCHAR2(50):='XX_EXCEPTION_REPORT_PROC';
    lc_debug_msg               VARCHAR2(1000);
    ln_conc_id                 fnd_concurrent_requests.request_id%TYPE;
    lc_translate_name          VARCHAR2(19)   :='GL_INTERFACE_EMAIL';
    lc_first_rec               VARCHAR(1);
    lc_output_file            VARCHAR2(50);
    lc_file_extension         VARCHAR2(10);
    p_org_id                  NUMBER;

    Type TYPE_TAB_EMAIL IS TABLE OF

                 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
                 BY BINARY_INTEGER ;

    EMAIL_TBL TYPE_TAB_EMAIL;


   BEGIN

   p_org_id := fnd_profile.value('ORG_ID');  --- added for defect 8506

FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Id is ' ||  p_org_id); --- added for defect 8506



            FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '|| gc_debug_pkg_nm
                                                     ||  lc_debug_prog );

----------------- To Fetch the Email Address to Which The Exception Report Need to be Send ---------
           BEGIN
                  SELECT TV.target_value1
                        ,TV.target_value2
                        ,TV.target_value3
                        ,TV.target_value4
                        ,TV.target_value5
                        ,TV.target_value6
                        ,TV.target_value7
                  INTO   EMAIL_TBL(1)
                        ,EMAIL_TBL(2)
                        ,EMAIL_TBL(3)
                        ,EMAIL_TBL(4)
                        ,EMAIL_TBL(5)
                        ,EMAIL_TBL(6)
                        ,EMAIL_TBL(7)
                  FROM   XX_FIN_TRANSLATEVALUES TV
                        ,XX_FIN_TRANSLATEDEFINITION TD
                  WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
                  AND   TRANSLATION_NAME = lc_translate_name
                  AND   source_value1    = 'OD COGS';

                 lc_first_rec  := 'Y';
                 FOR ln_cnt IN 1..7 LOOP

                      IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                           IF lc_first_rec = 'Y' THEN
                               lc_temp_email := EMAIL_TBL(ln_cnt);
                               lc_first_rec := 'N';
                           ELSE
                               lc_temp_email :=  lc_temp_email ||' : ' || EMAIL_TBL(ln_cnt);
                           END IF;
                      END IF;
                 END LOOP ;

           EXCEPTION
           WHEN OTHERS THEN
                 FND_FILE.PUT_LINE(FND_FILE.LOG, 'Exception raised while fetching Email Address to send the Excel Output for'
                 ||'the Exception Report');
           END;

            lb_set_layout_option := FND_REQUEST.ADD_LAYOUT(
                                                          template_appl_name => 'XXFIN',
                                                          template_code      => 'XXGLCOGSEXC',
                                                          template_language  => 'en',
                                                          template_territory => 'US',
                                                          output_format      => 'EXCEL');

            ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                        application => 'XXFIN'
                                                        ,program     => 'XXGLCOGSEXC'
                                                        ,description => 'OD: GL COGS Journal Exception Report '
                                                        ,start_time  => NULL
                                                        ,sub_request => FALSE
                                                        ,argument1   => p_org_id   --- added for defect 8506
                                                       );
           COMMIT;

        IF ln_request_id = 0   THEN

            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error : OD: GL COGS Journal Exception Report Not Submitted');

        ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitted request '|| TO_CHAR (ln_request_id)||'OD: GL  COGS Journal Exception Report');
            lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                              request_id => ln_request_id
                                                             ,interval   => '10'
                                                             ,max_wait   => ''
                                                             ,phase      => lc_phase
                                                             ,status     => lc_status
                                                             ,dev_phase  => lc_devphase
                                                             ,dev_status => lc_devstatus
                                                             ,message    => lc_message
                                                            );

            IF    (lc_devstatus !='NORMAL_STATUS')
            AND   (lc_devphase   = 'COMPLETE_PHASE')     THEN
               FND_FILE.PUT_LINE (FND_FILE.LOG,'Warning: Failed to OD: GL  COGS Journal Exception Report Program ');

            ELSE

           lc_output_file    := 'XXGLCOGSEXC_'||ln_request_id||'_1'||'.EXCEL';
           lc_file_extension := '.xls';
           ln_conc_id        := FND_REQUEST.SUBMIT_REQUEST(
                                                         application => 'XXFIN'
                                                        ,program     => 'XXODROEMAILERCOGSPROG'
                                                        ,description => NULL
                                                        ,start_time  => SYSDATE
                                                        ,sub_request => FALSE
                                                        ,argument1   => NULL
                                                        ,argument2   => lc_temp_email
                                                        ,argument3   => 'OD_COGS_Exception_report'
                                                        ,argument4   => NULL
                                                        ,argument5   => 'Y'
                                                        ,argument6   => ln_request_id
                                                        ,argument7   => lc_output_file
                                                        ,argument8   => lc_file_extension
                                                       );
           END IF;
       END IF;

   EXCEPTION
         WHEN OTHERS THEN
             fnd_message.set_name('FND','FS-UNKNOWN');
             fnd_message.set_token('ERROR',SQLERRM);
             fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                           ||lc_debug_prog);

             lc_debug_msg := fnd_message.get();

             DEBUG_MESSAGE  (lc_debug_msg);
             FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );

   END  XX_EXCEPTION_REPORT_PROC;


-- +===================================================================+
-- | Name  : PROCESS_JOURNALS                                          |
-- | Description      : The main controlling procedure for the COGS    |
-- |                    interfaces This will be called by the OD: GL   |
-- |                    Interface for COGS concurrent program          |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_source_name, p_group_id                             |
-- |                                                                   |
-- |                                                                   |
-- | Returns : x_return_code, x_return_message                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
       PROCEDURE PROCESS_JOURNALS (x_return_message   OUT VARCHAR2
                                ,x_return_code      OUT VARCHAR2
                                ,p_source_name       IN VARCHAR2
                                ,p_debug_flg         IN VARCHAR2 DEFAULT 'N'
                                ,P_BATCH_SIZE        IN NUMBER DEFAULT '50000' -- Added for Defect # 9123
                                ,P_SET_OF_BOOKS_ID   IN NUMBER --Added for the defect#9419
                                 )
     IS

          NO_GROUP_ID_FOUND    EXCEPTION;

          ---------------------------
          -- local variables declared
          ---------------------------
          ln_error_cnt       NUMBER;
          lc_phase                    VARCHAR2(50);
          lc_status                   VARCHAR2(50);
          lc_devphase                 VARCHAR2(50);
          lc_devstatus                VARCHAR2(50);
          lc_message                  VARCHAR2(250);
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
          lb_bool            BOOLEAN;
          ln_cnt             NUMBER;
          gc_email_lkup       XX_FIN_TRANSLATEVALUES.source_value1%TYPE;



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
          p_org_id          NUMBER;
          ln_set_of_books_id  NUMBER;
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
          --P_SET_OF_BOOKS_ID number;  --Commented for the defect#9419

CURSOR c_insert_je_lines (P_SET_OF_BOOKS_ID in NUMBER)
IS
SELECT /*+ index (GL_CODE_COMBINATIONS GL_CODE_COMBINATIONS_U1)*/  --Added for defect #7700
       'NEW' stat
       ,rad.set_of_books_id sob
       ,rad.gl_date acct_date
       ,gls.currency_code  curr_code
       ,SYSDATE date_crtd
       ,3  crtd_by
       ,'A' act_flg
       ,'OD COGS' je_cat
       ,'OD COGS' je_src
       ,XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(DECODE(sign(ral.revenue_amount),
                      - 1,glc.segment4,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,
                                              nvl(SUBSTR(hou.name,1,6),glc.segment4))))segment1_cr
		,XX_GL_TRANSLATE_UTL_PKG.DERIVE_COMPANY_FROM_LOCATION(DECODE(sign(ral.revenue_amount),
                           -1,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,SUBSTR(hou.name,1,6))
                           ,glc.segment4)) segment1_dr
       ,DECODE(SUBSTR(DECODE(sign(ral.revenue_amount),- 1,DECODE(TRIM(rad.attribute10), NULL,rad.attribute8,rad.attribute10)
                      ,rad.attribute7),1,1)
                               ,'1','00000'
                               ,'2','00000'
                               ,'3','00000'
                               ,'4','00000'
                               ,'5','00000'
                               ,glc.segment2) seg2_dr  --- added for defect 8283
      ,DECODE(SUBSTR(DECODE(sign(ral.revenue_amount),- 1,rad.attribute7,
                               DECODE(TRIM(rad.attribute10), NULL,rad.attribute8,rad.attribute10)),1,1)
                               ,'1','00000'
                               ,'2','00000'
                               ,'3','00000'
                               ,'4','00000'
                               ,'5','00000'
                               ,glc.segment2) seg2_cr  --- added for defect 8283
       ,DECODE(sign(ral.revenue_amount),- 1,rad.attribute7,
                               DECODE(TRIM(rad.attribute10), NULL,rad.attribute8,rad.attribute10)) segment3_cr
		,DECODE(sign(ral.revenue_amount),- 1,DECODE(TRIM(rad.attribute10), NULL,rad.attribute8,rad.attribute10)
                      ,rad.attribute7) segment3_dr
       ,DECODE(sign(ral.revenue_amount),
                     - 1,glc.segment4,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,
                                             nvl(SUBSTR(hou.name,1,6),glc.segment4)))segment4_cr
		,DECODE(sign(ral.revenue_amount),
                       -1,DECODE(glc.segment4,nvl(SUBSTR(hou.name,1,6),glc.segment4),glc.segment4,SUBSTR(hou.name,1,6))
                       ,glc.segment4) segment4_dr
       ,glc.segment5  seg5
       ,DECODE((DECODE(sign(ral.revenue_amount)
                       ,- 1,rad.attribute7
		       ,DECODE(TRIM(rad.attribute10)
		               , NULL,rad.attribute8
			       ,rad.attribute10)
			       )
		)
                ,rad.attribute8,(XX_DERIVE_LOB(nvl(SUBSTR(hou.name,1,6),glc.segment4)
					      )
                                 )---Added for defect #3456 , modified for defect #13428 
               ,rad.attribute7,glc.segment6
               ,rad.attribute10,(XX_DERIVE_LOB(nvl(SUBSTR(hou.name,1,6),glc.segment4)
					      )
			        )
	      ) segment6_cr
	,DECODE((DECODE(sign(ral.revenue_amount)
	               ,- 1,DECODE(TRIM(rad.attribute10)
		                   , NULL,rad.attribute8
                                   ,rad.attribute10)
		       ,rad.attribute7)
		)
                ,rad.attribute8,(XX_DERIVE_LOB(nvl(SUBSTR(hou.name,1,6),glc.segment4)
					      )
				)
                ,rad.attribute7,glc.segment6
                ,rad.attribute10,(XX_DERIVE_LOB(nvl(SUBSTR(hou.name,1,6),glc.segment4)
					       )
			         )
	       )  segment6_dr ---Added for defect #3456, modified for defect #13428 
       ,glc.segment7 seg7
       ,ABS(ROUND(DECODE(to_number(nvl(rad.attribute9,'0')) * ral.quantity_invoiced, NULL
                 ,to_number(nvl(rad.attribute9,'0')) * ral.quantity_credited
                 ,to_number(nvl(rad.attribute9,'0')) * ral.quantity_invoiced),2)) amount
       ,to_char(rad.gl_date,'YYYY/MM/DD')  ref1
       ,rta.attribute14   ref20
       ,rad.cust_trx_line_gl_dist_id ref21
       ,ral.sales_order ref22
       ,ral.sales_order_line ref23
       ,ral.customer_trx_id ref24
       ,rad.attribute7 ref25
       ,rad.attribute8 ref26
       ,rad.attribute9 ref27
       ,rad.attribute11 ref28
       ,ral.description ref29
       ,ral.customer_trx_line_id ref30
       ,99900  grp_id
       ,ABS((DECODE(to_number(nvl(rad.attribute9,'0')) * RAL.quantity_invoiced, NULL
                 ,RAL.quantity_credited
                 ,RAL.quantity_invoiced)))  qty   --- added for defect 8261
       ,ral.customer_trx_id     cust_trx_id     --Added following 10 lines for defect 7793 and added ra_customer_trx_all rta in FROM Clause for getting rta.attribute14
       ,ral.customer_trx_line_id cust_trx_line_id
       ,rad.cust_trx_line_gl_dist_id cust_gl_dist_id
       ,rta.attribute14 att_14
       ,ral.sales_order_line att_15
       ,99999 gp_id
       ,rad.attribute11 dff
       ,ral.sales_order order_num
       ,ral.description descr
       ,'VALID' val
       ,'BALANCED' bal
 FROM  ra_customer_trx_all rta
       ,ra_cust_trx_line_gl_dist_all rad
       ,ra_customer_trx_lines_all ral
       ,gl_code_combinations glc
       ,gl_sets_of_books gls
       ,hr_organization_units hou
WHERE  rad.account_class = 'REV'
  AND  rad.attribute_category = 'SALES_ACCT'
  AND  rad.attribute6 IN ('N','E')
  AND  rad.gl_posted_date IS NOT NULL
  AND  rad.set_of_books_id = P_SET_OF_BOOKS_ID
  AND  ral.customer_trx_line_id = rad.customer_trx_line_id
  AND  rta.trx_number=ral.sales_order
  AND  gls.set_of_books_id = rad.set_of_books_id
  AND  glc.code_combination_id = rad.code_combination_id
  AND  hou.organization_id(+) = ral.warehouse_id;

TYPE c_insert_je_lines_tab_type  IS TABLE OF c_insert_je_lines%ROWTYPE;
v_insert_je_lines c_insert_je_lines_tab_type := c_insert_je_lines_tab_type() ;

TYPE xx_gl_interface_stg_type  is table of XX_GL_INTERFACE_NA_STG%ROWTYPE index by pls_integer;
ltab_xx_gl_interface_stg_dr xx_gl_interface_stg_type;
ltab_xx_gl_interface_stg_cr xx_gl_interface_stg_type;

         ------------------------------------------------
          -- Cursor to select all group ids from a source
          ------------------------------------------------
          /*CURSOR get_je_main_process_cursor
              IS
          SELECT DISTINCT
                  group_id
                 ,user_je_source_name
          FROM  XX_GL_INTERFACE_NA_STG
          WHERE user_je_source_name            = p_source_name;*/
          --AND   NVL(balanced   ,'UNBALANCED') = 'UNBALANCED';
           -- AND  (NVL(derived_val,'INVALID')    = 'INVALID'
           --  OR   NVL(derived_sob,'INVALID')    = 'INVALID'

        --Added the below Cursor for the defect#8706 and #8705
           CURSOR lcu_conc_req(p_master_request_id NUMBER)
           IS
           SELECT FCR.request_id
                 ,FLP.meaning
           FROM   fnd_concurrent_requests FCR
                 ,fnd_concurrent_programs FCP
                 ,FND_LOOKUPS             FLP
           WHERE  FCR.parent_request_id       = p_master_request_id
           AND    FCR.concurrent_program_id   = FCP.concurrent_program_id
           AND    FLP.lookup_code             = FCR.status_code
           AND    FLP.lookup_type             = 'CP_STATUS_CODE'
           AND    FCP.concurrent_program_name = 'GLLEZL';

     BEGIN

                ------------------------------------------------
                --Code changes for defect#8706 begins
                ------------------------------------------------

         /*       IF ((TO_NUMBER(FND_CONC_GLOBAL.request_data) = 0 OR TO_NUMBER(FND_CONC_GLOBAL.request_data) <> 0 AND NVL(FND_CONC_GLOBAL.request_data,0) <> 0))  THEN


                       IF  FND_CONC_GLOBAL.request_data <> 0 THEN

                               lc_mail_subject := 'ERRORS: Found in '||p_source_name ||' GL Import!';
                       ELSE
                               lc_mail_subject :=  p_source_name||' GL Import completed!';

                       END IF;

                       lc_debug_msg := 'Emailing output report: gn_request_id=> '
                                       ||gn_request_id || ' gc_source_name=> ' ||p_source_name
                                       || ' lc_mail_subject=> ' || lc_mail_subject;

                       DEBUG_MESSAGE (lc_debug_msg,1);
                       gc_email_lkup := p_source_name;

                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status:');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('REQUEST ID',20,' ')
                                                       ||RPAD('REQUEST STATUS',20));
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('----------',20,' ')
                                                       ||RPAD('--------------',20));

                       FOR lcu_conc_req_rec IN lcu_conc_req(gn_request_id)
                       LOOP

                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_conc_req_rec.request_id,20,' ')
                                                       ||RPAD(lcu_conc_req_rec.meaning,20));

                       ln_conc_id := fnd_request.submit_request(
                                                                application => 'XXFIN'
                                                               ,program     => 'XXGLINTERFACEEMAIL'
                                                               ,description => NULL
                                                               ,start_time  => SYSDATE
                                                               ,sub_request => FALSE
                                                               ,argument1   => lcu_conc_req_rec.request_id
                                                               ,argument2   => gc_email_lkup
                                                               ,argument3   => 'Journal Import Execution Report for Request'
                                                               );
                       COMMIT;

                       END LOOP;

                      ln_conc_id := fnd_request.submit_request(application => 'XXFIN'
                                                              ,program     => 'XXGLINTERFACEEMAIL'
                                                              ,description => NULL
                                                              ,start_time  => SYSDATE
                                                              ,sub_request => FALSE
                                                              ,argument1   => gn_request_id
                                                              ,argument2   => p_source_name
                                                              ,argument3   => lc_mail_subject
                                                              );
                      COMMIT;

                      x_return_message := 'COMPLETED PROGRAM SUCCESSFULLY-EXITING';
                      x_return_code    := 0;
                      RETURN;

                END IF;
*/
                ------------------------------------------------
                --Code changes for defect#8706 ends
                ------------------------------------------------

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


        -----------------------
        -- Create Journal Lines
        -----------------------

        --SET Context to Operating unit or register by operating unit
--P_SET_OF_BOOKS_ID :=  fnd_profile.value('GL_SET_OF_BKS_ID');      --Commented for the defect#9419

FND_FILE.PUT_LINE(FND_FILE.LOG,'SOB Id is ' ||  P_SET_OF_BOOKS_ID);

--P_SET_OF_BOOKS_ID := ln_set_of_books_id ;

OPEN c_insert_je_lines(P_SET_OF_BOOKS_ID );

---------------------------------------------------------------------------
-- Counter ln_cnt is used to check for the Data Exists or Not in the table
---------------------------------------------------------------------------

 ln_cnt := 1;

 LOOP

 
   -- Get the invoice lines data up to the limit
  FETCH c_insert_je_lines BULK COLLECT INTO v_insert_je_lines LIMIT P_BATCH_SIZE;
  SELECT gl_interface_control_s.nextval
  INTO   ln_group_id
  FROM   dual;

  FND_FILE.PUT_LINE(FND_FILE.LOG,'Group Id is ' ||  ln_group_id);

 -- Loop through the fetched array to assign the needed non-null values to create the credit lines for JE
   
-----------------------------------------------------------------------------------------
-- The IF statement is used to verify whether the First value in the table is NUll or Not
-----------------------------------------------------------------------------------------


IF v_insert_je_lines.FIRST IS NOT NULL THEN --  added for Defect # 9123

  
  FOR i IN v_insert_je_lines.FIRST .. v_insert_je_lines.LAST


   LOOP

     ltab_xx_gl_interface_stg_cr(i).status := v_insert_je_lines(i).stat;
     ltab_xx_gl_interface_stg_cr(i).set_of_books_id := v_insert_je_lines(i).sob;
     ltab_xx_gl_interface_stg_cr(i).accounting_date := v_insert_je_lines(i).acct_date;
     ltab_xx_gl_interface_stg_cr(i).currency_code := v_insert_je_lines(i).curr_code;
	 ltab_xx_gl_interface_stg_cr(i).date_created := v_insert_je_lines(i).date_crtd;
	 ltab_xx_gl_interface_stg_cr(i).created_by := v_insert_je_lines(i).crtd_by;
	 ltab_xx_gl_interface_stg_cr(i).actual_flag := v_insert_je_lines(i).act_flg;
	 ltab_xx_gl_interface_stg_cr(i).user_je_category_name := v_insert_je_lines(i).je_cat;
	 ltab_xx_gl_interface_stg_cr(i).user_je_source_name := v_insert_je_lines(i).je_src;
	 ltab_xx_gl_interface_stg_cr(i).segment1 := v_insert_je_lines(i).segment1_cr;
     ltab_xx_gl_interface_stg_cr(i).segment2 := v_insert_je_lines(i).seg2_cr;
     ltab_xx_gl_interface_stg_cr(i).segment3 := v_insert_je_lines(i).segment3_cr;
	 ltab_xx_gl_interface_stg_cr(i).segment4 := v_insert_je_lines(i).segment4_cr;
	 ltab_xx_gl_interface_stg_cr(i).segment5 := v_insert_je_lines(i).seg5;
	 ltab_xx_gl_interface_stg_cr(i).segment6 := v_insert_je_lines(i).segment6_cr;
	 ltab_xx_gl_interface_stg_cr(i).segment7 := v_insert_je_lines(i).seg7;
	 ltab_xx_gl_interface_stg_cr(i).entered_dr := NULL;
	 ltab_xx_gl_interface_stg_cr(i).entered_cr := v_insert_je_lines(i).amount;
	 ltab_xx_gl_interface_stg_cr(i).reference1 := v_insert_je_lines(i).ref1;
	 ltab_xx_gl_interface_stg_cr(i).reference20 := v_insert_je_lines(i).ref20;
	 ltab_xx_gl_interface_stg_cr(i).reference21 := v_insert_je_lines(i).ref21;
	 ltab_xx_gl_interface_stg_cr(i).reference22 := v_insert_je_lines(i).ref22;
	 ltab_xx_gl_interface_stg_cr(i).reference23 := v_insert_je_lines(i).ref23;
	 ltab_xx_gl_interface_stg_cr(i).reference24 := v_insert_je_lines(i).ref24;
	 ltab_xx_gl_interface_stg_cr(i).reference25 := v_insert_je_lines(i).ref25;
	 ltab_xx_gl_interface_stg_cr(i).reference26 := v_insert_je_lines(i).ref26;
	 ltab_xx_gl_interface_stg_cr(i).reference27 := v_insert_je_lines(i).ref27;
	 ltab_xx_gl_interface_stg_cr(i).reference28 := v_insert_je_lines(i).ref28;
	 ltab_xx_gl_interface_stg_cr(i).reference29 := v_insert_je_lines(i).ref29;
	 ltab_xx_gl_interface_stg_cr(i).reference30 := v_insert_je_lines(i).ref30;
	 ltab_xx_gl_interface_stg_cr(i).group_id := ln_group_id;
	 ltab_xx_gl_interface_stg_cr(i).attribute10 := v_insert_je_lines(i).qty;
	 ltab_xx_gl_interface_stg_cr(i).attribute11 := v_insert_je_lines(i).cust_trx_id;
	 ltab_xx_gl_interface_stg_cr(i).attribute12 := v_insert_je_lines(i).cust_trx_line_id;
	 ltab_xx_gl_interface_stg_cr(i).attribute13 := v_insert_je_lines(i).cust_gl_dist_id;
	 ltab_xx_gl_interface_stg_cr(i).attribute14 := v_insert_je_lines(i).att_14;
	 ltab_xx_gl_interface_stg_cr(i).attribute15 := v_insert_je_lines(i).att_15;
	 ltab_xx_gl_interface_stg_cr(i).attribute16 := ln_group_id;
	 ltab_xx_gl_interface_stg_cr(i).attribute18 := v_insert_je_lines(i).dff;
	 ltab_xx_gl_interface_stg_cr(i).attribute19 := v_insert_je_lines(i).order_num;
	 ltab_xx_gl_interface_stg_cr(i).attribute20 := v_insert_je_lines(i).descr;
	 ltab_xx_gl_interface_stg_cr(i).derived_val := v_insert_je_lines(i).val;
         ltab_xx_gl_interface_stg_cr(i).balanced := v_insert_je_lines(i).bal;

   END LOOP;
--- Code added for Defect # 9123--
ELSE

    IF v_insert_je_lines.FIRST IS NULL AND ln_cnt = 1 THEN

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data exists in staging table for processing');

    END IF;
 EXIT;

END IF;  


     
   --Insert the debit lines for JE into staging
 

   FORALL i IN ltab_xx_gl_interface_stg_cr.FIRST..ltab_xx_gl_interface_stg_cr.LAST
     INSERT INTO XX_GL_INTERFACE_NA_STG
     VALUES ltab_xx_gl_interface_stg_cr(i);

   -- Loop through the invoice lines to create the debit lines for JE
-----------------------------------------------------------------------------------------
-- The IF statement is used to verify whether the First value in the table is NUll or Not
-----------------------------------------------------------------------------------------

  IF v_insert_je_lines.FIRST IS NOT NULL  THEN

   FOR i IN v_insert_je_lines.FIRST .. v_insert_je_lines.LAST
    
     
   LOOP
     ltab_xx_gl_interface_stg_dr(i).status := v_insert_je_lines(i).stat;
     ltab_xx_gl_interface_stg_dr(i).set_of_books_id := v_insert_je_lines(i).sob;
     ltab_xx_gl_interface_stg_dr(i).accounting_date := v_insert_je_lines(i).acct_date;
     ltab_xx_gl_interface_stg_dr(i).currency_code := v_insert_je_lines(i).curr_code;
	 ltab_xx_gl_interface_stg_dr(i).date_created := v_insert_je_lines(i).date_crtd;
	 ltab_xx_gl_interface_stg_dr(i).created_by := v_insert_je_lines(i).crtd_by;
	 ltab_xx_gl_interface_stg_dr(i).actual_flag := v_insert_je_lines(i).act_flg;
	 ltab_xx_gl_interface_stg_dr(i).user_je_category_name := v_insert_je_lines(i).je_cat;
	 ltab_xx_gl_interface_stg_dr(i).user_je_source_name := v_insert_je_lines(i).je_src;
	 ltab_xx_gl_interface_stg_dr(i).segment1 := v_insert_je_lines(i).segment1_dr;
     ltab_xx_gl_interface_stg_dr(i).segment2 := v_insert_je_lines(i).seg2_dr;
     ltab_xx_gl_interface_stg_dr(i).segment3 := v_insert_je_lines(i).segment3_dr;
	 ltab_xx_gl_interface_stg_dr(i).segment4 := v_insert_je_lines(i).segment4_dr;
	 ltab_xx_gl_interface_stg_dr(i).segment5 := v_insert_je_lines(i).seg5;
	 ltab_xx_gl_interface_stg_dr(i).segment6 := v_insert_je_lines(i).segment6_dr;
	 ltab_xx_gl_interface_stg_dr(i).segment7 := v_insert_je_lines(i).seg7;
	 ltab_xx_gl_interface_stg_dr(i).entered_dr := v_insert_je_lines(i).amount;
	 ltab_xx_gl_interface_stg_dr(i).entered_cr := NULL;
	 ltab_xx_gl_interface_stg_dr(i).reference1 := v_insert_je_lines(i).ref1;
	 ltab_xx_gl_interface_stg_dr(i).reference20 := v_insert_je_lines(i).ref20;
	 ltab_xx_gl_interface_stg_dr(i).reference21 := v_insert_je_lines(i).ref21;
	 ltab_xx_gl_interface_stg_dr(i).reference22 := v_insert_je_lines(i).ref22;
	 ltab_xx_gl_interface_stg_dr(i).reference23 := v_insert_je_lines(i).ref23;
	 ltab_xx_gl_interface_stg_dr(i).reference24 := v_insert_je_lines(i).ref24;
	 ltab_xx_gl_interface_stg_dr(i).reference25 := v_insert_je_lines(i).ref25;
	 ltab_xx_gl_interface_stg_dr(i).reference26 := v_insert_je_lines(i).ref26;
	 ltab_xx_gl_interface_stg_dr(i).reference27 := v_insert_je_lines(i).ref27;
	 ltab_xx_gl_interface_stg_dr(i).reference28 := v_insert_je_lines(i).ref28;
	 ltab_xx_gl_interface_stg_dr(i).reference29 := v_insert_je_lines(i).ref29;
	 ltab_xx_gl_interface_stg_dr(i).reference30 := v_insert_je_lines(i).ref30;
	 ltab_xx_gl_interface_stg_dr(i).group_id := ln_group_id;
	 ltab_xx_gl_interface_stg_dr(i).attribute10 := v_insert_je_lines(i).qty;
	 ltab_xx_gl_interface_stg_dr(i).attribute11 := v_insert_je_lines(i).cust_trx_id;
	 ltab_xx_gl_interface_stg_dr(i).attribute12 := v_insert_je_lines(i).cust_trx_line_id;
	 ltab_xx_gl_interface_stg_dr(i).attribute13 := v_insert_je_lines(i).cust_gl_dist_id;
	 ltab_xx_gl_interface_stg_dr(i).attribute14 := v_insert_je_lines(i).att_14;
	 ltab_xx_gl_interface_stg_dr(i).attribute15 := v_insert_je_lines(i).att_15;
	 ltab_xx_gl_interface_stg_dr(i).attribute16 := ln_group_id;
	 ltab_xx_gl_interface_stg_dr(i).attribute18 := v_insert_je_lines(i).dff;
	 ltab_xx_gl_interface_stg_dr(i).attribute19 := v_insert_je_lines(i).order_num;
	 ltab_xx_gl_interface_stg_dr(i).attribute20 := v_insert_je_lines(i).descr;
	 ltab_xx_gl_interface_stg_dr(i).derived_val := v_insert_je_lines(i).val;
         ltab_xx_gl_interface_stg_dr(i).balanced    := v_insert_je_lines(i).bal;

  END LOOP;

 
ELSE

    IF v_insert_je_lines.FIRST IS NULL AND ln_cnt = 1 THEN

     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data exists in staging table for processing');
      
    END IF;  
  EXIT;
END IF;

  --Insert the debit lines for JE into staging


FORALL i IN ltab_xx_gl_interface_stg_dr.FIRST..ltab_xx_gl_interface_stg_dr.LAST
    INSERT INTO XX_GL_INTERFACE_NA_STG
     VALUES ltab_xx_gl_interface_stg_dr(i);

  COMMIT;
       ---------------------
        -- Main cursor opened
        ---------------------

       /* lc_debug_msg     := '    Opened get_je_main_process_cursor';
        DEBUG_MESSAGE (lc_debug_msg);

        OPEN get_je_main_process_cursor;
        LOOP

             FETCH get_je_main_process_cursor
              INTO      gn_group_id
                       ,gc_source_name;


             IF lc_firsT_record = 'Y'AND ( gc_source_name IS NULL
                                           OR gn_group_id IS NULL) THEN
                   RAISE NO_GROUP_ID_FOUND;

             END IF;

         EXIT WHEN get_je_main_process_cursor%NOTFOUND;

            lc_firsT_record  := 'N';*/


              SELECT count(*) INTO ln_cnt from XX_GL_INTERFACE_NA_STG WHERE group_id=ln_group_id AND user_je_source_name=p_source_name;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'No of records inserted into staging table for group id ' || gn_group_id || 'is' || ln_cnt);   --(sri)
  
            ----------------------------
            --  PROCESS JOURNAL LINES
            ----------------------------
            -- Prakash Sankaran - 5/10/08 - Changed p_chk_bal_flg to 'N'


            XX_GL_INTERFACE_PKG.PROCESS_JRNL_LINES(p_grp_id         => ln_group_id
                                                  ,p_source_nm      => p_source_name
                                                  ,p_err_cnt        => gn_error_count
                                                  ,p_debug_flag     => gc_debug_flg
                                                  ,p_chk_bal_flg    => 'N'
                                                  ,p_chk_sob_flg    => 'N'
                                                  ,p_summary_flag   => 'Y'
                                                  ,p_import_ctrl    => 'Y'
                                                  ,p_cogs_update    => 'Y'
                                                  );


--EXIT WHEN c_insert_je_lines%NOTFOUND; -- commented for Defect # 9123
  ln_cnt:=ln_cnt+1;  -- Added for Defect # 9123
  END LOOP;
  CLOSE c_insert_je_lines ;

 /* EXIT WHEN get_je_main_process_cursor%NOTFOUND;
   END LOOP;
  CLOSE get_je_main_process_cursor;*/

      XX_EXCEPTION_REPORT_PROC;

       lc_debug_msg := '!!!!!Total number of all errors: ' || gn_error_count;
       DEBUG_MESSAGE (lc_debug_msg,1);

--Commented for the defect#8706
/*
       IF  gn_error_count <> 0 THEN

               lc_mail_subject := 'ERRORS: Found in '||p_source_name ||' GL Import!';
       ELSE
               lc_mail_subject :=  p_source_name||' GL Import completed!';

       END IF;

       lc_debug_msg := 'Emailing output report: gn_request_id=> '
                       ||gn_request_id || ' gc_source_name=> ' ||p_source_name
                       || ' lc_mail_subject=> ' || lc_mail_subject;

       DEBUG_MESSAGE (lc_debug_msg,1);
       ln_conc_id := fnd_request.submit_request( application => 'XXFIN'
                                                ,program     => 'XXGLINTERFACEEMAIL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => gn_request_id
                                                ,argument2   => p_source_name
                                                ,argument3   => lc_mail_subject
                                                );
*/

                ------------------------------------------------
                --Code changes for defect#8706 begins
                ------------------------------------------------

           /*        FND_CONC_GLOBAL.set_req_globals(conc_status =>'PAUSED',request_data=>TO_CHAR(gn_error_count));
                   COMMIT;
                   FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING COGS PROGRAM');
                   x_return_message := 'Restarted COGS program';
                   x_return_code    := 0;
                   RETURN;*/

                ------------------------------------------------
                --Code changes for defect#8706 ends
                ------------------------------------------------
          
--------------------------------------
-- Code changes for Defect 9123 Starts
--------------------------------------

             /*    IF  gn_error_count <> 0 THEN

                        lc_mail_subject := 'ERRORS: Found in '||p_source_name ||' GL Import!';
                 ELSE

                        lc_mail_subject :=  p_source_name||' GL Import completed!';

                  END IF;*/

                       lc_mail_subject := 'OD GL COGS Import Interface Status_';
                  
                       lc_debug_msg := 'Emailing output report: gn_request_id=> '
                                       ||gn_request_id || ' gc_source_name=> ' ||p_source_name
                                       || ' lc_mail_subject=> ' || lc_mail_subject;



                       DEBUG_MESSAGE (lc_debug_msg,1);
                       gc_email_lkup := p_source_name;
                       
                       IF ln_cnt > 1 THEN

                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status:');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('REQUEST ID',20,' ')
                                                       ||RPAD('REQUEST STATUS',20));
                       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('----------',20,' ')
                                                       ||RPAD('--------------',20));

                       FOR lcu_conc_req_rec IN lcu_conc_req(gn_request_id)
                       LOOP
                   
                        lb_bool := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                              request_id => lcu_conc_req_rec.request_id
                                                             ,interval   => '10'
                                                             ,max_wait   => ''
                                                             ,phase      => lc_phase
                                                             ,status     => lc_status
                                                             ,dev_phase  => lc_devphase
                                                             ,dev_status => lc_devstatus
                                                             ,message    => lc_message
                                                            );


                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcu_conc_req_rec.request_id,20,' ')
                                                       ||RPAD(lcu_conc_req_rec.meaning,20));




                         ln_conc_id := fnd_request.submit_request(
                                                                application => 'XXFIN'
                                                               ,program     => 'XXGLINTERFACEEMAIL'
                                                               ,description => NULL
                                                               ,start_time  => SYSDATE
                                                               ,sub_request => FALSE
                                                               ,argument1   => lcu_conc_req_rec.request_id
                                                               ,argument2   => gc_email_lkup
                                                               ,argument3   => 'Journal Import Execution Report for Request'
                                                               );
 
 
 
                      END LOOP;

                     
                       ln_conc_id := fnd_request.submit_request(application => 'XXFIN'
                                                              ,program     => 'XXGLINTERFACEEMAIL'
                                                              ,description => NULL
                                                              ,start_time  => SYSDATE
                                                              ,sub_request => FALSE
                                                              ,argument1   => gn_request_id
                                                              ,argument2   => p_source_name
                                                              ,argument3   => lc_mail_subject
                                                              );
                      COMMIT;

		  ELSE
			                       ln_conc_id := fnd_request.submit_request(application => 'XXFIN'
                                                              ,program     => 'XXGLINTERFACEEMAIL'
                                                              ,description => NULL
                                                              ,start_time  => SYSDATE
                                                              ,sub_request => FALSE
                                                              ,argument1   => gn_request_id
                                                              ,argument2   => p_source_name
                                                              ,argument3   => lc_mail_subject
                                                              );
			COMMIT;
                 END IF;
--------------------------------------
-- Code changes for Defect 9123 Ends
--------------------------------------

                           
   EXCEPTION

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


                 FND_FILE.PUT_LINE(FND_FILE.LOG,'No records or invalid group ID/source name'
                                             ||' on staging table');
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No records or invalid group ID/source name'
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

END XX_GL_COGS_INTERFACE_PKG;
/