create or replace PACKAGE BODY XX_GL_INTERFACE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : XX_GL_INTERFACE_PKG                                       |
-- | Description      :  This PKG will be used to insert and process   |
-- |                     GL Journals using the staging tables          |
-- |                                                                   |
-- | RICE#            : I0985                                          |
-- | Main ITG Package : 31478                                          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ===== ======================|
-- |DRAFT 1A DD-MON-YYYY  P.Marco          Initial draft version       |
-- |1        25-JUN-2007  P.Marco                                      |
-- |                                                                   |
-- |Ver 1.0  18-DEC-2008  P.Marco          Defect 3076 Need to added   |
-- |                                       reference 21 to the         |
-- |                                       COPY_TO_GL_INTERFACE Proc   |
-- |                                       COGS requires this field for|
-- |                                       tracking the customer trx   |
-- |                                                                   |
-- |         18-DEC-2008  P.Marco          Defect 3094 fixed logic errs|
-- |                                       with balance cursor and stg |
-- |                                       table clean up              |
-- |                                                                   |
-- | 1.1    19-FEB-2008  Raji              Fixed defect 4686 and 4652  |
-- | 1.2    11-MAR-2008  Raji              Fixed defect 5330           |
-- | 1.3    17-MAR-2008  Samitha           Fixed defect 4140,4139      |
-- | 1.4    31-MAR-2008  Srividya          Fixed defect 5761           |
-- | 1.5    01-MAY-2008  Raji              Log msgs - defect 6558      |
-- | 1.6    11-MAY-2008  Prakash S         Performance Fixes           |
-- | 1.7    12-MAY-2008  Prakash S         Performance Fixes           |
-- | 1.8    14-MAY-2008  Raji              Performance Fixes           |
-- | 1.9    06-JUNE-2008 Srividya          Fixed defect #7700          |
-- | 2.0    06-JUNE-2008 Srinidhi          Fixed defect #7793          |
-- |                                       Populated few reference     |
-- |                                       columns in staging table    |
-- | 2.1    16-JUNE-2008 Srinidhi          Fixed defect #7634          |
-- |                                       Performance tuning          |
-- |                                       Added hint to the Select    |
-- |                                       statement                   |
-- | 2.2    18-JUNE-2008  Raji             Reverted the change made on |
-- |                                       UPDATE statement per defect |
-- |                                       # 7700                      |
-- |        19-JUNE-2008  Raji             Fixed defect 8261           |
-- |        02-JUL-2008   Raji             Fixed defect 8651           |
-- | 2.3    08-JUL-2008 Manovinayak        Added code for the          |
-- |                                       Defect#8705 and #8706       |
-- | 2.4    11-AUG-08   Manovinayak        Fix for defect#9639         |
-- | 2.5    13-AUG-08   Srividya           Fix for defect#9696         |
-- | 2.6    29-AUG-08   Chandrakala D      Fix for defect#5327         |
-- | 2.7    08-OCT-08   R.Aldridge         Defect#11885 - Add function |
-- |                                       GET_JE_LINE_CNT             |
-- | 2.8    30-Apr-09  Ranjith T           Changes for defect 14556    |
-- | 2.9    06-May-09  Lincy K             Changes for defect 14837    |
-- | 3.0    08-Jul-09  Usha R              Changes for defect 531      |
-- | 3.1    11-Jun-10  Sneha Anand         Changes for R1.4 defect 5494|
-- | 3.2    30-AUG-10  R. Hartman          Changes for R10.5 defect7765|
-- |                                  Archive Remove GL.* schema names |
-- | 3.3    06-Jul-12  Paddy Sanjeevi      Defect 19342                |
-- | 3.4    18-Jul-13  Sheetal Sundaram    I0463 - Changes for R12     |
-- |                                       Upgrade retrofit.           |
-- | 3.5    10-Jan-14  Jay Gupta           Defect#26736                |
-- | 3.6    09-APR-15  Shravya Gattu       Defect# 34078 Added where   |
-- |                                       clause to process a group_id|
-- |		                           and handling deadlock error |
-- | 3.7    16-Nov-15  Avinash Baddam      R12.2 Compliance Changes    |
-- +===================================================================+

    gc_debug_pkg_nm     VARCHAR2(21) := 'XX_GL_INTERFACE_PKG.';
    gn_error_count      NUMBER       := 0;
    gc_debug_flg        VARCHAR2(1)  := 'N';
    gn_request_id       NUMBER;
    --gn_import_request_id NUMBER; --Added for the defect#8705  --Commented for the defect#9639
    gc_email_lkup       XX_FIN_TRANSLATEVALUES.source_value1%TYPE;
    gc_import_ctrl      VARCHAR2(1);
    gc_mail_addresses   VARCHAR2(500);
    gc_file_name        XX_GL_INTERFACE_NA_STG.reference24%TYPE;
    gc_bypass_valid_flg VARCHAR2(1)   := 'N';
    lc_temp_email       VARCHAR2(2000);
    ln_v_dr_amt           NUMBER        :=0;
    ln_v_cr_amt           NUMBER        :=0;
    ln_in_dr_amt          NUMBER        :=0;
    ln_in_cr_amt          NUMBER        :=0;
    ln_del_rec            NUMBER        :=0;



-- +===================================================================+
-- | Name  GET_JE_LINE_CNT                                             |
-- | Description      :  This function is used to obtain the number of |
-- |                     journal lines in gl_import_references table   |
-- |                     for a given je_batch_id                       |
-- | Parameters       :  p_je_batch_id: journal batch id for which     |
-- |                     count needs to be obtained                    |
-- |                                                                   |
-- | Returns          : count                                          |
-- |                                                                   |
-- |Version   Date         Author           Remarks                    |
-- |=======   ===========  ================ ===========================|
-- |1.0       08-OCT-2008  R. Aldridge      Intial version             |
-- |1.1       30-AUG-2010  R. Hartman       Archive Defect 7765        |
-- |                                        Remove schema names        |
-- +===================================================================+
    FUNCTION GET_JE_LINE_CNT(p_je_batch_id IN NUMBER)
      RETURN NUMBER

    IS
      lc_count NUMBER;

    BEGIN
        SELECT COUNT(1)
          INTO lc_count
          FROM gl_je_headers GJH
              ,gl_import_references GIR
         WHERE GJH.je_batch_id  = p_je_batch_id
           AND GJH.je_header_id = GIR.je_header_id;

     RETURN lc_count;

     END GET_JE_LINE_CNT;


-- +===================================================================+
-- | Name  :DEBUG_MESSAGE                                              |
-- | Description      :  This local procedure will write debug state-  |
-- |                     ments to the log file if debug_flag is Y      |
-- |                                                                   |
-- | Parameters :p_message (msg written), p_lines (# of blank lines)   |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

   PROCEDURE DEBUG_MESSAGE (p_message  IN  VARCHAR2
                           ,p_lines   IN  NUMBER DEFAULT 0 )

   IS

         ln_lines_cnt NUMBER := 0;
         lc_debug_msg   VARCHAR2(1000);
         lc_debug_prog  VARCHAR2(25) := 'DEBUG_MESSAGE';

   BEGIN

         IF gc_debug_flg = 'Y' THEN
               LOOP

               EXIT WHEN ln_lines_cnt = p_lines;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,' ');
                    ln_lines_cnt := ln_lines_cnt + 1;

               END LOOP;

               FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

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


   END DEBUG_MESSAGE;

-- +===================================================================+-------Funtion Added as part of Defect #5761 By Srividya
-- | Name  :XX_VALIDATE_STG_PROC                                       |
-- | Description      :  This Procedure will validate the records      |
-- |                     which will be fetch  from the AR tables       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE XX_VALIDATE_STG_PROC(p_group_id IN NUMBER)
    IS
    BEGIN


/*--Added for defect #7700  ( reverted back to this query since this has less cost than the below update) added on 18/6/08
        UPDATE XX_GL_INTERFACE_NA_STG STG
        SET STG.derived_val='INVALID'
        WHERE STG.group_id = p_group_id
        AND EXISTS
               (SELECT ral.sales_order
                FROM  ra_cust_trx_line_gl_dist_all rad
                     ,ra_customer_trx_lines_all ral
                WHERE ral.sales_order = stg.reference22
                AND rad.attribute6 in ('N','E')
          --      AND rad.cust_trx_line_gl_dist_id = to_number(stg.reference21)
                AND ral.customer_trx_id = to_number(stg.reference24)
                AND ral.customer_trx_line_id = rad.customer_trx_line_id
                AND (rad.attribute7  IS NULL or rad.attribute8 IS NULL or rad.attribute9 IS NULL)); */

 -- Added for defect 8651

	   UPDATE xx_gl_interface_na_stg STG
         SET   STG.derived_val='INVALID'
         WHERE STG.group_id =p_group_id
          AND (STG.reference25 IS NULL or STG.reference26 IS NULL or STG.reference27 IS NULL);



          FND_FILE.PUT_LINE(FND_FILE.LOG,'No of rows updated with invalid status'||sql%rowcount);


         COMMIT;

   EXCEPTION
        WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others exception raised'||sqlerrm);

 END XX_VALIDATE_STG_PROC;


--XX_INSERT_TO_RA_CUSTOM_PROC(Procedure) commented as part of defect #7793
-- +===================================================================+
-- | Name  :TABLE_UTILITY                                              |
-- | Description      :  This public procedure will be used to clean   |
-- |                     up records on the custom interface tables     |
-- |                                                                   |
-- | Parameters :  p_group_id: is needed to delete records from any of |
-- |                           the tables.                             |
-- |               p_del_stg_tbl: set to Y to delete records from the  |
-- |                              staging table based on the group_id  |
-- |               p_del_err_tbl: set to Y to delete records from the  |
-- |                              errors table                         |
-- |                                                                   |
-- |               p_purge_log_tbl: Will ALL purge records from the log|
-- |                                table older then 6 months          |
-- |                                                                   |
-- | Returns :    x_return_message,x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE TABLE_UTILITY ( x_return_message    OUT VARCHAR2
                            ,x_return_code       OUT VARCHAR2
                            ,p_group_id          IN  NUMBER      DEFAULT NULL
                            ,p_del_stg_tbl       IN  VARCHAR2 DEFAULT 'N'
                            ,p_del_err_tbl       IN  VARCHAR2 DEFAULT 'N'
                            ,p_purge_log_tbl     IN  VARCHAR2 DEFAULT 'N'
                            ,p_purge_retain_days IN  NUMBER   DEFAULT NULL
                            ,p_debug_flag        IN  VARCHAR2 DEFAULT 'N'
                            )

   IS

         ln_lines_cnt   NUMBER := 0;
         lc_debug_msg   VARCHAR2(1000);
         lc_debug_prog  VARCHAR2(25) := 'DEBUG_MESSAGE';
         lc_rec_cnt     NUMBER;


   BEGIN

         gc_debug_flg  :=  p_debug_flag;

         IF p_group_id IS NOT NULL THEN

                IF UPPER(p_del_stg_tbl) = 'Y' THEN


                     ---------------------------------------------------
                     -- DELETE records from XX_GL_INTERFACE_NA_STG
                     ---------------------------------------------------

                     BEGIN

                          lc_debug_msg := '    Deleting records from'
                                          ||' XX_GL_INTERFACE_NA_STG'
                                          ||  'p_group_id=> ' || p_group_id;

                          DEBUG_MESSAGE  (lc_debug_msg);

                          -----------------------------
                          -- Record count to be deleted
                          -----------------------------
                          BEGIN

                                SELECT COUNT(1)
                                  INTO lc_rec_cnt
                                  FROM  XX_GL_INTERFACE_NA_STG
                                 WHERE group_id = p_group_id;

                          END;


                          lc_debug_msg := '    Number of records'
                                             ||' to be deleted = '
                                             ||  lc_rec_cnt;

                          DEBUG_MESSAGE  (lc_debug_msg);

                          ----------------
                          --Delete records
                          ----------------
                          BEGIN

                               DELETE XX_GL_INTERFACE_NA_STG
                                WHERE group_id = p_group_id;

                               COMMIT;

                          END;

                          -------------------------
                          --Check number of deletes
                          -------------------------

                          BEGIN

                                SELECT COUNT(1)
                                INTO lc_rec_cnt
                                FROM XX_GL_INTERFACE_NA_STG
                                WHERE group_id = p_group_id;

                          END;

                          IF  lc_rec_cnt <> 0 THEN

                                lc_debug_msg := '    Number of records'
                                                ||' NOT deleted = '
                                                ||  lc_rec_cnt;

                                DEBUG_MESSAGE  (lc_debug_msg);
                          ELSE


                                lc_debug_msg := '    All records where successfully'
                                                ||' deleted for group id '
                                                ||  p_group_id;

                                DEBUG_MESSAGE  (lc_debug_msg);
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


                     END;

                END IF;

                IF UPPER(p_del_err_tbl) = 'Y' THEN

                     -----------------------------------------------------
                     -- DELETE records from XX_GL_INTERFACE_NA_ERROR
                     -----------------------------------------------------

                     BEGIN

                          lc_debug_msg := '    Deleting records from'
                                          ||' XX_GL_INTERFACE_NA_ERROR';

                          DEBUG_MESSAGE  (lc_debug_msg);
                          -----------------------------
                          -- Record count to be deleted
                          -----------------------------
                          BEGIN

                                SELECT COUNT(1)
                                  INTO lc_rec_cnt
                                  FROM  XX_GL_INTERFACE_NA_ERROR
                                 WHERE group_id = p_group_id;

                          END;


                          lc_debug_msg := '    Number of records'
                                             ||' to be deleted = '
                                             ||  lc_rec_cnt;

                          DEBUG_MESSAGE  (lc_debug_msg);



                          -------------------
                          -- Deleting records
                          -------------------

                          DELETE XX_GL_INTERFACE_NA_ERROR
                           WHERE group_id = p_group_id;

                          COMMIT;

                          -------------------------
                          --Check number of deletes
                          -------------------------

                          BEGIN

                                SELECT COUNT(1)
                                INTO lc_rec_cnt
                                FROM XX_GL_INTERFACE_NA_ERROR
                                WHERE group_id = p_group_id;

                          END;

                          IF  lc_rec_cnt <> 0 THEN

                                lc_debug_msg := '    Number of records'
                                                ||' NOT deleted = '
                                                ||  lc_rec_cnt;

                                DEBUG_MESSAGE  (lc_debug_msg);
                          ELSE


                                lc_debug_msg := '    All records where successfully'
                                                ||' deleted for group id '
                                                ||  p_group_id;

                                DEBUG_MESSAGE  (lc_debug_msg);
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
                     END;

                END IF;


         END IF;

        ----------------------------------------------------------------
        -- Purge records from XX_GL_INTERFACE_NA_log, Records will
        -- be need to be at least 6 month or older then sysdate
        ----------------------------------------------------------------

        IF UPPER(p_purge_log_tbl) = 'Y' AND p_purge_retain_days > 181 THEN

            BEGIN

                 lc_debug_msg := '    Purge records from'
                                 ||' XX_GL_INTERFACE_NA_LOG older then '
                                 ||trunc(sysdate - p_purge_retain_days);

                  DEBUG_MESSAGE  (lc_debug_msg);

                  -----------------------------
                  -- Record count to be purged
                  -----------------------------
                  BEGIN

                         SELECT COUNT(1)
                           INTO lc_rec_cnt
                           FROM XX_GL_INTERFACE_NA_LOG
                           WHERE  trunc(to_date(date_time,'DD-MON-YYYY HH24:MI:SS'))
                                       < trunc(sysdate - p_purge_retain_days);

                  END;

                  lc_debug_msg := '    Number of records'
                                    ||' to be purged = '
                                    ||  lc_rec_cnt;

                  DEBUG_MESSAGE  (lc_debug_msg);


                  -----------------
                  --Purging records
                  -----------------
                  DELETE XX_GL_INTERFACE_NA_LOG
                   WHERE  trunc(to_date(date_time,'DD-MON-YYYY HH24:MI:SS'))
                                       < trunc(sysdate - p_purge_retain_days);
                  COMMIT;

                   -------------------------
                   --Check number of deletes
                   -------------------------

                   BEGIN

                         SELECT COUNT(1)
                           INTO lc_rec_cnt
                                FROM XX_GL_INTERFACE_NA_LOG
                                WHERE  trunc(to_date(
                                                    date_time,'DD-MON-YYYY HH24:MI:SS'
                                                    )
                                             ) < trunc(sysdate - p_purge_retain_days);

                          END;

                          IF  lc_rec_cnt <> 0 THEN

                                lc_debug_msg := '    Number of records'
                                                ||' NOT purged = '
                                                ||  lc_rec_cnt;
                                DEBUG_MESSAGE  (lc_debug_msg);
                          ELSE


                                lc_debug_msg := '    Utility was successfully';
                                DEBUG_MESSAGE  (lc_debug_msg);
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

             END;

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


   END TABLE_UTILITY;


-- +===================================================================+
-- | Name  :FORMAT_TABS                                                |
-- | Description : Format utility procedure. Used in CREATE_OUTPUT_FILE|
-- |                                                                   |
-- |                                                                   |
-- | Parameters :p_message (msg written), p_space (# of spaces)        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   FUNCTION FORMAT_TABS (p_tab_total   IN  NUMBER DEFAULT 0 )
    RETURN VARCHAR2

   IS

          ln_tab_cnt     NUMBER := 0;
          lc_tabs        VARCHAR2(1000);
          lc_debug_msg   VARCHAR2(1000);
          lc_debug_prog  VARCHAR2(25) := 'FORMAT_TABS';


   BEGIN
               lc_tabs := ' ';

               LOOP

               EXIT WHEN  ln_tab_cnt = p_tab_total;

                   lc_tabs := lc_tabs || lc_tabs;
                   ln_tab_cnt := ln_tab_cnt + 1;

               END LOOP;

               RETURN lc_tabs;

    EXCEPTION

       WHEN OTHERS THEN

               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                               ||lc_debug_prog);

                lc_debug_msg := fnd_message.get();

                DEBUG_MESSAGE  (lc_debug_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );


   END FORMAT_TABS;

-- +===================================================================+
-- | Name  :EMAIL_OUTPUT                                               |
-- | Description      :  This local procedure will submit concurrent   |
-- |                     program XX_GL_INTERFACE_EMAIL to email        |
-- |                     output file                                   |
-- |                     p_email_lookup is value on tranlation lookup  |
-- |                     Table                                         |
-- |                                                                   |
-- | Parameters : p_request_id, p_email_lookup, p_email_subject        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   x_return_message, x_return_code                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE EMAIL_OUTPUT (x_return_message   OUT VARCHAR2
                          ,x_return_code      OUT VARCHAR2
                          ,p_request_id       IN  NUMBER
                          ,p_email_lookup     IN VARCHAR2
                          ,p_email_subject    IN VARCHAR2
                           )

   IS
         --------------------------
         -- Declare local variables
         --------------------------
         ln_conc_id NUMBER;
         lb_bool    BOOLEAN;
         lc_old_status            VARCHAR2(30);
         lc_phase                 VARCHAR2(100);
         lc_status                VARCHAR2(100);
         lc_dev_phase             VARCHAR2(100);
         lc_dev_status            VARCHAR2(100);
         lc_message               VARCHAR2(100);
         lc_debug_prog            VARCHAR2(100)  := 'EMAIL_OUTPUT';
         lc_translate_name        VARCHAR2(19)   :='GL_INTERFACE_EMAIL';
         ln_cnt                   NUMBER ;
         lc_temp_email            VARCHAR2(2000);
         lc_first_rec             VARCHAR(1);
         lc_debug_msg             VARCHAR2(1000);




         -----------------------------
         --Define temp table of emails
         -----------------------------


         Type TYPE_TAB_EMAIL IS TABLE OF
                 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
                 BY BINARY_INTEGER ;

         EMAIL_TBL TYPE_TAB_EMAIL;



   BEGIN


       FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                 ||  lc_debug_prog );



      ------------------------------------------
      -- Selecting emails from translation table
      ------------------------------------------


       SELECT TV.target_value1
             ,TV.target_value2
             ,TV.target_value3
             ,TV.target_value4
             ,TV.target_value5
             ,TV.target_value6
             ,TV.target_value7
       INTO
              EMAIL_TBL(1)
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
       AND   source_value1    = p_email_lookup;


       ------------------------------------
       --Building string of email addresses
       ------------------------------------

      lc_first_rec  := 'Y';


       For ln_cnt in 1..7 Loop

            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN

                 IF lc_first_rec = 'Y' THEN

                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE

                     lc_temp_email :=  lc_temp_email ||' : ' || EMAIL_TBL(ln_cnt);

                 END IF;

            END IF;

       End loop ;


         lb_bool := fnd_concurrent.wait_for_request(p_request_id
                                                       ,5
                                                       ,5000
                                                       ,lc_phase
                                                       ,lc_status
                                                       ,lc_dev_phase
                                                       ,lc_dev_status
                                                       ,lc_message
                                                   );
--Commented for the defect#9639
/*
         ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXODROEMAILER'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => NULL
                                                ,argument2   => lc_temp_email
                                                ,argument3   => p_email_subject
                                                ,argument4   => NULL
                                                ,argument5   => 'Y'
                                                ,argument6   => p_request_id
                                                         );
*/
--Added the below lines for the defect#9639

/*       IF p_email_lookup = 'OD COGS' THEN

         ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXODCOGSM'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => NULL
                                                ,argument2   => lc_temp_email
                                                ,argument3   => p_email_subject
                                                ,argument4   => NULL
                                                ,argument5   => 'Y'
                                                ,argument6   => p_request_id
                                                         );
          COMMIT;

        ELSE
 */

         ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXODROEMAILER'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => NULL
                                                ,argument2   => lc_temp_email
                                                ,argument3   => p_email_subject
                                                ,argument4   => NULL
                                                ,argument5   => 'Y'
                                                ,argument6   => p_request_id
                                                         );
          COMMIT;

--        END IF;



         EXCEPTION

           WHEN OTHERS THEN

               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                               ||lc_debug_prog);

                lc_debug_msg := fnd_message.get();

                DEBUG_MESSAGE  (lc_debug_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );


   END EMAIL_OUTPUT;

-- +===================================================================+
-- | Name  :LOG_MESSAGE                                                |
-- | Description :  This procedure will be used to write record to the |
-- |                xx_gl_interface_na_log table.                      |
-- |                                                                   |
-- | Parameters : p_grp_id,p_source_nm,p_status,p_date_time,p_details  |
-- |              p_request_id                                         |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE  LOG_MESSAGE (p_grp_id         IN NUMBER   DEFAULT NULL
                           ,p_source_nm      IN VARCHAR2 DEFAULT NULL
                           ,p_status         IN VARCHAR2 DEFAULT NULL
                           ,p_details        IN VARCHAR2 DEFAULT NULL
                           ,p_debug_flag     IN VARCHAR2 DEFAULT NULL
                            )
     IS
           lc_debug_prog     VARCHAR2(12) := 'LOG_MESSAGE';
           ln_request_id     NUMBER := FND_GLOBAL.CONC_REQUEST_ID();
           x_output_msg      VARCHAR2(2000);
           lc_debug_msg      VARCHAR2(2000);
           lc_date           VARCHAR2(25);


     BEGIN
           FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                     ||  lc_debug_prog );



           IF p_debug_flag IS NOT NULL THEN

                 gc_debug_flg := p_debug_flag;

           END IF;


            SELECT to_char(sysdate,'DD-MON-YYYY HH24:MI:SS')
            INTO lc_date
            FROM DUAL;



          lc_debug_msg     := '    Inside log_message  gn_group_id=> '
                            ||p_grp_id
                            ||' gc_source_name=> '|| p_source_nm
                            || ' p_status => ' || p_status
                            || ' p_details => ' || p_details;



           DEBUG_MESSAGE (lc_debug_msg);



            BEGIN

                 INSERT INTO XX_GL_INTERFACE_NA_LOG
                         (group_id
                         ,source_name
                         ,status
                         ,request_id
                         ,date_time
                         ,details)
                   VALUES
                        (p_grp_id
                        ,p_source_nm
                        ,p_status
                        ,ln_request_id
                        ,lc_date
                        ,p_details );

                  COMMIT;
             END;

        EXCEPTION

           WHEN OTHERS THEN
               x_output_msg  := 'insert into log file'|| SQLERRM;
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);

                lc_debug_msg := fnd_message.get();

                DEBUG_MESSAGE  (lc_debug_msg);
                FND_FILE.PUT_LINE(FND_FILE.LOG, lc_debug_msg );

     END LOG_MESSAGE;



-- +===================================================================+
-- | Name  :CREATE_OUTPUT_FILE                                         |
-- | Description : This procedure will be used to format data written  |
-- |               to the ouput file for email reports prt_cntrl_flag  |
-- |               can be set to (HEADER,BODY, TRAILER)                |
-- | Parameters : p_group_id, p_sob_id, p_batch_name, p_total_dr       |
-- |              p_total_cr, prt_cntrl_flag|                          |
-- | Returns :                                                         |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE  CREATE_OUTPUT_FILE(p_group_id       IN NUMBER   DEFAULT NULL
                                 ,p_sob_id         IN NUMBER   DEFAULT NULL
                                 ,p_batch_name     IN VARCHAR2 DEFAULT NULL
                                 ,p_batch_desc     IN VARCHAR2 DEFAULT NULL
                                 ,p_total_dr       IN NUMBER   DEFAULT NULL
                                 ,p_total_cr       IN NUMBER   DEFAULT NULL
                                 ,p_source_name    IN VARCHAR2 DEFAULT NULL
                                 ,p_intrfc_transfr IN VARCHAR2 DEFAULT NULL
                                 ,p_submit_import  IN VARCHAR2 DEFAULT NULL
                                 ,p_import_stat    IN VARCHAR2 DEFAULT NULL
                                 ,p_import_req_id  IN NUMBER   DEFAULT NULL
                                 ,p_cntrl_flag     IN VARCHAR2
                                 )
     IS
           lc_debug_prog   VARCHAR2(18) := 'CREATE_OUTPUT_FILE';
            lc_debug_msg   VARCHAR2(1000);

           ln_request_id       NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();
           ln_group_len        NUMBER;
           ln_sob_len          NUMBER;
           ln_batch_len        NUMBER;
           ln_dr_len           NUMBER;
           ln_cr_len           NUMBER;
           ln_balance_cnt      NUMBER;
           ln_total_jrl_cnt    NUMBER;
           lc_balance_err      VARCHAR2(3);
           lc_type             XX_GL_INTERFACE_NA_ERROR.type%TYPE;
           lc_details          XX_GL_INTERFACE_NA_ERROR.details%TYPE;
           ln_derived_cnt      NUMBER;
           ln_derived_cnt_len  NUMBER;
           ln_total_err_cnt    NUMBER;
           ln_intcomp_bal_cnt  NUMBER;

           ln_cnt              NUMBER ;
           lc_temp_email       VARCHAR2(2000);
           lc_first_rec        VARCHAR(1);
           lc_translate_name   VARCHAR2(18)   :='GL_INTERFACE_EMAIL';

           lc_display_grp_id     XX_GL_INTERFACE_NA_STG.group_id%TYPE;
           lc_display_sob_id     XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
           lc_display_bat_nm     XX_GL_INTERFACE_NA_STG.reference1%TYPE;
           ln_display_tot_dr     XX_GL_INTERFACE_NA_STG.entered_cr%TYPE;
           ln_display_tot_cr     XX_GL_INTERFACE_NA_STG.entered_dr%TYPE;

           -----------------------------------------
           -- Cursor to summarize all derived errors
           -----------------------------------------
           CURSOR SUM_DERVIED_ERRORS IS
               SELECT details
                     ,type
                     ,count(*)
                 FROM  XX_GL_INTERFACE_NA_ERROR
                WHERE source_name = p_source_name
                  AND  group_id    = p_group_id
                  AND  FND_ERROR_CODE <> 'XX_GL_INTERFACE_BAL_ERR'
             GROUP BY details, TYPE
             ORDER BY details;


           -----------------------------------------
           -- Cursor to summarize all balance errors
           -----------------------------------------
           CURSOR SUM_BALANCE_ERRORS IS
               SELECT details
                     ,type
                     ,count(*)
                 FROM  XX_GL_INTERFACE_NA_ERROR
                WHERE source_name = p_source_name
                  AND  group_id    = p_group_id
                  AND  FND_ERROR_CODE = 'XX_GL_INTERFACE_BAL_ERR'
             GROUP BY details, TYPE
             ORDER BY details;



         -----------------------------
         --Define temp table of emails
         -----------------------------
         Type TYPE_TAB_EMAIL IS TABLE OF
                 XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX
                 BY BINARY_INTEGER ;

         EMAIL_TBL TYPE_TAB_EMAIL;


     BEGIN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                     ||  lc_debug_prog );

           gn_request_id := ln_request_id;

           ------------------------
           -- Create header records
           ------------------------

           IF p_cntrl_flag = 'HEADER' THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'p_source_name=> '||  p_source_name );

               BEGIN
                    ------------------------------------------
                    -- Selecting emails from translation table
                    ------------------------------------------
                    SELECT TV.target_value1
                          ,TV.target_value2
                          ,TV.target_value3
                          ,TV.target_value4
                          ,TV.target_value5
                          ,TV.target_value6
                          ,TV.target_value7
                    INTO
                           EMAIL_TBL(1)
                          ,EMAIL_TBL(2)
                          ,EMAIL_TBL(3)
                          ,EMAIL_TBL(4)
                          ,EMAIL_TBL(5)
                          ,EMAIL_TBL(6)
                          ,EMAIL_TBL(7)
                    FROM  XX_FIN_TRANSLATEVALUES TV
                         ,XX_FIN_TRANSLATEDEFINITION TD
                   WHERE TV.TRANSLATE_ID    = TD.TRANSLATE_ID
                   AND     TRANSLATION_NAME = lc_translate_name
                   AND     source_value1    = p_source_name;

               EXCEPTION
                    WHEN NO_DATA_FOUND THEN

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Emails are not being sent!!! '
                                                    || 'Mail needs to be setup in '
                                                    || 'Translation definition '
                                                    || ': GL_INTERFACE_EMAIL');

               END;

               ------------------------------------
               --Building string of email addresses
               ------------------------------------

               lc_first_rec  := 'Y';

               For ln_cnt in 1..7 Loop

                    IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN

                        IF lc_first_rec = 'Y' THEN

                           lc_temp_email :=  EMAIL_TBL(ln_cnt);
                           lc_first_rec := 'N';
                        ELSE

                           lc_temp_email :=  lc_temp_email
                                             ||' , ' || EMAIL_TBL(ln_cnt);

                        END IF;

                    END IF;

               END LOOP;
               ---------------------
               -- set global email
               ----------------------
               gc_mail_addresses  := lc_temp_email;

--Commented for the defect#9639
/*
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                               ||FORMAT_TABS(4)
                                               ||'OD GL Journal Interface Report'
                                               ||FORMAT_TABS(4)||'Report Date: '
                                               ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));


               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| ln_request_id);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Entry Source Name = '||RTRIM(p_source_name));
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error Notification Sent to : '|| gc_mail_addresses);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
*/
--Added the below line for the defect#9639

               IF p_source_name <> 'OD COGS' THEN

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OFFICE DEPOT, INC'
                                               ||FORMAT_TABS(4)
                                               ||'OD GL Journal Interface Report'
                                               ||FORMAT_TABS(4)||'Report Date: '
                                               ||to_char(sysdate,'DD-MON-YYYY HH24:MI'));


               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Request ID: '|| ln_request_id);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Entry Source Name = '||RTRIM(p_source_name));
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Error Notification Sent to : '|| gc_mail_addresses);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

               END IF;

             -----------------------------------------
             --Code changes for the defect#8705 begins
             -----------------------------------------

               IF p_source_name = 'OD COGS' THEN

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=========================================================================================================================');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

               END IF;

             -----------------------------------------
             --Code changes for the defect#8705 ends
             -----------------------------------------

           ELSIF p_cntrl_flag = 'BODYHEAD' THEN

               DEBUG_MESSAGE  (lc_debug_msg);

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Source File Name: '||gc_file_name );


               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, SUBSTR(RPAD('Group ID',15),1,15)
                               ||' '|| SUBSTR(RPAD('Set of Books',15),1,15)
                               ||' '|| SUBSTR(RPAD('Batch Name',50),1,50)
                               ||' '|| SUBSTR(RPAD('Total Debit',25),1,25)
                               ||' '|| SUBSTR(RPAD('Total Credit',25),1,25));

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,SUBSTR(RPAD('--------',15),1,15)
                               ||' '|| SUBSTR(RPAD('------------',15),1,15)
                               ||' '|| SUBSTR(RPAD('----------',50),1,50)
                               ||' '|| SUBSTR(RPAD('-----------',25),1,25)
                               ||' '|| SUBSTR(RPAD('-----------',25),1,25));




            ELSIF p_cntrl_flag = 'BODY' THEN
               lc_debug_msg := '    Writing body records.';



               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, SUBSTR(RPAD(NVL(TO_CHAR(p_group_id)  ,'n/a'),15),1,15)
                             ||' '||SUBSTR(RPAD(NVL(TO_CHAR(p_sob_id)    ,'n/a'),15),1,15)
                             ||' '||SUBSTR(RPAD(NVL(TO_CHAR(p_batch_name),'n/a'),50),1,50)
                             ||' '||RPAD(LTRIM(SUBSTR(NVL(TO_CHAR(p_total_dr,'999999999999.99'),0),1,25)),25)
                             ||' '||LTRIM(NVL(TO_CHAR(p_total_cr,'999999999999.99'),0)));


            ELSE

                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');


                  lc_debug_msg := '    Writing trailer records.'||'p_source_name=>'|| p_source_name
                                                                ||'p_group_id=>'   || p_group_id
                                                                || 'p_sob_id=>'    || p_sob_id;
                  DEBUG_MESSAGE  (lc_debug_msg);

                  -----------------------------------------------
                  -- Checking error table for balance error count
                  -----------------------------------------------
                  lc_debug_msg := '    Checking balance errors';

                  DEBUG_MESSAGE  (lc_debug_msg);

                  BEGIN

                      SELECT  count(1)
                        INTO  ln_balance_cnt
                        FROM  XX_GL_INTERFACE_NA_ERROR GLE
                       WHERE  GLE.source_name      = p_source_name
                         AND  GLE.group_id         = p_group_id
                         AND  GLE.set_of_books_id  = p_sob_id
                         AND  TYPE = 'Balance';

                  END;


                  -----------------------------------------------
                  -- Checking error table for intercomapany jrnls
                  -----------------------------------------------
                  lc_debug_msg := '    Checking intercomapany count';

                  DEBUG_MESSAGE  (lc_debug_msg);

                  BEGIN

                      SELECT  count(1)
                        INTO  ln_intcomp_bal_cnt
                        FROM  XX_GL_INTERFACE_NA_STG
                       WHERE  user_je_source_name = p_source_name
                         AND  group_id            = p_group_id
                         AND  set_of_books_id      = p_sob_id
                         AND  derived_sob = 'INTER-COMP';

                  END;

                  -----------------------------------------------
                  -- Checking error table for dervied error count
                  -----------------------------------------------
                  lc_debug_msg := '    Checking dervied errors';

                  DEBUG_MESSAGE  (lc_debug_msg);

                  BEGIN

                      SELECT  count(1)
                        INTO  ln_total_err_cnt
                        FROM  XX_GL_INTERFACE_NA_ERROR
                       WHERE  source_name          = p_source_name
                         AND  group_id             = p_group_id
                         AND  TYPE <> 'Balance';

                  END;

                  ---------------------------------------------
                  -- Checking error table for Total error count
                  ---------------------------------------------
                  lc_debug_msg := '    Checking Total error count.';

                  DEBUG_MESSAGE  (lc_debug_msg);

                  BEGIN
                      SELECT  count(1)
                        INTO  ln_total_jrl_cnt
                        FROM  XX_GL_INTERFACE_NA_STG
                       WHERE  user_je_source_name = p_source_name
                         AND  set_of_books_id     = p_sob_id
                         AND  group_id            = p_group_id ;


                  END;


                  IF ln_balance_cnt > 0 THEN

                     lc_balance_err := 'NO';


                  ELSE

                      lc_balance_err := 'YES';

                  END IF;

   IF p_source_name = 'OD COGS' THEN
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal balanced by Set of '
                                                     ||'Book and Accounting Date:   '
                                                     ||FORMAT_TABS(4)
                                                     || lc_balance_err);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Journal Lines in '
                                                     ||'GL interface Staging Table: '
                                                     ||FORMAT_TABS(4)
                                                     || ln_total_jrl_cnt);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Intercompany Journals '
                                                     ||'created in  interface Staging Table:   '
                                                     ||ln_intcomp_bal_cnt);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Journals Entry errors:       '
                                                     ||FORMAT_TABS(5)
                                                     ||ln_total_err_cnt);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total debit for the Valid records in the Staging table for '
                                                      ||p_source_name  ||' for group id ' ||p_group_id || ' is : ' ||
                                                      ln_v_dr_amt);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total credit for the Valid records in the Staging table for '
                                                      ||p_source_name  ||' for group id ' ||p_group_id || ' is : ' ||
                                                      ln_v_cr_amt);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total debit for the Invalid records deleted from Staging table for '
                                                      ||p_source_name  ||' for group id ' ||p_group_id || ' is : ' ||
                                                      ln_in_dr_amt);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total credit for the Invalid records deleted from Staging table for '
                                                      ||p_source_name  ||' for group id ' ||p_group_id || ' is : ' ||
                                                      ln_in_cr_amt);

                  --Changed 'No' to 'Number' for the defect#8705
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Invalid records deleted from Staging table for '
                                                      ||p_source_name ||' for group id ' ||p_group_id ||  ' is : ' ||
                                                      ln_del_rec );


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');



               --------------------------------------
               --Summarize derived and balance errors
               --------------------------------------

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number Of Records'||FORMAT_TABS(3)
                                                                    ||'Error Description' );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------'||FORMAT_TABS(3)
                                                                    ||'-----------------');

               OPEN SUM_DERVIED_ERRORS;
               LOOP
                    FETCH SUM_DERVIED_ERRORS INTO
                              lc_details
                             ,lc_type
                             ,ln_derived_cnt;

                    EXIT WHEN SUM_DERVIED_ERRORS%NOTFOUND;


                   ln_derived_cnt_len  :=  LENGTH(TO_CHAR(ln_derived_cnt));
                   ln_derived_cnt_len  :=  10 - ln_derived_cnt_len ;

                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FORMAT_TABS(2)
                                                      || ln_derived_cnt
                                                      ||FORMAT_TABS(4)
                                                      ||RPAD(' ',ln_derived_cnt_len)
                                                      ||lc_details);

               END LOOP;
               CLOSE SUM_DERVIED_ERRORS;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');


                  ------------------------------
                  -- Tracking status for process
                  ------------------------------

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Transferred Journals to GL Interface Table : '
                                                     ||FORMAT_TABS(5)
                                                     ||p_intrfc_transfr);

                  --Comented the below lines for the defect#9639
/*
                --Added the below output message for the defect#8705

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submitted Journal Import :                   '
                                                     ||FORMAT_TABS(5)
                                                     ||p_submit_import);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID :                  '
                                                     ||FORMAT_TABS(5)
                                                     ||gn_import_request_id );
*/
                  --Uncomented the below lines for the defect#9639

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submitted Journal Import :                   '
                                                     ||FORMAT_TABS(5)
                                                     ||p_submit_import);

                  --Comented the below lines for the defect#9639
/*
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status :                      '
                                                     ||FORMAT_TABS(5)
                                                     ||p_import_stat );
*/
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID :                  '
                                                     ||FORMAT_TABS(5)
                                                     ||p_import_req_id );


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

                  -----------------------------------------
                  --Code changes for the defect#8705 begins
                  -----------------------------------------

               IF p_source_name = 'OD COGS' THEN

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'=========================================================================================================================');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');

               END IF;

                  -----------------------------------------
                  --Code changes for the defect#8705 ends
                  -----------------------------------------

        ELSE

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal balanced by Set of '
                                                     ||'Book and Accounting Date:   '
                                                     ||FORMAT_TABS(4)
                                                     || lc_balance_err);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Journal Lines in '
                                                     ||'GL interface Staging Table: '
                                                     ||FORMAT_TABS(4)
                                                     || ln_total_jrl_cnt);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Intercompany Journals '
                                                     ||'created in  interface Staging Table:   '
                                                     ||ln_intcomp_bal_cnt);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number of Journals Entry errors:       '
                                                     ||FORMAT_TABS(5)
                                                     ||ln_total_err_cnt);


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');



               --------------------------------------
               --Summarize derived and balance errors
               --------------------------------------

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Number Of Records'||FORMAT_TABS(3)
                                                                    ||'Error Description' );

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'-----------------'||FORMAT_TABS(3)
                                                                    ||'-----------------');

               OPEN SUM_DERVIED_ERRORS;
               LOOP
                    FETCH SUM_DERVIED_ERRORS INTO
                              lc_details
                             ,lc_type
                             ,ln_derived_cnt;

                    EXIT WHEN SUM_DERVIED_ERRORS%NOTFOUND;


                   ln_derived_cnt_len  :=  LENGTH(TO_CHAR(ln_derived_cnt));
                   ln_derived_cnt_len  :=  10 - ln_derived_cnt_len ;

                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,FORMAT_TABS(2)
                                                      || ln_derived_cnt
                                                      ||FORMAT_TABS(4)
                                                      ||RPAD(' ',ln_derived_cnt_len)
                                                      ||lc_details);

               END LOOP;
               CLOSE SUM_DERVIED_ERRORS;

               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');


                  ------------------------------
                  -- Tracking status for process
                  ------------------------------

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Transferred Journals to GL Interface Table : '
                                                     ||FORMAT_TABS(5)
                                                     ||p_intrfc_transfr);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Submitted Journal Import :                   '
                                                     ||FORMAT_TABS(5)
                                                     ||p_submit_import);

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Status :                      '
                                                     ||FORMAT_TABS(5)
                                                     ||p_import_stat );


                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Journal Import Request ID :                  '
                                                     ||FORMAT_TABS(5)
                                                     ||p_import_req_id );

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
END IF;

            END IF;

     EXCEPTION
            WHEN OTHERS THEN

                 fnd_message.clear();
                 fnd_message.set_name('FND','FS-UNKNOWN');
                 fnd_message.set_token('ERROR',SQLERRM);
                 fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                ||lc_debug_prog);

                 FND_FILE.PUT_LINE(FND_FILE.LOG,fnd_message.get );


     END CREATE_OUTPUT_FILE;



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
                            ,p_sob_id        IN  NUMBER
                           )
    IS
        UPDATE_ERR      EXCEPTION;

        lc_detail_err   VARCHAR2(2000);
        lc_debug_msg    VARCHAR2(500);
        lc_debug_prog   VARCHAR2(15) := 'PROCESS_ERROR';



         BEGIN

              FND_FILE.PUT_LINE(FND_FILE.LOG,'' );

              FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                        ||  lc_debug_prog ||'!!!!!!!!!!!');

              -- intialize variables

              lc_debug_msg := 'Creating FND Message';
              lc_detail_err := p_details;

              IF p_fnd_message = 'XX_GL_INTERFACE_SOBID_ERROR' OR
                 p_fnd_message = 'XX_GL_INTERFACE_VALUE_ERROR' OR
                 p_fnd_message = 'XX_GL_INTERFACE_INTRCOMP_ERR' OR
                  p_fnd_message = 'XX_GL_TRANS_VALUE_ERROR' THEN

                  -- Create FND message.
                 fnd_message.clear();
                 fnd_message.set_name('XXFIN',p_fnd_message);
                 fnd_message.set_token('TYPE',p_type );
                 fnd_message.set_token('VALUE',p_value);
                 lc_detail_err := fnd_message.get;
              END IF;


               BEGIN



                   INSERT INTO XX_GL_INTERFACE_NA_ERROR
                                               (
                                                fnd_error_code
                                               ,source_name
                                               ,details
                                               ,type
                                               ,value
                                               ,group_id
                                               ,set_of_books_id
                                               ,creation_date
											   ,ledger_id --V3.5
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
												,p_sob_id --V3.5
                                                 );

                   COMMIT;

               EXCEPTION
                    WHEN OTHERS THEN

                         fnd_message.clear();
                         fnd_message.set_name('FND','FS-UNKNOWN');
                         fnd_message.set_token('ERROR',SQLERRM);
                         fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                ||lc_debug_prog
                                                ||lc_debug_msg
                                               );

                         fnd_file.put_line(fnd_file.log,fnd_message.get);


               END;

              ----------------------------------
              --update records to invalid status
              ----------------------------------

              IF p_fnd_message = 'XX_GL_INTERFACE_VALUE_ERROR' THEN

                    lc_debug_msg := 'Updating XX_GL_INTERFACE_NA_STG' ||
                                    ' with derived_val = INVALID, ROWID = ' ||
                                      p_rowid;

                    BEGIN
                          UPDATE XX_GL_INTERFACE_NA_STG
                          SET    derived_val = 'INVALID'
                          WHERE  rowid       =  p_rowid;

                          COMMIT;

                    EXCEPTION
                         WHEN OTHERS THEN
                              RAISE UPDATE_ERR;
                    END;

              END IF;

              IF p_fnd_message = 'XX_GL_TRANS_VALUE_ERROR' THEN

                    lc_debug_msg := 'Updating XX_GL_INTERFACE_NA_STG' ||
                                    ' with derived_val = INVALID, ROWID = ' ||
                                      p_rowid;

                    BEGIN
                          UPDATE XX_GL_INTERFACE_NA_STG
                          SET    derived_val = 'INVALID'
                          WHERE  rowid       =  p_rowid;

                          COMMIT;

                    EXCEPTION
                         WHEN OTHERS THEN
                              RAISE UPDATE_ERR;
                    END;

              END IF;

              IF p_fnd_message = 'XX_GL_INTERFACE_SOBID_ERROR' THEN

                    lc_debug_msg := 'Updating XX_GL_INTERFACE_NA_STG' ||
                                    ' with derived_SOB = INVALID, ROWID = ' ||
                                      p_rowid;

                    BEGIN
                           UPDATE XX_GL_INTERFACE_NA_STG
                           SET    derived_sob = 'INVALID'
                           WHERE  rowid       =  p_rowid;

                           COMMIT;

                    EXCEPTION
                         WHEN OTHERS THEN
                              RAISE UPDATE_ERR;
                    END;

              END IF;



            IF p_fnd_message = 'XX_GL_INTERFACE_INTRCOMP_ERR' THEN

                IF   p_value = 'derived' THEN

                    lc_debug_msg := '    Updating XX_GL_INTERFACE_NA_STG' ||
                                        ' with derived_val = INVALID, ROWID = ' ||
                                          p_rowid;

                    DEBUG_MESSAGE  (lc_debug_msg);

                    BEGIN
                          UPDATE XX_GL_INTERFACE_NA_STG
                          SET    derived_sob = 'INTER-COMP'
                                ,derived_val = 'INVALID'
                          WHERE  rowid       =  p_rowid;

                          COMMIT;

                    EXCEPTION
                         WHEN OTHERS THEN
                              RAISE UPDATE_ERR;
                    END;
                ELSE

                    lc_debug_msg := '    Updating XX_GL_INTERFACE_NA_STG' ||
                                     ' with Intercompany not created, ROWID = ' ||
                                        p_rowid;

                    DEBUG_MESSAGE  (lc_debug_msg);

                    BEGIN
                          UPDATE XX_GL_INTERFACE_NA_STG
                          SET    derived_sob = 'INTER-COMP'
                                ,balanced    = 'NOT-CREATED'
                          WHERE  rowid       =  p_rowid;

                          COMMIT;

                    EXCEPTION
                         WHEN OTHERS THEN
                              RAISE UPDATE_ERR;
                    END;

                END IF;




            END IF;

         EXCEPTION

              WHEN UPDATE_ERR THEN

                  fnd_message.clear();
                  fnd_message.set_name('FND','FS-UNKNOWN');
                  fnd_message.set_token('ERROR',SQLERRM);
                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm ||lc_debug_prog ||
                                                  lc_debug_msg
                                     );

                   fnd_file.put_line(fnd_file.log,fnd_message.get());

              WHEN OTHERS THEN

                  fnd_message.clear();
                  fnd_message.set_name('FND','FS-UNKNOWN');
                  fnd_message.set_token('ERROR',SQLERRM);
                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm ||lc_debug_prog ||
                                                  lc_debug_msg
                                     );


                  fnd_file.put_line(fnd_file.log,fnd_message.get());

    END PROCESS_ERROR;


-- +===================================================================+
-- | Name  : UPDATE_SET_OF_BOOKS_ID                                    |
-- | Description      : Call this procedure to update all the set of   |
-- |                    books IDs based on a group_id. This prodecure  |
-- |                    can be used by all interfaces                  |
-- |                                                                   |
-- | Parameters :p_group_id                                            |
-- |                                                                   |
-- |                                                                   |
-- | Returns : x_return_err_cnt, x_return_message                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

  PROCEDURE UPDATE_SET_OF_BOOKS_ID (p_group_id          IN  VARCHAR2
                                   ,x_return_err_cnt    OUT NUMBER
                                   ,x_return_message    OUT VARCHAR2
                                   )
  IS


          lc_debug_msg       VARCHAR2(250);
          lc_debug_prog      VARCHAR2(22) := 'UPDATE_SET_OF_BOOKS_ID';


          --local variables for get_je_lines_cursor
          ln_row_id          rowid;
          ln_group_id        XX_GL_INTERFACE_NA_STG.group_id%TYPE;
          lc_derived_sob     XX_GL_INTERFACE_NA_STG.derived_sob%TYPE;
          lc_ora_company     XX_GL_INTERFACE_NA_STG.segment1%TYPE;
          ln_sobid           XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
          lc_je_source_name  XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;

          counter  NUMBER := 0;


          CURSOR get_sob_cursor IS
          SELECT  rowid
                 ,group_id
                 ,user_je_source_name
                 ,derived_sob
                 ,segment1
            FROM  XX_GL_INTERFACE_NA_STG
           WHERE group_id                    =  p_group_id
            AND  (NVL(derived_sob,'INVALID') = 'INVALID'
                  OR NVL(derived_sob,'INTER-COMP') = 'INTER-COMP');

  BEGIN

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                  ||  lc_debug_prog );

       SELECT COUNT(*) INTO counter
        FROM  XX_GL_INTERFACE_NA_STG
           WHERE group_id                    =  p_group_id
            AND  (NVL(derived_sob,'INVALID') = 'INVALID'
                  OR NVL(derived_sob,'INTER-COMP') = 'INTER-COMP');



         lc_debug_msg := '    Calling:  X_GL_TRANSLATE_UTL_PKG.'
                              ||'DERIVE_SOBID_FROM_COMPANY ';
         DEBUG_MESSAGE  (lc_debug_msg,1);



         x_return_err_cnt := 0;

             lc_debug_msg := '    Open get_sob_cursor ';
             DEBUG_MESSAGE  (lc_debug_msg);

        OPEN get_sob_cursor;
        LOOP

             FETCH get_sob_cursor INTO
                           ln_row_id
                          ,ln_group_id
                          ,lc_je_source_name
                          ,lc_derived_sob
                          ,lc_ora_company;

             EXIT WHEN get_sob_cursor%NOTFOUND;


             ----------------------------
             --  Derive set of books id
             ----------------------------

            -- IF NVL(lc_derived_sob, 'INVALID') = 'INVALID' THEN


                  BEGIN



                      ln_sobid := XX_GL_TRANSLATE_UTL_PKG.DERIVE_SOBID_FROM_COMPANY
                                                                   (lc_ora_company);


                      IF ln_sobid IS NULL THEN
                 ---- Added by Raji 29/feb/08
                      BEGIN
                       UPDATE XX_GL_INTERFACE_NA_STG
                       sET    derived_sob     = 'INVALID'
                      WHERE  rowid           = ln_row_id;


                             COMMIT;


                        EXCEPTION

                              WHEN OTHERS THEN

                                    fnd_message.clear();
                                    fnd_message.set_name('FND','FS-UNKNOWN');
                                    fnd_message.set_token('ERROR',SQLERRM);
                                    fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                            ||lc_debug_prog
                                                            ||lc_debug_msg
                                                         );

                                   fnd_file.put_line(fnd_file.log,fnd_message.get());

                        END;

                             PROCESS_ERROR (p_rowid       =>  ln_row_id
                                           ,p_fnd_message =>  'XX_GL_INTERFACE_SOBID_ERROR'
                                           ,p_source_nm     =>  lc_je_source_name
                                           ,p_type        =>  'Set of Books ID'
                                           ,p_value       =>  lc_ora_company
                                           ,p_details     =>  lc_debug_msg
                                           ,p_group_id    =>  ln_group_id
                                           );

                          -- Add count of total errors
                          x_return_err_cnt   :=  x_return_err_cnt + 1;

                          lc_debug_msg := '    SOB ID not updated on '
                                              ||' XX_GL_INTERFACE_NA_STG'
                                              ||' for RoWID = ' || ln_row_id;
                          DEBUG_MESSAGE  (lc_debug_msg);

                       END IF;

                  END;


                  IF ln_sobid IS NOT NULL THEN

                        BEGIN

                             UPDATE XX_GL_INTERFACE_NA_STG
                             sET    set_of_books_id = ln_sobid
                                   ,derived_sob     = DECODE(lc_derived_sob
                                                             ,'INTER-COMP',lc_derived_sob
                                                             ,'VALID')
                             WHERE  rowid           = ln_row_id;


                             COMMIT;


                        EXCEPTION

                              WHEN OTHERS THEN

                                    fnd_message.clear();
                                    fnd_message.set_name('FND','FS-UNKNOWN');
                                    fnd_message.set_token('ERROR',SQLERRM);
                                    fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                            ||lc_debug_prog
                                                            ||lc_debug_msg
                                                         );

                                   fnd_file.put_line(fnd_file.log,fnd_message.get());

                        END;

                    END IF;


         END LOOP;
         CLOSE get_sob_cursor;

  EXCEPTION

       WHEN NO_DATA_FOUND THEN

               PROCESS_ERROR (p_rowid       =>  ln_row_id
                             ,p_fnd_message =>  'XX_GL_INTERFACE_SOBID_ERROR'
                             ,p_source_nm     =>  lc_je_source_name
                             ,p_type        =>  'Set of Books ID'
                             ,p_value       =>  lc_ora_company
                             ,p_details     =>  lc_debug_msg
                             ,p_group_id    =>  ln_group_id
                             );

                  -- Add count of total errors
                  x_return_err_cnt   :=  x_return_err_cnt + 1;

                  lc_debug_msg := '    SOB ID not updated on '
                                  ||' XX_GL_INTERFACE_NA_STG'
                                  ||' for RoWID = ' || ln_row_id;
                  DEBUG_MESSAGE  (lc_debug_msg);


        WHEN OTHERS THEN

               fnd_message.clear();
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                      ||lc_debug_prog
                                      ||lc_debug_msg
                                    );

               fnd_file.put_line(fnd_file.log,fnd_message.get());



  END UPDATE_SET_OF_BOOKS_ID;


-- +===================================================================+
-- | Name  : CHECK_BALANCES                                            |
-- | Description : Procedure to check that journal entry balance by    |                                                                |
-- |               SOB, GroupId, source, Currency, Category, Acct date |
-- |               gc_import_crtl = 'N' is set to balance by group_id  |
-- |               or gc_import_crtl = 'Y' to balance by  group_id, sob|
-- |               batch name, currency and accounting date            |
-- |                                                                   |
-- | Parameters : p_group_id                                           |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   x_return_message                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
     PROCEDURE CHECK_BALANCES (  p_group_id          IN  VARCHAR2
                                ,p_sob_id            IN  VARCHAR2
                                ,p_batch_name        IN  VARCHAR2
                                ,x_return_message    OUT VARCHAR2
                              )
     IS

         lc_batch_name  XX_GL_INTERFACE_NA_STG.reference1%TYPE;
         ln_entered_cr  XX_GL_INTERFACE_NA_STG.entered_cr%TYPE;
         ln_entered_dr  XX_GL_INTERFACE_NA_STG.entered_dr%TYPE;
         ln_cr_dr_sum   NUMBER;
         ln_group_id    XX_GL_INTERFACE_NA_STG.group_id%TYPE;
         ln_sob_id      XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
         lc_source_nm   XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
         lc_curr_code   XX_GL_INTERFACE_NA_STG.currency_code%TYPE;
         lc_category_nm XX_GL_INTERFACE_NA_STG.user_je_category_name%TYPE;
         ld_acct_date   XX_GL_INTERFACE_NA_STG.accounting_date%TYPE;
         lc_balance_flg VARCHAR2(1);


         lc_debug_prog  VARCHAR2(100) := 'CHECK_BALANCES';
         lc_debug_msg   VARCHAR2(500);
         lc_detail_err  VARCHAR2(1000);
         lc_fnd_message VARCHAR2(23)   := 'XX_GL_INTERFACE_BAL_ERR';


           ----------------------------------------
           -- cursor used when gc_import_crtl = 'Y'
           ----------------------------------------
           CURSOR balance_cursor_by_sob
           IS    SELECT  SUM(entered_dr)
                        ,SUM(entered_cr)
                        ,SUM(entered_dr) - SUM(entered_cr)
                        ,group_id
                        ,set_of_books_id
                        ,user_je_source_name
                        ,reference1
                        ,currency_code
                        ,user_je_category_name
                        ,accounting_date
                  FROM   XX_GL_INTERFACE_NA_STG
                 WHERE  group_id        = p_group_id
                   AND  set_of_books_id = NVL(p_sob_id,0)
                   AND  reference1      = p_batch_name
               GROUP BY set_of_books_id
                       ,group_id
                       ,user_je_source_name
                       ,currency_code
                       ,user_je_category_name
                       ,reference1
                       ,accounting_date;


     BEGIN

	 fnd_file.put_line(fnd_file.log,'Started inside the check balances');
            DEBUG_MESSAGE  (' ');
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                      ||  lc_debug_prog );

            ---------------------------------------------------------------
            -- gc_import_crtl = 'N' is set to balance by group_id
            -- or gc_import_crtl = 'Y' to balance by  group_id, sob,
            -- batch name, currency and accounting date
            ---------------------------------------------------------------
            IF gc_import_ctrl = 'N' THEN

                 lc_debug_msg := '    Balance checking by group_id ';
                 DEBUG_MESSAGE  (lc_debug_msg);

  ------Added for defect 4686 and 4652
                 lc_balance_flg  := 'N';

                 BEGIN
                      --   XX_GL_GLSI_INTERFACE_PKG.CREATE_SUSPENSE_LINES(p_group_id);
                     SELECT   SUM(entered_dr)
                             ,SUM(entered_cr)
                             ,SUM(entered_dr) - SUM(entered_cr)
                     INTO     ln_entered_cr
                             ,ln_entered_dr
                             ,ln_cr_dr_sum
                       FROM   XX_GL_INTERFACE_NA_STG
                      WHERE   group_id        = p_group_id;
                 END;


                IF ln_cr_dr_sum = 0 THEN

                     lc_balance_flg  := 'Y';


                     BEGIN

                            UPDATE XX_GL_INTERFACE_NA_STG
                            SET      balanced    = 'BALANCED'
                            WHERE group_id       = p_group_id;

                     COMMIT;
     -------------------------------------
     -- Write details to output file body
     -------------------------------------

                            lc_debug_msg := '    Updated XX_GL_INTERFACE_NA_STG '
                                            || 'Balanced column = BALANCED '
                                            || 'lc_group_id=> '      || p_group_id;


                            DEBUG_MESSAGE  (lc_debug_msg);
                     EXCEPTION
                              WHEN OTHERS THEN
                                  fnd_message.clear();
                                  fnd_message.set_name('FND','FS-UNKNOWN');
                                  fnd_message.set_token('ERROR',SQLERRM);
                                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                                ||lc_debug_prog
                                                                ||lc_debug_msg
                                                       );

                                  fnd_file.put_line(fnd_file.log,fnd_message.get());

                                 x_return_message := fnd_message.get();

                       END;


                  ELSE

                    fnd_file.put_line(fnd_file.log,'UPDATE as UNBALANCED '
                                       ||'ln_group_id'   || p_group_id);

                    BEGIN

                            UPDATE XX_GL_INTERFACE_NA_STG
                            SET   balanced                  = 'UNBALANCED'
                            WHERE group_id              = p_group_id;

                     COMMIT;

                           gn_error_count := gn_error_count + 1;
       -------------------------------------
       -- Write details to output file body
       -------------------------------------


                            lc_debug_msg := '    Updated XX_GL_INTERFACE_NA_STG '
                                            ||'Balanced = INVALID for '
                                            || 'lc_group_id=> '      || p_group_id;



                            fnd_message.clear();
                            fnd_message.set_name('XXFIN',lc_fnd_message);
                            fnd_message.set_token('TYPE','Balance' );
                            fnd_message.set_token('VALUE1',p_group_id);

                            lc_detail_err := fnd_message.get;

                            x_return_message := lc_detail_err;

                            fnd_file.put_line(fnd_file.log,'x_return_message'||x_return_message);


                     EXCEPTION

                               WHEN OTHERS THEN
                                  fnd_message.clear();
                                  fnd_message.set_name('FND','FS-UNKNOWN');
                                  fnd_message.set_token('ERROR',SQLERRM);
                                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                            ||lc_debug_prog
                                                            ||lc_debug_msg
                                                       );

                                  fnd_file.put_line(fnd_file.log,fnd_message.get());

                                  x_return_message := fnd_message.get();

                     END;


                END IF;

           ELSE

            --  END IF;                   -- commented out by p.Marco defect 3094

            --  lc_balance_flg  := 'N';   -- commented out by p.Marco defect 3094


              lc_debug_msg := '    Open balance_cursor checking SOB GrpId, Curr, Cat, Acc_dt ';
              DEBUG_MESSAGE  (lc_debug_msg);

               -----------------------------------------------------------
               -- Open cursor to select sob ids Group_Id, source, Currency,
               -- Category and Acct date
               -----------------------------------------------------------
               OPEN   balance_cursor_by_sob;

               LOOP

                   lc_balance_flg  := 'N';   -- added by p.Marco defect 3094

                   FETCH   balance_cursor_by_sob INTO
                           ln_entered_cr
                          ,ln_entered_dr
                          ,ln_cr_dr_sum
                          ,ln_group_id
                          ,ln_sob_id
                          ,lc_source_nm
                          ,lc_batch_name
                          ,lc_curr_code
                          ,lc_category_nm
                          ,ld_acct_date;

                   EXIT WHEN   balance_cursor_by_sob%NOTFOUND;

                   IF ln_cr_dr_sum = 0 THEN

                       lc_balance_flg  := 'Y';

                   END IF;

                  -- END LOOP;
                  -- CLOSE balance_cursor_by_sob;  -- commented out by p.Marco defect 3094


                  IF lc_balance_flg  = 'Y' THEN

                      BEGIN

                            UPDATE XX_GL_INTERFACE_NA_STG
                            SET   balanced              = 'BALANCED'
                            WHERE set_of_books_id       = ln_sob_id
                                 AND group_id              = ln_group_id
                                 AND user_je_source_name   = lc_source_nm
                                 AND currency_code         = lc_curr_code
                                 AND reference1            = lc_batch_name
                                 AND user_je_category_name = lc_category_nm
                                 AND accounting_date       = ld_acct_date;

                                 COMMIT;

                           -------------------------------------
                           -- Write details to output file body
                           -------------------------------------

                            lc_debug_msg := '    Updated XX_GL_INTERFACE_NA_STG '
                                            || 'Balanced column = BALANCED '
                                            || 'lc_group_id=> '      || ln_group_id
                                            || ', lc_source_nm=> '   || lc_source_nm
                                            || ', lc_category_nm=> ' || lc_category_nm
                                            || ', lc_curr_code=> '   || lc_curr_code
                                            || ', ld_acct_date=> '   || ld_acct_date;

                            DEBUG_MESSAGE  (lc_debug_msg);


                       EXCEPTION
                              WHEN OTHERS THEN
                                  fnd_message.clear();
                                  fnd_message.set_name('FND','FS-UNKNOWN');
                                  fnd_message.set_token('ERROR',SQLERRM);
                                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                                ||lc_debug_prog
                                                                ||lc_debug_msg
                                                       );

                                  fnd_file.put_line(fnd_file.log,fnd_message.get());

                                 x_return_message := fnd_message.get();

                       END;


                  ELSE

                    fnd_file.put_line(fnd_file.log,'UPDATE as UNBALANCED '
                                       ||'ln_sob_id'     || ln_sob_id
                                       ||'ln_group_id'   || ln_group_id
                                       ||'lc_source_nm'  || lc_source_nm
                                       ||'lc_batch_name '|| lc_batch_name);

                    BEGIN

                            UPDATE XX_GL_INTERFACE_NA_STG
                            SET   balanced                  = 'UNBALANCED'
                            WHERE set_of_books_id           = ln_sob_id
                                  AND group_id              = ln_group_id
                                  AND user_je_source_name   = lc_source_nm
                                  AND reference1            = lc_batch_name
                                  AND currency_code         = lc_curr_code
                                  AND user_je_category_name = lc_category_nm
                                  AND accounting_date       = ld_acct_date;

                                  COMMIT;

                           gn_error_count := gn_error_count + 1;
                           -------------------------------------
                           -- Write details to output file body
                           -------------------------------------


                            lc_debug_msg := '    Updated XX_GL_INTERFACE_NA_STG '
                                            ||'Balanced = INVALID for '
                                            || 'lc_group_id=> '      || ln_group_id
                                            || ', lc_source_nm=> '   || lc_source_nm
                                            || ', lc_category_nm=> ' || lc_category_nm
                                            || ', lc_curr_code=> '   || lc_curr_code
                                            || ', ld_acct_date=> '   || ld_acct_date;


                            fnd_message.clear();
                            fnd_message.set_name('XXFIN',lc_fnd_message);
                            fnd_message.set_token('TYPE','Balance' );
                            fnd_message.set_token('VALUE1',ln_group_id);
                            fnd_message.set_token('VALUE2',ln_sob_id );
                            fnd_message.set_token('VALUE3',lc_batch_name );
                            fnd_message.set_token('VALUE4',ld_acct_date);

                            lc_detail_err := fnd_message.get;

                            x_return_message := lc_detail_err;

                            fnd_file.put_line(fnd_file.log,'x_return_message'||x_return_message);

                             PROCESS_ERROR
                                   (p_fnd_message  =>  lc_fnd_message
                                   ,p_source_nm      =>  lc_source_nm
                                   ,p_type         =>  'Balance'
                                   ,p_value        =>  NULL
                                   ,p_sob_id       =>  ln_sob_id
                                   ,p_details      =>  lc_detail_err
                                   ,p_group_id     =>  ln_group_id
                                   );

                     EXCEPTION

                               WHEN OTHERS THEN
                                  fnd_message.clear();
                                  fnd_message.set_name('FND','FS-UNKNOWN');
                                  fnd_message.set_token('ERROR',SQLERRM);
                                  fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                            ||lc_debug_prog
                                                            ||lc_debug_msg
                                                       );

                                  fnd_file.put_line(fnd_file.log,fnd_message.get());

                                  x_return_message := fnd_message.get();

                     END;


                  END IF;

               END LOOP;
               CLOSE balance_cursor_by_sob;

        END IF;


     EXCEPTION

          WHEN OTHERS THEN
               fnd_message.clear();
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',gc_debug_pkg_nm
                                                  ||lc_debug_prog
                                                  ||lc_debug_msg
                                    );

               fnd_file.put_line(fnd_file.log,fnd_message.get());

               x_return_message := fnd_message.get();

     END CHECK_BALANCES;

-- +===================================================================+
-- | Name  :    UPDATE_CURRENCY_TYPE                                   |
-- | Description      : Update conversion type for Inter-Company jrnls |
-- |                                                                   |
-- |                                                                   |
-- | Parameters :   p_grp_id                                           |
-- |                                                                   |
-- |                                                                   |
-- | Returns :    x_output_msg                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
       PROCEDURE UPDATE_CURRENCY_TYPE (p_group_id       IN NUMBER
                                      ,x_output_msg     OUT VARCHAR2
                                       )
       IS


           ln_rowid             ROWID;
           lc_debug_msg         VARCHAR(1000);
           lc_debug_prog        VARCHAR2(25) := 'UPDATE_CURRENCY_TYPE';
           ln_conv_cnt          NUMBER;

           CURSOR currency_type_cursor
           IS
               SELECT  GIS.rowid
                 FROM XX_GL_INTERFACE_NA_STG GIS
                     --,GL_SETS_OF_BOOKS GSB Commented as part of R12 Retrofit
					   ,GL_LEDGERS GL --Added as part of R12 Retrofit
                --WHERE GIS.set_of_books_id = GSB.set_of_books_id Commented as part of R12 Retrofit
				WHERE GIS.set_of_books_id = GL.ledger_id --Added as part of R12 Retrofit
                  AND GIS.currency_code  <> GL.currency_code
                  AND GIS.group_id        = p_group_id;


       BEGIN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                     ||  lc_debug_prog );

           ln_conv_cnt := 0;

           OPEN currency_type_cursor;
           LOOP

               FETCH currency_type_cursor
                INTO      ln_rowid;

           EXIT WHEN currency_type_cursor%NOTFOUND;

                BEGIN

                    -------------------------------------------------
                    -- Update conversion type for Inter-Company jrnls
                    -------------------------------------------------

                    UPDATE XX_GL_INTERFACE_NA_STG
                    SET    user_currency_conversion_type = 'Ending Rate'
                          ,currency_conversion_date = accounting_date
                    WHERE  rowid = ln_rowid;

                    ln_conv_cnt := ln_conv_cnt +1;

                END;

                COMMIT;

           END LOOP;

           CLOSE currency_type_cursor;

                lc_debug_msg := '    Total records Conversion type update: '
                                || ln_conv_cnt;

                DEBUG_MESSAGE  (lc_debug_msg);

        EXCEPTION

           WHEN OTHERS THEN

               x_output_msg  := 'Copy to GL Interface Failure'|| SQLERRM;
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);

               x_output_msg := fnd_message.get();

               FND_FILE.PUT_LINE(FND_FILE.LOG,  fnd_message.get());

        END UPDATE_CURRENCY_TYPE;


-- +===================================================================+
-- | Name  :    COPY_TO_GL_INTERFACE                                   |
-- | Description      : This Procedure can be used to copy valid GL    |
-- |                    JE lines into the XX_GL_INTERFACE_NA  TABLE    |
-- |                                                                   |
-- | Parameters : p_user_je_source_name,  p_group_id                   |
-- |               p_set_of_books_id                                   |
-- |                                                                   |
-- | Returns :    x_output_msg                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
       PROCEDURE COPY_TO_GL_INTERFACE (p_user_je_source_name IN VARCHAR2
                                      ,p_group_id            IN NUMBER
                                      ,p_set_of_books_id     IN NUMBER
                                      ,x_output_msg         OUT VARCHAR2
                                       )
       IS

           lc_debug_msg             VARCHAR(100);
           lc_debug_prog            VARCHAR2(25) := 'COPY_TO_GL_INTERFACE';

       BEGIN

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                      ||  lc_debug_prog );

       ------------------------------------------------------------------
       -- gc_bypass_valid_flg = Y will load all lines with any validation
       ------------------------------------------------------------------

	   --V3.5, Updating the ledger_id in STG Table
	   UPDATE XX_GL_INTERFACE_NA_STG
	   SET LEDGER_ID=SET_OF_BOOKS_ID
	   WHERE GROUP_ID = p_group_id;          -- Defect# 34078 Added for updating only the group_id which is processed currently and avoiding deadlock on other rows
	   COMMIT;
	   --V3.5

       IF gc_bypass_valid_flg = 'Y' THEN

                 INSERT INTO XX_GL_INTERFACE_NA
                         (status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
                         ,reference21       --Added by P.Marco for Defect 3076
                         ,reference22       --Added for defect #7675
                         ,reference23       --Added following 8 lines for defect 7793
                         ,reference24
                         ,reference25
                         ,reference26
                         ,reference27
                         ,reference28
                         ,reference29
                         ,reference30
                         ,ledger_id)  -- Defect 26736
                   SELECT status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
--                        ,reference21       --Added by P.Marco for Defect 3076
--                        ,reference22       --Added for defect #7675
                         ,ATTRIBUTE11        --Added following 10 lines for defect 7793 and commented the above 2 lines
                         ,ATTRIBUTE12
                         ,ATTRIBUTE13
                         ,ATTRIBUTE14
                         ,ATTRIBUTE15
                         ,ATTRIBUTE16
                         ,(segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||','||entered_dr||','||entered_cr||','||attribute10||','||reference27)   --- added for defect 8261
                         ,ATTRIBUTE18
                         ,ATTRIBUTE19
                         ,ATTRIBUTE20
                         ,set_of_books_id
                   FROM
                          XX_GL_INTERFACE_NA_STG
                   WHERE user_je_source_name = p_user_je_source_name
                   AND   group_id            = p_group_id
                   AND   set_of_books_id     = p_set_of_books_id;

              COMMIT;

              ------------------------------------
              -- Write copy to GL interface to log
              ------------------------------------
              LOG_MESSAGE (p_grp_id      =>   p_group_id
                          ,p_source_nm   =>   p_user_je_source_name
                          ,p_status      =>  'COPIED TO INTERFACE'
                          ,p_details     =>  'Set of books id: '
                                            || p_set_of_books_id || 'By_Pass_Flg = Y'
                         -- ,p_request_id  =>   gn_request_id
                           );

         ELSIF gc_import_ctrl = 'N' THEN

                 INSERT INTO XX_GL_INTERFACE_NA
                         (status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
                         ,reference21       --Added by P.Marco for Defect 3076
                         ,reference22       --Added for defect #7675
                         ,reference23       --Added following 8 lines for defect 7793
                         ,reference24
                         ,reference25
                         ,reference26
                         ,reference27
                         ,reference28
                         ,reference29
                         ,reference30,
                         ledger_id)
                   SELECT status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
--                        ,reference21       --Added by P.Marco for Defect 3076
--                        ,reference22       --Added for defect #7675
                         ,ATTRIBUTE11        --Added following 10 lines for defect 7793 and commented the above 2 lines
                         ,ATTRIBUTE12
                         ,ATTRIBUTE13
                         ,ATTRIBUTE14
                         ,ATTRIBUTE15
                         ,ATTRIBUTE16
                        ,(segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||','||entered_dr||','||entered_cr||','||attribute10||','||reference27)  --- added for defect 8261
                         ,ATTRIBUTE18
                         ,ATTRIBUTE19
                         ,ATTRIBUTE20
                         ,set_of_books_id
                   FROM
                          XX_GL_INTERFACE_NA_STG
                   WHERE
                         derived_val         = 'VALID'
                   AND   (derived_sob        = 'VALID'
                          OR derived_sob     = 'INTER-COMP')
                   AND   balanced            = 'BALANCED'
                   AND   user_je_source_name = p_user_je_source_name
                   AND   group_id            = p_group_id;


           ELSE

                 INSERT INTO XX_GL_INTERFACE_NA
                         (status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
                         ,reference21       --Added by P.Marco for Defect 3076
                         ,reference22       --Added for defect #7675
                         ,reference23       --Added following 8 lines for defect 7793
                         ,reference24
                         ,reference25
                         ,reference26
                         ,reference27
                         ,reference28
                         ,reference29
                         ,reference30
                         ,ledger_id
                                                  )
                   SELECT status
                         ,date_created
                         ,created_by
                         ,actual_flag
                         ,group_id
                         ,reference1
                         ,reference2
                         ,reference4
                         ,reference5
                         ,reference6
                         ,reference_date
                         ,reference7
                         ,reference8
                         ,reference9
                         ,user_je_category_name
                         ,user_je_source_name
                         ,set_of_books_id
                         ,accounting_date
                         ,currency_code
                         ,currency_conversion_date
                         ,user_currency_conversion_type
                         ,segment1
                         ,segment2
                         ,segment3
                         ,segment4
                         ,segment5
                         ,segment6
                         ,segment7
                         ,code_combination_id
                         ,entered_dr
                         ,entered_cr
                         ,reference10
                         ,reference20
--                        ,reference21       --Added by P.Marco for Defect 3076
--                        ,reference22       --Added for defect #7675
                         ,ATTRIBUTE11        --Added following 10 lines for defect 7793 and commented the above 2 lines
                         ,ATTRIBUTE12
                         ,ATTRIBUTE13
                         ,ATTRIBUTE14
                         ,ATTRIBUTE15
                         ,ATTRIBUTE16
                       ,(segment1||'.'||segment2||'.'||segment3||'.'||segment4||'.'||segment5||'.'||segment6||'.'||segment7||','||entered_dr||','||entered_cr||','||attribute10||','||reference27)  --- added for defect 8261
                         ,ATTRIBUTE18
                         ,ATTRIBUTE19
                         ,ATTRIBUTE20
                         ,set_of_books_id
                  FROM
                          XX_GL_INTERFACE_NA_STG
                   WHERE
                         derived_val         = 'VALID'
                    AND   (derived_sob       = 'VALID'
                           OR derived_sob    = 'INTER-COMP')
                    AND  balanced            = 'BALANCED'
                    AND  user_je_source_name = p_user_je_source_name
                    AND  group_id            = p_group_id
                    AND  set_of_books_id     = p_set_of_books_id;

              COMMIT;

			  fnd_file.put_line(fnd_file.log,'After Insert in copy to gl interface table');

              ------------------------------------
              -- Write copy to GL interface to log
              ------------------------------------
              LOG_MESSAGE (p_grp_id      =>   p_group_id
                          ,p_source_nm   =>   p_user_je_source_name
                          ,p_status      =>  'COPIED TO INTERFACE'
                          ,p_details     =>  'Set of books id: '
                                            || p_set_of_books_id || 'import_ctrl_flag = ' || gc_import_ctrl
                         -- ,p_request_id  =>   gn_request_id
                           );

        END IF;

      --END IF;

            lc_debug_msg := '  Completed COPY_TO_GL_INTERFACE';
            FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg  );


      EXCEPTION

           WHEN OTHERS THEN
               x_output_msg  := 'Copy to GL Interface Failure'|| SQLERRM;
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);


               FND_FILE.PUT_LINE(FND_FILE.LOG,  fnd_message.get);

        END COPY_TO_GL_INTERFACE;

-- +===================================================================+
-- | Name  :    POPULATE_CONTROL_TABLE                                 |
-- | Description      :This Procedure is used to insert control records|
-- |                   into the POPULATE_INTERFACE_CONTROL TABLE       |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE POPULATE_CONTROL_TABLE  (p_user_je_source_name IN     VARCHAR2
                                       ,p_group_id            IN OUT NUMBER
                                       ,p_set_of_books_id     IN     NUMBER
                                       ,p_interface_run_id    IN OUT NUMBER
                                       ,p_table_name          IN     VARCHAR2
                                       ,x_output_msg          OUT    VARCHAR2
                                        )
      IS
           re_use_gl_interface_control EXCEPTION;

           lc_debug_prog            VARCHAR2(25) := 'POPULATE_CONTROL_TABLE';
           lc_debug_msg             VARCHAR2(1000);

      BEGIN


           FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                     ||  lc_debug_prog );


           gl_journal_import_pkg.populate_interface_control
                            (user_je_source_name => p_user_je_source_name
                            ,group_id            => p_group_id
                            ,set_of_books_id     => p_set_of_books_id
                            ,interface_run_id    => p_interface_run_id
                            ,table_name          => p_table_name
                            );
           COMMIT;

           lc_debug_msg := '    Completed:  POPULATE_CONTROL_TABLE ';
           DEBUG_MESSAGE (lc_debug_msg);


      EXCEPTION
         WHEN re_use_gl_interface_control THEN
                 x_output_msg  :=  'Control table NULL Failure:' ||
                                   ' Group p_group_id=>'         || p_group_id ||
                                   ' p_user_je_source_name=>'    || p_user_je_source_name ||
                                   ' p_set_of_books_id=> '       || p_set_of_books_id ;

                  FND_FILE.PUT_LINE(FND_FILE.LOG, x_output_msg );


         WHEN OTHERS THEN
               x_output_msg  := 'Populate Control Failure'|| SQLERRM;
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);

               FND_FILE.PUT_LINE(FND_FILE.LOG, fnd_message.get );



END POPULATE_CONTROL_TABLE;

-- +===================================================================+ --Added to update the COGS flag March 12
-- | Name  :    UPDATE_COGS_FLAG                                       |
-- | Description      :This Procedure will update the COGS Generated Flag
-- |                       for valid COGS journal entries              |
-- |                                                                   |
-- | Parameters :    p_group_id                                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       x_output_msg                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

 PROCEDURE UPDATE_COGS_FLAG   (  p_group_id   IN NUMBER
                                 ,p_sob_id IN NUMBER
                                   ,p_source_nm  IN VARCHAR2
                                   ,x_output_msg OUT VARCHAR2
                                    )
IS
lc_debug_msg  VARCHAR(1000);
lc_debug_prog            VARCHAR2(25):='UPDATE COGS FLAG';

  BEGIN
  --Added hint to select statement as part of defect 7634
            UPDATE /*+ index(RAD RA_CUST_TRX_LINE_GL_DIST_U1) */
            RA_CUST_TRX_LINE_GL_DIST_ALL RAD
            SET RAD.ATTRIBUTE6 = 'Y'
            WHERE RAD.CUST_TRX_LINE_GL_DIST_ID IN
            (SELECT TO_NUMBER(STG.REFERENCE21)
               FROM XX_GL_INTERFACE_NA_STG STG
               WHERE STG.GROUP_ID = p_group_id
               AND STG.USER_JE_SOURCE_NAME = p_source_nm
               AND STG.DERIVED_VAL = 'VALID'
               AND STG.DERIVED_SOB = 'VALID'
               AND STG.BALANCED = 'BALANCED');


              COMMIT;

----------------#Added By Nazima as part of Defect #5761----------------------

             UPDATE /*+ index(RAD RA_CUST_TRX_LINE_GL_DIST_U1) */
               ra_cust_trx_line_gl_dist_all RAD
              SET    rad.attribute6 = 'E'
              WHERE  rad.cust_trx_line_gl_dist_id in
                (SELECT to_number(STG.reference21)
                 FROM   xx_gl_interface_na_STG STG
                 WHERE  STG.group_id            = p_group_id
                 AND STG.user_je_source_name = p_source_nm
                 AND STG.derived_val        = 'INVALID');


              COMMIT;

/* ---------------Procedure to insert into Custom table ------------------------

     XX_INSERT_TO_RA_CUSTOM_PROC(p_group_id );   */   ---Commented as part of defect #7793

/*--------------Proceudre to call the exception report------------------------

     XX_EXCEPTION_REPORT_PROC;*/

---------------Deleting the INVALID records from the staging table for the source 'OD COGS'-----------

      SELECT
              SUM(entered_dr)
             ,SUM(entered_cr)
       INTO
             ln_in_dr_amt
            ,ln_in_cr_amt
      FROM xx_gl_interface_na_STG
      WHERE group_id=p_group_id
       AND  derived_val         = 'INVALID'
        OR derived_sob         = 'INVALID'
        OR balanced            = 'UNBALANCED';

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Debit (Invalid records) for group id  '||p_group_id ||' is : '||ln_in_dr_amt);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Credit (Invalid records) for group id  '||p_group_id ||' is : '||ln_in_cr_amt);

     SELECT
              SUM(entered_dr)
             ,SUM(entered_cr)
       INTO
             ln_v_dr_amt
            ,ln_v_cr_amt
      FROM xx_gl_interface_na_STG
      WHERE group_id=p_group_id
    -- AND derived_val         = 'INVALID'          -- Commented for R1.4 defect 5494
      AND (derived_val         = 'INVALID'          -- Added for for R1.4 defect 5494
           OR derived_sob         = 'INVALID'
       --  OR balanced            = 'UNBALANCED';   -- Commented for R1.4 defect 5494
           OR balanced            = 'UNBALANCED');  -- Added for for R1.4 defect 5494

    FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Debit (valid records) for group id '||p_group_id || ' is : '||ln_v_dr_amt);
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Sum of Entered Credit (valid records) for group id '||p_group_id ||' is : '||ln_v_cr_amt);

    IF p_source_nm='OD COGS' THEN      --Added by Nazima as part of defect# 5761

     DELETE FROM  xx_gl_interface_na_STG
     WHERE group_id=p_group_id
     AND set_of_books_id = p_sob_id
  -- AND derived_val         = 'INVALID'           -- Commented for R1.4 defect 5494
     AND (derived_val         = 'INVALID'          -- Added for for R1.4 defect 5494
          OR derived_sob         = 'INVALID'
    --    OR balanced            = 'UNBALANCED';   -- Commented for R1.4 defect 5494
          OR balanced            = 'UNBALANCED');  -- Added for for R1.4 defect 5494


      ln_del_rec :=sql%rowcount;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'No Of COGS records deleted for group id '||p_group_id ||' and SOB ID '||p_sob_id||' is : '||ln_del_rec);

     COMMIT;

     END IF;



    lc_debug_msg := '  Completed UPDATE_COGS_FLAG';

     EXCEPTION
           WHEN OTHERS then

               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);
               x_output_msg := fnd_message.get;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '|| gc_debug_pkg_nm
                                                          || lc_debug_prog
                                                          || fnd_message.get());

  END UPDATE_COGS_FLAG;


-- +===================================================================+
-- | Name  :    SUBMIT_GL_IMPORT                                       |
-- | Description      :This Procedure will submit the concurrent prog  |
-- |                   to import GL JE lines to the base tables        |
-- |                                                                   |
-- | Parameters :    p_group_id                                        |
-- |                                                                   |
-- |                                                                   |
-- | Returns :       x_output_msg                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE  SUBMIT_GL_IMPORT (p_group_id               IN  NUMBER
                                 ,p_sob_id                 IN  VARCHAR2
                                 ,p_source_nm              IN  VARCHAR2
                                 ,p_summary_import         IN VARCHAR2 DEFAULT 'N'
                                 ,x_output_msg             OUT VARCHAR2
                                 )
     IS


           COPY_TO_INT_EXP          EXCEPTION;
           POPULATE_CONTROL_EXP     EXCEPTION;

           -----------------
           --Local Variables
           -----------------

           ln_interface_run_id      NUMBER;
           ln_conc_id               INTEGER;
           lb_bool                  BOOLEAN;
           lc_old_status            VARCHAR2(30);
           lc_phase                 VARCHAR2(100);
           lc_status                VARCHAR2(100);
           lc_dev_phase             VARCHAR2(100);
           lc_dev_status            VARCHAR2(100);
           ln_sob_id                XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
           lc_user_je_source_name   XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
           ln_group_id              NUMBER;
           --lc_sob_name              GL_SETS_OF_BOOKS.short_name%TYPE; Commented as part of R12 Retrofit
		   lc_sob_name              GL_LEDGERS.short_name%TYPE; --Added as part of R12 Retrofit
          -- Below added for defect 14556
           ln_resp_id               NUMBER;
           ln_resp_app_id           NUMBER;
           ln_user_id               NUMBER;
           ln_CA_resp_id            NUMBER;
           ln_CA_set_of_book_id     NUMBER;
           lc_CA_resp_name          xx_fin_translatevalues.target_value1%TYPE;
           lc_CA_SOB_name           xx_fin_translatevalues.target_value2%TYPE;


           ----------------------------
           --Tracking status variables
           ----------------------------

           lc_intrfc_transfr       VARCHAR2(3);
           lc_submit_import        VARCHAR2(3);
           lc_import_stat          VARCHAR2(25);
           lc_import_req_id        NUMBER;

           ------------------
           --Debug variables
           ------------------

           lc_debug_prog            VARCHAR2(100)  := 'SUBMIT_GL_IMPORT';
           lc_intface_tbl_name      VARCHAR2(35)   := 'XX_GL_INTERFACE_NA';
           lc_debug_msg             VARCHAR2(250);
           lc_output_msg            VARCHAR2(2000);
           lc_message               VARCHAR2(100);




      BEGIN

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                   ||  lc_debug_prog );



             lc_intrfc_transfr  := 'NO';
             lc_submit_import   := 'NO';
             lc_import_stat     := 'N/A';
             lc_import_req_id   :=  0;
             ln_sob_id          :=  p_sob_id;
             lc_user_je_source_name := p_source_nm;
             x_output_msg       := NULL;

             -----------------------------
             -- Copy to GL Interface table
             -----------------------------
             BEGIN



                    COPY_TO_GL_INTERFACE(p_user_je_source_name => lc_user_je_source_name
                                        ,p_group_id            => p_group_id
                                        ,p_set_of_books_id     => ln_sob_id
                                        ,x_output_msg          => lc_output_msg
                                        );

             END;

             IF lc_output_msg IS NOT NULL THEN

                     lc_debug_msg  := 'Copy GL Interface Table Failure: '|| lc_output_msg;
                    fnd_message.set_name('FND','FS-UNKNOWN');
                    fnd_message.set_token('ERROR',SQLERRM);
                    x_output_msg := fnd_message.get;

                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '|| gc_debug_pkg_nm
                                                          || lc_debug_prog
                                                          || lc_debug_msg
                                                          || fnd_message.get());


             ELSE


                     lc_intrfc_transfr  := 'YES';

             END IF;


             ln_group_id := p_group_id;

             -----------------------------
             -- Populate GL Control table
             -----------------------------

                BEGIN


                     POPULATE_CONTROL_TABLE
                                       (p_user_je_source_name => lc_user_je_source_name
                                       ,p_group_id            => ln_group_id
                                       ,p_set_of_books_id     => ln_sob_id
                                       ,p_interface_run_id    => ln_interface_run_id
                                       ,p_table_name          => lc_intface_tbl_name
                                       ,x_output_msg          => lc_output_msg
                                       );


                END;

                IF lc_output_msg IS NOT NULL THEN

                     --  todo handle error
                     --  RAISE POPULATE_CONTROL_EXP;


                     lc_debug_msg := ' Error with POPULATE_CONTROL_TABLE '|| lc_output_msg;
                     fnd_message.set_name('FND','FS-UNKNOWN');
                     fnd_message.set_token('ERROR',SQLERRM);

                     x_output_msg := fnd_message.get;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '|| gc_debug_pkg_nm
                                                                || lc_debug_prog
                                                                || lc_debug_msg
                                                                || fnd_message.get());



                END IF;

  ---- Added by Raji 29/feb/08
       IF p_summary_import = 'N' THEN

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);

                lc_debug_msg  := 'Started: Journal Import Concurrent Program';
                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);


--Uncommented the below line for the defect#9639

            IF ( p_source_nm = 'OD COGS' ) THEN

                ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => TRUE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                         );

                  COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

/*                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );    */


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );


            /* ELSE
                    -- commented for defect 14556
                       ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                         );  */
                  -- ELSIF and subsequent ELSE block addded for defect 14556
          --  ELSIF ( p_source_nm = 'OD Global Sourcing System') THEN   commented for defect 14837
             -- ELSIF ( p_source_nm IN ('OD Global Sourcing System','OD Inventory (SIV)') ) THEN -- added 'OD Inventory (SIV)' source for defect# 14837   --Commented for defect 531
               ELSIF ( p_source_nm IN ('OD Global Sourcing System','OD Inventory (SIV)','Taxware') ) THEN--added 'Taxware' source for defect# 531

                       ln_resp_app_id := FND_GLOBAL.RESP_APPL_ID;
                       ln_resp_id := FND_GLOBAL.RESP_ID;
                       ln_user_id := FND_GLOBAL.USER_ID;

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Deriving the Translation values');

                       SELECT XFTV.target_value1,XFTV.target_value2
                       INTO   lc_ca_resp_name
                             ,lc_ca_sob_name
                       FROM   xx_fin_translatedefinition  XFTD
                             ,xx_fin_translatevalues XFTV
                        WHERE XFTV.translate_id = XFTD.translate_id
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                        AND XFTV.source_value1 = 'OD_CA'
                        AND XFTD.translation_name = 'OD_GSS_RESPONSIBILITY_SOB'
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Deriving the Resp ID and SOB id');

                          -- Deriving resp ID for CA responisibility
                           SELECT responsibility_id
                           INTO ln_ca_resp_id
                           FROM fnd_responsibility_tl
                           WHERE responsibility_name = lc_ca_resp_name;

                           -- Deriving SOB ID for CA responisibility
						   --SELECT set_of_books_id Commented as part of R12 Retrofit
						   SELECT ledger_id --Added as part of R12 Retrofit
                           INTO   ln_ca_set_of_book_id
                           --FROM   GL_SETS_OF_BOOKS Commented as part of R12 Retrofit
                           FROM   GL_LEDGERS --Added as part of R12 Retrofit
                           WHERE name = lc_ca_sob_name;

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_CA_resp_id '|| ln_CA_resp_id||' ln_CA_set_of_book_id '||ln_CA_set_of_book_id);

                IF (ln_sob_id = ln_ca_set_of_book_id) THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'In CA SOB ID');

                    --- initialize to a CA reponsibility
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_user_id,ln_CA_resp_id,ln_resp_app_id '||ln_user_id||','||ln_CA_resp_id||','||ln_resp_app_id);
                      fnd_global.apps_initialize(ln_user_id,ln_CA_resp_id,ln_resp_app_id);

                       ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                         );
                        --- reinitialize to a original reponsibility
                         fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_app_id);

                ELSE
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'In US SOB ID');

                     ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                            );
                END IF;

              COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );

              ELSE

              ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                         );
                 COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );


              END IF;

--Commented the below line for the defect#9639
/*
                           ------------------------------------------
                           --Code changes for the defect #8706 begins
                           ------------------------------------------

                          IF ( p_source_nm = 'OD COGS' ) THEN

                           ln_conc_id := fnd_request.submit_request(
                                                                    application => 'SQLGL'
                                                                   ,program     => 'GLLEZL'
                                                                   ,description => NULL
                                                                   ,start_time  => SYSDATE
                                                                   ,sub_request => FALSE
                                                                   ,argument1   => to_char(ln_interface_run_id)
                                                                   ,argument2   => to_char(ln_sob_id)
                                                                   ,argument3   => 'N'
                                                                   ,argument4   => NULL
                                                                   ,argument5   => NULL
                                                                   ,argument6   => 'N'
                                                                   ,argument7   => 'W'
                                                                   );

                           COMMIT;
                           gn_import_request_id := ln_conc_id;

                          -----------------------
                          -- Write submit to log
                          -----------------------
                           LOG_MESSAGE
                                   (p_grp_id      =>   p_group_id
                                   ,p_source_nm   =>   lc_user_je_source_name
                                   ,p_status      =>  'SUBMIT IMPORT'
                                   ,p_details     =>  'Submit request: '  || ln_conc_id
                                  -- ,p_request_id  =>   gn_request_id
                                    );

                          -----------------------
                          -- Write submit to log
                          -----------------------
                          LOG_MESSAGE (p_grp_id      =>   p_group_id
                                      ,p_source_nm   =>   lc_user_je_source_name
                                      ,p_status      =>  'IMPORT FINISHED'
                                      ,p_details     =>  'Submit request: '
                                                       || ln_conc_id
                                                       || ' Status => '
                                                       ||  lc_status
                                      );

                           ELSE
                             ln_conc_id := fnd_request.submit_request(
                                                                 application => 'SQLGL'
                                                                ,program     => 'GLLEZL'
                                                                ,description => NULL
                                                                ,start_time  => SYSDATE
                                                                ,sub_request => FALSE
                                                                ,argument1   => TO_CHAR(ln_interface_run_id)
                                                                ,argument2   => TO_CHAR(ln_sob_id)
                                                                ,argument3   => 'N'
                                                                ,argument4   => NULL
                                                                ,argument5   => NULL
                                                                ,argument6   => 'N'
                                                                ,argument7   => 'W'
                                                                 );
                             COMMIT;

                          -----------------------
                          -- Write submit to log
                          -----------------------
                           LOG_MESSAGE
                                   (p_grp_id      =>   p_group_id
                                   ,p_source_nm   =>   lc_user_je_source_name
                                   ,p_status      =>  'SUBMIT IMPORT'
                                   ,p_details     =>  'Submit request: '  || ln_conc_id
                                  -- ,p_request_id  =>   gn_request_id
                                    );


                          lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                        ,5
                                                                        ,5000
                                                                        ,lc_phase
                                                                        ,lc_status
                                                                        ,lc_dev_phase
                                                                        ,lc_dev_status
                                                                        ,lc_message
                                                                         );


                          -----------------------
                          -- Write submit to log
                          -----------------------
                          LOG_MESSAGE (p_grp_id      =>   p_group_id
                                      ,p_source_nm   =>   lc_user_je_source_name
                                      ,p_status      =>  'IMPORT FINISHED'
                                      ,p_details     =>  'Submit request: '
                                                       || ln_conc_id
                                                       || ' Status => '
                                                       ||  lc_status
                                      );
                           END IF;

                           ------------------------------------------
                           --Code changes for the defect #8706 ends
                           ------------------------------------------
*/
         ELSE

                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);

                lc_debug_msg  := 'Started: Journal Import Concurrent Program';
                FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);

--Uncommented for the defect#9639
               IF ( p_source_nm = 'OD COGS' ) THEN

                   ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => TRUE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'Y'
                                                ,argument7   => 'W'
                                                         );

                  COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

/*                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );    */


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );


            /* ELSE
                    -- commented for defect 14556
                       ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'Y'
                                                ,argument7   => 'W'
                                                         );  */
                       -- ELSIF and subsequent ELSE block addded for defect 14556
	   --  ELSIF ( p_source_nm = 'OD Global Sourcing System') THEN   commented for defect 14837
              --ELSIF ( p_source_nm IN ('OD Global Sourcing System','OD Inventory (SIV)') ) THEN -- added 'OD Inventory (SIV)' source for defect# 14837    --Commented for defect 531
                ELSIF ( p_source_nm IN ('OD Global Sourcing System','OD Inventory (SIV)','Taxware') ) THEN--added 'Taxware' source for defect# 531

                       ln_resp_app_id := FND_GLOBAL.RESP_APPL_ID;
                       ln_resp_id := FND_GLOBAL.RESP_ID;
                       ln_user_id := FND_GLOBAL.USER_ID;

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Deriving the Translation values');

                       SELECT XFTV.target_value1,XFTV.target_value2
                       INTO lc_CA_resp_name
                           ,lc_CA_SOB_name
                       FROM xx_fin_translatedefinition  XFTD
                            ,xx_fin_translatevalues XFTV
                        where XFTV.translate_id = XFTD.translate_id
                        AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                        AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                        AND XFTV.source_value1 = 'OD_CA'
                        AND XFTD.translation_name = 'OD_GSS_RESPONSIBILITY_SOB'
                        AND XFTV.enabled_flag = 'Y'
                        AND XFTD.enabled_flag = 'Y';

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'Deriving the Resp ID and SOB id');

                          -- Deriving resp ID for CA responisibility
                           SELECT responsibility_id
                           INTO ln_CA_resp_id
                           FROM fnd_responsibility_tl
                           WHERE responsibility_name = lc_CA_resp_name;

                           -- Deriving SOB ID for CA responisibility
                           --SELECT set_of_books_id Commented as part of R12 Retrofit
						   SELECT ledger_id --Added as part of R12 Retrofit
                           INTO   ln_CA_set_of_book_id
                           --FROM   GL_SETS_OF_BOOKS Commented as part of R12 Retrofit
						   FROM   GL_LEDGERS --Added as part of R12 Retrofit
                           WHERE name = lc_ca_sob_name;

                         FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_CA_resp_id '|| ln_CA_resp_id||' ln_CA_set_of_book_id '||ln_CA_set_of_book_id);

                IF (ln_sob_id = ln_CA_set_of_book_id) THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'In CA SOB ID');

                    --- initialize to a CA reponsibility
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_user_id,ln_CA_resp_id,ln_resp_app_id '||ln_user_id||','||ln_CA_resp_id||','||ln_resp_app_id);
                      fnd_global.apps_initialize(ln_user_id,ln_CA_resp_id,ln_resp_app_id);

                       ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'Y'
                                                ,argument7   => 'W'
                                                         );
                        --- reinitialize to a original reponsibility
                         fnd_global.apps_initialize(ln_user_id,ln_resp_id,ln_resp_app_id);

                ELSE
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'In US SOB ID');

                     ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'Y'
                                                ,argument7   => 'W'
                                                            );
                END IF;

              COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );

              ELSE

              ln_conc_id := fnd_request.submit_request(
                                                 application => 'SQLGL'
                                                ,program     => 'GLLEZL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => to_char(ln_interface_run_id)
                                                ,argument2   => to_char(ln_sob_id)
                                                ,argument3   => 'N'
                                                ,argument4   => NULL
                                                ,argument5   => NULL
                                                ,argument6   => 'N'
                                                ,argument7   => 'W'
                                                         );
                 COMMIT;

                  -----------------------
                  -- Write submit to log
                  -----------------------
                   LOG_MESSAGE
                           (p_grp_id      =>   p_group_id
                           ,p_source_nm   =>   lc_user_je_source_name
                           ,p_status      =>  'SUBMIT IMPORT'
                           ,p_details     =>  'Submit request: '  || ln_conc_id
                          -- ,p_request_id  =>   gn_request_id
                            );

                 lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                ,5
                                                                ,5000
                                                                ,lc_phase
                                                                ,lc_status
                                                                ,lc_dev_phase
                                                                ,lc_dev_status
                                                                ,lc_message
                                                                 );


                  -----------------------
                  -- Write submit to log
                  -----------------------
                  LOG_MESSAGE (p_grp_id      =>   p_group_id
                              ,p_source_nm   =>   lc_user_je_source_name
                              ,p_status      =>  'IMPORT FINISHED'
                              ,p_details     =>  'Submit request: '
                                               || ln_conc_id
                                               || ' Status => '
                                               ||  lc_status
                              );


              END IF;
 END IF;



--Commented for the defect#9639
/*
                           ------------------------------------------
                           --Code changes for the defect #8706 begins
                           ------------------------------------------

                           IF ( p_source_nm = 'OD COGS' ) THEN

                           ln_conc_id := fnd_request.submit_request(
                                                                    application => 'SQLGL'
                                                                   ,program     => 'GLLEZL'
                                                                   ,description => NULL
                                                                   ,start_time  => SYSDATE
                                                                   ,sub_request => FALSE
                                                                   ,argument1   => to_char(ln_interface_run_id)
                                                                   ,argument2   => to_char(ln_sob_id)
                                                                   ,argument3   => 'N'
                                                                   ,argument4   => NULL
                                                                   ,argument5   => NULL
                                                                   ,argument6   => 'N'
                                                                   ,argument7   => 'W'
                                                                   );

                           COMMIT;
                           gn_import_request_id := ln_conc_id;

                          -----------------------
                          -- Write submit to log
                          -----------------------
                           LOG_MESSAGE
                                   (p_grp_id      =>   p_group_id
                                   ,p_source_nm   =>   lc_user_je_source_name
                                   ,p_status      =>  'SUBMIT IMPORT'
                                   ,p_details     =>  'Submit request: '  || ln_conc_id
                                  -- ,p_request_id  =>   gn_request_id
                                    );

                          -----------------------
                          -- Write submit to log
                          -----------------------
                          LOG_MESSAGE (p_grp_id      =>   p_group_id
                                      ,p_source_nm   =>   lc_user_je_source_name
                                      ,p_status      =>  'IMPORT FINISHED'
                                      ,p_details     =>  'Submit request: '
                                                       || ln_conc_id
                                                       || ' Status => '
                                                       ||  lc_status
                                      );

                           ELSE

                             ln_conc_id := fnd_request.submit_request(
                                                                 application => 'SQLGL'
                                                                ,program     => 'GLLEZL'
                                                                ,description => NULL
                                                                ,start_time  => SYSDATE
                                                                ,sub_request => FALSE
                                                                ,argument1   => TO_CHAR(ln_interface_run_id)
                                                                ,argument2   => TO_CHAR(ln_sob_id)
                                                                ,argument3   => 'N'
                                                                ,argument4   => NULL
                                                                ,argument5   => NULL
                                                                ,argument6   => 'N'
                                                                ,argument7   => 'W'
                                                                 );
                             COMMIT;

                          -----------------------
                          -- Write submit to log
                          -----------------------
                           LOG_MESSAGE
                                   (p_grp_id      =>   p_group_id
                                   ,p_source_nm   =>   lc_user_je_source_name
                                   ,p_status      =>  'SUBMIT IMPORT'
                                   ,p_details     =>  'Submit request: '  || ln_conc_id
                                  -- ,p_request_id  =>   gn_request_id
                                    );


                          lb_bool := fnd_concurrent.wait_for_request(ln_conc_id
                                                                        ,5
                                                                        ,5000
                                                                        ,lc_phase
                                                                        ,lc_status
                                                                        ,lc_dev_phase
                                                                        ,lc_dev_status
                                                                        ,lc_message
                                                                         );


                          -----------------------
                          -- Write submit to log
                          -----------------------
                          LOG_MESSAGE (p_grp_id      =>   p_group_id
                                      ,p_source_nm   =>   lc_user_je_source_name
                                      ,p_status      =>  'IMPORT FINISHED'
                                      ,p_details     =>  'Submit request: '
                                                       || ln_conc_id
                                                       || ' Status => '
                                                       ||  lc_status
                                      );
                           END IF;

                           ------------------------------------------
                           --Code changes for the defect #8706 ends
                           ------------------------------------------
*/
      --          END IF;


                  IF (ln_conc_id = 0) THEN

                          lc_debug_msg  := '    Could not Submit '
                                       || 'Journal Import Concurrent Program'
                                       || 'lc_phase=>  '||lc_phase
                                       ||',lc_status=> '||lc_status;

                           x_output_msg := lc_debug_msg;

                           FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);

                  ELSE


                          lc_submit_import      := 'YES';
                          lc_import_stat        := lc_status;
                          lc_import_req_id      := ln_conc_id;

--Commented for the defect#9639

                     --Added the IF statement for the defect#8706
                       IF ( p_source_nm <>'OD COGS' ) THEN


                          --------------------------------------------
                          -- Submit request to email for output report
                          --------------------------------------------

                          ln_conc_id := fnd_request.submit_request(
                                                 application => 'XXFIN'
                                                ,program     => 'XXGLINTERFACEEMAIL'
                                                ,description => NULL
                                                ,start_time  => SYSDATE
                                                ,sub_request => FALSE
                                                ,argument1   => lc_import_req_id
                                                ,argument2   => gc_email_lkup
                                                ,argument3   => 'Journal Import Execution Report for Request'
                                                     );

                       END IF ;  ----Commented for the defect#9639


                          lc_debug_msg := '    Completed: Journal '
                                      ||'import execution report.'
                                      || ' ln_conc_id=> ' ||ln_conc_id
                                      ||',lc_phase=>  '   ||lc_phase
                                      ||',lc_status=> '   ||lc_status;


                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg);

                  END IF;




          ----------------------------
          --Create trailer record info
          ----------------------------

          IF  x_output_msg IS NULL THEN

                 CREATE_OUTPUT_FILE(p_cntrl_flag      =>'TRAILER'
                            ,p_source_name     => lc_user_je_source_name
                            ,p_group_id        => p_group_id
                             ,p_sob_id         => ln_sob_id
                            ,p_intrfc_transfr  => lc_intrfc_transfr
                            ,p_submit_import   => lc_submit_import
                            ,p_import_stat     => lc_import_stat
                            ,p_import_req_id   => lc_import_req_id
                            );

          END IF;

          lc_debug_msg := '  Completed SUBMIT_GL_IMPORT';
          FND_FILE.PUT_LINE(FND_FILE.LOG,lc_debug_msg  );

      EXCEPTION
           WHEN OTHERS then

               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);
               x_output_msg := fnd_message.get;

               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '|| gc_debug_pkg_nm
                                                          || lc_debug_prog
                                                          || fnd_message.get());


      END SUBMIT_GL_IMPORT;




-- +===================================================================+
-- | Name  :    CREATE_STG_JRNL_LINE                                   |
-- | Description      : This Procedure can be used to insert GL Journal|
-- |                    entry line into the XX_GL_INTERFACE_NA_STG     |
-- |                    table                                          |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :                                                         |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

      PROCEDURE CREATE_STG_JRNL_LINE (  p_status            IN  VARCHAR2
                                       ,p_date_created      IN  DATE
                                       ,p_created_by        IN  NUMBER
                                       ,p_actual_flag       IN  VARCHAR2
                                       ,p_group_id          IN  NUMBER
                                       ,p_batch_name        IN  VARCHAR2
                                       ,p_batch_desc        IN  VARCHAR2
                                       ,p_je_name           IN  VARCHAR2
                                       ,p_je_Descrp         IN  VARCHAR2
                                       ,p_je_reference      IN  VARCHAR2
                                       ,p_je_ref_date       IN  DATE
                                       ,p_je_rev_flg        IN  VARCHAR2
                                       ,p_je_rev_period     IN  VARCHAR2
                                       ,p_je_rev_method     IN  VARCHAR2
                                       ,p_user_source_name  IN  VARCHAR2
                                       ,p_user_catgory_name IN  VARCHAR2
                                       ,p_set_of_books_id   IN  NUMBER
                                       ,p_accounting_date   IN  DATE
                                       ,p_currency_code     IN  VARCHAR2
                                       ,p_company           IN  VARCHAR2
                                       ,p_cost_center       IN  VARCHAR2
                                       ,p_account           IN  VARCHAR2
                                       ,p_location          IN  VARCHAR2
                                       ,p_intercompany      IN  VARCHAR2
                                       ,p_channel           IN  VARCHAR2
                                       ,p_future            IN  VARCHAR2
                                       ,p_ccid              IN  NUMBER
                                       ,p_entered_dr        IN  NUMBER
                                       ,p_entered_cr        IN  NUMBER
                                       ,p_je_line_dsc       IN  VARCHAR2
                                       ,p_reference11       IN  VARCHAR2
                                       ,p_reference12       IN  VARCHAR2
                                       ,p_reference13       IN  VARCHAR2
                                       ,p_reference14       IN  VARCHAR2
                                       ,p_reference15       IN  VARCHAR2
                                       ,p_reference16       IN  VARCHAR2
                                       ,p_reference17       IN  VARCHAR2
                                       ,p_reference18       IN  VARCHAR2
                                       ,p_reference19       IN  VARCHAR2
                                       ,p_reference20       IN  VARCHAR2
                                       ,p_reference21       IN  VARCHAR2
                                       ,p_reference22       IN  VARCHAR2
                                       ,p_reference23       IN  VARCHAR2
                                       ,p_reference24       IN  VARCHAR2
                                       ,p_reference25       IN  VARCHAR2
                                       ,p_reference26       IN  VARCHAR2
                                       ,p_reference27       IN  VARCHAR2
                                       ,p_reference28       IN  VARCHAR2
                                       ,p_reference29       IN  VARCHAR2
                                       ,p_reference30       IN  VARCHAR2
                                       ,p_legacy_segment1   IN  VARCHAR2
                                       ,p_legacy_segment2   IN  VARCHAR2
                                       ,p_legacy_segment3   IN  VARCHAR2
                                       ,p_legacy_segment4   IN  VARCHAR2
                                       ,p_legacy_segment5   IN  VARCHAR2
                                       ,p_legacy_segment6   IN  VARCHAR2
                                       ,p_legacy_segment7   IN  VARCHAR2
                                       ,p_derived_val       IN  VARCHAR2
                                       ,p_derived_sob       IN  VARCHAR2
                                       ,p_balanced          IN  VARCHAR2
                                       ,x_output_msg        OUT VARCHAR2
                                     )

        IS

            p_output_msg          VARCHAR2(2000);
            lc_debug_prog         VARCHAR2(30) := 'CREATE_STG_JRNL_LINE';

        BEGIN

            INSERT INTO XX_GL_INTERFACE_NA_STG
                                  (status
                                  ,date_created
                                  ,created_by
                                  ,actual_flag
                                  ,group_id
                                  ,reference1
                                  ,reference2
                                  ,reference4
                                  ,reference5
                                  ,reference6
                                  ,reference_date
                                  ,reference7
                                  ,reference8
                                  ,reference9
                                  ,user_je_category_name
                                  ,user_je_source_name
                                  ,set_of_books_id
                                  ,accounting_date
                                  ,currency_code
                                  ,segment1
                                  ,segment2
                                  ,segment3
                                  ,segment4
                                  ,segment5
                                  ,segment6
                                  ,segment7
                                  ,code_combination_id
                                  ,entered_dr
                                  ,entered_cr
                                  ,reference10
                                  ,reference11
                                  ,reference12
                                  ,reference13
                                  ,reference14
                                  ,reference15
                                  ,reference16
                                  ,reference17
                                  ,reference18
                                  ,reference19
                                  ,reference20
                                  ,reference21
                                  ,reference22
                                  ,reference23
                                  ,reference24
                                  ,reference25
                                  ,reference26
                                  ,reference27
                                  ,reference28
                                  ,reference29
                                  ,reference30
                                  ,legacy_segment1
                                  ,legacy_segment2
                                  ,legacy_segment3
                                  ,legacy_segment4
                                  ,legacy_segment5
                                  ,legacy_segment6
                                  ,legacy_segment7
                                  ,derived_val
                                  ,derived_sob
                                  ,balanced
                                                                     )
                             VALUES
                                  (
                                   p_status
                                  ,p_date_created
                                  ,p_created_by
                                  ,p_actual_flag
                                  ,p_group_id
                                  ,p_batch_name
                                  ,p_batch_desc
                                  ,p_je_name
                                  ,p_je_Descrp
                                  ,p_je_reference
                                  ,p_je_ref_date
                                  ,p_je_rev_flg
                                  ,p_je_rev_period
                                  ,p_je_rev_method
                                  ,p_user_catgory_name
                                  ,p_user_source_name
                                  ,p_set_of_books_id
                                  ,p_accounting_date
                                  ,p_currency_code
                                  ,p_company
                                  ,p_cost_center
                                  ,p_account
                                  ,p_location
                                  ,p_intercompany
                                  ,p_channel
                                  ,p_future
                                  ,p_ccid
                                  ,p_entered_dr
                                  ,p_entered_cr
                                  ,p_je_line_dsc
                                  ,p_reference11
                                  ,p_reference12
                                  ,p_reference13
                                  ,p_reference14
                                  ,p_reference15
                                  ,p_reference16
                                  ,p_reference17
                                  ,p_reference18
                                  ,p_reference19
                                  ,p_reference20
                                  ,p_reference21
                                  ,p_reference22
                                  ,p_reference23
                                  ,p_reference24
                                  ,p_reference25
                                  ,p_reference26
                                  ,p_reference27
                                  ,p_reference28
                                  ,p_reference29
                                  ,p_reference30
                                  ,p_legacy_segment1
                                  ,p_legacy_segment2
                                  ,p_legacy_segment3
                                  ,p_legacy_segment4
                                  ,p_legacy_segment5
                                  ,p_legacy_segment6
                                  ,p_legacy_segment7
                                  ,p_derived_val
                                  ,p_derived_sob
                                  ,p_balanced
                                  );



        EXCEPTION

             WHEN OTHERS THEN

                  fnd_message.set_name('FND','FS-UNKNOWN');
                  fnd_message.set_token('ERROR',SQLERRM);
                  fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);

                  x_output_msg  := fnd_message.get();

    END CREATE_STG_JRNL_LINE;


-- +===================================================================+
-- | Name  :PROCESS_JRNL_LINES                                         |
-- | Description :  The main processing procedure.  After records are  |
-- |               inserted in the staging table using the             |
-- |               CREATE_STG_JRNL_LINE, you can call the              |
-- |               PROCESS_JRNL_LINES process to validate, copy and    |
-- |               import the JE lines into GL.                        |
-- |                    table                                          |
-- |                                                                   |
-- | Parameters : user_je_source_name,group_id, set_of_books_id        |
-- |              p_file_name: BPEL File name                          |
-- |              p_import_ctrl: controls how records a balanced and   |
-- |                             imported to gl_inteface table. Set to |
-- |                             'Y' to balance and import by both     |
-- |                              group_id and set of books id.        |
-- |              p_chk_sob_flg: Set 'Y' to derive set_of_books_id     |
-- |              p_chk_bal_flg: Set 'Y' to check if jrnls balance     |
-- |              p_bypass_flg : Set 'Y' to bypass 50 error count chk  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :   output_msg                                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

     PROCEDURE  PROCESS_JRNL_LINES (p_grp_id      IN      NUMBER
                                   ,p_source_nm   IN      VARCHAR2
                                   ,p_import_ctrl IN      VARCHAR2 DEFAULT 'Y'
                                   ,p_file_name   IN      VARCHAR2 DEFAULT NULL
                                   ,p_err_cnt     IN OUT  NUMBER
                                   ,p_debug_flag  IN      VARCHAR2 DEFAULT 'N'
                                   ,p_chk_sob_flg IN      VARCHAR2 DEFAULT 'N'
                                   ,p_chk_bal_flg IN      VARCHAR2 DEFAULT 'N'
                                   ,p_bypass_flg  IN      VARCHAR2 DEFAULT 'N'
                                   ,p_summary_flag IN     VARCHAR2 DEFAULT 'N'
                                   ,p_cogs_update IN      VARCHAR2 DEFAULT 'N'
                                    )
     IS
            SUBMIT_IMPORT_EXP              EXCEPTION;

            --------------------------
            -- Declare local variables
            --------------------------

            ln_interface_run_id      NUMBER;
            ln_rec_cnt               NUMBER;
            ln_group_id              NUMBER;
            lc_output_msg            VARCHAR2(2000);
            lc_intface_tbl_name      VARCHAR2(35)   := 'XX_GL_INTERFACE_NA';
            lc_submit_gl_import      VARCHAR2(1)    := 'Y';
            x_output_msg             VARCHAR2(1000);
            lc_debug_prog            VARCHAR2(100)  := 'PROCESS_JRNL_LINES';
            lc_debug_msg             VARCHAR2(1000);
            ln_temp_err_cnt          NUMBER;
            ln_sob_id                XX_GL_INTERFACE_NA_STG.set_of_books_id%TYPE;
            lc_user_je_source_name   XX_GL_INTERFACE_NA_STG.user_je_source_name%TYPE;
            lc_batch_name            XX_GL_INTERFACE_NA_STG.reference1%TYPE;
            ln_entered_cr            XX_GL_INTERFACE_NA_STG.entered_cr%TYPE;
            ln_entered_dr            XX_GL_INTERFACE_NA_STG.entered_dr%TYPE;


           -----------------------------------
           --Cursor is select Distinct SOB IDs
           -----------------------------------

           CURSOR submit_cursor
           IS
               SELECT DISTINCT
                      set_of_books_id
                     ,user_je_source_name
               FROM   XX_GL_INTERFACE_NA_STG
               WHERE  group_id = p_grp_id;

           --------------------------------------
           --SUB-Cursor for balance ck and output
           --------------------------------------

           CURSOR bal_output_cursor
           IS
               SELECT DISTINCT
                      set_of_books_id
                     ,user_je_source_name
                     ,reference1
                     ,SUM(entered_dr)
                     ,SUM(entered_cr)
               FROM   XX_GL_INTERFACE_NA_STG
               WHERE  group_id = p_grp_id
                 AND  (set_of_books_id = ln_sob_id
                       OR set_of_books_id IS NULL)
               GROUP BY set_of_books_id
                       ,group_id
                       ,user_je_source_name
                       ,currency_code
                       ,user_je_category_name
                       ,reference1
                       ,accounting_date;

    BEGIN
          ---------------------
          --intialize variables
          ---------------------
          --get total error cnt from calling program
          gn_error_count := p_err_cnt;

          gc_debug_flg        := p_debug_flag;
          gc_email_lkup       := p_source_nm;
          gc_import_ctrl      := p_import_ctrl;
          lc_submit_gl_import := 'Y';
          gc_file_name        := p_file_name;

          IF p_bypass_flg = 'Y'  THEN

             gc_bypass_valid_flg := p_bypass_flg;

          END IF;


          FND_FILE.PUT_LINE(FND_FILE.LOG,'Started: '||  gc_debug_pkg_nm
                                                    ||  lc_debug_prog );

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Import by Source Name and'
                               || ' Set of books ID flag = ' || p_import_ctrl);


          ----------------------------
          --  Derive set of books id
          ----------------------------
        IF UPPER (p_chk_sob_flg) = 'Y'  THEN


                -----------------------
                -- Write to status log
                -----------------------
                LOG_MESSAGE  (p_grp_id      =>   p_grp_id
                             ,p_source_nm   =>   lc_user_je_source_name
                             ,p_status      =>  'UPDATE SOBIDs'
                             ,p_details     =>  'Calling update program'
                              );

                XX_GL_INTERFACE_PKG.UPDATE_SET_OF_BOOKS_ID

                                (p_group_id       => p_grp_id
                                ,x_return_err_cnt => ln_temp_err_cnt
                                ,x_return_message => lc_output_msg
                                 );

               IF ln_temp_err_cnt > 0 THEN

                   -- Add total cnt from proc to global total
                   gn_error_count := gn_error_count + ln_temp_err_cnt;

               END IF;
            ---- Added by Raji 29/feb/08
            ELSE
            UPDATE XX_GL_INTERFACE_NA_STG
                    SET    derived_sob = 'VALID'
                  WHERE  group_id  = p_grp_id;

          END IF;


         --------------------------------
         -- Open cursor to select sob ids
         --------------------------------
         OPEN submit_cursor;

         LOOP

             FETCH submit_cursor INTO
                         ln_sob_id
                        ,lc_user_je_source_name;


         EXIT WHEN submit_cursor%NOTFOUND;

         -------------------------------------
         -- Write details to output file body
         -------------------------------------

                CREATE_OUTPUT_FILE(p_group_id   => p_grp_id
                                  ,p_cntrl_flag => 'BODYHEAD'
                                   );

----Added for defect
           -- XX_GL_GLSI_INTERFACE_PKG.CREATE_SUSPENSE_LINES(p_grp_id,ln_sob_id);  -- Added for suspense lines posting defect # 5327
                ----------------------------------------------------------------
                -- Open sub-cursor to ck balances and write outputselect sob ids
                ----------------------------------------------------------------
                OPEN bal_output_cursor;

                LOOP

                FETCH bal_output_cursor INTO
                         ln_sob_id
                        ,lc_user_je_source_name
                        ,lc_batch_name
                        ,ln_entered_dr
                        ,ln_entered_cr;
                EXIT WHEN bal_output_cursor%NOTFOUND;

                     ----------------------------
                     --  Check Journal Balances
                     ----------------------------
                     IF UPPER (p_chk_bal_flg) = 'Y'  THEN

                         -----------------------
                         -- Write to status log
                         -----------------------
                         LOG_MESSAGE  (p_grp_id    =>   p_grp_id
                                      ,p_source_nm =>   lc_user_je_source_name
                                      ,p_status    =>  'CHECK BALANCE'
                                      ,p_details   =>  'Calling Check balance program'
                                      );


                         CHECK_BALANCES (p_group_id   => p_grp_id
                                        ,p_sob_id     => ln_sob_id
                                        ,p_batch_name => lc_batch_name
                                        ,x_return_message   => lc_output_msg
                                         );

                          p_err_cnt :=  gn_error_count;

                          IF lc_output_msg IS NOT NULL THEN

                                 FND_FILE.PUT_LINE(FND_FILE.LOG,'Balance errors found :'
                                           || 'XX_GL_INTERFACE_PKG.CHECK_BALANCES');
                                 lc_submit_gl_import  := 'N';


                          END IF;
                    ---- Added by Raji 29/feb/08
                     ELSE

                    UPDATE XX_GL_INTERFACE_NA_STG
                    SET    balanced = 'BALANCED'
                    WHERE  group_id  = p_grp_id;

                     END IF;






 IF p_cogs_update = 'N' THEN
                     -------------------------------------------------
                     -- Update conversion type for Inter-Company jrnls
                     -------------------------------------------------

                     UPDATE_CURRENCY_TYPE(p_group_id    => p_grp_id
                                         ,x_output_msg  => lc_output_msg);


                     IF lc_output_msg IS NOT NULL THEN

                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Error found in :' ||
                                        'XX_GL_INTERFACE_PKG.UPDATE_CURRENCY_TYPE');

                            lc_output_msg := NULL;

                    END IF;
END IF;
                    -------------------------------------
                    -- Write details to output file body
                    -------------------------------------

                    CREATE_OUTPUT_FILE(p_group_id  => p_grp_id
                                     ,p_sob_id     => ln_sob_id
                                     ,p_batch_name => lc_batch_name
                                     ,p_total_dr   => ln_entered_dr
                                     ,p_total_cr   => ln_entered_cr
                                     ,p_cntrl_flag => 'BODY'
                                      );

              END LOOP;

              CLOSE bal_output_cursor;

       ----------Procedure to Update the COGS Flag and insert into Custom table ---------------Added to update COGS flag defect 4140,4139


     IF p_cogs_update = 'Y' THEN

             -----------------------
             -- Write to status log
             -----------------------
             LOG_MESSAGE  (p_grp_id    =>   p_grp_id
                                      ,p_source_nm =>   lc_user_je_source_name
                                      ,p_status    =>  'XX_VALIDATE_STG_PROC'
                                      ,p_details   =>  'Calling update XX_VALIDATE_STG_PROC program'
                                      );


              XX_VALIDATE_STG_PROC(p_grp_id);

             LOG_MESSAGE  (p_grp_id    =>   p_grp_id
                                      ,p_source_nm =>   lc_user_je_source_name
                                      ,p_status    =>  'UPDATE COGS FLAG'
                                      ,p_details   =>  'Calling update COGS flag program'
                                      );


            UPDATE_COGS_FLAG   (    p_group_id   => p_grp_id
                                    ,p_sob_id    => ln_sob_id
                                    ,p_source_nm  => lc_user_je_source_name
                                    ,x_output_msg => lc_output_msg
                                    );

            END IF;


             ---------------------------
             --Submit Import Program
             ---------------------------

             FND_FILE.PUT_LINE(FND_FILE.LOG,'    Total errors found: '
                                   || gn_error_count);
         BEGIN

         SELECT COUNT(1)
         INTO ln_rec_cnt
         FROM XX_GL_INTERFACE_NA_STG
         WHERE group_id = p_grp_id
         AND user_je_source_name = lc_user_je_source_name
         AND set_of_books_id     = ln_sob_id;

         FND_FILE.PUT_LINE(FND_FILE.LOG,'No of records in Staging table for group ID ' ||p_grp_id||'is' || ln_rec_cnt);

         END;

         IF ln_rec_cnt = 0 THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'No records in Staging table for group ID ' ||p_grp_id);

           CREATE_OUTPUT_FILE(p_cntrl_flag      =>'TRAILER'
                            ,p_source_name     => lc_user_je_source_name
                            ,p_group_id        =>  p_grp_id
                             ,p_sob_id         => ln_sob_id
                             );
           RAISE SUBMIT_IMPORT_EXP;

         ELSE

	   -- Defect 19342 -- Submitting gl import for the source 'OD Inventory (SIV)' eventhough error exists

             IF   (gn_error_count < 51 AND lc_submit_gl_import = 'Y' AND p_source_nm<>'OD Inventory (SIV)')
               OR (gc_bypass_valid_flg = 'Y' AND lc_submit_gl_import = 'Y' AND p_source_nm<>'OD Inventory (SIV)')
	       OR p_source_nm='OD Inventory (SIV)' THEN

                   --Commented the below assignment for the defect#9639
                   --gn_import_request_id := NULL;----Added for the defect#8705

                   SUBMIT_GL_IMPORT ( p_group_id   => p_grp_id
                                     ,p_sob_id     => ln_sob_id
                                     ,p_source_nm  => lc_user_je_source_name
                                     ,p_summary_import => p_summary_flag
                                     ,x_output_msg => lc_output_msg
                                    );


                   IF lc_output_msg IS NOT NULL THEN


                        -----------------------
                        -- Write complete to log
                        -----------------------
                        LOG_MESSAGE  (p_grp_id      =>   p_grp_id
                                     ,p_source_nm   =>   lc_user_je_source_name
                                     ,p_status      =>  'COMPLETED'
                                     ,p_details     =>  'Program has completed: With Errors for SOB_ID = '||ln_sob_id
                                      );

                       ----------------------------
                       --Create trailer record info
                       ----------------------------

                       CREATE_OUTPUT_FILE(p_cntrl_flag        => 'TRAILER'
                                         ,p_source_name       => p_source_nm
                                         ,p_group_id          => p_grp_id
                                         ,p_sob_id            => ln_sob_id
                                         ,p_intrfc_transfr    => 'NO'
                                         ,p_submit_import     => 'NO'
                                         ,p_import_stat       => 'n/a'
                                         );

                    ELSE


                        -----------------------
                        -- Write complete to log
                        -----------------------
                        LOG_MESSAGE (p_grp_id      =>   p_grp_id
                                    ,p_source_nm   =>   lc_user_je_source_name
                                    ,p_status      =>  'COMPLETED'
                                    ,p_details     =>  'Program has completed: Successfully for SOB_ID = '||ln_sob_id
                                     );

                        lc_debug_msg := '    Deleting records from'
                                             ||' staging table for group_id=> '
                                             || p_grp_id
                                             ||' gc_bypass_valid_flg flag => ' ||gc_bypass_valid_flg
                                             ||' gc_import_ctrl flag => '      ||gc_import_ctrl;

                        DEBUG_MESSAGE (lc_debug_msg);



                        ---------------------------------------------
                        -- Deleting xx_gl_interface_na_stg table
                        ---------------------------------------------
                        IF gc_bypass_valid_flg = 'Y' THEN       -- P.Marco Added IF statements to resolve
                                                                -- Defect 3094 table clean up
                             BEGIN

                               ----------------------------------------
                               -- By passed validation. Delete based on
                               -- group_id and sob
                               ----------------------------------------
                               DELETE FROM XX_GL_INTERFACE_NA_STG
                               WHERE  group_id        = p_grp_id
                               AND    set_of_books_id = ln_sob_id;

                               COMMIT;

                               lc_debug_msg := '    Deleted records from'
                                             ||' staging table for group_id: '
                                             || p_grp_id
                                             ||' and set of books id => '
                                             ||ln_sob_id ;

                                DEBUG_MESSAGE (lc_debug_msg);

                             EXCEPTION

                              WHEN OTHERS THEN

                                fnd_message.clear();
                                fnd_message.set_name('FND','FS-UNKNOWN');
                                fnd_message.set_token('ERROR',SQLERRM);
                                fnd_message.set_token('ROUTINE',lc_debug_msg
                                                          ||gc_debug_pkg_nm
                                                          ||lc_debug_prog);

                                FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '
                                                    ||  fnd_message.get());

                            END;

                        ELSE
                                                                    -- P.Marco Added IF statements
                            IF gc_import_ctrl = 'N' THEN            -- to resolve Defect 3094 table
                                                                    -- clean up
                                BEGIN

                                   ----------------------------------------
                                   -- Deleting with validation
                                   -- based on group_id
                                   ----------------------------------------
                                   DELETE FROM XX_GL_INTERFACE_NA_STG
                                   WHERE derived_val         = 'VALID'
                                   AND   (derived_sob        = 'VALID'
                                          OR derived_sob     = 'INTER-COMP')
                                   AND   balanced            = 'BALANCED'
                                   AND   group_id            = p_grp_id;

                                   COMMIT;

                                  lc_debug_msg := 'Deleting records from'
                                               ||' staging table for group_id: '
                                               || p_grp_id;

                                  DEBUG_MESSAGE (lc_debug_msg);


                                EXCEPTION

                                WHEN OTHERS THEN

                                   fnd_message.clear();
                                   fnd_message.set_name('FND','FS-UNKNOWN');
                                   fnd_message.set_token('ERROR',SQLERRM);
                                   fnd_message.set_token('ROUTINE',lc_debug_msg
                                                          ||gc_debug_pkg_nm
                                                          ||lc_debug_prog);

                                   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '
                                                    ||  fnd_message.get());

                                END;

                            ELSE

                                BEGIN

                                   ----------------------------------------
                                   -- Deleting with validation
                                   -- based on group_id,sob
                                   ----------------------------------------

                                   DELETE FROM XX_GL_INTERFACE_NA_STG
                                   WHERE derived_val        = 'VALID'
                                   AND   (derived_sob       = 'VALID'
                                          OR derived_sob    = 'INTER-COMP')
                                   AND  balanced            = 'BALANCED'
                                   AND  group_id            = p_grp_id
                                   AND  set_of_books_id     = ln_sob_id;

                                   COMMIT;

                                  lc_debug_msg := 'Deleting records from'
                                               ||' staging table for group_id: '
                                               || p_grp_id
                                               ||' and set of books id => '
                                               ||ln_sob_id ;

                                   DEBUG_MESSAGE (lc_debug_msg);

                                EXCEPTION

                                WHEN OTHERS THEN

                                   fnd_message.clear();
                                   fnd_message.set_name('FND','FS-UNKNOWN');
                                   fnd_message.set_token('ERROR',SQLERRM);
                                   fnd_message.set_token('ROUTINE',lc_debug_msg
                                                          ||gc_debug_pkg_nm
                                                          ||lc_debug_prog);
                                   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '
                                                    ||  fnd_message.get());

                                END;

                            END IF;

                       END IF;

                   END IF;

             ELSE

                  -----------------------
                  -- Write complete to log
                  -----------------------
                  LOG_MESSAGE  (p_grp_id      =>   p_grp_id
                               ,p_source_nm   =>   lc_user_je_source_name
                               ,p_status      =>  'COMPLETED'
                               ,p_details     =>  'Program has completed: With Errors'
                                );

                   ----------------------------
                   --Create trailer record info
                   ----------------------------

                    CREATE_OUTPUT_FILE(p_cntrl_flag         =>'TRAILER'
                                      ,p_source_name       => p_source_nm
                                      ,p_group_id          => p_grp_id
                                      ,p_sob_id            => ln_sob_id
                                      ,p_intrfc_transfr    => 'NO'
                                      ,p_submit_import     => 'NO'
                                      ,p_import_stat       => 'n/a'
                                       );

             END IF;
          END IF;

          END LOOP;

          CLOSE submit_cursor;

    /* --------------Proceudre to call the exception report------------------------
      IF p_cogs_update = 'Y' THEN

                   XX_EXCEPTION_REPORT_PROC;

      END IF;*/


        EXCEPTION

           WHEN SUBMIT_IMPORT_EXP  THEN
              -- x_output_msg  := ' Journal Import Program is not invoked for group Id: ' || p_grp_id;


               /*fnd_message.clear();
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);
               fnd_message.set_token('ROUTINE',x_output_msg
                                               ||gc_debug_pkg_nm
                                               ||lc_debug_prog);*/

               FND_FILE.PUT_LINE(FND_FILE.LOG,' Journal Import Program is not invoked for group Id: ' || p_grp_id);


           WHEN OTHERS THEN
               x_output_msg  :=  SQLERRM;
               fnd_message.set_name('FND','FS-UNKNOWN');
               fnd_message.set_token('ERROR',SQLERRM);

               FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR in: '|| gc_debug_pkg_nm
                                                          || lc_debug_prog
                                                          || fnd_message.get());

         END PROCESS_JRNL_LINES;

END XX_GL_INTERFACE_PKG;
/
SHOW ERROR;