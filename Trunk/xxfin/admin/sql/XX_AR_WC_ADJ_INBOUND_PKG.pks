CREATE OR REPLACE PACKAGE XX_AR_WC_ADJ_INBOUND_PKG
AS
--+==========================================================================================+
--|      Office Depot - Project FIT                                                          |
--|   Capgemini/Office Depot/Consulting Organization                                         |
--+==========================================================================================+
--|Name        :XX_AR_WC_CM_INBOUND_PKG                                                      |
--|RICE        : I2161                                                                       |
--|Description :This Package is used for creating Credit Memo in Oracle AR                   |
--|                                                                                          |
--|              1.It will create the CM in oracle based on WC staging table data            |
--|                                                                                          |
--|                                                                                          |
--|                                                                                          |
--|Change Record:                                                                            |
--|==============                                                                            |
--|Version    Date           Author                       Remarks                            |
--|=======   ======        ====================          =========                           |
--|1.0      21-Nov-2011    Maheswararao N              Intial creation                       |
--|                                                                                          |
--+==========================================================================================+

   -- This procedure is used to register through a concurrent program and calls the above procedures.
   PROCEDURE CREATE_ADJ(
      p_errbuf    OUT      VARCHAR2,
      p_retcode   OUT      NUMBER,
      p_debug     IN       VARCHAR2
   );
END XX_AR_WC_ADJ_INBOUND_PKG;
/

SHOW ERRORS;
