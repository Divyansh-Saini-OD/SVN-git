SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK


 CREATE OR REPLACE PACKAGE XX_ASN_ACCT_REQ_REPORT_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_ASN_ACCT_REQ_REPORT_PKG                                        |
 -- | Description      : This program is for querying and detailing ASN ACCOUNT SETUP      |
 -- |                    REQUEST details.                                                  |
 -- |                                                                                      | 
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  Account setup request details                 |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  18-JUL-2008  Satyasrinivas    Initial draft version                         |
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
                        , p_start_date       IN VARCHAR2
                        , p_end_date         IN VARCHAR2 
                    );

END;

/ 
SHOW ERRORS;
