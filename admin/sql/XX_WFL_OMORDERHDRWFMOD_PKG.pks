SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_WFL_OMORDERHDRWFMOD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                 Oracle NAIO Consulting Organization               |
-- +===================================================================+
-- | Name  : XX_WFL_OMORDERHDRWFMOD_PKG                                |
-- | Rice Id    : E0201_OrderHeaderWorkflowModification                |
-- | Description: Package containing procedure to apply holds before   |
-- |              and after booking of the sales order and perfoming   |
-- |              inventory reservations.                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   09-May-2007   Shashi Kumar     Initial draft version    |
-- |                                                                   |
-- |1.0        15-May-2007   Shashi Kumar     Based Lined after testing|
-- |                                          The dummy procedure      |
-- |                                          'External_App_Temp'      |
-- |                                          written has to be removed|
-- +===================================================================+

AS

-- Variable declared as object type referencing the global exception handling framework
---------------------------------------------------------------------------------------

g_exception xx_om_report_exception_t:= xx_om_report_exception_t('OTHERS','OTC','Order Management','Order header Workflow',NULL,NULL,NULL,NULL);

-- +===================================================================+
-- | Name  : Log_Exceptions                                            |
-- | Description: This procedure will be responsible to store all      |
-- |              the exceptions occured during the procees using      |
-- |              global custom exception handling framework           |
-- |                                                                   |
-- | Parameters:  IN:                                                  |
-- |     P_Error_Code        --Custom error code                       |
-- |     P_Error_Description --Custom Error Description                |
-- +===================================================================+

PROCEDURE log_exceptions(p_error_code        IN VARCHAR2,
                         p_error_description IN VARCHAR2
                        );
                          
-- +===================================================================+
-- | Name  : Apply_Hold_before_Booking                                 |
-- | Description: This Procedure is used to apply the holds before     |
-- |              booking and perform inventory reservation in EBS.    |
-- | Parameters:  i_itemtype                                           |
-- |              i_itemkey                                            |
-- |              activity_id                                          |
-- |              command                                              |
-- |              resultout                                            |
-- | Returns :                                                         |
-- +===================================================================+

PROCEDURE Apply_Hold_Before_Booking(
                                    i_itemtype      IN     VARCHAR2,
                                    i_itemkey       IN     VARCHAR2,
                                    activity_id     IN     NUMBER,
                                    command         IN     VARCHAR2,
                                    resultout       IN OUT VARCHAR2
                                   );

-- +===================================================================+
-- | Name  : Apply_Hold_After_Booking                                  |
-- | Description: This Procedure is used to apply the holds After      |
-- |              booking and perform inventory reservation in EBS.    |
-- | Parameters:  i_itemtype                                           |
-- |              i_itemkey                                            |
-- |              activity_id                                          |
-- |              command                                              |
-- |              resultout                                            |
-- | Returns :                                                         |
-- +===================================================================+
          
PROCEDURE APPLY_HOLD_AFTER_BOOKING(
                                   i_itemtype     IN     VARCHAR2,
                                   i_itemkey      IN     VARCHAR2,
                                   activity_id    IN     NUMBER,
                                   command        IN     VARCHAR2,
                                   resultout      IN OUT VARCHAR2
                                 );       
                                 
-- +===================================================================+
-- | Name  : Check_For_External_Approval                               |
-- | Description: This Procedure is used to check the hold is waiting  |
-- |              for an external approval.                            |
-- | Parameters:  i_itemtype                                           |
-- |              i_itemkey                                            |
-- |              activity_id                                          |
-- |              command                                              |
-- |              resultout                                            |
-- | Returns :                                                         |
-- +===================================================================+                                 

PROCEDURE Check_For_External_Approval(
                                      i_itemtype     IN     VARCHAR2,
                                      i_itemkey      IN     VARCHAR2,
                                      activity_id    IN     NUMBER,
                                      command        IN     VARCHAR2,
                                      resultout      IN OUT VARCHAR2
                                    );

-- +===================================================================+
-- | Name  : check_hold_days                                           |
-- | Description: This Procedure is used to check the hold if it has   |
-- |              to wait for specified number of days.                |
-- | Parameters:  i_itemtype                                           |
-- |              i_itemkey                                            |
-- |              activity_id                                          |
-- |              command                                              |
-- |              resultout                                            |
-- | Returns :                                                         |
-- +===================================================================+
PROCEDURE check_hold_days(
                          i_itemtype     IN     VARCHAR2,
                          i_itemkey      IN     VARCHAR2,
                          activity_id    IN     NUMBER,
                          command        IN     VARCHAR2,
                          resultout      IN OUT VARCHAR2
                         );
                        
-- +===================================================================+
-- | Name  : External_App_Temp                                         |
-- | Description: This Procedure is used as a dummy procedure so that  |
-- |              the process check for external approval completes    |
-- |              This procedure has to be removed once the external   | 
-- |              approval process is given                            |
-- | Parameters:  i_itemtype                                           |
-- |              i_itemkey                                            |
-- |              activity_id                                          |
-- |              command                                              |
-- |              resultout                                            |
-- | Returns :                                                         |
-- +===================================================================+

PROCEDURE External_App_Temp(
                            i_itemtype     IN     VARCHAR2,
                            i_itemkey      IN     VARCHAR2,
                            activity_id    IN     NUMBER,
                            command        IN     VARCHAR2,
                            resultout      IN OUT VARCHAR2
                           );

END XX_WFL_OMORDERHDRWFMOD_PKG;
/

SHOW ERRORS;
EXIT;
