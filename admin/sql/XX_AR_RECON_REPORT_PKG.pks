CREATE OR REPLACE PACKAGE XX_AR_RECON_REPORT_PKG
AS
--+==========================================================================================+
--|      Office Depot - Project FIT                                                          |
--|   Capgemini/Office Depot/Consulting Organization                                         |
--+==========================================================================================+
--|Name        :XX_AR_RECON_REPORT_PKG                                                       |
--|RICE        :                                                                             |
--|Description :This Package is used for AR Recon Reporting after extract                    |
--|                                                                                          |
--|              1.It will provide a detail report on AR Recon data based on stage data      |
--|                                                                                          |
--|                                                                                          |
--|                                                                                          |
--|Change Record:                                                                            |
--|==============                                                                            |
--|Version    Date           Author                       Remarks                            |
--|=======   ======        ====================          =========                           |
--|1.0      03-Oct-2011    Maheswararao N              Initial Version                       |
--|1.1      21-Oct-2011    Maheswararao N              Modified based on MD70 changes        |
--|                                                                                          |
--+==========================================================================================+

   -- This procedure is used to register through a concurrent program and calls the above procedures.
   PROCEDURE ar_recon_report (
      p_errbuf    OUT      VARCHAR2,
      p_retcode   OUT      NUMBER,     
      p_debug     IN       VARCHAR2,
      p_process_type IN    VARCHAR2
   );
END XX_AR_RECON_REPORT_PKG;
/

SHOW ERRORS;
