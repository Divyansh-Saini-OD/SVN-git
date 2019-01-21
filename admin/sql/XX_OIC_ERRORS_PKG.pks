SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


   -- +===================================================================+
   -- |                  Office Depot - Project Simplify                  |
   -- |                Oracle NAIO Consulting Organization                |
   -- +===================================================================+
   -- | Name        : XX_OIC_ERRORS_PKG.pks                                    |
   -- | Description : Plan copy error routine                             |
   -- |               COPY Object                                         |
   -- | Author      : Nageswara Rao                                       |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |                                                                   |
   -- |Date      Version     Description                                  |
   -- |=======   ==========  =============                                |
   -- |01-Aug-07   1.0       Initial Draft version                        |
   -- +===================================================================+
   
CREATE OR REPLACE PACKAGE APPS.XX_OIC_ERRORS_PKG
AUTHID CURRENT_USER
AS

g_sta_update_error        VARCHAR2(3000);
g_sequence_id             NUMBER (15);
g_request_id              NUMBER (15);
g_program_id              NUMBER (15);
g_debug_flag              VARCHAR2(1);

-- +===================================================================================================+
-- |                                          Oracle NAIO (India)                                      |
-- |                                          Bangalore, India                                         |
-- +===================================================================================================+
-- +===================================================================================================+
-- |                                                                                                   |
-- |  Object Name        : Error Packgae                                                               |
-- |  Package Name       : XX_OIC_ERRORS_PKG                                                           |
-- |  File Name and Path :                                                                             |
-- |  Author Name        : Nageswara Rao                                 |
-- |  Company Name       : Oracle Corporation                                                          |
-- |  Purposes           : This package contains Procedures to handle errors generated for             |
-- |                       the validation of plan copy objects.                                        |
-- |                                                                                                   |
-- |  Sl No Procedure Name                                  Description                                |
-- |  ----- ---------------                   -----------------------------------------                |
-- |  1     cnc_check_error_prc                     Procedure checks if an error has occurred          |
-- |                                                                                                   |
-- |  2     cnc_insert_header_record_prc            Inserts the error details into the headers table   |
-- |                                                                                                   |
-- |  3     cnc_update_header_record_prc            Updates the error headers table                    |
-- |                                                                                                   |
-- |  4     cnc_delete_header_record_prc            Deletes the error details from the headers  table  |
-- |                                                                                                   |
-- |  5     cnc_purge_error_record_prc              Deletes the errors from headers and error lines    |
-- |                                                                                                   |
-- |  6     cnc_insert_line_record_prc              Inserts the error messages into headers and error  |
-- |                                                lines                                              |
-- |                                                                                                   |
-- |  7     cnc_show_errors_prc                     Shows errors to the user through the log file      |
-- |                                                                                                   |
-- |  8     cnc_write_message_prc                   Writes the error message                           |
-- |                                                                                                   |
-- |                                                                                                   |
-- |  9     cnc_get_report_title_fnc                Error details displayed for the front end user     |
-- |                                                                                                   |
-- |  10    cnc_record_wrap_utility_fnc             Gives the details of the number of errors occurred,|
-- |                                           number successfully completed                           |
-- |                                                                                                   |
-- |  11    cnc_get_set_of_book_fnc                 Gets the set of books name                         |
-- |                                                                                                   |
-- |  12    cnc_is_program_sucess_fnc               Gives the status if the program is successful      |
-- |                                                                                                   |
-- |  13    cnc_print_sucess_header_fnc             Prints the details on the log file when the     |
-- |                                                program is a  success                              |
-- |  14    cnc_generate_summary_log_prc            Generates the summary log in the output report     |
-- |                                                                                                   |
-- |  15    cnc_debug_message_prc                   Used for the debugging purpose                     |
-- |                                                                                                   |
-- |  16    cnc_report_header_footer_fnc       Used for the debug level hesder footer                  |
-- |  Modification Log:                                                                                |
-- |  Version      Date               Modified By                Remarks                               |
-- |  ------------------------------------------------------------------------------------             |
-- |  1.0         01-AUG-2007         Nageswara Rao    Original Version                             | 
-- |                                                                                                   |
-- +===================================================================================================+

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|   It is an internal procedure used by other procedures to change the proc_status |
--|   as error ed.                                                                   |
--| Prerequisites:                                                                   |
--|   None                                                                           |
--|                                                                                  |
--| Post Success:                                                                    |
--|  The out parameter will have the status as 'E' and the error message             |
--| Post Failure:                                                                    |
--|  None                                                                            |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|
    PROCEDURE cnc_check_error_prc 
                          ( p_status                OUT VARCHAR2                          --OUT PARAMETER-- PROCEDURE STATUS
                          , p_err_msg               OUT VARCHAR2                          --OUT PARAMETER-- ERROR MESSAGE
                          ) ;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--| This is a  Procedure  is  used while using batch processing the batch id is      |
--| inserted into this table(name of the batch)                                      |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   None                                                                           |
--|                                                                                  |
--| Post Success:                                                                    |
--|   The the request id and the program name will get inserted in the table         |
--| Post Failure:                                                                    |
--|   Application error will be generated.                                           |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|

    PROCEDURE cnc_insert_header_record_prc 
                                   ( p_pgm_name              IN   XX_OIC_ERROR_HEADERS.program_name%TYPE  --IN PARAMETER-- THE PROGRAME NAME FOR WHICH THE VALIDATION HAS STARTED
                                   , p_request_id            IN   XX_OIC_ERROR_HEADERS.request_id%TYPE    --IN PARAMETER-- THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                   ) ;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|   This is a  Procedure  is  used to update the header table data                 |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   allready the data should exsist in the table                                   |
--|                                                                                  |
--| Post Success:                                                                    |
--|   the data in the error headers table will be updated                            |
--| Post Failure:                                                                    |
--|   the out parameter will be errored and will send back the error message         |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|

    PROCEDURE cnc_update_header_record_prc 
                                   ( p_program_id            IN  XX_OIC_ERROR_HEADERS.program_id%TYPE     --IN PARAMETER-- THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                   , p_batch_rec_cnt         IN  XX_OIC_ERROR_HEADERS.record_count%TYPE   --IN PARAMETER-- TOTAL NUMBER OF RECORDS IN THE BATCH
                                   , p_process_flag          IN  XX_OIC_ERROR_HEADERS.process_flag%TYPE   --IN PARAMETER-- THE PROCESS FLAG
                                   );
--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|    This is a  Procedure  is  used to delete the header lines from the            |
--|                     XX_OIC_ERROR_HEADERS                                                |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   those lines which exsist in the search criteria will only be deleted from the  |
--|   headers table                                                                  |
--| Post Success:                                                                    |
--|   the delete headers lines procedure will delete all the records in regard       |
--|   the program name sent                                                          |
--| Post Failure:                                                                    |
--|   the status of the out parameter will be 'E' with the error message             |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|
    PROCEDURE cnc_delete_header_record_prc
                                  ( p_prog_name         IN  XX_OIC_ERROR_HEADERS.program_name%TYPE   --IN PARAMETER--THE PROGRAME NAME FOR WHICH THE VALIDATION HAS STARTED
                                  ) ;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|  This is a  Procedure  is  used to purge the data from the headers table         |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   None                                                                           |
--|                                                                                  |
--| Post Success:                                                                    |
--|  the data is purged from the headers table                                       |
--| Post Failure:                                                                    |
--|  the error warning will be 'E' and the error message is generated                |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|
    PROCEDURE cnc_purge_error_record_prc( p_date                    IN  VARCHAR2                          --IN PARAMETER--Date in YYYYMMDD
                                , p_no_of_headers           OUT NUMBER                            --OUT PARAMETER--THE NUMBER OF HEADERS cnc_purge_error_record_prcD
                                , p_no_of_lines             OUT NUMBER                            --OUT PARAMETER--THE TOTAL NUMBER OF LINES cnc_purge_error_record_prcD
                                , p_no_of_batch_files       OUT NUMBER                            --OUT PARAMETER--THE TOTAL NUMBER OF BATCH FILES
                                ) ;

--  -----------------------------------------------------------------------------   |
 --| --------------------------------------< >--------------------------------------- |
 --|  -----------------------------------------------------------------------------   |
 --|                                                                                  |
 --| {Start Of Comments}                                                              |
 --|                                                                                  |
 --|                                                                                  |
 --| Description:                                                                     |
 --|  This is a  Procedure  is  used to insert the errors occured while validating    |
 --|                                                                                  |
 --| Prerequisites:                                                                   |
 --|   None                                                                           |
 --|                                                                                  |
 --| Post Success:                                                                    |
 --|  all the errors occured while validating is inserted in the error lines          |
 --| Post Failure:                                                                    |
 --|  the error will be insertd in the output file.                                   |
 --|                                                                                  |
 --| Access Status:                                                                   |
 --|   Internal Development Use Only                                                  |
 --|                                                                                  |
 --| {End Of Comments}                                                                |
 --|----------------------------------------------------------------------------------|
    PROCEDURE cnc_insert_line_record_prc
                                ( p_error_message        IN  XX_OIC_ERROR_LINES.error_message%TYPE    --IN PARAMETER--ERROR MESSAGE
                                , p_field                IN  XX_OIC_ERROR_LINES.field%TYPE            --IN PARAMETER--THE PARTICULAR FEILD WHERE THE ERROR EXSIST
                                , p_field_value          IN  XX_OIC_ERROR_LINES.field_value%TYPE      --IN PARAMETER--THE VALUE WHICH HAS RAISED THE ERROR
                                , p_record_id            IN  XX_OIC_ERROR_LINES.record_id%TYPE        --IN PARAMETER--THE RECORD ID
                                ) ;

--  -----------------------------------------------------------------------------   |
 --| --------------------------------------< >--------------------------------------- |
 --|  -----------------------------------------------------------------------------   |
 --|                                                                                  |
 --| {Start Of Comments}                                                              |
 --|                                                                                  |
 --|                                                                                  |
 --| Description:                                                                     |
 --|  This is a  Procedure  is  used to show errors occured in the output file        |
 --|                                                                                  |
 --| Prerequisites:                                                                   |
 --|   None                                                                           |
 --|                                                                                  |
 --| Post Success:                                                                    |
 --|  The output file will be generated with all the errors and number of success     |
 --|  ,failure, total count                                                           |
 --| Post Failure:                                                                    |
 --|  it will return a error message which has to be handled by the executable        |
 --|                                                                                  |
 --| Access Status:                                                                   |
 --|   Internal Development Use Only                                                  |
 --|                                                                                  |
 --| {End Of Comments}                                                                |
 --|----------------------------------------------------------------------------------|
    FUNCTION cnc_show_errors_prc
                        ( p_module_name        IN VARCHAR2                           --IN PARAMETER--THE MODULE NAME
                        , p_request_id         IN NUMBER                             --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                        , p_program_id         IN NUMBER
                        )
    RETURN VARCHAR2;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|   This is a  Procedure  is  used to write the messages on the log file or the    |
--|                    output file.                                                  |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   None                                                                           |
--|                                                                                  |
--| Post Success:                                                                    |
--|   the message will be wriiten in the log file or the output file or sql promt    |
--| Post Failure:                                                                    |
--|   None                                                                           |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|

    PROCEDURE cnc_write_message_prc( p_av_level        IN NUMBER                             --IN PARAMETER--THREE LEVEL ARE THERE 1,2 are for
                           , p_av_message      IN VARCHAR2                           --IN PARAMETER--THE ERROR MESSAGE
                           ) ;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|   This is a  Procedure  is  used get the report title                            |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   It should run after the concurrent progranm has run already                    |
--|                                                                                  |
--| Post Success:                                                                    |
--|   the reprt title will be sent                                                   |
--| Post Failure:                                                                    |
--|   Do nothing                                                                     |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|------------------------------------------------------------------------------------|
    FUNCTION cnc_get_report_title_fnc( p_reqid         IN NUMBER)                   --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
    RETURN VARCHAR2;

--  -----------------------------------------------------------------------------   |
 --| --------------------------------------< >--------------------------------------- |
 --|  -----------------------------------------------------------------------------   |
 --|                                                                                  |
 --| {Start Of Comments}                                                              |
 --|                                                                                  |
 --|                                                                                  |
 --| Description:                                                                     |
 --| This is a  Procedure  is  used toverify whether the validation run was a success |
 --|                                                                                  |
 --| Prerequisites:                                                                   |
 --|   None                                                                           |
 --|                                                                                  |
 --| Post Success:                                                                    |
 --|   Return'SUCESS' else return 'FAILURE'                                           |
 --| Post Failure:                                                                    |
 --|   Return 'FAIL'                                                                  |
 --|                                                                                  |
 --| Access Status:                                                                   |
 --|   Internal Development Use Only                                                  |
 --|                                                                                  |
 --| {End Of Comments}                                                                |
 --|----------------------------------------------------------------------------------|

    FUNCTION cnc_is_program_sucess_fnc( p_program_id  IN  NUMBER )                          --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
    RETURN VARCHAR2;

--  -----------------------------------------------------------------------------   |
-- | --------------------------------------< >--------------------------------------- |
-- |  -----------------------------------------------------------------------------   |
-- |                                                                                  |
-- | {Start Of Comments}                                                              |
-- |                                                                                  |
-- |                                                                                  |
-- | Description:                                                                     |
-- | This is a  Procedure  is  used to provide with the output file format            |
-- | and show the header name on the report                                           |
-- |                                                                                  |
-- | Prerequisites:                                                                   |
-- |   None                                                                           |
-- |                                                                                  |
-- | Post Success:                                                                    |
-- |  it generates the output file report in a particular format.                     |
-- | Post Failure:                                                                    |
-- |  it returns with a error message                                                 |
-- |                                                                                  |
-- | Access Status:                                                                   |
-- |   Internal Development Use Only                                                  |
-- |                                                                                  |
-- | {End Of Comments}                                                                |
-- |----------------------------------------------------------------------------------|

    FUNCTION cnc_print_sucess_header_fnc ( p_page_no    IN  NUMBER                            --IN PARAMETER--THE PAGE NUMBER
                                 , p_request_id IN  NUMBER                            --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                 , p_header     IN VARCHAR2                           --IN PARAMETER--THE HEADER NAME
                                 )
    RETURN VARCHAR2;

--  -----------------------------------------------------------------------------   |
-- | --------------------------------------< >--------------------------------------- |
-- |  -----------------------------------------------------------------------------   |
-- |                                                                                  |
-- | {Start Of Comments}                                                              |
-- |                                                                                  |
-- |                                                                                  |
-- | Description:                                                                     |
-- | This is a  Procedure  is  used to  concatenate two strings                       |
-- |                                                                                  |
-- | Prerequisites:                                                                   |
-- |   None                                                                           |
-- |                                                                                  |
-- | Post Success:                                                                    |
-- | The two strings are concatenated                                                 |
-- | Post Failure:                                                                    |
-- | Error is raise and will be written over the fnd output file                      |
-- |                                                                                  |
-- | Access Status:                                                                   |
-- |   Internal Development Use Only                                                  |
-- |                                                                                  |
-- | {End Of Comments}                                                                |
-- |----------------------------------------------------------------------------------|
--start cnc_record_wrap_utility_fnc

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
                                  ) ;
--end cnc_record_wrap_utility_fnc
--  -----------------------------------------------------------------------------   |
-- | --------------------------------------< >--------------------------------------- |
-- |  -----------------------------------------------------------------------------   |
-- |                                                                                  |
-- | {Start Of Comments}                                                              |
-- |                                                                                  |
-- |                                                                                  |
-- | Description:                                                                     |
-- |  This Procedure  is  used to get the user/responsibility/application name        |
-- |                                                                                  |
-- | Prerequisites:                                                                   |
-- |   None                                                                           |
-- |                                                                                  |
-- | Post Success:                                                                    |
-- | the information corresponding  to the 'GL_SET_OF_BKS_NAME' will be returned      |
-- | Post Failure:                                                                    |
-- |  None                                                                            |
-- |                                                                                  |
-- | Access Status:                                                                   |
-- |   Internal Development Use Only                                                  |
-- |                                                                                  |
-- | {End Of Comments}                                                                |
-- |----------------------------------------------------------------------------------|

    FUNCTION cnc_get_set_of_book_fnc
    RETURN VARCHAR2;

--  -----------------------------------------------------------------------------   |
-- | --------------------------------------< >--------------------------------------- |
-- |  -----------------------------------------------------------------------------   |
-- |                                                                                  |
-- | {Start Of Comments}                                                              |
-- |                                                                                  |
-- |                                                                                  |
-- | Description:                                                                     |
-- |  This Procedure  is  used to print the report for the header , fotter            |
-- |                                                                                  |
-- | Prerequisites:                                                                   |
-- |  None                                                                            |
-- |                                                                                  |
-- | Post Success:                                                                    |
-- | the report is generated                                                          |
-- | Post Failure:                                                                    |
-- |  None                                                                            |
-- |                                                                                  |
-- | Access Status:                                                                   |
-- |   Internal Development Use Only                                                  |
-- |                                                                                  |
-- | {End Of Comments}                                                                |
-- |----------------------------------------------------------------------------------|
    FUNCTION cnc_report_header_footer_fnc
                                 (p_page_no      IN NUMBER                             --IN PARAMETER--THE PAGE NUMBER
                                 ,p_conc_prog_name IN apps.fnd_concurrent_programs_vl.concurrent_program_name%TYPE --IN PARAMETER--THE CONCURRENT PROGRAM NAME
                                 ,p_request_id   IN NUMBER                             --IN PARAMETER--THE REQUEST ID GENERATED OF THE CONCURRENT PROGRAM
                                 ,p_report_title IN VARCHAR2                           --IN PARAMETER--THE TITLE OF THE REPORT
                                 ,p_destination  IN VARCHAR2                           --IN PARAMETER--To find whter to wite into OUTPUT or LOG File
                                 )
    RETURN VARCHAR2 ;

--  -----------------------------------------------------------------------------   |
-- | --------------------------------------< >--------------------------------------- |
-- |  -----------------------------------------------------------------------------   |
-- |                                                                                  |
-- | {Start Of Comments}                                                              |
-- |                                                                                  |
-- |                                                                                  |
-- | Description:                                                                     |
-- |  This is a  Procedure  is  used to generate the summary log                      |
-- |                                                                                  |
-- | Prerequisites:                                                                   |
-- |  None                                                                            |
-- |                                                                                  |
-- | Post Success:                                                                    |
-- |  the error report is generated                                                   |
-- | Post Failure:                                                                    |
-- |  The exception is handled and the out parameter returncode has to be handled in  |
-- |   the main program                                                               |
-- |                                                                                  |
-- | Access Status:                                                                   |
-- |   Internal Development Use Only                                                  |
-- |                                                                                  |
-- | {End Of Comments}                                                                |
-- |----------------------------------------------------------------------------------|
    PROCEDURE  cnc_generate_summary_log_prc
                                  ( p_program_name     IN  VARCHAR2                          --IN PARAMETER--THE PROGRAM NAME
                                   , p_request_id       IN  VARCHAR2                          --IN PARAMETER--THE REQUEST ID
                                   , p_total_rec_cnt    IN  NUMBER                            --IN PARAMETER--THE TOTAL RECORD COUNT
                                   , p_valid_rec_cnt    IN  NUMBER                            --IN PARAMETER--THE VALID RECORD COUNT
                                   , p_error_rec_cnt    IN  NUMBER                            --IN PARAMETER--THE ERROR RECORD COUNT
                                   , p_retcode          OUT NUMBER                            --OUT PARAMETER--THE RETURNCODE
                                   ) ;

--  -----------------------------------------------------------------------------  |
--| --------------------------------------< >--------------------------------------- |
--|  -----------------------------------------------------------------------------   |
--|                                                                                  |
--| {Start Of Comments}                                                              |
--|                                                                                  |
--|                                                                                  |
--| Description:                                                                     |
--|  This is a  Procedure  is  used for debugging purpose                            |
--|                                                                                  |
--| Prerequisites:                                                                   |
--|   None                                                                           |
--|                                                                                  |
--| Post Success:                                                                    |
--|  the message is shown in case of any exception                                   |
--| Post Failure:                                                                    |
--|  None                                                                            |
--|                                                                                  |
--| Access Status:                                                                   |
--|   Internal Development Use Only                                                  |
--|                                                                                  |
--| {End Of Comments}                                                                |
--|----------------------------------------------------------------------------------|
    PROCEDURE  cnc_debug_message_prc ( p_debug_mode            IN  VARCHAR2                          --IN PARAMETER--THE DEBUG MODE CAN BE Y OR N
                             , p_message               IN  VARCHAR2                          --IN PARAMETER--THE THE ERROR MESSAGE
                             ) ;

END  XX_OIC_ERRORS_PKG;
/