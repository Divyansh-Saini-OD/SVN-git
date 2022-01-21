SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_WFL_ORDERHDRWFMOD_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  : XXOD_ROADNET_TO_EBS_PKG                                   |
-- | Description      : Package Specification containing UPDATION of   |
-- |                    route number and stop number in EBS            |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   25-Apr-2007   Shashi Kumar.    Initial Draft version    |
-- |                                                                   |
-- +===================================================================+
AS

-- Variable decalred as object type referencing the global exception handling framework
---------------------------------------------------------------------------------------

g_exception xxod_report_exception:= xxod_report_exception(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

-- +=============================================================+
-- | Name  : Log_Exceptions                                      |
-- | Rice Id : E0201                                             |
-- | Description: This procedure will be responsible to store all|
-- |              the exceptions occured during the procees using|
-- |              global custom exception handling framework     |
-- +=============================================================+

--PROCEDURE log_exceptions;
                          
-- +=============================================================+
-- | Name  : Apply_Hold_Before_Booking                           |
-- | Rice Id : E0201                                             |
-- | Description: This procedure will be responsible to apply    |
-- |              holds for the order befor booking at the header|
-- |              level  if reservation for the line is not done |
-- |              then reservation for that line will be done    |
-- +=============================================================+

PROCEDURE Apply_Hold_Before_Booking(
          i_itemtype      IN     VARCHAR2,
          i_itemkey       IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          );
          
PROCEDURE APPLY_HOLD_AFTER_BOOKING(
          i_itemtype      IN     VARCHAR2,
          i_itemkey       IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          );          

PROCEDURE Check_For_External_Approval(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          );

PROCEDURE check_hold_days(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          );

PROCEDURE dummy(
          i_itemtype     IN     VARCHAR2,
          i_itemkey      IN     VARCHAR2,
          activity_id    IN     NUMBER,
          command        IN     VARCHAR2,
          resultout      IN OUT VARCHAR2
          );

END XX_WFL_ORDERHDRWFMOD_PKG;
/
SHOW ERRORS;
