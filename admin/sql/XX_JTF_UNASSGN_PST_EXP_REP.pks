SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_UNASSGN_PST_EXP_REP package specification
PROMPT

CREATE OR REPLACE PACKAGE XX_JTF_UNASSGN_PST_EXP_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_UNASSGN_PST_EXP_REP                                    |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Unassigned Party Sites Exception Report' with |
-- |                     Party Site ID From and Party Site ID To as the Input          |  
-- |                     parameters. This public procedure will create a report        |
-- |                     consisting of the party sites of external customers that are  |
-- |                     not assigned to any of the sales reps                         |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Create_Exception_Report This is the public procedure.                 |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  30-Jan-07   Abhradip Ghosh               Initial draft version           |
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
-- | Name  : create_exception_report                                   |
-- |                                                                   |
-- | Description:       This is the public procedure which will get    |
-- |                    called from the concurrent program 'OD: TM     | 
-- |                    Unassigned Party Sites Exception Report' with  |
-- |                    Party Site ID From and Party Site ID To as the |
-- |                    Input parameters to  create a report consisting|
-- |                    of the party sites of external customers that  |
-- |                    that are not assigned to any of the sales reps |
-- |                                                                   |
-- +===================================================================+

PROCEDURE create_exception_report
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
             , p_from_party_site_id IN  NUMBER
             , p_to_party_site_id   IN  NUMBER
            );

END XX_JTF_UNASSGN_PST_EXP_REP;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
