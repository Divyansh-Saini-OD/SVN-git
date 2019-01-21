SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_SL_REP_UNASSGN_INT_CUST package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_SL_REP_UNASSGN_INT_CUST
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_SL_REP_UNASSGN_INT_CUST                                |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Unassign Internal Customers' to unassign      |
-- |                     the party sites of the internal customer in the custom        |
-- |                     assignments entity table                                      |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    End_Date_Entity         This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  11-Jan-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------
G_APPLICATION_NAME              CONSTANT  VARCHAR2(10) := 'XXCRM';
G_PROGRAM_TYPE                  CONSTANT  VARCHAR2(50) := 'E1309_Autonamed_Account_Creation';
G_MODULE_NAME                   CONSTANT  VARCHAR2(80) := 'TM';
G_MEDIUM_ERROR_MSG_SEVERTY      CONSTANT  VARCHAR2(30) := 'MEDIUM';
G_MAJOR_ERROR_MESSAGE_SEVERITY  CONSTANT  VARCHAR2(30) := 'MAJOR';
G_ERROR_STATUS_FLAG             CONSTANT  VARCHAR2(10) := 'ACTIVE';
G_LIMIT                         CONSTANT  PLS_INTEGER  := 10000;
G_COMMIT                        CONSTANT  PLS_INTEGER  := 1000;

----------------------------
--Declaring Global Variables
----------------------------
gn_program_id   PLS_INTEGER  := FND_GLOBAL.CONC_REQUEST_ID;

-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : end_date_entity                                           |
-- |                                                                   |
-- | Description: This is a public procedure which will get called     |
-- |              from the concurrent program 'OD: TM Unassign Internal| 
-- |              Customers' to unassign the party sites of the        | 
-- |              internal customer in the custom assignments entity   | 
-- |              table                                                |     
-- +===================================================================+

PROCEDURE end_date_entity
            (
               x_errbuf     OUT NOCOPY VARCHAR2
             , x_retcode    OUT NOCOPY NUMBER
            );

END XX_JTF_SL_REP_UNASSGN_INT_CUST;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

