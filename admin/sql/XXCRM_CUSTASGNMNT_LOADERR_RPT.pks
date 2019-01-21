create or replace
PACKAGE XXCRM_CUSTASGNMNT_LOADERR_RPT
 -- +===================================================================================== +
  -- |                  Office Depot - Project Simplify                                     |
  -- +===================================================================================== +
  -- |                                                                                      |
  -- | Name             : XXCRM_CUSTASGNMNT_LOADERR_RPT                                     |
  -- | Description      : This program is for querying and detailing CUSTOMER               |
  -- |                    ASSIGNMENT UPLOAD Error details.                                  |
  -- |                                                                                      |
  -- |                                                                                      |
  -- | This package contains the following sub programs:                                    |
  -- | =================================================                                    |
  -- |Type         Name                  Description                                        |
  -- |=========    ===========           ================================================   |
  -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
  -- |                                   the  Customer Assignment Upload Errors             |
  -- |                                           .                                          |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version   Date         Author           Remarks                                       |
  -- |=======   ==========   =============    ============================================= |
  -- |Change    05-21-2009  Mohan Kalyanasundaram New Version                               !
 -- +===================================================================================== +


 AS

     -- +====================================================================+
     -- | Name        :  display_log                                         |
     -- | Description :  This procedure is invoked to print in the log file  |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+

     PROCEDURE display_log(
                           p_message IN VARCHAR2
                          );

        -- +====================================================================+
        -- | Name        :  display_out                                         |
        -- | Description :  This procedure is invoked to print in the output    |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+

        PROCEDURE display_out(
                              p_message IN VARCHAR2
                             );


     -- +====================================================================+
     -- | Name        :  Main_Proc                                           |
     -- | Description :  This is the Main Procedure  invoked by the          |
     -- |                Concurrent Program                                  |
     -- |                file                                                |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+


   PROCEDURE Main_Proc (  x_errbuf           OUT VARCHAR2
                        , x_retcode          OUT NUMBER
                                ,p_delete_flag IN VARCHAR2);

  PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2,
    p_attribute1 IN VARCHAR2);

END;
/