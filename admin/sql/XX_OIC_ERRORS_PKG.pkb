SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_ERRORS_PKG.pkb                               |
   -- | Description : Plan copy error routine                             |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07   1.0       Initial Draft version                        |
   -- +===================================================================+
   
CREATE OR REPLACE
PACKAGE BODY APPS.XX_OIC_ERRORS_PKG
AS

-- start variables
 l_error_number                NUMBER;          -- Variable to store Error Number
 l_error_message               VARCHAR2(500);   -- Variable to store Error Message
 l_inserrorlines_error_status  VARCHAR2(1)  :='S';-- Variable to store Error Status while inserting error messages in the error lines table
 l_inserrorlines_error_message VARCHAR2(500);    -- Variable to store Error Messages while inserting error messages in the error lines table
 l_created_by                  NUMBER(15)   :=   NVL (TO_NUMBER (apps.fnd_profile.VALUE ('USER_ID')) ,0);  -- variable to store owner of record
 l_last_updated_by             NUMBER(15)   :=   NVL (TO_NUMBER (apps.fnd_profile.VALUE ('USER_ID')) ,0);  -- varible to store owner of record
 l_last_updated_login          NUMBER(15)   :=   TO_NUMBER (apps.fnd_profile.VALUE ('LOGIN_ID'));

-- end variables


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE cnc_check_error_prc 
                          ( p_status                OUT VARCHAR2                          --OUT PARAMETER-- PROCEDURE STATUS
                          , p_err_msg               OUT VARCHAR2                          --OUT PARAMETER-- ERROR MESSAGE
                          )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to validate the Hire date                       |
-- |                                                                                                    |
-- |  Input Parameters   :                                                                              |
-- |                                                                                                    |
-- |  Return Value       :  x_ststus        it refers to the status                                     |
-- |                        p_err_msg       it refers to the error message                              |
-- |                                                                                                    |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao 1.0     1-Aug-07       Original Version                                      |
-- |                                                                                                    |
-- |                                                                                                    |
-- +====================================================================================================+
    IS

    BEGIN
       p_status  := 'E';
       p_err_msg := l_error_number||l_error_message;
    END cnc_check_error_prc;

  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    PROCEDURE cnc_insert_header_record_prc 
                                   ( p_pgm_name              IN   XX_OIC_ERROR_HEADERS.program_name%TYPE  --IN PARAMETER-- THE PROGRAME NAME FOR WHICH THE VALIDATION HAS STARTED
                                   , p_request_id            IN   XX_OIC_ERROR_HEADERS.request_id%TYPE    --IN PARAMETER-- THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                   )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used while using batch processing the batch id is    |
-- |                     inserted into this table(name of the batch)                                    |
-- |  Input Parameters   : p_pgm_name         it refers to the  concurrent program name                 |
-- |                       p_request_id       it refers to the request id of the concurrent program name|
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
       PRAGMA AUTONOMOUS_TRANSACTION;

       l_program_id        XX_OIC_ERROR_HEADERS.program_id%TYPE;

       CURSOR c_program_id IS
         SELECT
              XX_OIC_ERROR_HEADERS_s.NEXTVAL program_id
         FROM DUAL;
    BEGIN
          FOR rec_program_id IN c_program_id LOOP
              l_program_id  :=  rec_program_id.program_id;
              g_program_id  :=  l_program_id;
          END LOOP;
--
           XX_OIC_ERRORS_PKG.g_sequence_id  :=   0;
           g_request_id  := p_request_id;

           INSERT INTO XX_OIC_ERROR_HEADERS( request_id
                                        , program_id
                                        , program_name
                                        , run_time
                                        , record_count
                                        , process_flag
                                        , creation_date
                                        , created_by
                                        , last_updated_date
                                        , last_updated_by
                                        , last_updated_login
                                        )
                                 VALUES ( SUBSTR(p_request_id,1,15)
                                        , l_program_id
                                        , SUBSTR(p_pgm_name,1,100)
                                        , SYSDATE
                                        , NULL
                                        , NULL
                                        , SYSDATE
                                        , l_created_by
                                        , SYSDATE
                                        , l_last_updated_by
                                        , l_last_updated_login
                                        );
      COMMIT;
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
            l_error_number  := SQLCODE;
            l_error_message := SUBSTR('error occured while updating the header table',1,100);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
      WHEN OTHERS THEN
           l_error_number  := SQLCODE;
           l_error_message := SUBSTR('pre_defined error occured while inserting the header table'||SQLERRM,1,100);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
           RAISE_APPLICATION_ERROR(2004,'pre_defined error occured while updating the header table');
    END cnc_insert_header_record_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    PROCEDURE cnc_update_header_record_prc 
                                   ( p_program_id            IN  XX_OIC_ERROR_HEADERS.program_id%TYPE     --IN PARAMETER-- THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                   , p_batch_rec_cnt         IN  XX_OIC_ERROR_HEADERS.record_count%TYPE      --IN PARAMETER-- TOTAL NUMBER OF RECORDS IN THE BATCH
                                   , p_process_flag          IN  XX_OIC_ERROR_HEADERS.process_flag%TYPE   --IN PARAMETER-- THE PROCESS FLAG
                                   )
    IS
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to update the header table data                 |
-- |                                                                                                    |
-- |  Input Parameters   :  p_request_id     it refers to the concurrent program request id             |
-- |                        p_batch_rec_cnt  it refers to the batch record count                        |
-- |                        p_process_flag   it refers to the process flag to'E' or 'P'                 |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- |                                                                                                    |
-- +====================================================================================================+
         l_dummy VARCHAR2(1); -- Variable to store the character 'x' if the batch id exists

    BEGIN

         SELECT 'x'
         INTO    l_dummy
         FROM    XX_OIC_ERROR_HEADERS
         WHERE   program_id = p_program_id
         AND   rownum = 1;

         UPDATE XX_OIC_ERROR_HEADERS
         SET    record_count       = p_batch_rec_cnt
              , process_flag       = p_process_flag
              , last_updated_by    = l_last_updated_by
              , last_updated_login = l_last_updated_login
         WHERE  program_id         = p_program_id;

    EXCEPTION
         WHEN NO_DATA_FOUND THEN
            l_error_number  := SQLCODE;
            l_error_message := SUBSTR('Invalid Program ID',1,100);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
         WHEN TOO_MANY_ROWS THEN
            l_error_number  := SQLCODE;
            l_error_message := SUBSTR('Too Many rows in Error Headers for program id ' || p_program_id,1,500);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
         WHEN OTHERS THEN
            l_error_number  := SQLCODE;
            l_error_message := SUBSTR(SQLERRM,1,100);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
    END cnc_update_header_record_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE cnc_write_message_prc
                           ( p_av_level        IN NUMBER                             --IN PARAMETER--THREE LEVEL ARE THERE 1,2 are for
                           , p_av_message      IN VARCHAR2                           --IN PARAMETER--THE ERROR MESSAGE
                           )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to write the messages on the log file or the    |
-- |                     output file.                                                                   |
-- |  Input Parameters   :p_av_level   it refer to the level of choices you can have '1','2','3'        |
-- |                      p_av_message it refer to the error message                                    |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS

    BEGIN
       -- Option 1 is for LOG
       -- Option 2 is for OUTPUT
       -- Option 3 is for DBMS-OUTPUT
       IF p_av_level  =1 THEN
          apps.FND_FILE.PUT_LINE(apps.FND_FILE.LOG,p_av_message);
       ELSIF p_av_level = 2 THEN
          apps.FND_FILE.PUT_LINE(apps.FND_FILE.OUTPUT,p_av_message);
       ELSIF p_av_level = 3 THEN
          DBMS_OUTPUT.put_line(p_av_message);
       ELSE
          NULL;
       END IF;
    END cnc_write_message_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE cnc_delete_header_record_prc 
                                  ( p_prog_name         IN  XX_OIC_ERROR_HEADERS.program_name%TYPE   --IN PARAMETER--THE PROGRAME NAME FOR WHICH THE VALIDATION HAS STARTED
                                  )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to delete the header lines from the             |
-- |                     XX_OIC_ERROR_HEADERS                                                                  |
-- |                                                                                                    |
-- |  Input Parameters   :p_program_name     it refer to the program name                               |
-- |                                                                                                    |
-- |  Return Value       :x_proc_status      it refer to the status which cane be 'P' or 'E'            |
-- |                      x_proc_err_msg     it refere to the error message                             |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS

        l_program_id XX_OIC_ERROR_HEADERS.program_id%TYPE; -- Variable to store the Request id
    BEGIN

        SELECT program_id
        INTO   l_program_id
        FROM  XX_OIC_ERROR_HEADERS
        WHERE  program_name = p_prog_name
        AND    program_id = ( SELECT MAX(program_id)
                            FROM   XX_OIC_ERROR_HEADERS
                            WHERE  program_name = p_prog_name
                          );


        DELETE XX_OIC_ERROR_LINES
        WHERE program_id = l_program_id;

        DELETE XX_OIC_ERROR_HEADERS
        WHERE program_name = p_prog_name;

    EXCEPTION
        WHEN OTHERS THEN
        l_error_number      := SQLCODE;
        l_error_message     := SUBSTR(SQLERRM,1,100);
        cnc_check_error_prc (l_error_number, l_error_message);
    END cnc_delete_header_record_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    PROCEDURE cnc_purge_error_record_prc
                                ( p_date                    IN  VARCHAR2                          --IN PARAMETER--Date in YYYYMMDD
                                , p_no_of_headers           OUT NUMBER                            --OUT PARAMETER--THE NUMBER OF HEADERS cnc_purge_error_record_prcD
                                , p_no_of_lines             OUT NUMBER                            --OUT PARAMETER--THE TOTAL NUMBER OF LINES cnc_purge_error_record_prcD
                                , p_no_of_batch_files       OUT NUMBER                            --OUT PARAMETER--THE TOTAL NUMBER OF BATCH FILES
                                )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to cnc_purge_error_record_prc the data from the headers |
-- |                     table                                                                          |
-- |                                                                                                    |
-- |  Input Parameters   : p_date                it refers to the date                                  |
-- |                                                                                                    |
-- |  Return Value       : p_no_of_headers       it refer to the no of headers                          |
-- |                       p_no_of_lines         it refer to the number of lines deleted                |
-- |                       p_no_of_batch_files   it refers to the batch file                            |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
       l_count NUMBER;  ---- Variable to store the total count of the records before the given date
       ld_date     DATE; ---- Variable to store the the date
    BEGIN
       SELECT to_date(p_date, 'YYYYMMDD')
       INTO      ld_date
       FROM      SYS.dual;

       SELECT count(*)
       INTO  p_no_of_headers
       FROM  XX_OIC_ERROR_HEADERS
       WHERE creation_date <= ld_date;

       SELECT count(*)
       INTO p_no_of_lines
       FROM XX_OIC_ERROR_LINES
       WHERE request_id = (
                    SELECT request_id
                    FROM  XX_OIC_ERROR_HEADERS
                    WHERE creation_date <= ld_date
                    );


       DELETE XX_OIC_ERROR_LINES
       WHERE  request_id = (
                            SELECT request_id
                            FROM   XX_OIC_ERROR_HEADERS
                            WHERE  creation_date <= ld_date
                           );

       DELETE XX_OIC_ERROR_HEADERS
       WHERE  creation_date <= ld_date;


    EXCEPTION
       WHEN OTHERS THEN
            l_error_number  := SQLCODE;
            l_error_message := SUBSTR(SQLERRM,1,100);
            XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_error_number||l_error_message );
    END cnc_purge_error_record_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE cnc_insert_line_record_prc( p_error_message        IN  XX_OIC_ERROR_LINES.error_message%TYPE    --IN PARAMETER--ERROR MESSAGE
                                , p_field                IN  XX_OIC_ERROR_LINES.field%TYPE            --IN PARAMETER--THE PARTICULAR FEILD WHERE THE ERROR EXSIST
                                , p_field_value          IN  XX_OIC_ERROR_LINES.field_value%TYPE      --IN PARAMETER--THE VALUE WHICH HAS RAISED THE ERROR
                                , p_record_id            IN  XX_OIC_ERROR_LINES.record_id%TYPE        --IN PARAMETER--THE RECORD ID
                                )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to insert the errors occured while validating   |
-- |                                                                                                    |
-- |  Input Parameters   :p_error_message  it refers to the error messages to be inserted in the error lines|
-- |                      p_field      it refere to the field name where the error has occured          |
-- |                      p_field_value it refers to the fiels value due to which error has occured     |
-- |                      p_record_id   it refers to the rowid                                           |
-- |                                                                                                    |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
       --invalid_val_exception EXCEPTION;
       l_request_id  XX_OIC_ERROR_LINES.request_id%TYPE;---- Variable to store the request_id
       l_program_id  XX_OIC_ERROR_LINES.program_id%TYPE;---- Variable to store the request_id
       l_object_name varchar2(100);         ---- Variable to store the object version number
       PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
          XX_OIC_ERRORS_PKG.g_sequence_id:=XX_OIC_ERRORS_PKG.g_sequence_id+1;
          l_request_id  :=  XX_OIC_ERRORS_PKG.g_request_id;
          l_program_id  :=  XX_OIC_ERRORS_PKG.g_program_id;

          INSERT INTO XX_OIC_ERROR_LINES ( request_id
                                      , program_id
                                      , error_sequence
                                      , error_message
                                      , field
                                      , field_value
                                      , record_id
                                      , creation_date
                                      , created_by
                                      , last_updated_date
                                      , last_updated_by
                                      , last_updated_login
                                      )
                               VALUES ( l_request_id
                                      , l_program_id
                                      , SUBSTR(XX_OIC_ERRORS_PKG.g_sequence_id,1,10)
                                      , SUBSTR(p_error_message,1,400)
                                      , SUBSTR(p_field,1,30)
                                      , SUBSTR(p_field_value,1,1000)
                                      , SUBSTR(p_record_id,1,40)
                                      , SYSDATE
                                      , l_created_by
                                      , SYSDATE
                                      , l_last_updated_by
                                      , l_last_updated_login
                                      );
       COMMIT;
    EXCEPTION
       WHEN DUP_VAL_ON_INDEX THEN
           l_inserrorlines_error_message := SUBSTR('Invalid Request Id + Seq No. ' || l_request_id ||
                                                     '! Duplicate Value - Error on Insert',1,500);
           l_inserrorlines_error_status  := 'E';
           XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_inserrorlines_error_message);
       WHEN OTHERS THEN
           l_inserrorlines_error_message := SUBSTR('Error in Procedure(Handle_error_lines) as p_record_id = : '||p_record_id ||SQLERRM,1,500);
           l_inserrorlines_error_status  := 'E';
           XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_inserrorlines_error_message);
           l_error_number  := SQLCODE;
           l_error_message := SUBSTR(SQLERRM,1,100);
           cnc_check_error_prc (l_inserrorlines_error_status, l_inserrorlines_error_message);
    END cnc_insert_line_record_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    FUNCTION cnc_show_errors_prc
                        ( p_module_name        IN VARCHAR2                           --IN PARAMETER--THE MODULE NAME
                        , p_request_id         IN NUMBER                             --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                        , p_program_id         IN NUMBER
                        )
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to show errors occured in the output file       |
-- |                                                                                                    |
-- |  Input Parameters   :  p_module_name     it refers to the module name                              |
-- |                        p_request_id      it refers to the request id of the concurrent program     |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
       l_wrap                 VARCHAR2(900);                                        ---- Variable to store the OUT Parameter--resulting message
       l_par1                 XX_OIC_ERROR_LINES.field_value%TYPE;                     ---- Variable to store the part message 1
       l_par2                 XX_OIC_ERROR_LINES.error_message%TYPE;                   ---- Variable to store the part message 2
       l_rec_id               XX_OIC_ERROR_LINES.record_id%TYPE;                       ---- Variable to store the record id
       l_record_id            XX_OIC_ERROR_LINES.record_id%TYPE;                       ---- Variable to store the record id
       l_field                XX_OIC_ERROR_LINES.field%TYPE;                           ---- Variable to store the the field name
       l_msg                  VARCHAR2(100);                                        ---- Variable to store the the error message
       l_count                NUMBER;                                               ---- Variable to store the count
       l_report_title         VARCHAR2(200);                                        ---- Variable to store the name of the report
       l_lines                NUMBER := 0;                                          ---- Variable to store the count of line
       l_flag                 NUMBER;                                               ---- Variable to store the page break flag setter
       l_par_cnt              NUMBER;                                               ---- Variable to store the filling blank spaces to the page till the page break
       l_no_of_lines          NUMBER := 65 ;                                         ---- Variable to store the number of lines
       l_conc_prog_name       apps.fnd_concurrent_programs_vl.concurrent_program_name%TYPE;---- Variable to store the concurrent program name
       l_page                 NUMBER := 1;                                          ---- Variable to store the page number
       l_summary_lines        VARCHAR2(100);                                        ---- Variable to store the summary lines
       l_cnt_wrap             NUMBER;                                               ---- Variable to store the count for wrap
       l_rst                  NUMBER;                                               ---- Variable to store the reset
       l_status               VARCHAR2(10);                                         ---- Variable to store the status
       l_prog_status          VARCHAR2(20);                                         ---- Variable to store the the program status
       l_parent_request_id    NUMBER;     -- parent request ID                      ---- Variable to store the parent request id
       l_child_request_id     NUMBER;                                                -- child request ID                      ---- Variable to store the child request id
       l_found                NUMBER := 0;
       -- cursor for record based error selection
       CURSOR cr_record_errors(l_request_id IN NUMBER, l_program_id IN NUMBER) -- selection from the error table with unique batch id and request id
       IS
       SELECT   TO_CHAR(SYSDATE, 'DD-MON-YY') today
         ,  CEH.request_id                request_id
         ,  CEL.error_sequence            error_sequence
         ,  CEL.record_id                 record_id
         ,  CEL.field                     field
         ,  CEL.field_value               fvalue
         ,  CEL.error_message             error_message
       FROM XX_OIC_ERROR_LINES   CEL
         ,  XX_OIC_ERROR_HEADERS CEH
       WHERE    CEH.request_id  =  CEL.request_id
       AND      CEH.program_id  =  CEL.program_id
       AND      CEH.request_id  =  l_request_id
       AND      CEH.program_id  =  l_program_id
       AND      UPPER(NVL(CEL.record_id,0)) <> UPPER('Validation Summary')
       ORDER BY CEH.program_id, CEH.request_id,CEL.error_sequence;
        -- cursor for summary records selection
       CURSOR cr_summary_errors(l_request_id IN NUMBER, l_program_id IN NUMBER) -- selection from the error table with unique batch id and request id
       IS
       SELECT   TO_CHAR(SYSDATE, 'DD-MON-YY') today
         ,  CEH.request_id                  request_id
         ,  CEL.error_sequence            error_sequence
         ,  CEL.record_id                 record_id
         ,  CEL.field                     field
         ,  CEL.field_value               fvalue
         ,  CEL.error_message             error_message
       FROM XX_OIC_ERROR_LINES   CEL
         ,  XX_OIC_ERROR_HEADERS CEH
       WHERE    CEH.request_id  =  CEL.request_id
       AND      CEH.program_id  =  CEL.program_id
       AND      CEH.request_id  =  l_request_id
       AND      CEH.program_id  =  l_program_id
       AND      UPPER(CEL.record_id) = UPPER('Validation Summary');

    BEGIN
       l_found  := 0;
       BEGIN
          l_parent_request_id := p_request_id;
          LOOP -- getting the parent ID
            SELECT FCR.parent_request_id
            INTO   l_child_request_id
            FROM   FND_CONCURRENT_REQUESTS FCR
            WHERE  FCR.request_id = l_parent_request_id;
            EXIT WHEN l_child_request_id is NULL OR l_child_request_id = -1;
            l_parent_request_id := l_child_request_id;
          END LOOP;

       -- getting the report set name
          SELECT FCR.DESCRIPTION
          INTO   l_report_title
          FROM   FND_CONCURRENT_REQUESTS FCR
          WHERE FCR.request_id = l_parent_request_id;

       -- if it is NULL then the concurrent program name is chosen
          IF LTRIM(RTRIM(l_report_title)) IS NULL THEN
             l_report_title    := XX_OIC_ERRORS_PKG.cnc_get_report_title_fnc(p_request_id); -- getting report title from the request id  ||' '|| p_module_name ||' '
          END IF;

       -- getting the concurrent program short name
          SELECT  fcp.concurrent_program_name
          INTO    l_conc_prog_name
          FROM    apps.fnd_concurrent_programs_vl fcp,
                  apps.fnd_concurrent_requests fcr
          WHERE   fcr.request_id = p_request_id
          AND     fcp.application_id = fcr.program_application_id
          AND     fcp.concurrent_program_id = fcr.concurrent_program_id;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_msg := 'Request id not passed properly';
               RETURN l_msg;
          WHEN OTHERS THEN
               l_msg := 'Unknown Exception while handling concurrent program name';
               RETURN l_msg;
      END;

      l_prog_status :=  XX_OIC_ERRORS_PKG.cnc_is_program_sucess_fnc(p_program_id);

      IF l_prog_status = 'SUCCESS' THEN
          --l_msg := XX_OIC_ERRORS_PKG.cnc_print_sucess_header_fnc(l_page,p_request_id,'   ');
          l_lines := 5;

          IF l_msg IS NOT NULL THEN
              RETURN l_msg;
          END IF;
      ELSE
          l_msg := XX_OIC_ERRORS_PKG.cnc_report_header_footer_fnc(l_page,l_conc_prog_name,p_request_id,l_report_title,'LOG');
          l_lines := 7;

          IF l_msg IS NOT NULL THEN
              RETURN l_msg;
          END IF;
      END IF;
        -- call for error field layout display
      FOR rec_cr_err_csr IN cr_record_errors(p_request_id,p_program_id) -- loop the data
      LOOP
      -- checking for NULL columns
          IF rec_cr_err_csr.fvalue IS NULL THEN
             l_par1 := 'NULL';
          ELSE
             l_par1 := rec_cr_err_csr.fvalue;
          END IF;

          IF rec_cr_err_csr.error_message IS NULL THEN
              l_par2 := 'NULL';
          ELSE
              l_par2 := rec_cr_err_csr.error_message;
          END IF;

          IF LTRIM(RTRIM(rec_cr_err_csr.field)) IS NULL THEN
              l_field := 'NULL';
          ELSE
              l_field := SUBSTR(rec_cr_err_csr.field,1,30);
          END IF;

          IF LTRIM(RTRIM(rec_cr_err_csr.record_id)) IS NULL THEN
              l_record_id := 'NULL';
          ELSE
              l_record_id := SUBSTR(rec_cr_err_csr.record_id,1,40);
          END IF;

     -- end of checking of NULL columns
     -- word wrap procedure
           XX_OIC_ERRORS_PKG.cnc_record_wrap_utility_fnc ( l_record_id
                                             , l_field
                                             , l_par1       -- message 1
                                             , l_par2       -- message 2
                                             , 20
                                             , 20
                                             , 22            -- length for mesaage 1
                                             , 33            -- length for mesaage 2
                                             , l_no_of_lines-- number of lines
                                             , l_lines      -- lines
                                             , l_par_cnt    -- partial count
                                             , l_status     -- Status
                                             , l_wrap       -- OUT Parameter--resulting message
                                             ) ;

          IF l_status = 'END' THEN -- wrapped string matching exactly at the end of the page
               apps.fnd_file.put_line(apps.fnd_file.LOG,l_record_id||'  '||RPAD(l_field,22,' ')||'    '||l_wrap);
               l_lines := l_lines + 7;
               l_page := trunc(l_lines/l_no_of_lines) + 1;
               l_msg := XX_OIC_ERRORS_PKG.cnc_report_header_footer_fnc(l_page,l_conc_prog_name,p_request_id,l_report_title,'LOG');
               apps.fnd_file.put_line(apps.fnd_file.LOG,l_wrap);

               IF l_msg IS NOT NULL THEN
                   RETURN l_msg;
               END IF;

          ELSIF l_status = 'MIDDLE' THEN --  wrapped string matching  at the middle of the page
               l_page := trunc(l_lines/l_no_of_lines) + 1;
                 apps.fnd_file.put_line(apps.fnd_file.LOG,l_wrap);
          ELSE
               FOR j IN 1..l_par_cnt -- filling blank spaces to the page till the page break
               LOOP
                  l_lines := l_lines + 1;
                  apps.fnd_file.put_line(apps.fnd_file.LOG,'   ');
               END LOOP;

               l_lines := l_lines + 7;
               l_page := trunc(l_lines/l_no_of_lines) + 1;
               l_msg := XX_OIC_ERRORS_PKG.cnc_report_header_footer_fnc(l_page,l_conc_prog_name,p_request_id,l_report_title,'LOG');

               IF l_msg IS NOT NULL THEN
                  RETURN l_msg;
               END IF;
                 apps.fnd_file.put_line(apps.fnd_file.LOG,l_wrap);

          END IF;
          l_found := 1;
      END LOOP; -- end loop
       IF l_found = 1 THEN 
           cnc_write_message_prc(1,'    ');
           cnc_write_message_prc(1,LPAD(RPAD('***************************************** End of Report **********************************',100),110));
           cnc_write_message_prc(1,'    ');
           cnc_write_message_prc(1,'    ');
       END IF;    
    -- end line demarcation
      l_msg := XX_OIC_ERRORS_PKG.cnc_report_header_footer_fnc(l_page,l_conc_prog_name,p_request_id,l_report_title,'OUTPUT');
    -- call for summary record display
      FOR rec_sum_err_csr IN cr_summary_errors(p_request_id,p_program_id) -- loop the data
      LOOP
         IF UPPER(nvl(LTRIM(RTRIM(rec_sum_err_csr.field)),'0')) = 'TOTAL' THEN
            l_summary_lines := 'Number of Records Count        ';
         ELSIF UPPER(nvl(LTRIM(RTRIM(rec_sum_err_csr.field)),'0')) = 'FAILURE' THEN
            l_summary_lines := 'Number of Records Errored    ';
         ELSIF UPPER(nvl(LTRIM(RTRIM(rec_sum_err_csr.field)),'0')) = 'SUCCESS' THEN
            l_summary_lines := 'Number of Records Successfully Processed ';
         ELSE
            l_summary_lines := nvl(rec_sum_err_csr.field,0);
         END IF;
         cnc_write_message_prc( 2,'               '||'Total '||RPAD(l_summary_lines,40,' ')||' : '||LPAD(nvl(rec_sum_err_csr.fvalue,0),23,' '));
      END LOOP;
      cnc_write_message_prc(2,'    ');
      cnc_write_message_prc(2,LPAD(RPAD('***************************************** End of Report **********************************',100),110));
      cnc_write_message_prc(2,'    ');
      cnc_write_message_prc(2,'    ');
      RETURN l_msg;
    EXCEPTION
      WHEN OTHERS THEN
        l_msg := 'Unknown Exception on trying to display errors'||' '||SQLERRM;
        RETURN l_msg;
    END cnc_show_errors_prc;


   ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    FUNCTION cnc_get_report_title_fnc( p_reqid         IN NUMBER)
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used get the report title                            |
-- |                                                                                                    |
-- |  Input Parameters   :  p_reqid   it refers to the request id of the concurrent program             |
-- |                                                                                                    |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
       l_report_title VARCHAR2(80);  ---- Variable to store the report title
    BEGIN
       SELECT  FCP.user_concurrent_program_name
       INTO    l_report_title
       FROM    apps.fnd_concurrent_programs_vl FCP,
               apps.fnd_concurrent_requests FCR
       WHERE   FCR.request_id = p_reqid
       AND         FCP.application_id = FCR.program_application_id
       AND         FCP.concurrent_program_id = FCR.concurrent_program_id;
       RETURN  l_report_title;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END cnc_get_report_title_fnc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    FUNCTION cnc_is_program_sucess_fnc( p_program_id  IN  NUMBER )                          --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
    RETURN VARCHAR2
-- +=====================================================================================================+
-- |                                          Oracle NAIO (India)                                        |
-- |                                          Bangalore, India                                           |
-- +=====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used toverify whether the validation run was a success|
-- |                                                                                                     |
-- |  Input Parameters   :   p_request_id      It refers to the request id of the concurrent program     |
-- |                                                                                                     |
-- |  Return Value       :                                                                               |
-- |   Change History                                                                                    |
-- |  -----------------                                                                                  |
-- |  WHO              Version   WHEN              HISTORY                                               |
-- |  --------------   ------- ---------------   -----------------------------------------               |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                     |
-- +=====================================================================================================+
    IS

       l_count NUMBER;---- Variable to store the counts the number of occurences of the errors
    BEGIN
       SELECT  COUNT(*)
       INTO    l_count
       FROM    XX_OIC_ERROR_LINES   CEL
             , XX_OIC_ERROR_HEADERS CEH
       WHERE   CEH.program_id   = CEL.program_id
       AND     CEH.program_id = p_program_id
       AND     UPPER(NVL(CEL.record_id,0)) <> UPPER('Validation Summary');

       IF l_count = 0 THEN
          RETURN 'SUCCESS';
       ELSE
          RETURN 'FAIL';
       END IF;

    EXCEPTION
       WHEN OTHERS THEN
          RETURN 'FAIL';
    END cnc_is_program_sucess_fnc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    FUNCTION get_instance_name
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to get the instance name                        |
-- |                                                                                                    |
-- |  Input Parameters   :                                                                              |
-- |                                                                                                    |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS

       l_instance_name VARCHAR2(20); ---- Variable to store the instance name
    BEGIN
       SELECT  SUBSTR(name,1,6)
       INTO    l_instance_name
       FROM    v$database;
       RETURN  l_instance_name;
    EXCEPTION
       WHEN OTHERS THEN
          RETURN NULL;
    END  get_instance_name;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    FUNCTION cnc_print_sucess_header_fnc
                                (p_page_no    IN  NUMBER                            --IN PARAMETER--THE PAGE NUMBER
                                ,p_request_id IN  NUMBER                            --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                ,p_header     IN VARCHAR2 )                         --IN PARAMETER--THE HEADER NAME
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This  Procedure  is  used to provide with the output file format               |
-- |                    and show the header name on the report                                          |
-- |  Input Parameters   : p_page_no     it refers to the page number of the output file                |
-- |                       p_request_id  it refers to the request id generated of the concurrent program|
-- |                       p_header      it refers to the header name                                   |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS

        l_sob_name          VARCHAR2(100);--local variable for set of books
        l_instance_name     VARCHAR2(100);--local variable for instance name
        l_title             VARCHAR2(100);--local variable for title
        l_report_title      VARCHAR2(100);--local variable for report title
        l_msg               VARCHAR2(100);--local variable for message
        l_conc_prog_name    VARCHAR2(200);--local variable for concurrent program short name
        l_part1             VARCHAR2(100);--local variable for message 1 to be conactenated
        l_req_design        VARCHAR2(100);--local variable for request id trimming purpose
        l_part_no           NUMBER := 0;  --local variable for getting the count of blank spaces
        l_left_padder       VARCHAR2(106) := ' '; --local variable for space padder
        l_parent_request_id NUMBER;       -- local variable for parent request ID
        l_child_request_id  NUMBER;       -- local variable for child request ID
        l_left_position     NUMBER;       -- local variable for left position
        l_header_printed    VARCHAR2(106);-- local variable for formatted header layout
        l_report_len        NUMBER;       -- local variable for report length
        l_title_len         NUMBER;       -- local variable for title length
        l_mid_len           NUMBER := 56; -- local variable for length of the middle string
        l_str_mid_len       NUMBER := 48; -- local variable for string mid length
        l_left_len          NUMBER := 25; -- local variable for length of the left side string
        l_program_name     VARCHAR2(100);

       CURSOR c_program_name IS
           SELECT  program_name
           FROM XX_OIC_ERROR_HEADERS
           WHERE program_id = g_program_id;

    BEGIN
       
       FOR rec_program_name  IN  c_program_name LOOP
         l_program_name  :=  rec_program_name.program_name;
       END LOOP;

        BEGIN
           l_parent_request_id := p_request_id;
           BEGIN
               LOOP -- getting the parent ID
                  SELECT FCR.parent_request_id
                  INTO   l_child_request_id
                  FROM   FND_CONCURRENT_REQUESTS FCR
                  WHERE  FCR.request_id = l_parent_request_id;
                  EXIT WHEN l_child_request_id is NULL OR l_child_request_id = -1;
                  l_parent_request_id := l_child_request_id;
               END LOOP;

          -- getting the report set name
               SELECT FCR.DESCRIPTION
               INTO   l_report_title
               FROM   FND_CONCURRENT_REQUESTS FCR
               WHERE FCR.request_id = l_parent_request_id;

          -- if it is NULL then the concurrent program name is chosen
               IF LTRIM(RTRIM(l_report_title)) IS NULL THEN
                  l_report_title    := XX_OIC_ERRORS_PKG.cnc_get_report_title_fnc(p_request_id); -- getting report title from the request id
               END IF;

           EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  l_report_title    := XX_OIC_ERRORS_PKG.cnc_get_report_title_fnc(p_request_id); -- getting report title from the request id
               WHEN OTHERS THEN
                  l_report_title    := XX_OIC_ERRORS_PKG.cnc_get_report_title_fnc(p_request_id); -- getting report title from the request id
           END;

         -- getting the concurrent program short name
           SELECT  fcp.concurrent_program_name
           INTO    l_conc_prog_name
           FROM    apps.fnd_concurrent_programs_vl fcp,
                   apps.fnd_concurrent_requests fcr
           WHERE   fcr.request_id = p_request_id
           AND     fcp.application_id = fcr.program_application_id
           AND     fcp.concurrent_program_id = fcr.concurrent_program_id;

       EXCEPTION
          WHEN NO_DATA_FOUND THEN
                l_msg := 'Request id not passed properly';
                RETURN l_msg;
          WHEN OTHERS THEN
                l_msg := 'Unknown Exception while handling concurrent program name';
                RETURN l_msg;
       END;
       l_sob_name        := XX_OIC_ERRORS_PKG.cnc_get_set_of_book_fnc; -- getting the set of book name
       l_instance_name   := XX_OIC_ERRORS_PKG.GET_INSTANCE_NAME; -- getting the instance name
       l_part1           := SUBSTR(RPAD(l_conc_prog_name,l_left_len,' '),1,l_left_len); -- getting the conc prog short name
       l_part_no         := length(l_part1) - length(RTRIM(l_part1)); -- getting the count of blank spaces
       l_part1           := RTRIM(l_part1); -- trimming the string
       l_mid_len         := l_mid_len + l_part_no ;-- the middle length alteration
       l_str_mid_len     := l_str_mid_len + l_part_no ; -- the second line length alteration
       l_title           := l_sob_name||' - '||l_instance_name; -- second line in the layout
       l_title           := SUBSTR(l_title,1,l_str_mid_len); -- truncatiing them to exact length
       l_title_len       := length(l_title) + (l_mid_len - length(l_title))/2; -- centralization
       l_title_len       := trunc(l_title_len);
       l_req_design      := SUBSTR(RPAD(to_char(p_request_id),l_left_len,' '),1,length(l_part1));
       l_report_title    := SUBSTR(l_report_title,1,l_str_mid_len);
       l_report_len      := length(l_report_title) + (l_mid_len - length(l_report_title))/2; -- centralization
       l_report_len      := trunc(l_report_len);
       l_left_position   := CEIL((114 - length(p_header))/2)-1;
       l_header_printed  := LPAD(l_left_padder,l_left_position,' ')||p_header;

       l_report_title    := '  '||LPAD(RPAD(l_report_title ,l_report_len,' '),l_mid_len,' '); -- first line of the layout
       l_title           := '  '||LPAD(RPAD(l_title , l_title_len,' '),l_mid_len,' '); -- second line of the layout
    --  printing the layout
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,' ');
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,' ');
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,'-------------------------------------------------------------------------------------------------------------');
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,'Name       : '||l_part1||l_report_title||'Date : '||to_char(SYSDATE,'DD-MON-YYYY'));
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,'Request ID : '||l_req_design||l_title||'Page : '||to_char(p_page_no));
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,l_header_printed);
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,'-------------------------------------------------------------------------------------------------------------');
       apps.fnd_file.put_line(apps.fnd_file.OUTPUT,' ');
      RETURN NULL;
    EXCEPTION
       WHEN OTHERS THEN
          l_msg := 'Unknown Exception on cnc_print_sucess_header_fnc';
          RETURN l_msg;
    END cnc_print_sucess_header_fnc;

  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE cnc_record_wrap_utility_fnc 
                                  ( p_str1           IN VARCHAR2                           --IN PARAMETER--THE STRING 1
                                  , p_str2           IN VARCHAR2                           --IN PARAMETER--THE STRING 2
                                  , p_str3           IN VARCHAR2                           --IN PARAMETER--THE STRING 3
                                  , p_str4           IN VARCHAR2                           --IN PARAMETER--THE STRING 4
                                  , p_limit1         IN NUMBER                             --IN PARAMETER--THE LIMIT 1
                                  , p_limit2         IN NUMBER                             --IN PARAMETER--THE LIMIT 2
                                  , p_limit3         IN NUMBER                             --IN PARAMETER--THE LIMIT 3
                                  , p_limit4         IN NUMBER                             --IN PARAMETER--THE LIMIT 4
                                  , p_no_of_lines    IN NUMBER                             --IN PARAMETER--THE NUMBER OF LINES
                                  , p_count          IN OUT NUMBER                         --IN PARAMETER--THE COUNT
                                  , p_par_cnt        OUT NUMBER                            --OUT PARAMETER--THE PARTIAL COUNT TILL THE PAGE BREAK ENCOUNTERED
                                  , p_status         OUT VARCHAR2                          --OUT PARAMETER--THE STATUS
                                  , p_conc           OUT VARCHAR2                          --OUT PARAMETER--THE COUNT
                                  )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used to  concatenate two strings                     |
-- |                                                                                                    |
-- |  Input Parameters   : p_str1      it refers to the string1                                         |
-- |                       p_str2      it refers to the string2                                         |
-- |                       p_limit1    it refers to the limit1                                          |
-- |                       p_limit2    it refers to the limit2                                          |
-- |                       p_no_of_lines it refers to the number of lines                               |
-- |                                                                                                    |
-- |  Return Value       : p_count     it refers to the count                                           |
-- |                       p_par_cnt   it refers to the count till the line break                       |
-- |                       p_status    it refers to the status                                          |
-- |                       p_conc      it refers to the concatenated count                              |
-- |                                                                                                    |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
        l_dummy    VARCHAR2(500); -- the line of 2 strings concatenated
        l_flag     NUMBER := 0;   -- page break flag setter
        l_str1     VARCHAR2(500); -- input string1
        l_str2     VARCHAR2(500); -- same as p_str2 initially
        l_str3     VARCHAR2(500); -- same as p_str3 initially
        l_str4     VARCHAR2(500); -- same as p_str4 initially
        l_sub1     VARCHAR2(200); -- substring to the p_limit1 of p_str1
        l_sub2     VARCHAR2(200); -- substring to the p_limit2 of p_str2
        l_sub3     VARCHAR2(200); -- substring to the p_limit3 of p_str3
        l_sub4     VARCHAR2(200); -- substring to the p_limit4 of p_str4
        l_cnt_wrap NUMBER := 0;   -- number of lines in the concatenated string


    BEGIN
     -- initializing the variables
       p_par_cnt := 0;
       l_str1 := p_str1;
       l_str2 := p_str2;
       l_str3 := p_str3;
       l_str4 := p_str4;
        -- checking for the loop of the two input strings for NULL condition
       WHILE LTRIM(RTRIM(l_str1)) IS NOT NULL OR LTRIM(RTRIM(l_str2)) IS NOT NULL
          OR LTRIM(RTRIM(l_str3)) IS NOT NULL OR LTRIM(RTRIM(l_str4)) IS NOT NULL
       LOOP
           l_sub1 := substr(l_str1,1,p_limit1); -- taking the substring of string1 for the input limit
           l_str1 := substr(l_str1,p_limit1+1,length(p_str1)); -- removing the string which has been selected for concatenation
           l_sub1 := LTRIM(RTRIM(l_sub1)); -- trimming on both sides
           l_sub2 := substr(l_str2,1,p_limit2); -- taking the substring of string2 for the input limit
           l_str2 := substr(l_str2,p_limit2+1,length(p_str2));-- removing the string which has been selected for concatenation
           l_sub2 := LTRIM(RTRIM(l_sub2)); -- trimming on both sides
           l_sub3 := substr(l_str3,1,p_limit3); -- taking the substring of string3 for the input limit
           l_str3 := substr(l_str3,p_limit3+1,length(p_str3));-- removing the string which has been selected for concatenation
           l_sub3 := LTRIM(RTRIM(l_sub3)); -- trimming on both sides
           l_sub4 := substr(l_str4,1,p_limit4); -- taking the substring of string4 for the input limit
           l_str4 := substr(l_str4,p_limit4+1,length(p_str4));-- removing the string which has been selected for concatenation
           l_sub4 := LTRIM(RTRIM(l_sub4)); -- trimming on both sides

           IF l_sub1 IS NULL THEN  -- checking if the substring of the first string is null
               l_sub1 := '    ';
           END IF;

           IF l_sub2 IS NULL THEN  -- checking if the substring of the second string is null
               l_sub2 := '    ';
           END IF; -- l_dummy will have the concatenated string of two input substrings

           IF l_sub3 IS NULL THEN  -- checking if the substring of the second string is null
               l_sub3 := '    ';
           END IF; -- l_dummy will have the concatenated string of two input substrings

           IF l_sub4 IS NULL THEN  -- checking if the substring of the second string is null
               l_sub4 := '    ';
           END IF; -- l_dummy will have the concatenated string of two input substrings

           l_dummy := rpad(l_sub1,p_limit1,' ')
                    || lpad(rpad(l_sub2,p_limit2,' '),(p_limit2 + 5),' ')
                    || lpad(rpad(l_sub3,p_limit3,' '),(p_limit3 + 5),' ')
                    || lpad(rpad(l_sub4,p_limit4,' '),(p_limit4 + 5),' ') ;

           IF l_sub1 IS NULL AND l_sub2 IS NULL AND l_sub3 IS NULL AND l_sub4 IS NULL THEN
              NULL;
           ELSE
              l_cnt_wrap := l_cnt_wrap +  1; -- getting the count of the concatenated string
              IF p_conc IS NULL THEN -- initially it will be NULL
                    p_count:= p_count + 1;
                    IF l_flag = 0 THEN
                        p_par_cnt := p_par_cnt + 1; --getting the count of the concatenated string before page break
                    END IF;
                    p_conc := l_dummy;
                    IF mod(p_count,p_no_of_lines) = 0 THEN -- checking for page break
                        l_flag := 1; -- page break flag has been set
                        apps.FND_FILE.PUT_LINE(apps.FND_FILE.LOG,CHR(12));  -- For page Break -- Refer Version 1.5 of Change History
                    END IF;
              ELSE  -- the second loop will have p_conc not null
                    p_conc := p_conc||chr(10)||LPAD(l_dummy,110); -- chr(10) to pasre into the second line
                    p_count:= p_count + 1;
                    IF l_flag = 0 THEN
                       p_par_cnt := p_par_cnt + 1;
                    END IF;

                    IF mod(p_count,p_no_of_lines) = 0 THEN -- checking for page break
                         l_flag := 1; -- page break flag has been set
                         apps.FND_FILE.PUT_LINE(apps.FND_FILE.LOG,CHR(12));  -- For page Break -- Refer Version 1.5 of Change History
                    END IF;
              END IF;
           END IF;
       END LOOP;

       IF (p_par_cnt = l_cnt_wrap) AND l_flag = 1 THEN
         p_status := 'END'; -- the wrapped string is  happening exactly at the end of the page
       ELSIF (p_par_cnt = l_cnt_wrap) AND l_flag = 0 THEN
         p_status := 'MIDDLE'; -- the wrapped string is  happening in the middle of the page
       ELSIF l_flag = 1 THEN
         p_status := 'BREAK'; -- the wrapped string is  before and after the page break
       END IF;

     EXCEPTION
       WHEN OTHERS THEN
          apps.fnd_file.put_line(apps.fnd_file.OUTPUT,'Unknown error'||' '||SQLERRM);
     END cnc_record_wrap_utility_fnc;



  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    FUNCTION cnc_get_set_of_book_fnc
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This Procedure  is  used to get the user/responsibility/application name       |
-- |                                                                                                    |
-- |  Input Parameters   :                                                                              |
-- |                                                                                                    |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
         l_sob_name varchar2(80); -- Variable to store the  set of books
    BEGIN
         l_sob_name := apps.FND_PROFILE.value_specific('GL_SET_OF_BKS_NAME');
         RETURN l_sob_name;
    EXCEPTION
         WHEN OTHERS THEN
            RETURN NULL;
    END cnc_get_set_of_book_fnc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------


    PROCEDURE  cnc_generate_summary_log_prc
                                   ( p_program_name     IN  VARCHAR2                          --IN PARAMETER --THE PROGRAM NAME
                                   , p_request_id       IN  VARCHAR2                          --IN PARAMETER --THE REQUEST ID
                                   , p_total_rec_cnt    IN  NUMBER                            --IN PARAMETER --THE TOTAL RECORD COUNT
                                   , p_valid_rec_cnt    IN  NUMBER                            --IN PARAMETER --THE VALID RECORD COUNT
                                   , p_error_rec_cnt    IN  NUMBER                            --IN PARAMETER --THE ERROR RECORD COUNT
                                   , p_retcode          OUT NUMBER                            --OUT PARAMETER--THE RETURNCODE
                                   )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description        This is a  Procedure  is  used to generate the summary log                     |
-- |                                                                                                    |
-- |  Input Parameters   : p_program_name      it refers to the programe name                           |
-- |                       p_request_id        it refers to the request id                              |
-- |                       p_total rec_cnt     it refers to the total record count                      |
-- |                       p_valid_rec_cnt     it refers to the valid record count                      |
-- |                       p_error_rec_cnt     it refers to the error record count                      |
-- |  Return Value       : p_retcode           it refers to the return code                             |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
     IS
         l_program_id               XX_OIC_ERROR_HEADERS.program_id%TYPE;
         l_report_generation_error  VARCHAR2(500); -- Variable to store the report generation errors
         others_exception            EXCEPTION;    -- Variable to store the other exceptions

     BEGIN

               l_program_id    :=   g_program_id;

               cnc_insert_line_record_prc( p_error_message               => 'TOTAL RECORD COUNT'
                                 , p_field                       => 'TOTAL'
                                 , p_field_value                 =>  p_total_rec_cnt
                                 , p_record_id                   => 'VALIDATION SUMMARY'
                                 ) ;

               cnc_insert_line_record_prc( p_error_message               => 'SUCCESS COUNT'
                                 , p_field                       => 'SUCCESS'
                                 , p_field_value                 =>  p_valid_rec_cnt
                                 , p_record_id                   => 'VALIDATION SUMMARY'
                                 ) ;

               cnc_insert_line_record_prc( p_error_message               => 'FAILURE COUNT'
                                 , p_field                       => 'FAILURE'
                                 , p_field_value                 =>  p_error_rec_cnt
                                 , p_record_id                   => 'VALIDATION SUMMARY'
                                 ) ;

               l_report_generation_error := XX_OIC_ERRORS_PKG.cnc_show_errors_prc ( p_program_name
                                                                       , p_request_id
                                                                       , l_program_id
                                                                       ) ;

               IF l_report_generation_error is not null THEN
                       XX_OIC_ERRORS_PKG.cnc_write_message_prc(1,l_report_generation_error);
               END IF;

     EXCEPTION
         WHEN others_exception Then
            p_retcode := 2;
            RETURN;
         WHEN OTHERS THEN
            XX_OIC_ERRORS_PKG.cnc_debug_message_prc ( 'Y', 'PRE-DEFINED ERROR WHILE UPDATING VALIDATION SUMMARY' || SQLERRM);
            p_retcode := 2;
            RETURN;
     END cnc_generate_summary_log_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    PROCEDURE  cnc_debug_message_prc 
                             ( p_debug_mode            IN  VARCHAR2                          --IN PARAMETER--THE DEBUG MODE CAN BE Y OR N
                             , p_message               IN  VARCHAR2                          --IN PARAMETER--THE THE ERROR MESSAGE
                             )
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :     This is a  Procedure  is  used for debugging purpose                           |
-- |                                                                                                    |
-- |  Input Parameters   : p_debug_mode      it refers to the debug mode which can be either 'Y' or 'N' |
-- |                       p_message         it refers to the error message to be shown on exception    |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
    IS
    BEGIN
          IF p_debug_mode = 'Y' then
              XX_OIC_ERRORS_PKG.cnc_write_message_prc(2,p_message);
          END IF;
    END cnc_debug_message_prc;


  ---------------------------------------------------------------------------------------------------
-----------------------------------<                              >------------------------------------
  ---------------------------------------------------------------------------------------------------

    FUNCTION cnc_report_header_footer_fnc
                                 (p_page_no      IN NUMBER                             --IN PARAMETER--THE PAGE NUMBER
                                 ,p_conc_prog_name IN apps.fnd_concurrent_programs_vl.concurrent_program_name%TYPE --IN PARAMETER--THE CONCURRENT PROGRAM NAME
                                 ,p_request_id   IN NUMBER                             --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                 ,p_report_title IN VARCHAR2                           --IN PARAMETER--THE TITLE OF THE REPORT
                                 ,p_destination  IN VARCHAR2                           --IN PARAMETER--To find whter to wite into OUTPUT or LOG File
                                 )
    RETURN VARCHAR2
-- +====================================================================================================+
-- |                                          Oracle NAIO (India)                                       |
-- |                                          Bangalore, India                                          |
-- +====================================================================================================+
-- |  Description  :       This  Procedure  is  used to provide with the output file format             |
-- |                    and show the page number,concurrent program name,request id on the report       |
-- |  Input Parameters   :  p_page_no         it refers to the page number generated at the report      |
-- |                        p_conc_prog_name  it refers to the concurrent program name                  |
-- |                        p_request_id      it refers to the request id of the concurrent program     |
-- |                        p_report_title    it refers to the title of the report                      |
-- |  Return Value       :                                                                              |
-- |   Change History                                                                                   |
-- |  -----------------                                                                                 |
-- |  WHO              Version   WHEN              HISTORY                                              |
-- |  --------------   ------- ---------------   -----------------------------------------              |
-- |   Nageswara Rao   1.0     01-Aug-07          Original Version                                      |
-- |                                                                                                    |
-- +====================================================================================================+
     IS

       l_sob_name        VARCHAR2(100);-- Variable to store the  set of books
       l_instance_name   VARCHAR2(100);-- Variable to store the instance name
       l_title           VARCHAR2(100);--local variable for title
       l_report_title    VARCHAR2(100);--local variable for report title
       l_msg             VARCHAR2(100);--local variable for message
       l_part1           VARCHAR2(100);--local variable for message 1 to be conactenated
       l_req_design      VARCHAR2(100);--local variable for request id trimming purpose
       l_part_no         NUMBER := 0;  --local variable for getting the count of blank spaces

       l_report_len      NUMBER;       -- local variable for report length
       l_title_len       NUMBER;       -- local variable for title length
       l_mid_len         NUMBER := 50; -- length of the middle string
       l_str_mid_len     NUMBER := 43; -- local variable for string mid length
       l_left_len        NUMBER := 25; -- length of the left side string
       l_program_name     VARCHAR2(100);

       CURSOR c_program_name IS
           SELECT  program_name
           FROM XX_OIC_ERROR_HEADERS
           WHERE program_id = g_program_id;

    BEGIN
       
       FOR rec_program_name  IN  c_program_name LOOP
         l_program_name  :=  rec_program_name.program_name;
       END LOOP;
       
       l_sob_name        := XX_OIC_ERRORS_PKG.cnc_get_set_of_book_fnc; -- getting the set of book name
       l_instance_name   := XX_OIC_ERRORS_PKG.get_instance_name; -- getting the instance name
       l_part1           := SUBSTR(RPAD(p_conc_prog_name,l_left_len,' '),1,l_left_len); -- getting the conc prog short name
       l_part_no         := length(l_part1) - length(RTRIM(l_part1)); -- getting the count of blank spaces
       l_part1           := RTRIM(l_part1); -- trimming the string
       l_mid_len         := l_mid_len + l_part_no ;-- the middle length alteration
       l_str_mid_len     := l_str_mid_len + l_part_no ; -- the second line length alteration
       l_report_title    := p_report_title; -- report title
       l_title           := l_program_name;--||' - '||l_instance_name; -- second line in the layout
       l_title           := SUBSTR(l_title,1,l_str_mid_len); -- truncatiing them to exact length
       l_title_len       := length(l_title) + (l_mid_len - length(l_title))/2; -- centralization
       l_title_len       := trunc(l_title_len);
       l_req_design      := SUBSTR(RPAD(to_char(p_request_id),l_left_len,' '),1,length(l_part1));
       l_report_title    := SUBSTR(l_report_title,1,l_str_mid_len);
       l_report_len      := length(l_report_title) + (l_mid_len - length(l_report_title))/2; -- centralization
       l_report_len      := trunc(l_report_len);

       l_report_title    := '  '||LPAD(RPAD(l_report_title ,l_report_len,' '),l_mid_len,' '); -- first line of the layout
       l_title           := '  '||LPAD(RPAD(l_title , l_title_len,' '),l_mid_len,' '); -- second line of the layout
     -- printing the layout

       IF p_destination = 'LOG' Then
           cnc_write_message_prc( 1,'-------------------------------------------------------------------------------------------------------------');
           cnc_write_message_prc( 1,'Name      : '||l_part1||l_report_title||'Date: '||to_char(SYSDATE,'DD-MON-YYYY'));
           cnc_write_message_prc( 1,'Request ID: '||l_req_design||l_title||'Page: '||to_char(p_page_no));
           cnc_write_message_prc( 1,'    ');
           cnc_write_message_prc( 1,'-------------------------------------------------------------------------------------------------------------');
           cnc_write_message_prc( 1,'Record Number            Field Name               Field Value              Error-Message ');
           cnc_write_message_prc( 1,'--------------------     --------------------     --------------------     ----------------------------------');
           cnc_write_message_prc( 1,'    ');
       ELSIF p_destination = 'OUTPUT' Then
           cnc_write_message_prc( 2,'-------------------------------------------------------------------------------------------------------------');
           cnc_write_message_prc( 2,'Name       : '||l_part1||l_report_title||'Date : '||to_char(SYSDATE,'DD-MON-YYYY'));
           cnc_write_message_prc( 2,'Request ID : '||l_req_design||l_title);
           cnc_write_message_prc( 2,'    ');
           cnc_write_message_prc( 2,'-------------------------------------------------------------------------------------------------------------');
           cnc_write_message_prc( 2,'    ');
       END IF;
       RETURN NULL;
    EXCEPTION
       WHEN OTHERS THEN
           l_msg := 'Unknown Exception on cnc_show_errors_prc report title';
           RETURN l_msg;

    END cnc_report_header_footer_fnc;

END  XX_OIC_ERRORS_PKG;
/