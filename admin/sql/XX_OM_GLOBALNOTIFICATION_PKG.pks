SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR  EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_globalnotification_pkg

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : xx_om_globalnotification_pkg                                |
-- | Rice ID     : E0270_GlobalNotification                                    |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 10-Jul-2007  Pankaj Kapse           Initial draft version         |
-- |                                                                           |
-- +===========================================================================+

AS  -- Package Specification Starts

-- ----------------------------------
-- Global Variable Declarations
-- ----------------------------------
   gn_header_id  NUMBER   := NULL;

   ge_exception  xx_om_report_exception_t := xx_om_report_exception_t(
                                                                       'OTHERS'
                                                                      ,'OTC'
                                                                      ,'Global Notification'
                                                                      ,'Global Notification'
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                      ,NULL
                                                                     );
   -- -----------------------------------
   -- Procedure Declarations
   -- -----------------------------------

   -- +===================================================================+
   -- | Name        : Write_Exception                                     |
   -- | Description : Procedure to log exceptions from this package using |
   -- |               the Common Exception Handling Framework             |
   -- |                                                                   |
   -- | Parameters  : Error_Code                                          |
   -- |               Error_Description                                   |
   -- |               Entity_Reference                                    |
   -- |               Entity_Reference_Id                                 |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Write_Exception (
                               p_error_code        IN  VARCHAR2
                              ,p_error_description IN  VARCHAR2
                              ,p_entity_reference  IN  VARCHAR2
                              ,p_entity_ref_id     IN  VARCHAR2
                             );

   -- +===================================================================+
   -- | Name        : Process_Bussiness_Event                             |
   -- | Description : This procedure is used in concurrent program which  |
   -- |               is used to select the lastest and deffered mode     |
   -- |               custom bussiness event and processed it.            |
   -- |                                                                   |
   -- | Parameters :  p_mode                                              |
   -- |               p_cause                                             |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Process_Bussiness_Event(
                                      errbuf   OUT VARCHAR2
                                     ,retcode  OUT PLS_INTEGER
                                     );

   -- +===================================================================+
   -- | Name        : To_Raise_Bussiness_Event                            |
   -- | Description : Procedure is used to raise the custome bussiness    |
   -- |               event.                                              |
   -- |                                                                   |
   -- | Parameters :  p_mode                                              |
   -- |               p_cause                                             |
   -- |               p_order_header_id                                   |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE To_Raise_Bussiness_Event(
                                      p_mode             IN  VARCHAR2
                                     ,p_cause            IN  VARCHAR2
                                     ,p_order_header_id  IN  PLS_INTEGER
                                  );

END xx_om_globalnotification_pkg; -- End Package Specification
/
SHOW ERRORS;

EXIT;